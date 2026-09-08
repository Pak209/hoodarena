// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";

/// @title Deploy sketch - DRY / NO BROADCAST BY DEFAULT
/// @notice LIVE LOCKED. Prints intended constructor args only.
///         Do NOT run with `--broadcast`. No private keys. No mainnet deploy.
/// @dev Usage (local dry): `forge script script/DeploySketch.s.sol`
contract DeploySketch is Script {
    address constant USDG = 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168; // Paxos Global Dollar (6 dp)
    address constant PONS_FACTORY = 0x7eD598BcEf8bd9Edd8C97A195C6d13f40801EC7e;

    function run() external view {
        console2.log("=== HOOD ARENA DEPLOY SKETCH (DRY) ===");
        console2.log("LIVE LOCKED - do not --broadcast");
        console2.log("chainId target: 4663");
        console2.log("PONS factory (ponsFactory immutable):", PONS_FACTORY);
        console2.log("USDG (verified):", USDG);
        console2.log("Would deploy Arena + GraduationRace with feeBps=100");
        console2.log("Resolve: getLaunchedToken.phase==2 (PoolCreated) - permissionless");
        console2.log("Trusted-keeper unlock REJECTED by Pak");
        // Intentionally no vm.startBroadcast()
    }
}
