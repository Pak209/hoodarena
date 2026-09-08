// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Arena} from "../src/Arena.sol";
import {MockUSDG} from "../src/mocks/MockUSDG.sol";
import {MockPonsFactory} from "../src/mocks/MockPonsFactory.sol";
import {IPonsV2LaunchFactory} from "../src/interfaces/IPonsV2LaunchFactory.sol";

contract ArenaTest is Test {
    Arena arena;
    MockUSDG usdg;
    MockPonsFactory factory;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address stranger = address(0x57A);
    address treasury = address(0xFEE);
    address token = address(0x70CE1);

    function setUp() public {
        usdg = new MockUSDG();
        factory = new MockPonsFactory();
        // Token exists on factory (phase 0 until tests set phase 2)
        factory.setLaunch(token, IPonsV2LaunchFactory.Phase.NotGraduated, 0, true);
        arena = new Arena(address(usdg), 100, treasury, address(factory));
        usdg.mint(alice, 10_000e6);
        usdg.mint(bob, 10_000e6);
        vm.prank(alice);
        usdg.approve(address(arena), type(uint256).max);
        vm.prank(bob);
        usdg.approve(address(arena), type(uint256).max);
    }

    function test_gracePeriodDefault() public view {
        assertEq(arena.gracePeriod(), 1 days);
    }

    function test_ponsFactoryImmutable() public view {
        assertEq(arena.ponsFactory(), address(factory));
        assertEq(arena.DEFAULT_PONS_FACTORY(), 0x7eD598BcEf8bd9Edd8C97A195C6d13f40801EC7e);
    }

    function test_defaultFactoryWhenZero() public {
        Arena a2 = new Arena(address(usdg), 100, treasury, address(0));
        assertEq(a2.ponsFactory(), a2.DEFAULT_PONS_FACTORY());
    }

    function test_createAndStake() public {
        uint256 id = arena.createArena(token, uint64(block.timestamp + 1 days));
        vm.prank(alice);
        arena.stake(id, true, 1_000e6);
        vm.prank(bob);
        arena.stake(id, false, 500e6);
        (,, uint256 yesPool, uint256 noPool,,,) = _arena(id);
        assertEq(yesPool, 1_000e6);
        assertEq(noPool, 500e6);
    }

    function test_fakeTokenCreateReverts() public {
        address fake = address(0xF4CE);
        vm.expectRevert(Arena.TokenNotLaunched.selector);
        arena.createArena(fake, uint64(block.timestamp + 1 days));
    }

    function test_resolveYes_viaPhase2() public {
        uint256 id = arena.createArena(token, uint64(block.timestamp + 1 days));
        vm.prank(alice);
        arena.stake(id, true, 1_000e6);
        vm.prank(bob);
        arena.stake(id, false, 1_000e6);

        factory.setPhase(token, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(token, block.timestamp);

        // Permissionless — stranger may resolve
        vm.prank(stranger);
        arena.resolveArenaYes(id);

        uint256 before = usdg.balanceOf(alice);
        vm.prank(alice);
        uint256 payout = arena.claim(id);
        assertEq(payout, 1_000e6 + 990e6);
        assertEq(usdg.balanceOf(alice), before + payout);
        assertEq(usdg.balanceOf(treasury), 10e6);
    }

    function test_lateYes_viaSweptAt() public {
        uint64 t = uint64(block.timestamp + 1 hours);
        uint256 id = arena.createArena(token, t);
        vm.prank(alice);
        arena.stake(id, true, 1_000e6);
        vm.prank(bob);
        arena.stake(id, false, 1_000e6);

        uint256 swept = block.timestamp + 30 minutes; // before T
        factory.setPhase(token, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(token, swept);

        vm.warp(t + 100); // after T — late YES OK via sweptAt < T
        vm.prank(stranger);
        arena.resolveArenaYes(id);

        (,,,, Arena.Status status,, uint64 stored) = _arena(id);
        assertTrue(status == Arena.Status.ResolvedYes);
        assertEq(stored, uint64(swept));

        vm.prank(alice);
        assertEq(arena.claim(id), 1_000e6 + 990e6);
    }

    function test_lateYes_sweptAtAfterDeadline_reverts() public {
        uint64 t = uint64(block.timestamp + 1 hours);
        uint256 id = arena.createArena(token, t);
        vm.prank(alice);
        arena.stake(id, true, 100e6);
        vm.prank(bob);
        arena.stake(id, false, 100e6);

        factory.setPhase(token, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(token, uint256(t)); // sweptAt >= T

        vm.warp(t + 1);
        vm.expectRevert(Arena.YesTimeWindowClosed.selector);
        arena.resolveArenaYes(id);
    }

    function test_yes_phaseNot2_reverts() public {
        uint256 id = arena.createArena(token, uint64(block.timestamp + 1 days));
        vm.prank(alice);
        arena.stake(id, true, 100e6);
        vm.prank(bob);
        arena.stake(id, false, 100e6);

        factory.setPhase(token, IPonsV2LaunchFactory.Phase.Swept); // phase 1
        vm.expectRevert(Arena.NotPoolCreated.selector);
        arena.resolveArenaYes(id);
    }

    function test_emptyWinPool_autoCancel_refund() public {
        uint256 id = arena.createArena(token, uint64(block.timestamp + 1 days));
        vm.prank(bob);
        arena.stake(id, false, 500e6);

        factory.setPhase(token, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(token, block.timestamp);
        arena.resolveArenaYes(id);
        (,,,, Arena.Status status,,) = _arena(id);
        assertTrue(status == Arena.Status.Cancelled);

        vm.prank(bob);
        assertEq(arena.claim(id), 500e6);
    }

    function test_cancelRefund_emptyOnly() public {
        uint256 id = arena.createArena(token, uint64(block.timestamp + 1 days));
        arena.cancelArena(id);
        (,,,, Arena.Status status,,) = _arena(id);
        assertTrue(status == Arena.Status.Cancelled);
    }

    function test_cancelWithStakesReverts() public {
        uint256 id = arena.createArena(token, uint64(block.timestamp + 1 days));
        vm.prank(alice);
        arena.stake(id, true, 250e6);
        vm.expectRevert(Arena.HasStakes.selector);
        arena.cancelArena(id);
    }

    function test_lockClosesStaking() public {
        uint256 id = arena.createArena(token, uint64(block.timestamp + 1 days));
        arena.lockArena(id);
        vm.prank(alice);
        vm.expectRevert(Arena.NotOpen.selector);
        arena.stake(id, true, 100e6);

        uint256 id2 = arena.createArena(token, uint64(block.timestamp + 2 days));
        vm.prank(alice);
        arena.stake(id2, true, 100e6);
        vm.prank(bob);
        arena.stake(id2, false, 100e6);
        arena.lockArena(id2);
        factory.setPhase(token, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(token, block.timestamp);
        arena.resolveArenaYes(id2);
        vm.prank(alice);
        assertEq(arena.claim(id2), 100e6 + 99e6);
    }

    function test_resolveNo_whenPhaseNot2_afterT() public {
        uint256 id = arena.createArena(token, uint64(block.timestamp + 1 hours));
        vm.prank(alice);
        arena.stake(id, true, 400e6);
        vm.prank(bob);
        arena.stake(id, false, 600e6);

        // still phase 0
        vm.warp(block.timestamp + 1 hours + 1);
        vm.prank(stranger);
        arena.resolveArenaNo(id);

        vm.prank(bob);
        uint256 payout = arena.claim(id);
        assertEq(payout, 600e6 + 396e6);
    }

    function test_resolveNo_whenPhase2_reverts() public {
        uint64 t = uint64(block.timestamp + 1 hours);
        uint256 id = arena.createArena(token, t);
        vm.prank(alice);
        arena.stake(id, true, 100e6);
        vm.prank(bob);
        arena.stake(id, false, 100e6);

        factory.setPhase(token, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(token, block.timestamp + 10); // before T

        vm.warp(t + 1);
        vm.expectRevert(Arena.StillGraduated.selector);
        arena.resolveArenaNo(id);

        // late YES still works
        arena.resolveArenaYes(id);
        (,,,, Arena.Status status,,) = _arena(id);
        assertTrue(status == Arena.Status.ResolvedYes);
    }

    function test_duplicateClaimReverts() public {
        uint256 id = arena.createArena(token, uint64(block.timestamp + 1 days));
        vm.prank(alice);
        arena.stake(id, true, 100e6);
        vm.prank(bob);
        arena.stake(id, false, 100e6);
        factory.setPhase(token, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(token, block.timestamp);
        arena.resolveArenaYes(id);
        vm.prank(alice);
        arena.claim(id);
        vm.prank(alice);
        vm.expectRevert(Arena.AlreadyClaimed.selector);
        arena.claim(id);
    }

    function test_feeRecipientZeroReverts() public {
        vm.expectRevert(Arena.InvalidFeeRecipient.selector);
        new Arena(address(usdg), 100, address(0), address(factory));
    }

    function test_setFeeRecipient() public {
        address next = address(0xBEEF);
        arena.setFeeRecipient(next);
        assertEq(arena.feeRecipient(), next);
    }

    function test_topic0Pin() public view {
        assertEq(
            arena.POOL_GRADUATED_TOPIC0(),
            bytes32(0x0a44ef75df69c534f43cd6c1aa3ef8983065fe5fe79ef9e79f6494e6f258c259)
        );
    }

    function _arena(uint256 id)
        internal
        view
        returns (address, uint64, uint256, uint256, Arena.Status, bool, uint64)
    {
        return arena.arenas(id);
    }

    // --- Reviewer re-pass CRITICAL fixes ---

    /// @notice Swept-NO grief before grace must revert (wait for createGraduatedPool)
    function test_sweptNo_beforeGrace_reverts() public {
        uint64 t = uint64(block.timestamp + 1 hours);
        uint256 id = arena.createArena(token, t);
        vm.prank(alice);
        arena.stake(id, true, 100e6);
        vm.prank(bob);
        arena.stake(id, false, 100e6);

        factory.setPhase(token, IPonsV2LaunchFactory.Phase.Swept);
        factory.setSweptAt(token, block.timestamp + 10);

        vm.warp(t + 1); // after T, before grace
        vm.expectRevert(Arena.SweptPending.selector);
        arena.resolveArenaNo(id);
    }

    /// @notice After grace, stuck Swept (phase==1) may resolve NO
    function test_stuckSwept_no_afterGrace() public {
        uint64 t = uint64(block.timestamp + 1 hours);
        uint256 id = arena.createArena(token, t);
        vm.prank(alice);
        arena.stake(id, true, 400e6);
        vm.prank(bob);
        arena.stake(id, false, 600e6);

        factory.setPhase(token, IPonsV2LaunchFactory.Phase.Swept);
        factory.setSweptAt(token, block.timestamp + 10);

        vm.warp(uint256(t) + uint256(arena.gracePeriod()));
        vm.prank(stranger);
        arena.resolveArenaNo(id);

        (,,,, Arena.Status status,,) = _arena(id);
        assertTrue(status == Arena.Status.ResolvedNo);
        vm.prank(bob);
        assertEq(arena.claim(id), 600e6 + 396e6);
    }

    /// @notice Strand escape: phase==2 but late YES fails → cancel+refund after grace
    function test_strandEscape_afterGrace_cancelRefund() public {
        uint64 t = uint64(block.timestamp + 1 hours);
        uint256 id = arena.createArena(token, t);
        vm.prank(alice);
        arena.stake(id, true, 250e6);
        vm.prank(bob);
        arena.stake(id, false, 250e6);

        // PoolCreated but sweptAt >= T → late YES fails; NO blocked by phase==2
        factory.setPhase(token, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(token, uint256(t)); // sweptAt >= T

        vm.warp(t + 1);
        vm.expectRevert(Arena.YesTimeWindowClosed.selector);
        arena.resolveArenaYes(id);
        vm.expectRevert(Arena.StillGraduated.selector);
        arena.resolveArenaNo(id);
        vm.expectRevert(Arena.GraceNotElapsed.selector);
        vm.prank(stranger);
        arena.cancelArena(id);

        vm.warp(uint256(t) + uint256(arena.gracePeriod()));
        vm.prank(stranger);
        arena.cancelArena(id);

        (,,,, Arena.Status status,,) = _arena(id);
        assertTrue(status == Arena.Status.Cancelled);
        vm.prank(alice);
        assertEq(arena.claim(id), 250e6);
        vm.prank(bob);
        assertEq(arena.claim(id), 250e6);
    }

    /// @notice Strand escape blocked while late YES still available
    function test_strandEscape_lateYesAvailable_reverts() public {
        uint64 t = uint64(block.timestamp + 1 hours);
        uint256 id = arena.createArena(token, t);
        vm.prank(alice);
        arena.stake(id, true, 100e6);
        vm.prank(bob);
        arena.stake(id, false, 100e6);

        factory.setPhase(token, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setSweptAt(token, block.timestamp + 10); // sweptAt < T

        vm.warp(uint256(t) + uint256(arena.gracePeriod()));
        vm.expectRevert(Arena.LateYesStillAvailable.selector);
        arena.cancelArena(id);

        // late YES still works
        arena.resolveArenaYes(id);
        (,,,, Arena.Status status,,) = _arena(id);
        assertTrue(status == Arena.Status.ResolvedYes);
    }

}
