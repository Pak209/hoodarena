// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {Arena} from "../src/Arena.sol";
import {MockUSDG} from "../src/mocks/MockUSDG.sol";
import {MockPonsFactory} from "../src/mocks/MockPonsFactory.sol";
import {IPonsV2LaunchFactory} from "../src/interfaces/IPonsV2LaunchFactory.sol";

/// @notice Testnet smoke: mintable USDG + createArena + YES stake.
/// @dev Uses existing MockPonsFactory if SMOKE_FACTORY set; else deploys one.
///      chainId must be 46630. Mainnet forbidden.
contract SmokeCreateStake is Script {
    address constant EXISTING_FACTORY = 0xa027B44Ba034AFdA1f46dA998425b43e917c9d2E;
    address constant FAKE_TOKEN = 0x2222222222222222222222222222222222222222;
    uint16 constant FEE_BPS = 100;
    uint256 constant STAKE_AMT = 10_000_000; // 10 USDG (6 dp)

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);
        require(block.chainid == 46630, "smoke: testnet 46630 only");

        vm.startBroadcast(pk);

        MockUSDG usdg = new MockUSDG();
        MockPonsFactory factory = MockPonsFactory(EXISTING_FACTORY);
        factory.setLaunch(FAKE_TOKEN, IPonsV2LaunchFactory.Phase.NotGraduated, 0, true);

        Arena arena = new Arena(address(usdg), FEE_BPS, deployer, address(factory));
        uint64 deadline = uint64(block.timestamp + 3 days);
        uint256 arenaId = arena.createArena(FAKE_TOKEN, deadline);

        usdg.mint(deployer, STAKE_AMT);
        usdg.approve(address(arena), STAKE_AMT);
        arena.stake(arenaId, true, STAKE_AMT);

        vm.stopBroadcast();

        console2.log("Smoke MockUSDG", address(usdg));
        console2.log("Smoke Arena", address(arena));
        console2.log("arenaId", arenaId);
        console2.log("staked YES", STAKE_AMT);
        console2.log("deadline", deadline);
    }
}
