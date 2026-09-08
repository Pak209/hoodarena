// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {Arena} from "../src/Arena.sol";
import {GraduationRace} from "../src/GraduationRace.sol";

/// @title Deploy Hood Arena to RH MAINNET 4663
/// @notice MAINNET LOCKED until Pak says exactly:
///         `UNLOCK HOOD ARENA BROADCAST mainnet 4663`
/// @dev Uses real PONS factory + mainnet USDG. Never run --broadcast without unlock.
contract DeployMainnet is Script {
    address constant USDG_MAINNET = 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168;
    address constant PONS_FACTORY = 0x7eD598BcEf8bd9Edd8C97A195C6d13f40801EC7e;
    uint16 constant FEE_BPS = 100;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);
        // Prefer FEE_RECIPIENT env; default deployer (swap to multisig before real unlock)
        address feeRecipient = vm.envOr("FEE_RECIPIENT", deployer);

        require(block.chainid == 4663, "DeployMainnet: chainId must be 4663");
        // Soft gate: require explicit env ACK (second lock besides Pak chat unlock)
        require(
            vm.envBool("I_UNLOCKED_MAINNET_4663"),
            "set I_UNLOCKED_MAINNET_4663=true only after Pak unlock phrase"
        );

        console2.log("=== HOOD ARENA MAINNET DEPLOY 4663 ===");
        console2.log("deployer", deployer);
        console2.log("feeRecipient", feeRecipient);
        console2.log("USDG", USDG_MAINNET);
        console2.log("PONS", PONS_FACTORY);

        vm.startBroadcast(pk);
        Arena arena = new Arena(USDG_MAINNET, FEE_BPS, feeRecipient, PONS_FACTORY);
        GraduationRace race = new GraduationRace(USDG_MAINNET, FEE_BPS, feeRecipient, PONS_FACTORY);
        vm.stopBroadcast();

        console2.log("Arena", address(arena));
        console2.log("GraduationRace", address(race));
    }
}
