// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "./interfaces/IERC20.sol";
import {PlayerCard} from "./PlayerCard.sol";

/// @title Hood Arena — Mode C pack sale + commit-reveal open
/// @notice Buy with USDG (feeBps=100 to treasury), commit, wait delay, reveal → mint AF cards.
/// @dev Spec: SPEC_CARDS.md §5 + §12b. Matches cosmetic only — never escrows match USDG.
///      Starter guarantee: each pack mints 5 distinct compressed AF positions (QB..DB) so `/match` is playable immediately (K is pack-random later / optional).
///
/// ## RNG (documented bias)
/// Commit-reveal + post-commit block entropy:
///   seed = keccak256(secret, salt, packId, blockhash(commitBlock + revealDelay))
/// Opener chooses secret before seeing the reveal-block hash (commit first).
/// Bias remaining: (1) opener may abandon reveal if seed is "bad" (mitigated by
/// `abandonWindow` after which anyone can burn unrevealed pack — no refund);
/// (2) validators who can influence blockhash within delay — documented; prefer
/// Chainlink VRF when available on RH. Not VRF-grade fairness.
/// Published rarity weights (out of 10_000): Common 6000, Rare 2500, Epic 1200, Legend 300.
/// LIVE LOCKED for mainnet broadcast; dry/testnet OK.
contract CardPack {
    uint16 public constant FEE_BPS = 100; // Spec lock
    uint16 public constant BPS_DENOM = 10_000;

    uint16 public constant W_COMMON = 6000;
    uint16 public constant W_RARE = 2500;
    uint16 public constant W_EPIC = 1200;
    uint16 public constant W_LEGEND = 300; // sum = 10_000

    uint8 public constant CARDS_PER_PACK = 5; // within Spec 3–5
    uint256 public constant DEFAULT_PACK_PRICE = 10e6; // 10 USDG (6 decimals), Spec placeholder

    IERC20 public immutable usdg;
    PlayerCard public immutable cards;
    address public immutable feeRecipient;

    address public owner;
    uint256 public packPrice;
    uint64 public revealDelay; // blocks after commit before reveal
    uint64 public abandonWindow; // blocks after reveal-eligible; then burn (no refund)
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
    error TransferFailed();
    error Reentrancy();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PackPriceSet(uint256 price);
    event RevealParamsSet(uint64 revealDelay, uint64 abandonWindow);
    event SeasonSet(uint16 season);
    event BaseUriSet(string baseUri);
    event RosterNameSet(uint8 index, string name);
    event PausedSet(bool paused);
    event PackPurchased(uint256 indexed packId, address indexed buyer, uint256 price, uint256 fee);
    event PackCommitted(uint256 indexed packId, bytes32 commitHash, uint64 commitBlock);
    event PackOpened(uint256 indexed packId, address indexed buyer, uint256[5] tokenIds, bytes32 seed);
    event PackAbandoned(uint256 indexed packId);

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
        abandonWindow = 256; // ~blockhash availability window
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
        revealDelay = revealDelay_;
        abandonWindow = abandonWindow_;
        emit RevealParamsSet(revealDelay_, abandonWindow_);
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
            paid: price
        });
        emit PackPurchased(packId, msg.sender, price, fee);
    }

    /// @notice Commit `keccak256(abi.encodePacked(secret, salt, packId, buyer))` before reveal.
    function commit(uint256 packId, bytes32 commitHash) external whenNotPaused {
        Pack storage p = packs[packId];
        if (p.status == PackStatus.None) revert PackMissing();
        if (p.status != PackStatus.Purchased) revert BadStatus();
        if (p.buyer != msg.sender) revert NotBuyer();
        if (commitHash == bytes32(0)) revert BadCommit();

        p.commitHash = commitHash;
        p.commitBlock = uint64(block.number);
        p.status = PackStatus.Committed;
        emit PackCommitted(packId, commitHash, p.commitBlock);
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

        uint256 unlock = uint256(p.commitBlock) + uint256(revealDelay);
        if (block.number < unlock) revert TooEarly();

        bytes32 expected = keccak256(abi.encodePacked(secret, salt, packId, msg.sender));
        if (expected != p.commitHash) revert BadCommit();

        // Entropy from post-commit block (documented: 256-blockhash limit)
        bytes32 bh = blockhash(unlock);
        if (bh == bytes32(0)) {
            // Too far past unlock — use current prevrandao/block as fallback (weaker; prefer abandon)
            bh = blockhash(block.number - 1);
            if (bh == bytes32(0)) bh = bytes32(uint256(block.prevrandao));
        }

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

    /// @notice After abandonWindow past unlock, burn unrevealed pack (no refund) — anti cherry-pick.
    function abandon(uint256 packId) external {
        Pack storage p = packs[packId];
        if (p.status != PackStatus.Committed) revert BadStatus();
        uint256 unlock = uint256(p.commitBlock) + uint256(revealDelay);
        if (block.number < unlock + uint256(abandonWindow)) revert TooEarly();
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

    function _mintFromSeed(address to, bytes32 cardSeed, uint8 position)
        internal
        returns (uint256 tokenId)
    {
        uint256 roll = uint256(cardSeed) % BPS_DENOM;
        uint8 rarity;
        if (roll < W_COMMON) rarity = 0;
        else if (roll < W_COMMON + W_RARE) rarity = 1;
        else if (roll < W_COMMON + W_RARE + W_EPIC) rarity = 2;
        else rarity = 3;

        // Starter positions 0..4 map 1:1 to Kit AF archetypes; K (5) reuses DB art until Kit adds a K slug
        uint8 rosterIdx = position < 5 ? position : 4;

        // Ratings = SPD ARM HND TCK POW; scale with rarity (soft floors)
        uint8 floor_ = 40 + rarity * 12; // Common 40 … Legend 76
        uint8 span = 20 + rarity * 4;
        uint8[5] memory ratings;
        for (uint256 r = 0; r < 5; r++) {
            uint256 rv = uint256(keccak256(abi.encodePacked(cardSeed, "stat", r)));
            ratings[r] = uint8(floor_ + (rv % span));
            if (ratings[r] > 99) ratings[r] = 99;
        }

        string memory playerName = rosterNames[rosterIdx];
        // Kit layout: /art/player-{slug}.png
        string memory uri = string.concat(baseUri, "player-", rosterSlugs[rosterIdx], ".png");

        tokenId = cards.mint(to, playerName, uri, position, rarity, season, ratings);
    }

    /// @notice Owner withdraw of pack proceeds (post-fee) sitting on this contract.
    function withdrawProceeds(address to, uint256 amount) external onlyOwner nonReentrant {
        if (to == address(0)) revert InvalidAddress();
        if (!usdg.transfer(to, amount)) revert TransferFailed();
    }
}
