// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {Arena} from "../src/Arena.sol";
import {GraduationRace} from "../src/GraduationRace.sol";
import {MockPonsFactory} from "../src/mocks/MockPonsFactory.sol";

/// @title Deploy Hood Arena to RH testnet 46630 ONLY
/// @notice Requires Pak unlock: `UNLOCK HOOD ARENA BROADCAST testnet 46630`
/// @dev PONS mainnet factory is NOT on testnet — deploys MockPonsFactory for smoke.
///      Mainnet 4663 remains LOCKED. Never point this script at mainnet USDG/RPC.
contract DeployTestnet is Script {
    address constant USDG_TESTNET = 0x7E955252E15c84f5768B83c41a71F9eba181802F;
    uint16 constant FEE_BPS = 100;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);
        require(block.chainid == 46630, "DeployTestnet: chainId must be 46630");

        console2.log("=== HOOD ARENA TESTNET DEPLOY 46630 ===");
        console2.log("deployer:", deployer);
        console2.log("USDG testnet:", USDG_TESTNET);
        console2.log("feeBps:", FEE_BPS);

        vm.startBroadcast(pk);

        MockPonsFactory factory = new MockPonsFactory();
        Arena arena = new Arena(USDG_TESTNET, FEE_BPS, deployer, address(factory));
        GraduationRace race = new GraduationRace(USDG_TESTNET, FEE_BPS, deployer, address(factory));

        vm.stopBroadcast();

        console2.log("MockPonsFactory:", address(factory));
        console2.log("Arena:", address(arena));
        console2.log("GraduationRace:", address(race));
        console2.log("feeRecipient=keeper=owner:", deployer);
    }
}
