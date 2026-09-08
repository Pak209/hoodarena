# HOOD ARENA — concept (rough)

Working name: **Hood Arena**. Chain: Robinhood EVM 4663. Stake asset: **USDG**.

## Loop
1. Browse live arenas (short binary questions).
2. Pick YES/NO — tug-of-war fills as USDG stakes land.
3. Stake locked until resolve.
4. Resolve via oracle / clear rule (v1: pad graduation, price thresholds — **no RHJ stock outcomes**).
5. Winners split pot minus small fee; optional share card.

## Feel
Arcade fight / tug-of-war, not sportsbook. Robinhood neon lime + dark. Skill/prediction framing.

## v1 scope (contracts later)
- Create arena (question, duration, resolve rule)
- Stake USDG on side
- Resolve + claim
- No leverage, no continuous order book, no stock tokens

## Screens
- `mocks/01-home.png` — live feed
- `mocks/02-stake.png` — fight select + stake
- `mocks/03-result.png` — resolve + payout

## Competitive wedge (2026-09-05)
**HoodWars** (`hoodwars.co`) already ships USDG PvP tug-of-war on price duels (self-reported ~$6.7k volume / 19 battles). Do **not** Spec as BONK-vs-WIF / BTC price fights.

### Locked Spec wedge
- Arena type: **pad graduation / launch-event** binaries only
  - e.g. “Will this Pools.trade / PONS / hood.fun launch graduate before T?”
- Stake: USDG only
- No RHJ / stock-token outcomes
- No Astro-style crash / luck games
- Short rounds (minutes–hours)
- Optional: CA safety glance before stake (companion to safety terminal)

### Resolve hooks to research next
Pools.trade $10k FDV / v4 lock; PONS curve→v4; hood.fun graduate — need factory/event CAs for Spec.

## Visual direction (user 2026-09-05)
**Arcade + DeFi** — CRT/coin-op energy + real wallet/USDG chrome. Not casino (no slots/crash). Not sterile Polymarket tables.

## Spec v1 pad scope (Niche + Field, 2026-09-05)
**PONS-only** graduation arenas for v1.
- Resolve: watch `PoolGraduated` on PONS V2 factory `0x7eD598Bc…EC7e` (see `/workspace/rh-build/research/pad-resolve-signals.md`)
- Defer Pools.trade Instant (no Graduated event) and hood.fun (CAs soft)
- Multi-pad adapters = v1.1+

## Approval package (2026-09-05)
- Spec: `SPEC.md` (PONS-only, PoolGraduated resolve, USDG, arcade+DeFi)
- Approval mocks: `06-approval-home.png`, `07-approval-stake.png`, `08-approval-resolved.png`

## Companion mode (Pak 2026-09-05)
**Graduation Race** — 3 live PONS lanes; stake USDG on which hits `PoolGraduated` first. Mock: `mocks/09-graduation-race.png`. Same locks as Arena.


## Mode C (2026-09-07)
**PONS Parlay** — multi-leg graduation tickets (see `SPEC_PARLAY.md`). Sports Fantasy stubbed (`SPEC_SPORTS_STUB.md`).


## Mode C pivot (2026-09-07)
PONS Parlay / sports scratched. Mode C **LOCKED**: Big Win–style **packs + card NFTs on-chain**, matches **cosmetic** — `SPEC_CARDS.md`.
