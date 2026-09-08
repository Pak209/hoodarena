// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "./interfaces/IERC20.sol";
import {PlayerCard} from "./PlayerCard.sol";

/// @title Hood Arena — Mode C pack sale + commit-reveal open
/// @notice Buy with USDG (feeBps=100 to treasury), commit, wait delay, reveal → mint AF cards.
/// @dev Spec: SPEC_CARDS.md §5 + §12b + §12c. Matches cosmetic only — never escrows match USDG.
///      Starter guarantee: each pack mints 5 distinct compressed AF positions (QB..DB) so `/match` is playable immediately (K is pack-random later / optional).
///
/// ## RNG (documented bias)
/// Commit-reveal + post-commit block entropy:
///   seed = keccak256(secret, salt, packId, blockhash(commitBlock + revealDelay))
/// Opener chooses secret before seeing the reveal-block hash (commit first).
/// Bias remaining: (1) opener may abandon reveal if seed is "bad" (mitigated by
/// snapshotted `abandonBlock` after which anyone can burn unrevealed pack — no refund);
/// (2) validators who can influence blockhash within delay — documented; prefer
/// Chainlink VRF when available on RH. Not VRF-grade fairness.
/// A1: if `blockhash(unlockBlock)==0` reveal REVERTS (no prevrandao fallback) — buyer must abandon.
/// A1: revealDelay/abandonWindow snapshotted onto Pack at commit (absolute unlock/abandon blocks).
/// MEDIUM: prefer `buyAndCommit`; Purchased-only packs refundable after `purchaseRefundBlocks`.
/// Minter: PlayerCard should list only this CardPack as minter before any broadcast.
/// §12c rarity weights are **per position** (bps/10_000); see rarityWeights(pos).
/// LIVE LOCKED for mainnet broadcast; dry/testnet OK.
contract CardPack {
    uint16 public constant FEE_BPS = 100; // Spec lock
    uint16 public constant BPS_DENOM = 10_000;

    // §12c SKILL/LINE_D baseline aliases (UI odds sheet) — prefer rarityWeights(pos)
    uint16 public constant W_COMMON = 6000;
    uint16 public constant W_RARE = 2500;
    uint16 public constant W_EPIC = 1200;
    uint16 public constant W_LEGEND = 300;

    uint8 public constant CARDS_PER_PACK = 5; // within Spec 3–5
    uint256 public constant DEFAULT_PACK_PRICE = 10e6; // 10 USDG (6 decimals), Spec placeholder

    IERC20 public immutable usdg;
    PlayerCard public immutable cards;
    address public immutable feeRecipient;

    address public owner;
    uint256 public packPrice;
    uint64 public revealDelay; // default for new commits (snapshotted per Pack)
    uint64 public abandonWindow; // default for new commits (snapshotted per Pack)
    uint64 public purchaseRefundBlocks; // Purchased w/o commit → refund after this many blocks
    uint16 public season;
    bool public paused;

    uint256 private _status; // 1 = entered (reentrancy)

    enum PackStatus {
        None,
        Purchased,
        Committed,
        Opened,
        Abandoned
    }

    struct Pack {
        address buyer;
        PackStatus status;
        bytes32 commitHash;
        uint64 commitBlock;
        uint64 unlockBlock; // commitBlock + revealDelay snapshotted at commit
        uint64 abandonBlock; // unlockBlock + abandonWindow snapshotted at commit
        uint64 purchasedBlock; // set on buy; used for Purchased-only refund
        uint256 paid;
    }

    uint256 public nextPackId = 1;
    mapping(uint256 => Pack) public packs;

    /// @dev Kit AF dry paths: tokenURI = baseUri + "player-" + slug + ".png"
    ///      Index aligns with starter positions QB..DB (0..4). POS_K uses index 4 art until a K archetype lands.
    string public baseUri;
    string[5] public rosterNames; // display names
    string[5] public rosterSlugs; // Kit file slugs under public/art

    error NotOwner();
    error Paused();
    error InvalidAddress();
    error InvalidPrice();
    error InvalidDelay();
    error PackMissing();
    error BadStatus();
    error NotBuyer();
    error BadCommit();
    error TooEarly();
    error EntropyExpired(); // blockhash(unlockBlock)==0 — reveal past 256-window; abandon only
    error TransferFailed();
    error Reentrancy();
    error RefundTooEarly();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PackPriceSet(uint256 price);
    event RevealParamsSet(uint64 revealDelay, uint64 abandonWindow);
    event SeasonSet(uint16 season);
    event BaseUriSet(string baseUri);
    event RosterNameSet(uint8 index, string name);
    event PausedSet(bool paused);
    event PackPurchased(uint256 indexed packId, address indexed buyer, uint256 price, uint256 fee);
    event PackCommitted(
        uint256 indexed packId,
        bytes32 commitHash,
        uint64 commitBlock,
        uint64 unlockBlock,
        uint64 abandonBlock
    );
    event PackOpened(uint256 indexed packId, address indexed buyer, uint256[5] tokenIds, bytes32 seed);
    event PackAbandoned(uint256 indexed packId);
    event PackRefunded(uint256 indexed packId, address indexed buyer, uint256 amount);
    event PurchaseRefundBlocksSet(uint64 blocks);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier nonReentrant() {
        if (_status == 1) revert Reentrancy();
        _status = 1;
        _;
        _status = 0;
    }

    constructor(address usdg_, address cards_, address feeRecipient_, uint16 season_) {
        if (usdg_ == address(0) || cards_ == address(0) || feeRecipient_ == address(0)) {
            revert InvalidAddress();
        }
        usdg = IERC20(usdg_);
        cards = PlayerCard(cards_);
        feeRecipient = feeRecipient_;
        owner = msg.sender;
        packPrice = DEFAULT_PACK_PRICE;
        revealDelay = 1; // 1 block for testnet/dry; raise for production
        abandonWindow = 256; // keep unlock within blockhash window (~256)
        purchaseRefundBlocks = 7200; // ~1 day @ 12s; Purchased w/o commit refund
        season = season_;
        baseUri = "/art/";
        // Kit AF reissue (2026-09-07) — no NFL IP
        rosterNames[0] = "Neon Arm";
        rosterNames[1] = "Chain Slash";
        rosterNames[2] = "Vault Wall";
        rosterNames[3] = "RH Rush";
        rosterNames[4] = "Street Pick";
        rosterSlugs[0] = "neon-arm";
        rosterSlugs[1] = "chain-slash";
        rosterSlugs[2] = "vault-wall";
        rosterSlugs[3] = "rh-rush";
        rosterSlugs[4] = "street-pick";
        emit OwnershipTransferred(address(0), msg.sender);
        emit PackPriceSet(packPrice);
        emit RevealParamsSet(revealDelay, abandonWindow);
        emit PurchaseRefundBlocksSet(purchaseRefundBlocks);
        emit SeasonSet(season_);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setPackPrice(uint256 price) external onlyOwner {
        if (price == 0) revert InvalidPrice();
        packPrice = price;
        emit PackPriceSet(price);
    }

    function setRevealParams(uint64 revealDelay_, uint64 abandonWindow_) external onlyOwner {
        if (revealDelay_ == 0 || abandonWindow_ == 0) revert InvalidDelay();
        // abandonWindow > 256 is useless: blockhash(unlock) is already 0 by then
        if (abandonWindow_ > 256) revert InvalidDelay();
        revealDelay = revealDelay_;
        abandonWindow = abandonWindow_;
        emit RevealParamsSet(revealDelay_, abandonWindow_);
    }

    function setPurchaseRefundBlocks(uint64 blocks_) external onlyOwner {
        if (blocks_ == 0) revert InvalidDelay();
        purchaseRefundBlocks = blocks_;
        emit PurchaseRefundBlocksSet(blocks_);
    }

    function setSeason(uint16 season_) external onlyOwner {
        season = season_;
        emit SeasonSet(season_);
    }

    function setBaseUri(string calldata uri) external onlyOwner {
        baseUri = uri;
        emit BaseUriSet(uri);
    }

    function setRosterName(uint8 index, string calldata playerName) external onlyOwner {
        require(index < 5, "index");
        rosterNames[index] = playerName;
        emit RosterNameSet(index, playerName);
    }

    event RosterSlugSet(uint8 index, string slug);

    function setRosterSlug(uint8 index, string calldata slug) external onlyOwner {
        require(index < 5, "index");
        rosterSlugs[index] = slug;
        emit RosterSlugSet(index, slug);
    }

    function setPaused(bool paused_) external onlyOwner {
        paused = paused_;
        emit PausedSet(paused_);
    }

    /// @notice Purchase a pack. Pulls `packPrice` USDG; `FEE_BPS` to feeRecipient, rest stays here (treasury sink).
    function buyPack() external whenNotPaused nonReentrant returns (uint256 packId) {
        uint256 price = packPrice;
        uint256 fee = (price * FEE_BPS) / BPS_DENOM;
        if (!usdg.transferFrom(msg.sender, address(this), price)) revert TransferFailed();
        if (fee > 0) {
            if (!usdg.transfer(feeRecipient, fee)) revert TransferFailed();
        }

        packId = nextPackId++;
        packs[packId] = Pack({
            buyer: msg.sender,
            status: PackStatus.Purchased,
            commitHash: bytes32(0),
            commitBlock: 0,
            unlockBlock: 0,
            abandonBlock: 0,
            purchasedBlock: uint64(block.number),
            paid: price
        });
        emit PackPurchased(packId, msg.sender, price, fee);
    }

    /// @notice Atomic buy + commit (preferred — avoids stranded Purchased packs).
    function buyAndCommit(bytes32 commitHash)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 packId)
    {
        if (commitHash == bytes32(0)) revert BadCommit();
        uint256 price = packPrice;
        uint256 fee = (price * FEE_BPS) / BPS_DENOM;
        if (!usdg.transferFrom(msg.sender, address(this), price)) revert TransferFailed();
        if (fee > 0) {
            if (!usdg.transfer(feeRecipient, fee)) revert TransferFailed();
        }

        packId = nextPackId++;
        uint64 cb = uint64(block.number);
        uint64 unlock = cb + uint64(revealDelay);
        uint64 abandonAt = unlock + uint64(abandonWindow);
        packs[packId] = Pack({
            buyer: msg.sender,
            status: PackStatus.Committed,
            commitHash: commitHash,
            commitBlock: cb,
            unlockBlock: unlock,
            abandonBlock: abandonAt,
            purchasedBlock: cb,
            paid: price
        });
        emit PackPurchased(packId, msg.sender, price, fee);
        emit PackCommitted(packId, commitHash, cb, unlock, abandonAt);
    }

    /// @notice Commit `keccak256(abi.encodePacked(secret, salt, packId, buyer))` before reveal.
    /// @dev Snapshots live revealDelay/abandonWindow into absolute unlock/abandon blocks.
    function commit(uint256 packId, bytes32 commitHash) external whenNotPaused {
        Pack storage p = packs[packId];
        if (p.status == PackStatus.None) revert PackMissing();
        if (p.status != PackStatus.Purchased) revert BadStatus();
        if (p.buyer != msg.sender) revert NotBuyer();
        if (commitHash == bytes32(0)) revert BadCommit();

        uint64 cb = uint64(block.number);
        uint64 unlock = cb + uint64(revealDelay);
        uint64 abandonAt = unlock + uint64(abandonWindow);
        p.commitHash = commitHash;
        p.commitBlock = cb;
        p.unlockBlock = unlock;
        p.abandonBlock = abandonAt;
        p.status = PackStatus.Committed;
        emit PackCommitted(packId, commitHash, cb, unlock, abandonAt);
    }

    /// @notice Refund a Purchased pack that never committed, after `purchaseRefundBlocks`.
    function refundPurchased(uint256 packId) external nonReentrant {
        Pack storage p = packs[packId];
        if (p.status != PackStatus.Purchased) revert BadStatus();
        if (p.buyer != msg.sender) revert NotBuyer();
        if (block.number < uint256(p.purchasedBlock) + uint256(purchaseRefundBlocks)) {
            revert RefundTooEarly();
        }
        uint256 amount = p.paid;
        // fee already sent to treasury on buy — refund only proceeds held here (price - fee)
        uint256 fee = (amount * FEE_BPS) / BPS_DENOM;
        uint256 refundAmt = amount - fee;
        p.status = PackStatus.Abandoned;
        p.paid = 0;
        if (refundAmt > 0) {
            if (!usdg.transfer(msg.sender, refundAmt)) revert TransferFailed();
        }
        emit PackRefunded(packId, msg.sender, refundAmt);
        emit PackAbandoned(packId);
    }

    /// @notice Reveal after `revealDelay` blocks; mints `CARDS_PER_PACK` cards to buyer.
    function reveal(uint256 packId, bytes32 secret, bytes32 salt)
        external
        whenNotPaused
        nonReentrant
        returns (uint256[5] memory tokenIds)
    {
        Pack storage p = packs[packId];
        if (p.status == PackStatus.None) revert PackMissing();
        if (p.status != PackStatus.Committed) revert BadStatus();
        if (p.buyer != msg.sender) revert NotBuyer();

        uint256 unlock = uint256(p.unlockBlock);
        // blockhash(unlock) is only available AFTER unlock is mined (not on unlock itself)
        if (block.number <= unlock) revert TooEarly();

        bytes32 expected = keccak256(abi.encodePacked(secret, salt, packId, msg.sender));
        if (expected != p.commitHash) revert BadCommit();

        // A1 HIGH1: only snapshotted unlock blockhash — never prevrandao / n-1 fallback
        bytes32 bh = blockhash(unlock);
        if (bh == bytes32(0)) revert EntropyExpired();

        bytes32 seed = keccak256(abi.encodePacked(secret, salt, packId, bh));
        p.status = PackStatus.Opened;

        // Fisher–Yates shuffle of starter positions QB..DB (0..4); excludes K so every pack is match-ready
        uint8[5] memory starterPos;
        for (uint8 i = 0; i < 5; i++) starterPos[i] = i;
        for (uint256 i = 4; i > 0; i--) {
            uint256 j = uint256(keccak256(abi.encodePacked(seed, "posshuf", i))) % (i + 1);
            (starterPos[i], starterPos[j]) = (starterPos[j], starterPos[i]);
        }

        for (uint256 i = 0; i < CARDS_PER_PACK; i++) {
            bytes32 cardSeed = keccak256(abi.encodePacked(seed, i));
            tokenIds[i] = _mintFromSeed(p.buyer, cardSeed, starterPos[i]);
        }
        emit PackOpened(packId, p.buyer, tokenIds, seed);
    }

    /// @notice After snapshotted abandonBlock, burn unrevealed pack (no refund) — anti cherry-pick / entropy expiry.
    function abandon(uint256 packId) external {
        Pack storage p = packs[packId];
        if (p.status != PackStatus.Committed) revert BadStatus();
        if (block.number < uint256(p.abandonBlock)) revert TooEarly();
        p.status = PackStatus.Abandoned;
        emit PackAbandoned(packId);
    }

    /// @notice Helper for clients: commit hash preimage layout.
    function commitHashOf(bytes32 secret, bytes32 salt, uint256 packId, address buyer)
        external
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(secret, salt, packId, buyer));
    }

    /// @notice §12c published weights for `position` (Common,Rare,Epic,Legend) — each sums to 10_000.
    function rarityWeights(uint8 position) public pure returns (uint16[4] memory w) {
        if (position == 0) {
            // QB — juicier Legend
            w = [uint16(5500), 2700, 1400, 400];
        } else if (position == 1) {
            // SKILL — baseline
            w = [uint16(6000), 2500, 1200, 300];
        } else if (position == 2) {
            // LINE_O
            w = [uint16(6200), 2400, 1100, 300];
        } else if (position == 3) {
            // LINE_D — baseline
            w = [uint16(6000), 2500, 1200, 300];
        } else if (position == 4) {
            // DB — mild chase
            w = [uint16(5800), 2600, 1300, 300];
        } else {
            // K — stingier Legend
            w = [uint16(6500), 2300, 1000, 200];
        }
    }

    function _rollRarity(bytes32 cardSeed, uint8 position) internal pure returns (uint8 rarity) {
        uint16[4] memory w = rarityWeights(position);
        uint256 roll = uint256(cardSeed) % BPS_DENOM;
        uint256 acc = w[0];
        if (roll < acc) return 0;
        acc += w[1];
        if (roll < acc) return 1;
        acc += w[2];
        if (roll < acc) return 2;
        return 3;
    }

    /// @dev Position primary stats (SPD ARM HND TCK POW): 2 = high tilt, 1 = mid, 0 = low tilt.
    function _statTilt(uint8 position) internal pure returns (uint8[5] memory tilt) {
        if (position == 0) {
            // QB: ARM HND high; SPD POW mid; TCK low
            tilt = [uint8(1), 2, 2, 0, 1];
        } else if (position == 1) {
            // SKILL: SPD HND high; ARM POW mid; TCK low
            tilt = [uint8(2), 1, 2, 0, 1];
        } else if (position == 2) {
            // LINE_O: POW TCK high; HND mid; SPD ARM low
            tilt = [uint8(0), 0, 1, 2, 2];
        } else if (position == 3) {
            // LINE_D: TCK POW high; SPD mid; ARM HND low
            tilt = [uint8(1), 0, 0, 2, 2];
        } else if (position == 4) {
            // DB: SPD TCK HND high; POW mid; ARM low
            tilt = [uint8(2), 0, 2, 2, 1];
        } else {
            // K: POW HND high; SPD mid; ARM TCK low
            tilt = [uint8(1), 0, 2, 0, 2];
        }
    }

    function _mintFromSeed(address to, bytes32 cardSeed, uint8 position)
        internal
        returns (uint256 tokenId)
    {
        uint8 rarity = _rollRarity(cardSeed, position);

        // Starter positions 0..4 map 1:1 to Kit AF archetypes; K (5) reuses DB art until Kit adds a K slug
        uint8 rosterIdx = position < 5 ? position : 4;

        // Ratings = SPD ARM HND TCK POW; floor/span from Spec; position tilts which stats land high
        uint8 floor_ = 40 + rarity * 12; // Common 40 … Legend 76
        uint8 span = 20 + rarity * 4;
        uint8 half = span / 2;
        if (half == 0) half = 1;
        uint8[5] memory tilt = _statTilt(position);
        uint8[5] memory ratings;
        for (uint256 r = 0; r < 5; r++) {
            uint256 rv = uint256(keccak256(abi.encodePacked(cardSeed, "stat", r)));
            uint8 t = tilt[r];
            uint8 rolled;
            if (t == 2) {
                // high half of span
                rolled = uint8(floor_ + half + (rv % (span - half)));
            } else if (t == 0) {
                // low half
                rolled = uint8(floor_ + (rv % half));
            } else {
                rolled = uint8(floor_ + (rv % span));
            }
            if (rolled > 99) rolled = 99;
            ratings[r] = rolled;
        }

        string memory playerName = rosterNames[rosterIdx];
        // Kit layout: /art/player-{slug}.png (rarity chrome via frame overlay until Kit variants land)
        string memory uri = string.concat(baseUri, "player-", rosterSlugs[rosterIdx], ".png");

        tokenId = cards.mint(to, playerName, uri, position, rarity, season, ratings);
    }

    /// @notice Owner withdraw of pack proceeds (post-fee) sitting on this contract.
    function withdrawProceeds(address to, uint256 amount) external onlyOwner nonReentrant {
        if (to == address(0)) revert InvalidAddress();
        if (!usdg.transfer(to, amount)) revert TransferFailed();
    }
}
