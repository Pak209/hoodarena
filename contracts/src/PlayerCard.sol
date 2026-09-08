// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721, IERC721Receiver, IERC721Metadata} from "./interfaces/IERC721.sol";

/// @title Hood Arena — Mode C player card NFT (ERC-721)
/// @notice Unique cards: AF position, SPD/ARM/HND/TCK/POW, rarity, season + art URI.
/// @dev Spec: SPEC_CARDS.md §6 + §12b. Mintable only by authorized minter (CardPack).
///      Original / RH-culture roster — no licensed NFL/FIFA IP in names.
///      LIVE LOCKED for mainnet; dry/testnet OK.
contract PlayerCard is IERC721, IERC721Metadata {
    // Compressed AF positions (Spec §6 / §12b) — not full 22-slot roster
    uint8 public constant POS_QB = 0;
    uint8 public constant POS_SKILL = 1;
    uint8 public constant POS_LINE_O = 2;
    uint8 public constant POS_LINE_D = 3;
    uint8 public constant POS_DB = 4;
    uint8 public constant POS_K = 5;
    uint8 public constant POS_COUNT = 6;

    uint8 public constant RARITY_COMMON = 0;
    uint8 public constant RARITY_RARE = 1;
    uint8 public constant RARITY_EPIC = 2;
    uint8 public constant RARITY_LEGEND = 3;

    /// @notice Rating vector indices (uint8[5]): SPD ARM HND TCK POW
    uint8 public constant STAT_SPD = 0;
    uint8 public constant STAT_ARM = 1;
    uint8 public constant STAT_HND = 2;
    uint8 public constant STAT_TCK = 3;
    uint8 public constant STAT_POW = 4;

    /// @notice On-chain card attributes (art path via `uri`)
    struct CardData {
        string name;
        string uri;
        uint8 position; // QB|SKILL|LINE_O|LINE_D|DB|K
        uint8 rarity; // Common|Rare|Epic|Legend
        uint16 season;
        uint8 spd;
        uint8 arm;
        uint8 hnd;
        uint8 tck;
        uint8 pow;
    }

    string public constant name = "Hood Arena Player Card";
    string public constant symbol = "HAPC";

    address public owner;
    mapping(address => bool) public minters;

    uint256 public nextTokenId = 1;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => CardData) private _cards;

    /// @dev Per-owner token enumeration (ERC721Enumerable-lite; no global tokenByIndex).
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;

    error NotOwner();
    error NotMinter();
    error InvalidAddress();
    error InvalidPosition();
    error InvalidRarity();
    error TokenMissing();
    error NotTokenOwner();
    error NotApproved();
    error UnsafeReceiver();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MinterSet(address indexed minter, bool enabled);
    event CardMinted(
        uint256 indexed tokenId,
        address indexed to,
        uint8 rarity,
        uint8 position,
        uint16 season
    );

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setMinter(address minter, bool enabled) external onlyOwner {
        if (minter == address(0)) revert InvalidAddress();
        minters[minter] = enabled;
        emit MinterSet(minter, enabled);
    }

    /// @notice Mint a unique card. Only authorized minter (CardPack).
    function mint(
        address to,
        string calldata playerName,
        string calldata uri,
        uint8 position,
        uint8 rarity,
        uint16 season,
        uint8[5] calldata ratings
    ) external returns (uint256 tokenId) {
        if (!minters[msg.sender]) revert NotMinter();
        if (to == address(0)) revert InvalidAddress();
        if (position >= POS_COUNT) revert InvalidPosition();
        if (rarity > RARITY_LEGEND) revert InvalidRarity();

        tokenId = nextTokenId++;
        _owners[tokenId] = to;
        _balances[to] += 1;
        _addTokenToOwnerEnumeration(to, tokenId);
        _cards[tokenId] = CardData({
            name: playerName,
            uri: uri,
            position: position,
            rarity: rarity,
            season: season,
            spd: ratings[0],
            arm: ratings[1],
            hnd: ratings[2],
            tck: ratings[3],
            pow: ratings[4]
        });

        emit Transfer(address(0), to, tokenId);
        emit CardMinted(tokenId, to, rarity, position, season);
    }

    function getCard(uint256 tokenId) external view returns (CardData memory) {
        if (_owners[tokenId] == address(0)) revert TokenMissing();
        return _cards[tokenId];
    }

    /// @notice List all token ids owned by `account` (order not guaranteed stable across transfers).
    function tokensOfOwner(address account) external view returns (uint256[] memory) {
        if (account == address(0)) revert InvalidAddress();
        return _ownedTokens[account];
    }

    function tokenOfOwnerByIndex(address account, uint256 index) external view returns (uint256) {
        if (account == address(0)) revert InvalidAddress();
        if (index >= _ownedTokens[account].length) revert TokenMissing();
        return _ownedTokens[account][index];
    }

    function ratingsOf(uint256 tokenId) external view returns (uint8[5] memory out) {
        if (_owners[tokenId] == address(0)) revert TokenMissing();
        CardData storage c = _cards[tokenId];
        out[0] = c.spd;
        out[1] = c.arm;
        out[2] = c.hnd;
        out[3] = c.tck;
        out[4] = c.pow;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        if (_owners[tokenId] == address(0)) revert TokenMissing();
        return _cards[tokenId].uri;
    }

    function balanceOf(address account) external view returns (uint256) {
        if (account == address(0)) revert InvalidAddress();
        return _balances[account];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address o = _owners[tokenId];
        if (o == address(0)) revert TokenMissing();
        return o;
    }

    function approve(address to, uint256 tokenId) external {
        address o = ownerOf(tokenId);
        if (msg.sender != o && !_operatorApprovals[o][msg.sender]) revert NotApproved();
        _tokenApprovals[tokenId] = to;
        emit Approval(o, to, tokenId);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        if (_owners[tokenId] == address(0)) revert TokenMissing();
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external {
        if (operator == address(0)) revert InvalidAddress();
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator) external view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        _safeTransfer(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)
        external
    {
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (
                bytes4 magic
            ) {
                if (magic != IERC721Receiver.onERC721Received.selector) revert UnsafeReceiver();
            } catch {
                revert UnsafeReceiver();
            }
        }
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        if (to == address(0)) revert InvalidAddress();
        address o = ownerOf(tokenId);
        if (o != from) revert NotTokenOwner();
        if (
            msg.sender != from && !_operatorApprovals[from][msg.sender]
                && _tokenApprovals[tokenId] != msg.sender
        ) {
            revert NotApproved();
        }
        delete _tokenApprovals[tokenId];
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _balances[from] -= 1;
        _addTokenToOwnerEnumeration(to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastIndex = _ownedTokens[from].length - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        _ownedTokens[from].pop();
        delete _ownedTokensIndex[tokenId];
    }
}
