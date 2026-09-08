// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {GraduationRace} from "../src/GraduationRace.sol";
import {MockUSDG} from "../src/mocks/MockUSDG.sol";
import {MockPonsFactory} from "../src/mocks/MockPonsFactory.sol";
import {IPonsV2LaunchFactory} from "../src/interfaces/IPonsV2LaunchFactory.sol";

contract GraduationRaceTest is Test {
    GraduationRace race;
    MockUSDG usdg;
    MockPonsFactory factory;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address carol = address(0xCA201);
    address stranger = address(0x57A);
    address treasury = address(0xFEE);
    address t0 = address(0xA11A1);
    address t1 = address(0xBE7A);
    address t2 = address(0xCA11A);

    function setUp() public {
        usdg = new MockUSDG();
        factory = new MockPonsFactory();
        factory.setLaunch(t0, IPonsV2LaunchFactory.Phase.NotGraduated, 0, true);
        factory.setLaunch(t1, IPonsV2LaunchFactory.Phase.NotGraduated, 0, true);
        factory.setLaunch(t2, IPonsV2LaunchFactory.Phase.NotGraduated, 0, true);
        race = new GraduationRace(address(usdg), 100, treasury, address(factory));
        usdg.mint(alice, 10_000e6);
        usdg.mint(bob, 10_000e6);
        usdg.mint(carol, 10_000e6);
        vm.prank(alice);
        usdg.approve(address(race), type(uint256).max);
        vm.prank(bob);
        usdg.approve(address(race), type(uint256).max);
        vm.prank(carol);
        usdg.approve(address(race), type(uint256).max);
    }

    function test_gracePeriodDefault() public view {
        assertEq(race.gracePeriod(), 1 days);
    }

    function test_fakeTokenCreateReverts() public {
        address fake = address(0xF4CE);
        vm.expectRevert(GraduationRace.TokenNotLaunched.selector);
        race.createRace(t0, t1, fake, uint64(block.timestamp + 1 days));
    }

    function test_createAndStakeThree() public {
        uint256 id = race.createRace(t0, t1, t2, uint64(block.timestamp + 1 days));
        vm.prank(alice);
        race.stake(id, 0, 100e6);
        vm.prank(bob);
        race.stake(id, 1, 200e6);
        vm.prank(carol);
        race.stake(id, 2, 300e6);
        (,,,, uint256 p0, uint256 p1, uint256 p2,,,,) = race.races(id);
        assertEq(p0, 100e6);
        assertEq(p1, 200e6);
        assertEq(p2, 300e6);
    }

    function test_resolveFirstBySweptAt() public {
        uint256 id = race.createRace(t0, t1, t2, uint64(block.timestamp + 1 days));
        vm.prank(alice);
        race.stake(id, 0, 1_000e6);
        vm.prank(bob);
        race.stake(id, 1, 1_000e6);
        vm.prank(carol);
        race.stake(id, 2, 1_000e6);

        // Both t0 and t1 phase 2; t1 swept earlier → t1 wins
        uint256 early = block.timestamp + 10;
        uint256 late = block.timestamp + 50;
        factory.setPhase(t0, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(t0, late);
        factory.setPhase(t1, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(t1, early);

        // Wrong winner (later sweptAt) reverts
        vm.expectRevert(GraduationRace.NotEarliestSweptAt.selector);
        race.resolveRace(id, t0);

        // Correct earliest — permissionless
        vm.prank(stranger);
        race.resolveRace(id, t1);

        vm.prank(bob);
        uint256 payout = race.claim(id);
        assertEq(payout, 1_000e6 + 1_980e6);
        assertEq(usdg.balanceOf(treasury), 20e6);
    }

    function test_solePhase2_wins() public {
        uint256 id = race.createRace(t0, t1, t2, uint64(block.timestamp + 1 days));
        vm.prank(alice);
        race.stake(id, 0, 100e6);
        vm.prank(bob);
        race.stake(id, 1, 100e6);

        factory.setPhase(t0, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(t0, block.timestamp);
        // t1/t2 still phase 0
        race.resolveRace(id, t0);
        vm.prank(alice);
        assertGt(race.claim(id), 100e6);
    }

    function test_lateResolve_viaSweptAt() public {
        uint64 t = uint64(block.timestamp + 1 hours);
        uint256 id = race.createRace(t0, t1, t2, t);
        vm.prank(alice);
        race.stake(id, 0, 100e6);
        vm.prank(bob);
        race.stake(id, 1, 100e6);

        uint256 swept = block.timestamp + 10;
        factory.setPhase(t0, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(t0, swept);
        vm.warp(t + 50);
        race.resolveRace(id, t0);
        vm.prank(alice);
        assertGt(race.claim(id), 100e6);
    }

    function test_emptyWinPot_autoCancel_refund() public {
        uint256 id = race.createRace(t0, t1, t2, uint64(block.timestamp + 1 days));
        vm.prank(bob);
        race.stake(id, 1, 200e6); // only pick 1 — winner pick 0 has pot 0

        factory.setPhase(t0, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(t0, block.timestamp);
        vm.prank(stranger);
        race.resolveRace(id, t0); // empty win pot → cancel+refund

        (,,,,,,,, GraduationRace.Status status,,) = race.races(id);
        assertEq(uint8(status), uint8(GraduationRace.Status.Cancelled));

        vm.prank(bob);
        assertEq(race.claim(id), 200e6);
    }

    function test_cancel_whenNonePhase2() public {
        uint256 id = race.createRace(t0, t1, t2, uint64(block.timestamp + 2 hours));
        vm.prank(alice);
        race.stake(id, 0, 50e6);
        vm.prank(bob);
        race.stake(id, 2, 75e6);

        vm.warp(block.timestamp + 2 hours + 1);
        vm.prank(stranger);
        race.cancelRace(id);

        vm.prank(alice);
        assertEq(race.claim(id), 50e6);
        vm.prank(bob);
        assertEq(race.claim(id), 75e6);
    }

    function test_cancel_whenPhase2_reverts() public {
        uint64 t = uint64(block.timestamp + 2 hours);
        uint256 id = race.createRace(t0, t1, t2, t);
        vm.prank(alice);
        race.stake(id, 0, 50e6);

        factory.setPhase(t1, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(t1, block.timestamp + 1);
        vm.warp(t + 1);
        vm.expectRevert(GraduationRace.StillGraduated.selector);
        race.cancelRace(id);
    }

    function test_badWinnerReverts() public {
        uint256 id = race.createRace(t0, t1, t2, uint64(block.timestamp + 1 days));
        vm.expectRevert(GraduationRace.BadWinner.selector);
        race.resolveRace(id, address(0xBAD));
    }

    function test_phaseNot2_reverts() public {
        uint256 id = race.createRace(t0, t1, t2, uint64(block.timestamp + 1 days));
        vm.prank(alice);
        race.stake(id, 0, 50e6);
        factory.setPhase(t0, IPonsV2LaunchFactory.Phase.Swept);
        vm.expectRevert(GraduationRace.NotPoolCreated.selector);
        race.resolveRace(id, t0);
    }

    function test_lockClosesStaking() public {
        uint256 id = race.createRace(t0, t1, t2, uint64(block.timestamp + 1 days));
        race.lockRace(id);
        vm.prank(alice);
        vm.expectRevert(GraduationRace.NotOpen.selector);
        race.stake(id, 0, 10e6);
    }

    function test_ponsFactoryAndTopic0() public view {
        assertEq(race.ponsFactory(), address(factory));
        assertEq(
            race.POOL_GRADUATED_TOPIC0(),
            bytes32(0x0a44ef75df69c534f43cd6c1aa3ef8983065fe5fe79ef9e79f6494e6f258c259)
        );
    }

    // --- Reviewer re-pass CRITICAL fixes ---

    /// @notice Equal sweptAt → lowest token address wins (never strand both)
    function test_equalSweptAt_resolvesByAddress() public {
        // Actual address order: t1(0xBE7A) < t0(0xA11A1) < t2(0xCA11A)
        assertTrue(t1 < t0 && t0 < t2);
        uint256 id = race.createRace(t0, t1, t2, uint64(block.timestamp + 1 days));
        vm.prank(alice);
        race.stake(id, 0, 1_000e6);
        vm.prank(bob);
        race.stake(id, 1, 1_000e6);
        vm.prank(carol);
        race.stake(id, 2, 1_000e6);

        uint256 same = block.timestamp + 20;
        factory.setPhase(t0, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(t0, same);
        factory.setPhase(t1, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(t1, same);

        // Higher address must revert
        vm.expectRevert(GraduationRace.NotEarliestSweptAt.selector);
        race.resolveRace(id, t0);

        // Lowest address wins
        vm.prank(stranger);
        race.resolveRace(id, t1);

        (,,,,,,, address winner,,,) = race.races(id);
        assertEq(winner, t1);
        vm.prank(bob);
        assertEq(race.claim(id), 1_000e6 + 1_980e6);
    }

    /// @notice Race waits on Swept sibling before grace — do not crown another phase==2 yet
    function test_race_waitsOnSweptSibling_beforeGrace() public {
        uint64 t = uint64(block.timestamp + 2 hours);
        uint256 id = race.createRace(t0, t1, t2, t);
        vm.prank(alice);
        race.stake(id, 0, 100e6);
        vm.prank(bob);
        race.stake(id, 1, 100e6);

        // t0 PoolCreated; t1 Swept early — must wait for t1 to possibly PoolCreate
        uint256 earlySweep = block.timestamp + 5;
        factory.setPhase(t0, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(t0, block.timestamp + 30);
        factory.setPhase(t1, IPonsV2LaunchFactory.Phase.Swept);
        factory.setSweptAt(t1, earlySweep);

        vm.expectRevert(GraduationRace.SweptSiblingPending.selector);
        race.resolveRace(id, t0);

        vm.warp(t + 1); // after T, still before grace
        vm.expectRevert(GraduationRace.SweptSiblingPending.selector);
        race.resolveRace(id, t0);
        // cancelRace sees phase==2 → StillGraduated (resolve path, not cancel)
        vm.expectRevert(GraduationRace.StillGraduated.selector);
        race.cancelRace(id);

        // After grace, t1 still Swept → t0 may win (sole phase==2)
        vm.warp(uint256(t) + uint256(race.gracePeriod()));
        race.resolveRace(id, t0);
        (,,,,,,, address winner,,,) = race.races(id);
        assertEq(winner, t0);
    }

    /// @notice After grace with Swept sibling that became PoolCreated earlier → that sibling wins
    function test_race_sweptSibling_becomesWinner_afterGrace() public {
        uint64 t = uint64(block.timestamp + 2 hours);
        uint256 id = race.createRace(t0, t1, t2, t);
        vm.prank(alice);
        race.stake(id, 0, 100e6);
        vm.prank(bob);
        race.stake(id, 1, 100e6);

        uint256 earlySweep = block.timestamp + 5;
        factory.setPhase(t0, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(t0, block.timestamp + 40);
        factory.setPhase(t1, IPonsV2LaunchFactory.Phase.Swept);
        factory.setSweptAt(t1, earlySweep);

        vm.warp(uint256(t) + uint256(race.gracePeriod()));
        // Sibling graduated during grace window
        factory.setPhase(t1, IPonsV2LaunchFactory.Phase.PoolCreated);

        vm.expectRevert(GraduationRace.NotEarliestSweptAt.selector);
        race.resolveRace(id, t0);

        race.resolveRace(id, t1);
        (,,,,,,, address winner,,,) = race.races(id);
        assertEq(winner, t1);
    }

    /// @notice After grace, none phase==2 → cancelRace even if stuck Swept remains
    function test_cancel_afterGrace_withStuckSwept() public {
        uint64 t = uint64(block.timestamp + 2 hours);
        uint256 id = race.createRace(t0, t1, t2, t);
        vm.prank(alice);
        race.stake(id, 0, 50e6);

        factory.setPhase(t1, IPonsV2LaunchFactory.Phase.Swept);
        factory.setSweptAt(t1, block.timestamp + 1);

        vm.warp(t + 1);
        vm.expectRevert(GraduationRace.SweptSiblingPending.selector);
        race.cancelRace(id);

        vm.warp(uint256(t) + uint256(race.gracePeriod()));
        vm.prank(stranger);
        race.cancelRace(id);

        vm.prank(alice);
        assertEq(race.claim(id), 50e6);
    }

    // --- Reviewer r5 HOLD: Race late-invalid + empty win pot ---

    /// @notice After grace, phase==2 with sweptAt >= T is NOT a valid YES → cancel+refund
    function test_cancel_afterGrace_phase2_invalidSweptAt_refund() public {
        uint64 t = uint64(block.timestamp + 2 hours);
        uint256 id = race.createRace(t0, t1, t2, t);
        vm.prank(alice);
        race.stake(id, 0, 80e6);
        vm.prank(bob);
        race.stake(id, 1, 40e6);

        // PoolCreated but sweptAt >= T → late YES unavailable
        factory.setPhase(t0, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(t0, uint256(t)); // sweptAt == T → invalid late YES

        vm.warp(t + 1);
        // StillGraduated must NOT fire — no *valid* YES winner
        // resolve also fails YesTimeWindowClosed
        vm.expectRevert(GraduationRace.YesTimeWindowClosed.selector);
        race.resolveRace(id, t0);

        vm.warp(uint256(t) + uint256(race.gracePeriod()));
        vm.prank(stranger);
        race.cancelRace(id);

        vm.prank(alice);
        assertEq(race.claim(id), 80e6);
        vm.prank(bob);
        assertEq(race.claim(id), 40e6);
    }

    /// @notice Sole valid winner with pot 0 → cancel+refund (not permanent EmptyWinPot)
    function test_soleValidWinner_emptyPot_autoCancel() public {
        uint64 t = uint64(block.timestamp + 1 hours);
        uint256 id = race.createRace(t0, t1, t2, t);
        vm.prank(bob);
        race.stake(id, 1, 150e6);
        vm.prank(carol);
        race.stake(id, 2, 50e6);
        // pick 0 has pot 0

        uint256 swept = block.timestamp + 10;
        factory.setPhase(t0, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(t0, swept);
        vm.warp(t + 50);

        race.resolveRace(id, t0);
        (,,,,,,,, GraduationRace.Status status,,) = race.races(id);
        assertEq(uint8(status), uint8(GraduationRace.Status.Cancelled));

        vm.prank(bob);
        assertEq(race.claim(id), 150e6);
        vm.prank(carol);
        assertEq(race.claim(id), 50e6);
    }

    /// @notice Valid winner with pot > 0 still resolves (sanity after empty-pot path)
    function test_validWinner_potPositive_stillResolves() public {
        uint256 id = race.createRace(t0, t1, t2, uint64(block.timestamp + 1 days));
        vm.prank(alice);
        race.stake(id, 0, 100e6);
        vm.prank(bob);
        race.stake(id, 1, 100e6);

        factory.setPhase(t0, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(t0, block.timestamp);
        race.resolveRace(id, t0);

        (,,,,,,, address winner, GraduationRace.Status status,,) = race.races(id);
        assertEq(winner, t0);
        assertEq(uint8(status), uint8(GraduationRace.Status.Resolved));
        vm.prank(alice);
        assertGt(race.claim(id), 100e6);
    }

}
