# Hood Arena — RH testnet 46630 addresses

**Status:** deployed 2026-09-06 (Pak unlock: `UNLOCK HOOD ARENA BROADCAST testnet 46630`).

| Item | Value |
|------|--------|
| chainId | `46630` |
| RPC | `https://rpc.testnet.chain.robinhood.com` |
| Explorer | `https://explorer.testnet.chain.robinhood.com` |
| Faucet | `https://faucet.testnet.chain.robinhood.com` |
| USDG testnet | `0x7E955252E15c84f5768B83c41a71F9eba181802F` |
| Deployer / owner / feeRecipient | `0x6f86de8ffCd6Ea67a831F9E955D2EcFD455C9D27` |
| MockPonsFactory | `0xa027B44Ba034AFdA1f46dA998425b43e917c9d2E` |
| Arena | `0x5f4A45FdA45D76404574dEf95b2101700deF77e7` |
| GraduationRace | `0x71a3aE51E2CC8CD6722C12319EC97502c2DFE771` |
| feeBps | `100` |

Notes:
- Live PONS factory is **not** on testnet; smoke uses `MockPonsFactory`.
- Mainnet `4663` remains locked.
- Explorer:
  - Arena: https://explorer.testnet.chain.robinhood.com/address/0x5f4A45FdA45D76404574dEf95b2101700deF77e7
  - Race: https://explorer.testnet.chain.robinhood.com/address/0x71a3aE51E2CC8CD6722C12319EC97502c2DFE771
  - Mock factory: https://explorer.testnet.chain.robinhood.com/address/0xa027B44Ba034AFdA1f46dA998425b43e917c9d2E


## Smoke Create+Stake (2026-09-06)

Official testnet USDG faucet path was empty on deployer — full stake used mintable MockUSDG.

| Item | Value |
|------|--------|
| Prod Arena (real testnet USDG pin) | `0x5f4A45FdA45D76404574dEf95b2101700deF77e7` |
| Prod arenaId created | `1` (token `0x1111…1111`, MockPons exists) |
| Prod create tx | `0xc28b2410feae1e3c2e49360b4bfdf269dc97a8c2fd661a421e0bd7eef4aa0fff` |
| Smoke MockUSDG | `0xdDfD024200631606c6aC045A41EFcE1a276AD7D0` |
| Smoke Arena | `0xf88327F666Dcfa05A34e815c80efDDea6CB7F4b5` |
| Smoke arenaId | `1` — YES stake `10` USDG (6 dp) |
| MockPonsFactory | `0xa027B44Ba034AFdA1f46dA998425b43e917c9d2E` |

Stake against **prod** Arena still needs real testnet USDG in the wallet (faucet does not mint USDG to us yet).


## WETH fallback smoke (2026-09-07) — faucet 403 on box IP

Faucet returned 403 from assistant machine; used WETH collateral instead of USDG.

| Item | Value |
|------|--------|
| WETH (Uniswap testnet) | `0x33e4191705c386532ba27cBF171Db86919200B94` |
| WETH Arena | `0xEe33446e96187D4E4bffEA61D909231CC98cBaE5` |
| MockPonsFactory | `0xa027B44Ba034AFdA1f46dA998425b43e917c9d2E` |
| Flow | wrap 0.001 ETH → stake YES 0.0006 + NO 0.0004 → phase=2 → resolveYes → claim |
| Claim payout | `0.000996` ETH (1% fee on losing pool) |

Mainnet remains USDG-only. Prod USDG Arena unchanged: `0x5f4A45FdA45D76404574dEf95b2101700deF77e7`.
