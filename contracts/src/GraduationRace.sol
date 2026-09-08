// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "./interfaces/IERC20.sol";
import {IResolveKeeper} from "./interfaces/IResolveKeeper.sol";
import {IPonsV2LaunchFactory} from "./interfaces/IPonsV2LaunchFactory.sol";

/// @title Hood Arena — Graduation Race (3-up pick)
/// @notice Stake USDG on which of three PONS launches graduates first.
/// @dev Resolve: factory VIEW phase==2 + earliest sweptAt among *valid* YES candidates;
///      equal sweptAt → lowest token address (never strand both).
///      Valid YES: phase==2 AND (now <= T OR (sweptAt != 0 && sweptAt < T)).
///      If any member is phase==1 (Swept) with sweptAt < deadline, wait until T+grace
///      before resolving another phase==2 winner (give Swept time to become PoolCreated).
///      After grace: among valid phase==2 pick earliest sweptAt then address; if none, cancelRace.
///      Permissionless. Empty win pot → auto-cancel+refund (mirror Arena). Trusted-keeper REJECTED.
///      LIVE LOCKED — dry sketch only. Do not broadcast.
contract GraduationRace is IResolveKeeper {
    uint8 internal constant PHASE_SWEPT = 1;
    uint8 internal constant PHASE_POOL_CREATED = 2;

    uint16 public immutable feeBps;
    /// @notice Grace after T: wait for Swept siblings before resolve/cancel
    uint64 public immutable gracePeriod;
    IERC20 public immutable usdg;
    address public immutable ponsFactory;

    address public constant DEFAULT_PONS_FACTORY = 0x7eD598BcEf8bd9Edd8C97A195C6d13f40801EC7e;
    bytes32 public constant POOL_GRADUATED_TOPIC0 =
        0x0a44ef75df69c534f43cd6c1aa3ef8983065fe5fe79ef9e79f6494e6f258c259;

    address public feeRecipient;
    address public owner;
    mapping(address => bool) public keepers;

    enum Status {
        Open,
        Locked,
        Resolved,
        Cancelled
    }

    struct Race {
        address token0;
        address token1;
        address token2;
        uint64 deadline;
        uint256 pot0;
        uint256 pot1;
        uint256 pot2;
        address winner;
        Status status;
        bool exists;
        uint64 sweptAt; // factory sweptAt of winner on resolve
    }

    uint256 public nextRaceId = 1;
    mapping(uint256 => Race) public races;
    mapping(uint256 => mapping(address => mapping(uint8 => uint256))) public stakes;
    mapping(uint256 => mapping(address => bool)) public claimed;

    event RaceCreated(
        uint256 indexed raceId, address token0, address token1, address token2, uint64 deadline
    );
    event Staked(uint256 indexed raceId, address indexed user, uint8 pick, uint256 amount);
    event Locked(uint256 indexed raceId);
    event Resolved(uint256 indexed raceId, address winner);
    event FactoryResolved(
        uint256 indexed raceId, address indexed winner, uint8 phase, uint256 sweptAt
    );
    event Cancelled(uint256 indexed raceId);
    event Claimed(uint256 indexed raceId, address indexed user, uint256 payout);
    event KeeperSet(address indexed keeper, bool enabled);
    event FeeRecipientSet(address indexed feeRecipient);

    error NotOwner();
    error NotKeeper();
    error InvalidFee();
    error InvalidFeeRecipient();
    error InvalidDeadline();
    error InvalidTokens();
    error InvalidAmount();
    error InvalidPick();
    error TokenNotLaunched();
    error NotPoolCreated();
    error YesTimeWindowClosed();
    error NotEarliestSweptAt();
    error StillGraduated();
    error SweptSiblingPending();
    error RaceMissing();
    error NotOpen();
    error DeadlinePassed();
    error DeadlineNotReached();
    error AlreadyResolved();
    error BadWinner();
    error NothingToClaim();
    error AlreadyClaimed();
    error ArenaNotSupported();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyKeeper() {
        if (!_isKeeper(msg.sender)) revert NotKeeper();
        _;
    }

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

    function createRace(address t0, address t1, address t2, uint64 deadline)
        external
        onlyOwner
        returns (uint256 raceId)
    {
        if (deadline <= block.timestamp) revert InvalidDeadline();
        if (t0 == address(0) || t1 == address(0) || t2 == address(0)) revert InvalidTokens();
        if (t0 == t1 || t0 == t2 || t1 == t2) revert InvalidTokens();
        _requireExists(t0);
        _requireExists(t1);
        _requireExists(t2);

        raceId = nextRaceId++;
        races[raceId] = Race({
            token0: t0,
            token1: t1,
            token2: t2,
            deadline: deadline,
            pot0: 0,
            pot1: 0,
            pot2: 0,
            winner: address(0),
            status: Status.Open,
            exists: true,
            sweptAt: 0
        });
        emit RaceCreated(raceId, t0, t1, t2, deadline);
    }

    function lockRace(uint256 raceId) external onlyKeeper {
        Race storage r = races[raceId];
        if (!r.exists) revert RaceMissing();
        if (r.status != Status.Open) revert NotOpen();
        r.status = Status.Locked;
        emit Locked(raceId);
    }

    function stake(uint256 raceId, uint8 pick, uint256 amount) external {
        if (amount == 0) revert InvalidAmount();
        if (pick > 2) revert InvalidPick();
        Race storage r = races[raceId];
        if (!r.exists) revert RaceMissing();
        if (r.status != Status.Open) revert NotOpen();
        if (block.timestamp >= r.deadline) revert DeadlinePassed();

        require(usdg.transferFrom(msg.sender, address(this), amount), "transferFrom");
        stakes[raceId][msg.sender][pick] += amount;
        if (pick == 0) r.pot0 += amount;
        else if (pick == 1) r.pot1 += amount;
        else r.pot2 += amount;

        emit Staked(raceId, msg.sender, pick, amount);
    }

    /// @inheritdoc IResolveKeeper
    /// @dev Permissionless. winner must be valid YES; earliest sweptAt among valid YES;
    ///      equal sweptAt → lowest address. Empty win pot → cancel+refund (Arena mirror).
    ///      Blocks while any sibling is Swept with sweptAt < T until T+grace.
    function resolveRace(uint256 raceId, address winnerToken) external {
        Race storage r = races[raceId];
        if (!r.exists) revert RaceMissing();
        if (r.status != Status.Open && r.status != Status.Locked) revert AlreadyResolved();

        uint8 wPick = _pickOf(r, winnerToken); // membership bind
        IPonsV2LaunchFactory.LaunchedToken memory w =
            IPonsV2LaunchFactory(ponsFactory).getLaunchedToken(winnerToken);
        if (!w.exists) revert TokenNotLaunched();
        if (uint8(w.phase) != PHASE_POOL_CREATED) revert NotPoolCreated();

        // YES clock: now <= T OR (sweptAt != 0 && sweptAt < T)
        if (block.timestamp > r.deadline) {
            if (w.sweptAt == 0 || w.sweptAt >= r.deadline) revert YesTimeWindowClosed();
        }

        _requireNoPendingSweptSibling(r);
        _requireEarliestOrSole(r, winnerToken, w.sweptAt);

        // Empty win pot would strand losers — auto-cancel + refund path (mirror Arena)
        if (_pot(r, wPick) == 0) {
            r.status = Status.Cancelled;
            r.winner = address(0);
            emit Cancelled(raceId);
            return;
        }

        r.winner = winnerToken;
        r.sweptAt = uint64(w.sweptAt > type(uint64).max ? type(uint64).max : w.sweptAt);
        r.status = Status.Resolved;
        emit FactoryResolved(raceId, winnerToken, uint8(w.phase), w.sweptAt);
        emit Resolved(raceId, winnerToken);
    }

    /// @inheritdoc IResolveKeeper
    /// @dev Permissionless after deadline when no *valid* YES winner exists
    ///      (phase==2 AND sweptAt!=0 AND sweptAt < T after deadline; before T any phase==2).
    ///      Late-invalid PoolCreated (phase==2, bad sweptAt) does NOT block cancel.
    ///      If a Swept sibling (phase==1, sweptAt < T) exists, wait until T+grace.
    function cancelRace(uint256 raceId) external {
        Race storage r = races[raceId];
        if (!r.exists) revert RaceMissing();
        if (r.status != Status.Open && r.status != Status.Locked) revert AlreadyResolved();
        if (block.timestamp < r.deadline) revert DeadlineNotReached();

        if (_anyValidYesWinner(r)) revert StillGraduated();
        _requireNoPendingSweptSibling(r);

        r.status = Status.Cancelled;
        r.winner = address(0);
        emit Cancelled(raceId);
    }

    function claim(uint256 raceId) external returns (uint256 payout) {
        Race storage r = races[raceId];
        if (!r.exists) revert RaceMissing();
        if (claimed[raceId][msg.sender]) revert AlreadyClaimed();

        if (r.status == Status.Cancelled) {
            payout = stakes[raceId][msg.sender][0] + stakes[raceId][msg.sender][1]
                + stakes[raceId][msg.sender][2];
            if (payout == 0) revert NothingToClaim();
            claimed[raceId][msg.sender] = true;
            stakes[raceId][msg.sender][0] = 0;
            stakes[raceId][msg.sender][1] = 0;
            stakes[raceId][msg.sender][2] = 0;
            require(usdg.transfer(msg.sender, payout), "transfer");
            emit Claimed(raceId, msg.sender, payout);
            return payout;
        }

        if (r.status != Status.Resolved) revert NothingToClaim();
        uint8 winPick = _pickOf(r, r.winner);
        uint256 userStake = stakes[raceId][msg.sender][winPick];
        if (userStake == 0) revert NothingToClaim();

        uint256 winPot = _pot(r, winPick);
        uint256 losePot = r.pot0 + r.pot1 + r.pot2 - winPot;
        uint256 fee = (losePot * feeBps) / 10_000;
        uint256 distributable = losePot - fee;
        payout = userStake + (distributable * userStake) / winPot;

        claimed[raceId][msg.sender] = true;
        stakes[raceId][msg.sender][winPick] = 0;

        uint256 userFeeShare = (fee * userStake) / winPot;
        if (userFeeShare > 0) {
            require(usdg.transfer(feeRecipient, userFeeShare), "fee");
        }
        require(usdg.transfer(msg.sender, payout), "transfer");
        emit Claimed(raceId, msg.sender, payout);
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

    function resolveArenaYes(uint256) external pure {
        revert ArenaNotSupported();
    }

    function resolveArenaNo(uint256) external pure {
        revert ArenaNotSupported();
    }

    function _isKeeper(address who) internal view returns (bool) {
        return keepers[who] || who == owner;
    }

    function _requireExists(address token) internal view {
        IPonsV2LaunchFactory.LaunchedToken memory lt =
            IPonsV2LaunchFactory(ponsFactory).getLaunchedToken(token);
        if (!lt.exists) revert TokenNotLaunched();
    }

    /// @dev Valid YES candidate under the product clock (same rule as resolveRace).
    function _isValidYesCandidate(IPonsV2LaunchFactory.LaunchedToken memory lt, uint64 deadline)
        internal
        view
        returns (bool)
    {
        if (!lt.exists || uint8(lt.phase) != PHASE_POOL_CREATED) return false;
        if (block.timestamp > deadline) {
            return lt.sweptAt != 0 && lt.sweptAt < deadline;
        }
        return true;
    }

    /// @dev True if any member is a valid YES winner (StillGraduated gate for cancel).
    function _anyValidYesWinner(Race storage r) internal view returns (bool) {
        IPonsV2LaunchFactory fac = IPonsV2LaunchFactory(ponsFactory);
        if (_isValidYesCandidate(fac.getLaunchedToken(r.token0), r.deadline)) return true;
        if (_isValidYesCandidate(fac.getLaunchedToken(r.token1), r.deadline)) return true;
        if (_isValidYesCandidate(fac.getLaunchedToken(r.token2), r.deadline)) return true;
        return false;
    }

    /// @dev Before T+grace: if any member is Swept (phase==1) with sweptAt < deadline,
    ///      do not resolve/cancel yet — give them time to become PoolCreated.
    function _requireNoPendingSweptSibling(Race storage r) internal view {
        if (block.timestamp >= uint256(r.deadline) + uint256(gracePeriod)) return;

        address[3] memory tokens = [r.token0, r.token1, r.token2];
        IPonsV2LaunchFactory fac = IPonsV2LaunchFactory(ponsFactory);
        for (uint256 i = 0; i < 3; i++) {
            IPonsV2LaunchFactory.LaunchedToken memory o = fac.getLaunchedToken(tokens[i]);
            if (o.exists && uint8(o.phase) == PHASE_SWEPT && o.sweptAt < r.deadline) {
                revert SweptSiblingPending();
            }
        }
    }

    /// @dev Winner must have earliest sweptAt among *valid* YES candidates;
    ///      equal sweptAt → lowest address. Late-invalid phase==2 ignored.
    function _requireEarliestOrSole(Race storage r, address winner, uint256 winnerSweptAt)
        internal
        view
    {
        address[3] memory tokens = [r.token0, r.token1, r.token2];
        IPonsV2LaunchFactory fac = IPonsV2LaunchFactory(ponsFactory);
        for (uint256 i = 0; i < 3; i++) {
            if (tokens[i] == winner) continue;
            IPonsV2LaunchFactory.LaunchedToken memory o = fac.getLaunchedToken(tokens[i]);
            if (!_isValidYesCandidate(o, r.deadline)) continue;
            if (o.sweptAt < winnerSweptAt) revert NotEarliestSweptAt();
            if (o.sweptAt == winnerSweptAt && tokens[i] < winner) revert NotEarliestSweptAt();
        }
    }

    function _pickOf(Race storage r, address token) internal view returns (uint8) {
        if (token == r.token0) return 0;
        if (token == r.token1) return 1;
        if (token == r.token2) return 2;
        revert BadWinner();
    }

    function _pot(Race storage r, uint8 pick) internal view returns (uint256) {
        if (pick == 0) return r.pot0;
        if (pick == 1) return r.pot1;
        return r.pot2;
    }
}
