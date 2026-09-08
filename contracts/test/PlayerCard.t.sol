// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PlayerCard} from "../src/PlayerCard.sol";

contract PlayerCardTest is Test {
    PlayerCard cards;
    address minter = makeAddr("minter");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    uint8[5] ratings = [uint8(70), 80, 60, 40, 55];

    function setUp() public {
        cards = new PlayerCard();
        cards.setMinter(minter, true);
    }

    function _mint(address to, uint8 position, uint8 rarity) internal returns (uint256) {
        vm.prank(minter);
        return cards.mint(to, "Test", "/art/player-neon-arm.png", position, rarity, 1, ratings);
    }

    function test_mint_tokensOfOwner() public {
        uint256 a = _mint(alice, 0, 0);
        uint256 b = _mint(alice, 1, 1);
        uint256 c = _mint(bob, 2, 0);

        uint256[] memory aliceIds = cards.tokensOfOwner(alice);
        assertEq(aliceIds.length, 2);
        assertEq(aliceIds[0], a);
        assertEq(aliceIds[1], b);
        assertEq(cards.balanceOf(alice), 2);

        uint256[] memory bobIds = cards.tokensOfOwner(bob);
        assertEq(bobIds.length, 1);
        assertEq(bobIds[0], c);
        assertEq(cards.balanceOf(bob), 1);

        uint256[] memory empty = cards.tokensOfOwner(makeAddr("nobody"));
        assertEq(empty.length, 0);
    }

    function test_transfer_updatesTokensOfOwner() public {
        uint256 t1 = _mint(alice, 0, 0);
        uint256 t2 = _mint(alice, 1, 1);
        uint256 t3 = _mint(alice, 2, 2);

        vm.prank(alice);
        cards.transferFrom(alice, bob, t2);

        uint256[] memory aliceIds = cards.tokensOfOwner(alice);
        assertEq(aliceIds.length, 2);
        assertEq(cards.balanceOf(alice), 2);
        // swap-and-pop: t2 removed; last token may move into its slot
        bool hasT1;
        bool hasT3;
        for (uint256 i = 0; i < aliceIds.length; i++) {
            if (aliceIds[i] == t1) hasT1 = true;
            if (aliceIds[i] == t3) hasT3 = true;
            assertTrue(aliceIds[i] != t2);
        }
        assertTrue(hasT1 && hasT3);

        uint256[] memory bobIds = cards.tokensOfOwner(bob);
        assertEq(bobIds.length, 1);
        assertEq(bobIds[0], t2);
        assertEq(cards.ownerOf(t2), bob);
        assertEq(cards.balanceOf(bob), 1);
    }

    function test_transfer_allTokensClearsEnumeration() public {
        uint256 t1 = _mint(alice, 0, 0);
        vm.prank(alice);
        cards.transferFrom(alice, bob, t1);
        assertEq(cards.tokensOfOwner(alice).length, 0);
        assertEq(cards.tokensOfOwner(bob).length, 1);
        assertEq(cards.tokensOfOwner(bob)[0], t1);
    }
}
