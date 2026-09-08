# Testnet collateral options

## Preferred: official USDG
- Token: `0x7E955252E15c84f5768B83c41a71F9eba181802F` (6 dp)
- Prod Arena: `0x5f4A45FdA45D76404574dEf95b2101700deF77e7`
- Path: faucet/swap → stake on prod Arena → resolve via MockPons → claim

## Wallet path (in progress)
- Desk wallet `0x6f86de8ffCd6Ea67a831F9E955D2EcFD455C9D27` (MetaMask import from vaulted mnemonic on box)
- Faucet: https://faucet.testnet.chain.robinhood.com (browser Turnstile + Google — may need human)
- Swap: thin NFLX/WETH community pools; USDG route may still fail

## Fallback if USDG unreachable (testnet-only)
Do **not** change mainnet Spec (USDG stays canonical on 4663).

Option A — **WETH stake Arena** (simplest):
- Redeploy Arena + Race with `usdg_` = testnet WETH `0x7943e237c7F95DA44E0301572D358911207852Fa`
- Wrap ETH → WETH → stake / claim as today
- MockPons unchanged

Option B — **Stock-token stake Arena**:
- Redeploy with a faucet stock (e.g. NFLX `0x3b8262A63d25f0477c4DDE23F83cfe22Cb768C93`) as collateral ERC-20
- Stake/claim in stock units; fees still `feeBps` of losing pool
- Label UI “testnet collateral = NFLX” so nobody confuses with mainnet USDG

Option C — keep MockUSDG smoke Arena (`0xf883…`) for claim/rewards demos only

## Mainnet
Always USDG `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168`. No stock/ETH collateral on mainnet without a separate Spec unlock.
