# Keeper / resolver runbook (dry)

**LIVE LOCKED** — never auto-broadcast resolve/cancel txs until Pak unlocks (see `DEPLOYER.md` unlock phrase).

## Trust model

**On-chain factory VIEW** — not trusted-keeper fiat.  
Pak **rejected** trusted-keeper unlock. Resolve is **permissionless** and keys off:

`getLaunchedToken(token).phase == 2` (`PoolCreated`)

Docs: phase is authoritative; **do not** treat `PoolGraduated` event decode as proof. Event shape (reference only): `PoolGraduated(token, poolId, pool)`.

| Constant | Value |
|----------|--------|
| Factory (`ponsFactory`) | `0x7eD598BcEf8bd9Edd8C97A195C6d13f40801EC7e` |
| YES unlock | `phase == 2` |
| YES clock | `phase==2` AND (`now <= T` OR (`sweptAt != 0 && sweptAt < T`)) |
| NO | before grace: phase 0/3 only; after grace: phase!=2 (stuck Swept OK) |
| Strand | after T+grace, phase==2 but late YES fails → `cancelArena` refund |
| topic0 (watcher pin only) | `0x0a44ef75df69c534f43cd6c1aa3ef8983065fe5fe79ef9e79f6494e6f258c259` |
| gracePeriod | `1 days` — Swept wait, early NO gate, strand escape |
| RPC (mainnet) | `https://rpc.mainnet.chain.robinhood.com` |

## Role

Anyone may call resolve/cancel when factory state satisfies the gates. **Keepers** still used for **lock** (close staking early) and ops monitoring. Prefer eth_call `getLaunchedToken` before submitting resolve.

## Dry watcher

```bash
cd /workspace/rh-build/hood-arena
python3 scripts/pons_watcher.py
python3 scripts/pons_watcher.py --blocks 5000 --dry-resolve
```

`--dry-resolve` **prints** calls. It does **not** sign or send. Confirm `phase==2` on-chain before any future live resolve.

### Mapping

| Observation | Call | Gate |
|-------------|------|------|
| Factory `phase==2` for arena token; YES clock OK | `resolveArenaYes(arenaId)` | **Permissionless**; empty YES → auto-cancel |
| After T; before grace phase 0/3; after grace phase!=2 | `resolveArenaNo(arenaId)` | **Permissionless**; Swept before grace → revert; empty NO → auto-cancel |
| Winner: valid YES + earliest sweptAt (addr tie-break); no pending Swept sibling | `resolveRace(raceId, winner)` | **Permissionless**; wait until T+grace if Swept sibling; empty win pot → cancel+refund |
| After T, no *valid* YES winner (wait grace if Swept sibling; late-invalid phase2 OK) | `cancelRace(raceId)` | **Permissionless** |
| Close staking early | `lockArena` / `lockRace` | onlyKeeper |
| Empty arena (no stakes) OR strand after grace | `cancelArena(arenaId)` | owner empty; anyone after grace if phase==2 && late YES fails |

## SOP before any future live resolve

1. `eth_call` `getLaunchedToken(token)` — require `exists` and `phase == 2` for YES/race.  
2. Confirm arena/race id, token CA, deadline, `sweptAt` for late path.  
3. For races with multiple valid YES, pick earliest `sweptAt` then lowest address; if any Swept sibling with sweptAt < T, wait until T+grace; empty win pot → cancel+refund.  
4. Print with `--dry-resolve` first; only broadcast after unlock.  
5. Gas wallet: ETH only — never custody user USDG.

## Never auto-broadcast until unlock

Default dry/print. Require unlock phrase in `DEPLOYER.md` before `cast send` / `--broadcast`.
