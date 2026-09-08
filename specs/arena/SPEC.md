# HOOD ARENA — Spec v1 (approval)

**Status:** APPROVED — dry package **complete** at `/workspace/rh-build/hood-arena/` (contracts + web mock UI + PONS watcher stub + docs; still **no deploy**)
**Date:** 2026-09-05 (PT)  
**Chain:** Robinhood EVM `4663`  
**Stake asset:** USDG only — mainnet CA `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168` (6 decimals; Paxos + on-chain verify 2026-09-05)  
**Live:** locked (no deploy until green-light after this Spec)

## 1. Product one-liner
Arcade + DeFi tug-of-war: stake USDG on whether a **PONS** launch **graduates** before the timer. Resolve is **on-chain-verifiable** via PONS factory VIEW `getLaunchedToken(token).phase == 2` (`PoolCreated`) — **not** keeper fiat and **not** a price duel. Trusted-keeper unlock **REJECTED** by Pak.

## 2. Locked decisions
| Decision | Lock |
|----------|------|
| Wedge vs HoodWars | Pad graduation / launch-event — **not** token-price PvP |
| Pad scope v1 | **PONS-only** |
| Stake | USDG |
| Stock tokens / RHJ | **Off limits** as outcomes |
| Crash / slots / Astro luck | Out of scope |
| Visual | Arcade + DeFi (neon lime, dark, wallet chrome) — not casino, not sportsbook |
| Modes v1 | **Arena** + **Graduation Race** |
| PONS Parlay / Sports | **SCRATCHED** 2026-09-07 |
| Mode C Cards | **LOCKED** — packs+cards on-chain, matches cosmetic — [`SPEC_CARDS.md`](./SPEC_CARDS.md) |

## 3. Game loop
1. Home shows **LIVE PONS ARENAS** (open launches with timers + YES/NO tug bars + pot).
2. User picks side: **YES GRADUATE** / **NO FAIL**.
3. Approve USDG → Stake (two-step tx UX).
4. Stakes lock until resolve or cancel rule.
5. Resolve → claim → optional share card → next arena.


## 3b. Mode B — Graduation Race (companion)
Same site, same art, second tab.

**Loop**
1. Race lobby shows **3 live PONS launches** (lanes with curve-fill hint UI only).
2. User picks **one** token: “which graduates first?”
3. Approve USDG → Stake on that pick.
4. Resolve when **first** of the three emits `PoolGraduated` (or race deadline with none — **cancel + full refund**, no fee).
5. Winners who picked the first graduate split pot minus fee.

**Resolve (factory VIEW)**
- Same `ponsFactory` as Arena; winner = race member with `phase == 2`; among those, **earliest `sweptAt`**, then **lowest token address** on ties.
- If any member is `phase==1` (Swept) with `sweptAt < T`, wait until `T + grace` before crowning another `phase==2` winner (or cancel if none).
- Permissionless `resolveRace(raceId, winner)`. Empty win pot reverts. Late path uses `sweptAt < T`.
- Do **not** use price, Dexscreener rank, or event decode as proof (phase is authoritative).

**Race object (v1)**
- `tokens[3]` — PONS V2 factory tokens
- `deadline` — unix `T`
- `pots[token]` — USDG staked per pick
- `status` — `Open` | `Locked` | `Resolved` | `Cancelled`
- `winner` — token address or null if cancelled

**UX mock:** `mocks/09-graduation-race.png`

**Deferred:** Curve Heat, Safety Strike, multi-pad races.

## 3c. Mode C — SCRATCHED (was PONS Parlay)
Superseded by **NFT Card Packs / Big Win–style** — see [`SPEC_CARDS.md`](./SPEC_CARDS.md). Old draft kept as scratched: [`SPEC_PARLAY.md`](./SPEC_PARLAY.md).

### (archived header) Mode C — PONS Parlay
Full Spec: [`SPEC_PARLAY.md`](./SPEC_PARLAY.md).

**Loop (summary)**
1. Slate of **2–5** PONS launches; user picks YES/NO per leg on one ticket.
2. Stake USDG once; ticket wins only if **all** legs hit.
3. Resolve permissionless with Arena YES/NO factory rules (`phase==2` / grace / Swept wait).
4. Parimutuel among winning tickets minus `feeBps`; no winners → cancel + refund.

**Sports Fantasy / Parlay:** stub only — [`SPEC_SPORTS_STUB.md`](./SPEC_SPORTS_STUB.md).


## 4. Resolve (PONS) — on-chain factory VIEW
**Trust model:** Resolve is **permissionless** and keys off factory storage-readable state:

`getLaunchedToken(token).exists && getLaunchedToken(token).phase == 2` (`PoolCreated`)

PONS docs: **`phase` is authoritative** — do not infer graduation from balances or events. Event `PoolGraduated(token, poolId, pool)` is watcher/audit only.

| Item | Value | Source |
|------|-------|--------|
| Factory (`ponsFactory` immutable) | `PonsV2LaunchFactory` `0x7eD598BcEf8bd9Edd8C97A195C6d13f40801EC7e` | pons docs + `pons-factory-views.md` |
| YES | `phase == 2` AND (`now <= T` **OR** (`sweptAt != 0 && sweptAt < T`)) — intentional *swept before T + eventually PoolCreated* (no `poolCreatedAt`) | Factory VIEW; permissionless |
| NO | After T: before grace only `phase==0\|3`; Swept waits; after grace `phase!=2` (stuck Swept OK) | Factory VIEW; permissionless + grace |
| Strand | After `T+grace`, `phase==2` but late YES fails → cancel+refund | Permissionless `cancelArena` |
| Race | Earliest `sweptAt` among `phase==2`, then lowest address; wait on Swept sibling until grace; empty winning pot auto-cancels + refunds (Arena-mirror; does not skip to next pick) | Factory VIEW |
| Create | `getLaunchedToken(token).exists` required | Factory VIEW |
| Preferred over | Event decode / keeper `graduatedAt` / `phase==1` Swept alone | Pak unlock gate + Field ABI |

**Trusted-keeper unlock: REJECTED.** Freeform keeper YES path removed.

**Deferred (v1.1+):** ZK/storage proof of same VIEW; Pools.trade Instant, Crowd Launch, hood.fun.

## 5. Arena object (v1)
- `token` — launched token address (must be from PONS V2 factory)
- `question` — fixed template: “Will $TICKER graduate on PONS before T?”
- `deadline` — unix `T`
- `yesPool` / `noPool` — USDG stakes
- `status` — `Open` | `Locked` | `ResolvedYes` | `ResolvedNo` | `Cancelled`
- `feeBps` — protocol fee on winning side; dry default **`100` (1%)** in Foundry tests / DeploySketch (max 1000)

## 6. UX screens (approval mocks)
| Screen | File | Must show |
|--------|------|-----------|
| Home | `mocks/06-approval-home.png` | Live PONS arenas, YES/NO bars, USDG pot, timer, wallet, chain 4663, resolve = factory phase==2 VIEW |
| Stake | `mocks/07-approval-stake.png` | Side select, USDG chips, Approve→Stake, CA safety strip |
| Resolved | `mocks/08-approval-resolved.png` | Winner, payout, timeline (Opened→Locked→Factory phase PoolCreated→Claim), rematch/next |

## 7. Safety / gates
- Read-only research + Spec until Pak approves visuals + this Spec.
- No production contracts, no deploy, no live stakes until explicit go.
- CA safety glance before stake (companion strip; not a full auditor).
- Auto-review / human gate for any later spend or deploy.

## 8. Out of scope v1
- Multi-pad adapters, continuous CLOB, leverage, stock-token arenas, HoodWars-style price duels, Curve Heat / Safety Strike, mobile-native app (web first).

## 9. Dry package status / next
1. Contract sketch done — Arena + GraduationRace + tests (dry).
1b. **PONS Parlay** Spec draft filed (`SPEC_PARLAY.md`); sports stub filed; contracts not started.
2. UI shell done — mock data + arcade art; `/how` page; Scan Cabinet CA strip.
3. PONS watcher stub done — `scripts/pons_watcher.py` read-only logs (+ `--dry-resolve` print-only).
4. Still no live mainnet release. Testnet plan on 4663 when Pak unlocks.
5. Production USDG CA locked (see §10) — never invent alternates; testnet CA must not mix with mainnet.

## Refs
- Concept: `CONCEPT.md`
- Resolve research: `/workspace/rh-build/research/pad-resolve-signals.md`
- Comps: `/workspace/rh-build/research/arena-comps.md`

## 10. Pre-deploy locks (Pak 2026-09-05 — must-haves)

| Item | Lock |
|------|------|
| `feeBps` | **100** (1%) on winning pool; immutable at deploy; max allowed in code 1000 — **still locked** |
| Race if none graduate by T | **Cancel + full refund** of all picks (no fee); permissionless `cancelRace` after T (wait `T+grace` if Swept sibling pending) |
| Arena YES | **Permissionless** `resolveArenaYes` when `phase == 2`; time: `now <= T` OR (`sweptAt != 0 && sweptAt < T`) — swept-before-T + eventually PoolCreated |
| Arena NO | **Permissionless** after T: before grace only phase 0/3; after grace phase!=2 (incl. stuck Swept) |
| Strand escape | After `T+grace`, phase==2 but late YES fails → permissionless cancel+refund |
| Race | **Permissionless** `resolveRace(winner)` — earliest `sweptAt` then lowest address; wait on Swept sibling until grace |
| Lock | Keeper-only `lockArena` / `lockRace`; `gracePeriod` gates Swept wait / early NO / strand |
| Token eligibility | Create requires `getLaunchedToken(token).exists` on `ponsFactory` `0x7eD598Bc…EC7e` |
| USDG mainnet | `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168` (6 decimals) |
| USDG testnet | `0x7E955252E15c84f5768B83c41a71F9eba181802F` — never mix with mainnet |
| Broadcast | **LOCKED** until Pak unlocks testnet or mainnet explicitly |

## 11. Unlock gate (Pak 2026-09-05)
**Trusted-keeper unlock: REJECTED.**  
**Implemented (dry):** factory `getLaunchedToken(token).phase == 2` (PoolCreated), permissionless resolve + `sweptAt` late path — not keeper-supplied `graduatedAt`.  
**r5 CRITICAL (Reviewer re-pass KILL):** Swept-NO wait before grace; YES clock = swept-before-T + eventually PoolCreated; race address tie-break; strand cancel+refund after grace; race waits on Swept sibling until grace.  
Broadcast remains LOCKED until Reviewer re-pass clears + Pak unlock phrase.

## 12. Reviewer status (2026-09-06)
**PROCEED** on Arena + GraduationRace for on-chain PONS `phase==2` path (strand KILLs closed).  
Live deploy still **LOCKED** until Pak unlock phrase. Residual: empty-pot earliest YES cancels whole race (intentional); fee dust / FoT / Ownable2Step medium-low.
