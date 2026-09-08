# Mainnet readiness checklist (PONS) — NO BROADCAST YET

**Status:** prepared 2026-09-06. Mainnet `4663` stays **LOCKED** until Pak says:

> `UNLOCK HOOD ARENA BROADCAST mainnet 4663`

## Pins (verified)

| Item | Value |
|------|--------|
| chainId | `4663` |
| RPC | `https://rpc.mainnet.chain.robinhood.com` |
| USDG (6 dp) | `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168` |
| PONS V2 factory | `0x7eD598BcEf8bd9Edd8C97A195C6d13f40801EC7e` |
| Resolve | `getLaunchedToken(token).phase == 2` (PoolCreated) — permissionless |
| feeBps | `100` (1%) |
| gracePeriod | `1 days` |

## Pre-flight

- [ ] Reviewer PROCEED still current on Arena + GraduationRace
- [ ] `FEE_RECIPIENT` = treasury multisig (not EOA deployer) — set env before broadcast
- [ ] Dedicated gas wallet funded with **real** mainnet ETH (small)
- [ ] Pak unlock phrase naming **mainnet 4663**
- [ ] Set `I_UNLOCKED_MAINNET_4663=true` only after that phrase
- [ ] Dry run: `forge script script/DeployMainnet.s.sol --rpc-url $MAINNET_RPC` (no `--broadcast`)
- [ ] Confirm PONS factory bytecode still at pin on mainnet
- [ ] Confirm USDG decimals == 6 on mainnet
- [ ] Wire `web/.env.mainnet` after deploy; keep testnet `.env.testnet` separate
- [ ] Keeper runbook points at live PONS factory (not MockPons)
- [ ] Watcher: `scripts/pons_watcher.py` against mainnet RPC + real token CAs

## Do NOT

- Do not deploy MockPonsFactory on mainnet
- Do not reuse testnet USDG / smoke MockUSDG addresses
- Do not enable trusted-keeper unlock path (rejected)
- Do not broadcast until unlock phrase

## Broadcast (after unlock only)

```bash
export PATH="$PATH:$HOME/.foundry/bin"
cd contracts
export PRIVATE_KEY=...   # operator secret store
export FEE_RECIPIENT=0x...  # multisig
export I_UNLOCKED_MAINNET_4663=true
forge script script/DeployMainnet.s.sol:DeployMainnet \
  --rpc-url https://rpc.mainnet.chain.robinhood.com \
  --chain-id 4663 \
  --broadcast
```

## Create / stake on mainnet (after deploy)

1. Pick a real PONS-launched token with `getLaunchedToken(token).exists == true`
2. `createArena(token, deadline)` as owner
3. Users `approve` mainnet USDG → Arena, then `stake(arenaId, yes, amount)`
