// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MockUSDG} from "../src/mocks/MockUSDG.sol";
import {PlayerCard} from "../src/PlayerCard.sol";
import {CardPack} from "../src/CardPack.sol";

contract CardPackTest is Test {
    MockUSDG usdg;
    PlayerCard cards;
    CardPack pack;
    address treasury = makeAddr("treasury");
    address buyer = makeAddr("buyer");
    address other = makeAddr("other");

    uint16 constant SEASON = 1;

    function setUp() public {
        usdg = new MockUSDG();
        cards = new PlayerCard();
        pack = new CardPack(address(usdg), address(cards), treasury, SEASON);
        cards.setMinter(address(pack), true);

        usdg.mint(buyer, 1_000e6);
        vm.prank(buyer);
        usdg.approve(address(pack), type(uint256).max);
    }

    function _buyCommitReveal(address who)
        internal
        returns (uint256 packId, uint256[5] memory tokenIds)
    {
        vm.prank(who);
        packId = pack.buyPack();

        bytes32 secret = keccak256("secret");
        bytes32 salt = keccak256("salt");
        bytes32 ch = pack.commitHashOf(secret, salt, packId, who);

        vm.prank(who);
        pack.commit(packId, ch);

        // past unlockBlock so blockhash(unlock) is non-zero
        vm.roll(block.number + pack.revealDelay() + 1);

        vm.prank(who);
        tokenIds = pack.reveal(packId, secret, salt);
    }

    function test_buyPack_feeBps100() public {
        uint256 price = pack.packPrice();
        uint256 fee = (price * 100) / 10_000;

        vm.prank(buyer);
        uint256 packId = pack.buyPack();

        assertEq(packId, 1);
        assertEq(usdg.balanceOf(treasury), fee);
        assertEq(usdg.balanceOf(address(pack)), price - fee);
        assertEq(usdg.balanceOf(buyer), 1_000e6 - price);

        (address b, CardPack.PackStatus st,,,,,,) = pack.packs(packId);
        assertEq(b, buyer);
        assertEq(uint8(st), uint8(CardPack.PackStatus.Purchased));
    }

    function test_commitReveal_mintsFiveCards() public {
        (uint256 packId, uint256[5] memory ids) = _buyCommitReveal(buyer);

        (, CardPack.PackStatus st,,,,,,) = pack.packs(packId);
        assertEq(uint8(st), uint8(CardPack.PackStatus.Opened));
        assertEq(cards.balanceOf(buyer), 5);

        for (uint256 i = 0; i < 5; i++) {
            assertEq(cards.ownerOf(ids[i]), buyer);
            PlayerCard.CardData memory c = cards.getCard(ids[i]);
            assertTrue(c.position <= 5);
            assertTrue(c.rarity <= 3);
            assertEq(c.season, SEASON);
            assertTrue(c.spd >= 40 && c.spd <= 99);
            // Kit dry art path
            assertTrue(
                _startsWith(c.uri, "/art/player-") && _endsWith(c.uri, ".png"),
                "uri should match Kit /art/player-*.png"
            );
        }
    }

    function _startsWith(string memory s, string memory prefix) internal pure returns (bool) {
        bytes memory a = bytes(s);
        bytes memory b = bytes(prefix);
        if (a.length < b.length) return false;
        for (uint256 i = 0; i < b.length; i++) if (a[i] != b[i]) return false;
        return true;
    }

    function _endsWith(string memory s, string memory suffix) internal pure returns (bool) {
        bytes memory a = bytes(s);
        bytes memory b = bytes(suffix);
        if (a.length < b.length) return false;
        uint256 off = a.length - b.length;
        for (uint256 i = 0; i < b.length; i++) if (a[off + i] != b[i]) return false;
        return true;
    }

    function test_tokensOfOwner_listsInventory() public {
        (, uint256[5] memory ids) = _buyCommitReveal(buyer);
        uint256[] memory owned = cards.tokensOfOwner(buyer);
        assertEq(owned.length, 5);
        // transfer one away — enumeration shrinks
        vm.prank(buyer);
        cards.transferFrom(buyer, other, ids[0]);
        uint256[] memory afterBuyer = cards.tokensOfOwner(buyer);
        uint256[] memory afterOther = cards.tokensOfOwner(other);
        assertEq(afterBuyer.length, 4);
        assertEq(afterOther.length, 1);
        assertEq(afterOther[0], ids[0]);
    }

    function test_afRosterUri_mapsPositionToKitSlug() public {
        (, uint256[5] memory ids) = _buyCommitReveal(buyer);
        string[5] memory expected = [
            "/art/player-neon-arm.png",
            "/art/player-chain-slash.png",
            "/art/player-vault-wall.png",
            "/art/player-rh-rush.png",
            "/art/player-street-pick.png"
        ];
        for (uint256 i = 0; i < 5; i++) {
            PlayerCard.CardData memory c = cards.getCard(ids[i]);
            assertEq(c.uri, expected[c.position]);
        }
    }

    function test_pack_guaranteesFiveDistinctStarterPositions() public {
        (, uint256[5] memory ids) = _buyCommitReveal(buyer);
        bool[6] memory seen;
        uint256 distinct;
        for (uint256 i = 0; i < 5; i++) {
            uint8 pos = cards.getCard(ids[i]).position;
            assertTrue(pos <= 4, "starter excludes K; positions QB..DB");
            if (!seen[pos]) {
                seen[pos] = true;
                distinct++;
            }
        }
        assertEq(distinct, 5, "pack must cover QB SKILL LINE_O LINE_D DB");
    }

    function test_reveal_revertsTooEarly() public {
        vm.prank(buyer);
        uint256 packId = pack.buyPack();
        bytes32 secret = bytes32(uint256(1));
        bytes32 salt = bytes32(uint256(2));
        bytes32 ch = pack.commitHashOf(secret, salt, packId, buyer);
        vm.prank(buyer);
        pack.commit(packId, ch);

        vm.prank(buyer);
        vm.expectRevert(CardPack.TooEarly.selector);
        pack.reveal(packId, secret, salt);
    }

    function test_reveal_badCommitReverts() public {
        vm.prank(buyer);
        uint256 packId = pack.buyPack();
        bytes32 secret = bytes32(uint256(1));
        bytes32 salt = bytes32(uint256(2));
        bytes32 ch = pack.commitHashOf(secret, salt, packId, buyer);
        vm.prank(buyer);
        pack.commit(packId, ch);
        (, , , , uint64 unlock,,,) = pack.packs(packId);
        vm.roll(uint256(unlock) + 1);

        vm.prank(buyer);
        vm.expectRevert(CardPack.BadCommit.selector);
        pack.reveal(packId, bytes32(uint256(99)), salt);
    }

    function test_onlyBuyerCanCommitAndReveal() public {
        vm.prank(buyer);
        uint256 packId = pack.buyPack();
        bytes32 secret = bytes32(uint256(1));
        bytes32 salt = bytes32(uint256(2));
        bytes32 ch = pack.commitHashOf(secret, salt, packId, buyer);

        vm.prank(other);
        vm.expectRevert(CardPack.NotBuyer.selector);
        pack.commit(packId, ch);

        vm.prank(buyer);
        pack.commit(packId, ch);
        (, , , , uint64 unlock2,,,) = pack.packs(packId);
        vm.roll(uint256(unlock2) + 1);

        vm.prank(other);
        vm.expectRevert(CardPack.NotBuyer.selector);
        pack.reveal(packId, secret, salt);
    }

    function test_onlyMinterCanMintCards() public {
        uint8[5] memory ratings = [uint8(50), 50, 50, 50, 50];
        vm.prank(buyer);
        vm.expectRevert(PlayerCard.NotMinter.selector);
        cards.mint(buyer, "X", "uri", 0, 0, 1, ratings);
    }

    function test_transferCard() public {
        (, uint256[5] memory ids) = _buyCommitReveal(buyer);
        assertEq(cards.tokensOfOwner(buyer).length, 5);
        vm.prank(buyer);
        cards.transferFrom(buyer, other, ids[0]);
        assertEq(cards.ownerOf(ids[0]), other);
        assertEq(cards.balanceOf(buyer), 4);
        assertEq(cards.balanceOf(other), 1);
        assertEq(cards.tokensOfOwner(buyer).length, 4);
        assertEq(cards.tokensOfOwner(other).length, 1);
        assertEq(cards.tokensOfOwner(other)[0], ids[0]);
    }

    function test_abandon_afterWindow() public {
        vm.prank(buyer);
        uint256 packId = pack.buyPack();
        bytes32 secret = bytes32(uint256(1));
        bytes32 salt = bytes32(uint256(2));
        bytes32 ch = pack.commitHashOf(secret, salt, packId, buyer);
        vm.prank(buyer);
        pack.commit(packId, ch);

        // unlock = commit+delay; abandon needs unlock+abandonWindow
        vm.roll(block.number + pack.revealDelay() + pack.abandonWindow());
        pack.abandon(packId);

        (, CardPack.PackStatus st,,,,,,) = pack.packs(packId);
        assertEq(uint8(st), uint8(CardPack.PackStatus.Abandoned));
        assertEq(cards.balanceOf(buyer), 0);
    }

    function test_abandon_tooEarlyReverts() public {
        vm.prank(buyer);
        uint256 packId = pack.buyPack();
        bytes32 secret = bytes32(uint256(1));
        bytes32 salt = bytes32(uint256(2));
        bytes32 ch = pack.commitHashOf(secret, salt, packId, buyer);
        vm.prank(buyer);
        pack.commit(packId, ch);
        vm.roll(block.number + pack.revealDelay());

        vm.expectRevert(CardPack.TooEarly.selector);
        pack.abandon(packId);
    }

    function test_A1_reveal_revertsWhenBlockhashExpired() public {
        vm.prank(buyer);
        uint256 packId = pack.buyPack();
        bytes32 secret = bytes32(uint256(1));
        bytes32 salt = bytes32(uint256(2));
        bytes32 ch = pack.commitHashOf(secret, salt, packId, buyer);
        vm.prank(buyer);
        pack.commit(packId, ch);

        (, , , , uint64 unlock, uint64 abandonAt,,) = pack.packs(packId);
        // past 256-blockhash window for unlock
        vm.roll(uint256(unlock) + 257);
        vm.prank(buyer);
        vm.expectRevert(CardPack.EntropyExpired.selector);
        pack.reveal(packId, secret, salt);

        // abandon allowed at/after abandonBlock
        if (block.number < abandonAt) vm.roll(abandonAt);
        pack.abandon(packId);
        (, CardPack.PackStatus st,,,,,,) = pack.packs(packId);
        assertEq(uint8(st), uint8(CardPack.PackStatus.Abandoned));
    }

    function test_A1_commitSnapshotsIgnoreLaterParamChange() public {
        vm.prank(buyer);
        uint256 packId = pack.buyPack();
        bytes32 secret = keccak256("secret");
        bytes32 salt = keccak256("salt");
        bytes32 ch = pack.commitHashOf(secret, salt, packId, buyer);
        vm.prank(buyer);
        pack.commit(packId, ch);
        (, , , , uint64 unlock,,,) = pack.packs(packId);

        // owner tries to stretch delay after commit — must not affect this pack
        pack.setRevealParams(100, 100);
        vm.roll(uint256(unlock) + 1);
        vm.prank(buyer);
        uint256[5] memory ids = pack.reveal(packId, secret, salt);
        assertEq(cards.ownerOf(ids[0]), buyer);
    }

    function test_buyAndCommit_atomic() public {
        bytes32 secret = keccak256("s");
        bytes32 salt = keccak256("t");
        // packId will be 1
        bytes32 ch = pack.commitHashOf(secret, salt, 1, buyer);
        vm.prank(buyer);
        uint256 packId = pack.buyAndCommit(ch);
        assertEq(packId, 1);
        (, CardPack.PackStatus st,,,,,,) = pack.packs(packId);
        assertEq(uint8(st), uint8(CardPack.PackStatus.Committed));
        vm.roll(block.number + pack.revealDelay() + 1);
        vm.prank(buyer);
        pack.reveal(packId, secret, salt);
        assertEq(cards.balanceOf(buyer), 5);
    }

    function test_feeBps_constantIs100() public {
        assertEq(pack.FEE_BPS(), 100);
    }

    function test_rarityWeights_sum10000() public {
        // baseline aliases still sum
        assertEq(uint256(pack.W_COMMON()) + pack.W_RARE() + pack.W_EPIC() + pack.W_LEGEND(), 10_000);
        // §12c every position sums to 10_000
        for (uint8 pos = 0; pos < 6; pos++) {
            uint16[4] memory w = pack.rarityWeights(pos);
            assertEq(uint256(w[0]) + w[1] + w[2] + w[3], 10_000);
        }
        // QB juicier Legend, K stingier
        assertEq(pack.rarityWeights(0)[3], 400);
        assertEq(pack.rarityWeights(5)[3], 200);
    }

    function test_positionBias_qbArmHigh_lineDTckHigh() public {
        (, uint256[5] memory ids) = _buyCommitReveal(buyer);
        for (uint256 i = 0; i < 5; i++) {
            PlayerCard.CardData memory c = cards.getCard(ids[i]);
            uint8 floor_ = 40 + c.rarity * 12;
            uint8 span = 20 + c.rarity * 4;
            uint8 mid = floor_ + span / 2;
            if (c.position == 0) {
                // QB: ARM + HND should land in high half
                assertTrue(c.arm >= mid, "QB ARM high tilt");
                assertTrue(c.hnd >= mid, "QB HND high tilt");
            }
            if (c.position == 3) {
                assertTrue(c.tck >= mid, "LINE_D TCK high tilt");
                assertTrue(c.pow >= mid, "LINE_D POW high tilt");
            }
        }
    }

    function test_pausedBlocksBuy() public {
        pack.setPaused(true);
        vm.prank(buyer);
        vm.expectRevert(CardPack.Paused.selector);
        pack.buyPack();
    }

    function test_doubleRevealReverts() public {
        (uint256 packId,) = _buyCommitReveal(buyer);
        vm.prank(buyer);
        vm.expectRevert(CardPack.BadStatus.selector);
        pack.reveal(packId, keccak256("secret"), keccak256("salt"));
    }

    function test_withdrawProceeds() public {
        vm.prank(buyer);
        pack.buyPack();
        uint256 proceeds = usdg.balanceOf(address(pack));
        pack.withdrawProceeds(address(this), proceeds);
        assertEq(usdg.balanceOf(address(pack)), 0);
        assertEq(usdg.balanceOf(address(this)), proceeds);
    }
}
