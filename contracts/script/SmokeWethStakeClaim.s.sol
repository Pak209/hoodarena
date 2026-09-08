// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {Arena} from "../src/Arena.sol";
import {MockPonsFactory} from "../src/mocks/MockPonsFactory.sol";
import {IPonsV2LaunchFactory} from "../src/interfaces/IPonsV2LaunchFactory.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}

/// @notice Testnet-only: Arena collateral = WETH (not USDG). Full stake YES+NO → resolve YES → claim.
/// @dev Mainnet remains USDG. chainId must be 46630.
contract SmokeWethStakeClaim is Script {
    address constant EXISTING_FACTORY = 0xa027B44Ba034AFdA1f46dA998425b43e917c9d2E;
    address constant WETH = 0x33e4191705c386532ba27cBF171Db86919200B94;
    address constant FAKE_TOKEN = 0x3333333333333333333333333333333333333333;
    uint16 constant FEE_BPS = 100;
    // Keep gas: wrap 0.001 ETH total → 0.0006 YES + 0.0004 NO
    uint256 constant YES_AMT = 0.0006 ether;
    uint256 constant NO_AMT = 0.0004 ether;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);
        require(block.chainid == 46630, "testnet only");

        vm.startBroadcast(pk);

        IWETH weth = IWETH(WETH);
        weth.deposit{value: YES_AMT + NO_AMT}();

        MockPonsFactory factory = MockPonsFactory(EXISTING_FACTORY);
        factory.setLaunch(FAKE_TOKEN, IPonsV2LaunchFactory.Phase.NotGraduated, 0, true);

        Arena arena = new Arena(WETH, FEE_BPS, deployer, address(factory));
        uint64 deadline = uint64(block.timestamp + 2 days);
        uint256 arenaId = arena.createArena(FAKE_TOKEN, deadline);

        weth.approve(address(arena), YES_AMT + NO_AMT);
        arena.stake(arenaId, true, YES_AMT);
        arena.stake(arenaId, false, NO_AMT);

        // Graduate for YES resolve
        factory.setPhase(FAKE_TOKEN, IPonsV2LaunchFactory.Phase.PoolCreated);
        arena.resolveArenaYes(arenaId);

        uint256 payout = arena.claim(arenaId);

        vm.stopBroadcast();

        console2.log("WETH Arena", address(arena));
        console2.log("arenaId", arenaId);
        console2.log("claim payout wei", payout);
        console2.log("deployer", deployer);
    }
}
