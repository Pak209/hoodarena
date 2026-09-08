# Test venue (dry — no broadcast)

Two local/read-only paths for verifying contracts and UI config against Robinhood Chain. **No `--broadcast`.**

## Path A — Anvil fork of RH mainnet (chainId 4663)

| Item | Value |
|------|--------|
| RPC | `https://rpc.mainnet.chain.robinhood.com` |
| chainId | `4663` |
| USDG | `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168` (6 decimals) |
| PONS factory | `0x7eD598BcEf8bd9Edd8C97A195C6d13f40801EC7e` |

```bash
# from hood-arena/
make anvil-fork
# other terminal:
make forge-test
make forge-test-fork   # optional fork-url tests (still no broadcast)
```

Or manually:

```bash
export PATH="$PATH:$HOME/.foundry/bin"
anvil --fork-url https://rpc.mainnet.chain.robinhood.com --chain-id 4663
```

Use fork only to read USDG/factory state and run local forge tests. DeploySketch remains print-only.

## Path B — RH testnet USDG

| Item | Value |
|------|--------|
| Public RPC | `https://rpc.testnet.chain.robinhood.com` ([docs](https://docs.robinhood.com/chain/connecting/)) |
| chainId | `46630` |
| USDG testnet | `0x7E955252E15c84f5768B83c41a71F9eba181802F` — **never mix with mainnet USDG** |
| Explorer | `https://explorer.testnet.chain.robinhood.com` |
| Faucet | `https://faucet.testnet.chain.robinhood.com` |

```bash
make anvil-fork-testnet
```

Alchemy-keyed RPCs also exist (`robinhood-testnet.g.alchemy.com`) — optional; public RPC is enough for dry reads.

**Still no broadcast** until unlock phrase in `DEPLOYER.md`.

## Web env placeholders

See `web/.env.example`:

- `VITE_CHAIN_ID`
- `VITE_RPC_URL`
- `VITE_ARENA_ADDRESS`
- `VITE_RACE_ADDRESS`
- `VITE_USDG_ADDRESS`

Empty arena/race addresses → UI **mock mode**.

## Helpers

| File | Purpose |
|------|---------|
| `Makefile` | `anvil-fork`, `anvil-fork-testnet`, `forge-test`, `forge-test-fork`, `export-abi` |
| `scripts/anvil-fork.sh` | Mainnet fork launcher |
| `scripts/anvil-fork-testnet.sh` | Testnet fork launcher |
| `contracts/script/DeploySketch.s.sol` | Dry print only |
