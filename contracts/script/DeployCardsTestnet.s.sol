// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {PlayerCard} from "../src/PlayerCard.sol";
import {CardPack} from "../src/CardPack.sol";
import {MockUSDG} from "../src/mocks/MockUSDG.sol";

/// @title Deploy Mode C PlayerCard + CardPack to RH testnet 46630 ONLY
/// @notice Kakashi A2 GO + Pak testnet unlock. Mainnet 4663 LOCKED.
/// @dev Official testnet USDG balance may be 0 — deploys MockUSDG as pack collateral for smoke.
///      Redeploy against real USDG `0x7E9552…802F` when faucet funds exist (immutable usdg on CardPack).
contract DeployCardsTestnet is Script {
    address constant USDG_TESTNET_OFFICIAL = 0x7E955252E15c84f5768B83c41a71F9eba181802F;
    uint16 constant SEASON = 1;
    uint256 constant SMOKE_MINT = 1_000e6; // 1000 MockUSDG

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);
        require(block.chainid == 46630, "DeployCardsTestnet: chainId must be 46630");

        console2.log("=== HOOD ARENA CARDS TESTNET DEPLOY 46630 ===");
        console2.log("deployer:", deployer);
        console2.log("official USDG (not used - balance 0):", USDG_TESTNET_OFFICIAL);
        console2.log("season:", SEASON);

        vm.startBroadcast(pk);

        MockUSDG mock = new MockUSDG();
        PlayerCard cards = new PlayerCard();
        CardPack pack = new CardPack(address(mock), address(cards), deployer, SEASON);
        cards.setMinter(address(pack), true);
        // sole minter — do not enable other minters
        mock.mint(deployer, SMOKE_MINT);

        vm.stopBroadcast();

        console2.log("MockUSDG (pack collateral):", address(mock));
        console2.log("PlayerCard:", address(cards));
        console2.log("CardPack:", address(pack));
        console2.log("feeRecipient=owner:", deployer);
        console2.log("minter: CardPack only");
        console2.log("smoke MockUSDG minted to deployer:", SMOKE_MINT);
    }
}
