// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {Arena} from "../src/Arena.sol";
import {GraduationRace} from "../src/GraduationRace.sol";
import {MockPonsFactory} from "../src/mocks/MockPonsFactory.sol";
import {IPonsV2LaunchFactory} from "../src/interfaces/IPonsV2LaunchFactory.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";

/// @notice Testnet-only NFLX collateral: Arena + Race smoke (stake/resolve/claim).
contract SmokeNflxStakeClaim is Script {
    address constant EXISTING_FACTORY = 0xa027B44Ba034AFdA1f46dA998425b43e917c9d2E;
    address constant NFLX = 0x3b8262A63d25f0477c4DDE23F83cfe22Cb768C93;
    address constant T0 = 0x4444444444444444444444444444444444444444;
    address constant T1 = 0x5555555555555555555555555555555555555555;
    address constant T2 = 0x6666666666666666666666666666666666666666;
    uint16 constant FEE_BPS = 100;
    uint256 constant YES_AMT = 0.5 ether; // 0.5 NFLX (18 dp)
    uint256 constant NO_AMT = 0.3 ether;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);
        require(block.chainid == 46630, "testnet only");

        IERC20 nflx = IERC20(NFLX);
        require(nflx.balanceOf(deployer) >= YES_AMT + NO_AMT + 0.6 ether, "need NFLX");

        vm.startBroadcast(pk);

        MockPonsFactory factory = MockPonsFactory(EXISTING_FACTORY);
        factory.setLaunch(T0, IPonsV2LaunchFactory.Phase.NotGraduated, 0, true);
        factory.setLaunch(T1, IPonsV2LaunchFactory.Phase.NotGraduated, 0, true);
        factory.setLaunch(T2, IPonsV2LaunchFactory.Phase.NotGraduated, 0, true);

        Arena arena = new Arena(NFLX, FEE_BPS, deployer, address(factory));
        GraduationRace race = new GraduationRace(NFLX, FEE_BPS, deployer, address(factory));

        uint64 deadline = uint64(block.timestamp + 2 days);
        uint256 arenaId = arena.createArena(T0, deadline);
        uint256 raceId = race.createRace(T0, T1, T2, deadline);

        nflx.approve(address(arena), YES_AMT + NO_AMT);
        arena.stake(arenaId, true, YES_AMT);
        arena.stake(arenaId, false, NO_AMT);

        // Race: stake 0.2 on each of 3 legs
        uint256 leg = 0.2 ether;
        nflx.approve(address(race), leg * 3);
        race.stake(raceId, 0, leg);
        race.stake(raceId, 1, leg);
        race.stake(raceId, 2, leg);

        // Arena YES resolve
        factory.setPhase(T0, IPonsV2LaunchFactory.Phase.PoolCreated);
        arena.resolveArenaYes(arenaId);
        uint256 arenaPayout = arena.claim(arenaId);

        // Race: T1 wins (phase 2), T0 also phase 2 but later sweptAt? use setLaunch with sweptAt for ordering
        // Simplest: only T1 to PoolCreated, others stay NotGraduated; after deadline+grace for NO path
        // For YES race resolve need winner with phase 2. Set only T1 to PoolCreated.
        factory.setPhase(T0, IPonsV2LaunchFactory.Phase.NotGraduated);
        factory.setPhase(T1, IPonsV2LaunchFactory.Phase.PoolCreated);
        factory.setPhase(T2, IPonsV2LaunchFactory.Phase.NotGraduated);
        race.resolveRace(raceId, T1);
        uint256 racePayout = race.claim(raceId);

        vm.stopBroadcast();

        console2.log("NFLX Arena", address(arena));
        console2.log("NFLX Race", address(race));
        console2.log("arenaId", arenaId);
        console2.log("raceId", raceId);
        console2.log("arena claim", arenaPayout);
        console2.log("race claim", racePayout);
    }
}
