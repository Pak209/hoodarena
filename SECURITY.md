# Hood Arena — security review

**Date:** 2026-09-05 / 2026-09-06 (PT)  
**Reviewer:** Reviewer (adversarial) + Kakashi desk  
**Verdict path:** KILL → remediations → re-pass KILL → r3 PROCEED-WITH-FIXES → r4 factory phase → r5 KILL → **r5 HOLD (Arena) / Race strand KILL → remediations below**  
**Deploy:** LOCKED until Reviewer clear + Pak unlock phrase

## Trust model (honest)

**On-chain-verifiable PONS graduation via factory VIEW.**  
Resolve reads `IPonsV2LaunchFactory(ponsFactory).getLaunchedToken(token)`:

- **YES / race win** = `exists && phase == 2` (`PoolCreated`) — authoritative; **do not** infer from `PoolGraduated` event decode.
- **YES product clock (intentional):** `phase==2` AND (`block.timestamp <= deadline` OR (`sweptAt != 0 && sweptAt < deadline`)).  
  Meaning: **swept before T and eventually PoolCreated** — not a PoolCreated-at-T clock (no `poolCreatedAt` on-chain).
- **NO** after deadline:
  - **Before `T + grace`:** only if `phase==0` (NotGraduated) or `phase==3` (Rescued).  
    `phase==1` (Swept) **reverts** (`SweptPending` — wait for `createGraduatedPool`). `phase==2` → `StillGraduated` (should YES).
  - **After grace:** NO if `phase != 2` (incl. **stuck Swept**).
- **Strand escape:** After `T + grace`, if `phase==2` but late YES fails (`sweptAt==0 || sweptAt >= deadline`), permissionless **cancel+refund** via `cancelArena` (neither YES nor NO fair).
- **Race** winner = member that is a **valid YES** (`phase==2` AND (`now <= T` OR (`sweptAt != 0 && sweptAt < T`))); among valid, **earliest `sweptAt`**, then **lowest token address** (never strand both). Late-invalid `phase==2` ignored for earliest. Empty win pot → **auto-cancel+refund** (Arena mirror).
- **Race “first” wait:** If any member is `phase==1` with `sweptAt < deadline`, do **not** `resolveRace`/`cancelRace` until `T + grace` (`SweptSiblingPending`). After grace: among valid YES pick earliest `sweptAt` then address; if none valid, `cancelRace`.
- **cancelRace** after deadline when **no valid YES winner** exists. `StillGraduated` only if a valid YES exists. Late-invalid PoolCreated (`phase==2` but `sweptAt==0 || sweptAt >= T`) does **not** block cancel (strand escape). Same Swept-sibling wait until grace.

`ponsFactory` is an **immutable** (default `0x7eD598BcEf8bd9Edd8C97A195C6d13f40801EC7e`).  
`POOL_GRADUATED_TOPIC0` remains a watcher/audit pin only — resolve does **not** key off events.  
**Trusted-keeper unlock: REJECTED by Pak.** Freeform keeper `graduatedAt` YES path **removed**.

Keepers retained only for **lock** (close staking early). `gracePeriod` (1 day) gates Swept wait, early NO, and strand escape.

## CRITICAL / HIGH — status

| # | Finding | Status |
|---|---------|--------|
| 1 | Trusted-keeper resolve / unused factory proof | **Closed (r4)** — permissionless `phase==2` VIEW |
| 2 | Late resolve after T | **Fixed** — late YES via factory `sweptAt < deadline` |
| 3 | Empty winning side | **Fixed** — Arena empty YES → auto-cancel; **Race** empty win pot → auto-cancel+refund |
| 4 | `Status.Locked` unused | **Fixed** — lockArena / lockRace |
| 5 | Owner cancel with stakes | **Fixed** — `HasStakes`; strand escape is separate permissionless path |
| 6 | Keeper key loss freezes pots | **Closed (r4/r5)** — YES/NO/race/cancel permissionless via factory + grace |
| 7 | `feeRecipient==0` | **Fixed** |
| 8 | Race “first” = keeper pick | **Closed (r4/r5)** — earliest `sweptAt` + address tie-break |
| 9 | Future / freeform `graduatedAt` | **Removed** — no keeper timestamp path |
| **10** | **Wrong-NO during Swept** (grief before grace) | **Fixed (r5)** — NO before grace only phase 0/3; Swept waits |
| **11** | **Equal sweptAt strands both** | **Fixed (r5)** — lowest token address tie-break |
| **12** | **Strand: phase==2 + late YES fail** | **Fixed (r5)** — Arena `cancelArena`; Race `cancelRace` when no valid YES |
| **13** | **Race crowns winner while Swept sibling pending** | **Fixed (r5)** — wait until T+grace |
| **14** | **Race late-invalid PoolCreated strands cancel** | **Fixed (r5 HOLD)** — `StillGraduated` only if valid YES exists |
| **15** | **Race EmptyWinPot permanent lock** | **Fixed (r5 HOLD)** — resolve empty win pot → cancel+refund |

## Reviewer re-pass VERDICT (r5) — 2026-09-05/06 PT

**Arena: HOLD** (prior CRITICAL closed). **GraduationRace: KILL → remediations:**

1. **Wrong-NO during Swept:** `resolveArenaNo` no longer treats `phase==1` as fail before grace. Before `T+grace`: NO only for `phase==0|3`; Swept reverts; PoolCreated still blocks NO. After grace: NO if `phase!=2` (stuck Swept OK).
2. **Product/time docs:** YES = `phase==2` AND (`now <= T` OR (`sweptAt != 0 && sweptAt < T`)) — intentional swept-before-T + eventually PoolCreated. SPEC / SECURITY / How updated (not PoolCreated-at-T).
3. **Race equal sweptAt:** Lowest token address among equal earliest `sweptAt` (never strand both).
4. **Strand escape (Arena):** After `T+grace`, `cancelArena` permissionless when `phase==2 && !(sweptAt < T)`.
5. **Race Swept sibling:** Block `resolveRace`/`cancelRace` while any member `phase==1 && sweptAt < T` until grace; then earliest+address or cancel.
6. **Race late-invalid PoolCreated:** `cancelRace` `StillGraduated` only when a *valid* YES winner exists (`phase==2 && sweptAt!=0 && sweptAt < T` after deadline). Phase==2 with bad `sweptAt` allows permissionless cancel+refund (after Swept wait / grace as applicable).
7. **Race empty win pot:** `resolveRace` with chosen winner pot==0 → auto-cancel+refund (mirror Arena empty YES); pot>0 still resolves.

**Forge cases added:** Swept-NO before grace; NO after grace on stuck Swept; equal sweptAt by address; Arena strand escape; race Swept sibling wait; Race cancel after grace with phase2+invalid sweptAt; Race empty/sole winner pot0 → cancel+refund; valid pot>0 still resolves.

## MEDIUM / LOW (still open)
Reentrancy guard on stake; FoT/weird-ERC20; no Ownable2Step; fee dust.

## Remaining blockers before unlock
1. Reviewer re-pass on Race strand CRITICAL fixes (#14/#15)  
2. Explicit unlock phrase (`ops/DEPLOYER.md`) before any broadcast  
3. Optional later: ZK/storage proof of same VIEW (not required if VIEW call accepted)

## Reviewer round-4 (prior) — factory VIEW
Pak rejected trusted-keeper unlock. Permissionless resolve keyed to `phase == 2`. Create requires `exists`.

**Still LOCKED:** Deploy / broadcast / live stakes until Reviewer clear + Pak unlock.

## Race re-pass — PROCEED (Reviewer 2026-09-06)
Strand KILLs closed (late-invalid cancel escape; EmptyWinPot → auto-cancel+refund). Arena HOLD. forge 43/43. Deploy locked pending Pak unlock. Residual: empty-pot cancels whole race (no skip-to-next); SPEC synced; fee dust/FoT/Ownable2Step still MEDIUM/LOW.
