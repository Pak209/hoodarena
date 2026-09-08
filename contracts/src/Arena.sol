// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "./interfaces/IERC20.sol";
import {IResolveKeeper} from "./interfaces/IResolveKeeper.sol";
import {IPonsV2LaunchFactory} from "./interfaces/IPonsV2LaunchFactory.sol";

/// @title Hood Arena — binary YES/NO PONS graduation escrow
/// @notice Stake USDG on whether a PONS launch graduates before deadline T.
/// @dev Resolve: **on-chain factory VIEW** — `getLaunchedToken(token).phase == 2`
///      (PoolCreated). Permissionless. Trusted-keeper / freeform graduatedAt REJECTED by Pak.
///      YES product clock: phase==2 AND (now <= T OR (sweptAt != 0 && sweptAt < T))
///      — intentional “swept before T and eventually PoolCreated” (no poolCreatedAt on-chain).
///      LIVE LOCKED — dry only. Do not broadcast.
contract Arena is IResolveKeeper {
    uint8 internal constant PHASE_NOT_GRADUATED = 0;
    uint8 internal constant PHASE_SWEPT = 1;
    uint8 internal constant PHASE_POOL_CREATED = 2;
    uint8 internal constant PHASE_RESCUED = 3;

    uint16 public immutable feeBps;
    /// @notice Grace after T: wait for Swept→PoolCreated; gates early NO + strand escape
    uint64 public immutable gracePeriod;
    IERC20 public immutable usdg;
    /// @notice PONS V2 LaunchFactory — source of truth for exists + phase + sweptAt
    address public immutable ponsFactory;

    /// @notice Default factory when constructor passes address(0)
    address public constant DEFAULT_PONS_FACTORY = 0x7eD598BcEf8bd9Edd8C97A195C6d13f40801EC7e;
    /// @notice PoolGraduated topic0 — audit/watcher pin only (resolve keys off phase VIEW)
    bytes32 public constant POOL_GRADUATED_TOPIC0 =
        0x0a44ef75df69c534f43cd6c1aa3ef8983065fe5fe79ef9e79f6494e6f258c259;

    address public feeRecipient;
    mapping(address => bool) public keepers;
    address public owner;

    enum Status {
        Open,
        Locked,
        ResolvedYes,
        ResolvedNo,
        Cancelled
    }

    struct ArenaData {
        address token;
        uint64 deadline;
        uint256 yesPool;
        uint256 noPool;
        Status status;
        bool exists;
        uint64 sweptAt; // copied from factory on YES resolve (audit); 0 otherwise
    }

    uint256 public nextArenaId = 1;
    mapping(uint256 => ArenaData) public arenas;
    mapping(uint256 => mapping(address => uint256)) public yesStake;
    mapping(uint256 => mapping(address => uint256)) public noStake;
    mapping(uint256 => mapping(address => bool)) public claimed;

    event ArenaCreated(uint256 indexed arenaId, address indexed token, uint64 deadline);
    event Staked(uint256 indexed arenaId, address indexed user, bool yes, uint256 amount);
    event Locked(uint256 indexed arenaId);
    event Resolved(uint256 indexed arenaId, Status status);
    event FactoryResolved(
        uint256 indexed arenaId, address indexed token, uint8 phase, uint256 sweptAt
    );
    event Claimed(uint256 indexed arenaId, address indexed user, uint256 payout);
    event Cancelled(uint256 indexed arenaId);
    event KeeperSet(address indexed keeper, bool enabled);
    event FeeRecipientSet(address indexed feeRecipient);

    error NotOwner();
    error NotKeeper();
    error InvalidFee();
    error InvalidFeeRecipient();
    error InvalidDeadline();
    error InvalidAmount();
    error InvalidFactory();
    error TokenNotLaunched();
    error NotPoolCreated();
    error YesTimeWindowClosed();
    error StillGraduated();
    error SweptPending();
    error GraceNotElapsed();
    error LateYesStillAvailable();
    error ArenaMissing();
    error NotOpen();
    error DeadlinePassed();
    error DeadlineNotReached();
    error AlreadyResolved();
    error NothingToClaim();
    error AlreadyClaimed();
    error HasStakes();
    error RaceNotSupported();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyKeeper() {
        if (!_isKeeper(msg.sender)) revert NotKeeper();
        _;
    }

    /// @param ponsFactory_ PONS factory; address(0) → DEFAULT_PONS_FACTORY
    constructor(address usdg_, uint16 feeBps_, address feeRecipient_, address ponsFactory_) {
        if (feeBps_ > 1000) revert InvalidFee();
        if (feeRecipient_ == address(0)) revert InvalidFeeRecipient();
        usdg = IERC20(usdg_);
        feeBps = feeBps_;
        feeRecipient = feeRecipient_;
        gracePeriod = 1 days;
        ponsFactory = ponsFactory_ == address(0) ? DEFAULT_PONS_FACTORY : ponsFactory_;
        owner = msg.sender;
        keepers[msg.sender] = true;
    }

    function createArena(address token, uint64 deadline) external onlyOwner returns (uint256 arenaId) {
        if (deadline <= block.timestamp) revert InvalidDeadline();
        if (token == address(0)) revert TokenNotLaunched();
        _requireExists(token);
        arenaId = nextArenaId++;
        arenas[arenaId] = ArenaData({
            token: token,
            deadline: deadline,
            yesPool: 0,
            noPool: 0,
            status: Status.Open,
            exists: true,
            sweptAt: 0
        });
        emit ArenaCreated(arenaId, token, deadline);
    }

    /// @notice Close staking early (Open → Locked). Resolve still allowed.
    function lockArena(uint256 arenaId) external onlyKeeper {
        ArenaData storage a = arenas[arenaId];
        if (!a.exists) revert ArenaMissing();
        if (a.status != Status.Open) revert NotOpen();
        a.status = Status.Locked;
        emit Locked(arenaId);
    }

    function stake(uint256 arenaId, bool yes, uint256 amount) external {
        if (amount == 0) revert InvalidAmount();
        ArenaData storage a = arenas[arenaId];
        if (!a.exists) revert ArenaMissing();
        if (a.status != Status.Open) revert NotOpen();
        if (block.timestamp >= a.deadline) revert DeadlinePassed();

        bool ok = usdg.transferFrom(msg.sender, address(this), amount);
        require(ok, "transferFrom");

        if (yes) {
            yesStake[arenaId][msg.sender] += amount;
            a.yesPool += amount;
        } else {
            noStake[arenaId][msg.sender] += amount;
            a.noPool += amount;
        }
        emit Staked(arenaId, msg.sender, yes, amount);
    }

    /// @inheritdoc IResolveKeeper
    /// @dev Permissionless. phase==2 required.
    ///      Time: now <= deadline OR (sweptAt != 0 && sweptAt < deadline).
    ///      Intentional product clock: swept-before-T + eventually PoolCreated (no poolCreatedAt).
    function resolveArenaYes(uint256 arenaId) external {
        ArenaData storage a = arenas[arenaId];
        if (!a.exists) revert ArenaMissing();
        if (a.status != Status.Open && a.status != Status.Locked) revert AlreadyResolved();

        IPonsV2LaunchFactory.LaunchedToken memory lt =
            IPonsV2LaunchFactory(ponsFactory).getLaunchedToken(a.token);
        if (!lt.exists) revert TokenNotLaunched();
        if (uint8(lt.phase) != PHASE_POOL_CREATED) revert NotPoolCreated();

        // YES = phase==2 AND (now <= T OR (sweptAt != 0 && sweptAt < T))
        if (block.timestamp > a.deadline) {
            if (lt.sweptAt == 0 || lt.sweptAt >= a.deadline) revert YesTimeWindowClosed();
        }

        // Empty YES pool would strand NO stakes — auto-cancel + refund path
        if (a.yesPool == 0) {
            a.status = Status.Cancelled;
            emit Cancelled(arenaId);
            return;
        }

        a.sweptAt = uint64(lt.sweptAt > type(uint64).max ? type(uint64).max : lt.sweptAt);
        a.status = Status.ResolvedYes;
        emit FactoryResolved(arenaId, a.token, uint8(lt.phase), lt.sweptAt);
        emit Resolved(arenaId, Status.ResolvedYes);
    }

    /// @inheritdoc IResolveKeeper
    /// @dev Permissionless after deadline.
    ///      Before T+grace: NO only if phase==0 (NotGraduated) or phase==3 (Rescued).
    ///      Revert if phase==1 (Swept — wait for createGraduatedPool) or phase==2 (should YES).
    ///      After grace: NO if phase!=2 (incl. stuck Swept).
    function resolveArenaNo(uint256 arenaId) external {
        ArenaData storage a = arenas[arenaId];
        if (!a.exists) revert ArenaMissing();
        if (a.status != Status.Open && a.status != Status.Locked) revert AlreadyResolved();
        if (block.timestamp < a.deadline) revert DeadlineNotReached();

        IPonsV2LaunchFactory.LaunchedToken memory lt =
            IPonsV2LaunchFactory(ponsFactory).getLaunchedToken(a.token);
        // Missing factory record → treat as NotGraduated (phase 0)
        uint8 phase = lt.exists ? uint8(lt.phase) : PHASE_NOT_GRADUATED;

        if (phase == PHASE_POOL_CREATED) revert StillGraduated();

        bool pastGrace = block.timestamp >= uint256(a.deadline) + uint256(gracePeriod);
        if (!pastGrace) {
            // Before grace: only clear fails (0 / 3). Swept (1) must wait.
            if (phase == PHASE_SWEPT) revert SweptPending();
            if (phase != PHASE_NOT_GRADUATED && phase != PHASE_RESCUED) revert SweptPending();
        }
        // After grace: any phase != 2 is NO (incl. stuck Swept)

        if (a.noPool == 0) {
            a.status = Status.Cancelled;
            emit Cancelled(arenaId);
            return;
        }
        a.status = Status.ResolvedNo;
        emit Resolved(arenaId, Status.ResolvedNo);
    }

    function claim(uint256 arenaId) external returns (uint256 payout) {
        ArenaData storage a = arenas[arenaId];
        if (!a.exists) revert ArenaMissing();
        if (claimed[arenaId][msg.sender]) revert AlreadyClaimed();

        if (a.status == Status.Cancelled) {
            payout = yesStake[arenaId][msg.sender] + noStake[arenaId][msg.sender];
            if (payout == 0) revert NothingToClaim();
            claimed[arenaId][msg.sender] = true;
            yesStake[arenaId][msg.sender] = 0;
            noStake[arenaId][msg.sender] = 0;
            require(usdg.transfer(msg.sender, payout), "transfer");
            emit Claimed(arenaId, msg.sender, payout);
            return payout;
        }

        if (a.status != Status.ResolvedYes && a.status != Status.ResolvedNo) revert NothingToClaim();

        bool yesWon = a.status == Status.ResolvedYes;
        uint256 userStake = yesWon ? yesStake[arenaId][msg.sender] : noStake[arenaId][msg.sender];
        if (userStake == 0) revert NothingToClaim();

        uint256 winPool = yesWon ? a.yesPool : a.noPool;
        uint256 losePool = yesWon ? a.noPool : a.yesPool;
        uint256 fee = (losePool * feeBps) / 10_000;
        uint256 distributable = losePool - fee;
        payout = userStake + (distributable * userStake) / winPool;

        claimed[arenaId][msg.sender] = true;
        if (yesWon) {
            yesStake[arenaId][msg.sender] = 0;
        } else {
            noStake[arenaId][msg.sender] = 0;
        }

        if (fee > 0) {
            uint256 userFeeShare = (fee * userStake) / winPool;
            if (userFeeShare > 0) {
                require(usdg.transfer(feeRecipient, userFeeShare), "fee");
            }
        }

        require(usdg.transfer(msg.sender, payout), "transfer");
        emit Claimed(arenaId, msg.sender, payout);
    }

    /// @notice Cancel + refund.
    /// @dev (1) Owner may cancel while Open/Locked with no stakes.
    ///      (2) Permissionless strand escape after T+grace when phase==2 but late YES fails
    ///      (`sweptAt==0 || sweptAt >= deadline`) — neither YES nor NO is fair.
    function cancelArena(uint256 arenaId) external {
        ArenaData storage a = arenas[arenaId];
        if (!a.exists) revert ArenaMissing();
        if (a.status != Status.Open && a.status != Status.Locked) revert AlreadyResolved();

        // Owner empty cancel
        if (msg.sender == owner && a.yesPool + a.noPool == 0) {
            a.status = Status.Cancelled;
            emit Cancelled(arenaId);
            return;
        }

        // Strand escape: after grace, phase==2, late YES unavailable
        if (block.timestamp < uint256(a.deadline) + uint256(gracePeriod)) {
            if (msg.sender == owner) revert HasStakes();
            revert GraceNotElapsed();
        }

        IPonsV2LaunchFactory.LaunchedToken memory lt =
            IPonsV2LaunchFactory(ponsFactory).getLaunchedToken(a.token);
        if (!lt.exists || uint8(lt.phase) != PHASE_POOL_CREATED) revert NotPoolCreated();
        // Late YES still fair → do not cancel
        if (lt.sweptAt != 0 && lt.sweptAt < a.deadline) revert LateYesStillAvailable();

        a.status = Status.Cancelled;
        emit Cancelled(arenaId);
    }

    function setKeeper(address keeper, bool enabled) external onlyOwner {
        keepers[keeper] = enabled;
        emit KeeperSet(keeper, enabled);
    }

    function setFeeRecipient(address feeRecipient_) external onlyOwner {
        if (feeRecipient_ == address(0)) revert InvalidFeeRecipient();
        feeRecipient = feeRecipient_;
        emit FeeRecipientSet(feeRecipient_);
    }

    function resolveRace(uint256, address) external pure {
        revert RaceNotSupported();
    }

    function cancelRace(uint256) external pure {
        revert RaceNotSupported();
    }

    function _isKeeper(address who) internal view returns (bool) {
        return keepers[who] || who == owner;
    }

    function _requireExists(address token) internal view {
        IPonsV2LaunchFactory.LaunchedToken memory lt =
            IPonsV2LaunchFactory(ponsFactory).getLaunchedToken(token);
        if (!lt.exists) revert TokenNotLaunched();
    }
}
