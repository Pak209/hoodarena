# HOOD ARENA — dry package

> DO NOT DEPLOY. On-chain factory-phase resolve (Pak rejected trusted-keeper unlock). Still LOCKED pending Reviewer re-pass + Pak unlock.

## Trust model
**On-chain-verifiable** via PONS V2 factory VIEW `getLaunchedToken(token)`:
- YES / race win = `phase == 2` (PoolCreated) — authoritative; not event decode
- YES clock: `phase==2` AND (`now <= T` OR (`sweptAt != 0 && sweptAt < T`)) — swept before T + eventually PoolCreated
- NO after T: before grace only phase 0/3; after grace phase!=2 (stuck Swept OK)
- Strand: after T+grace, phase==2 but late YES fails → cancel+refund
- Race: earliest valid YES `sweptAt` then lowest address; wait on Swept sibling until grace; late-invalid phase2 → cancel; empty win pot → cancel+refund
- Create requires `exists` on factory

`ponsFactory` immutable (default `0x7eD598Bc…EC7e`). Trusted-keeper freeform `graduatedAt` **removed**.

## Docs
- SECURITY.md — Reviewer history + r5 CRITICAL (KILL remediations)
- ops/KEEPER.md — dry-resolve now = permissionless phase calls (lock still keeper)
- ops/DEPLOYER.md — gas wallet + unlock phrase
- Spec: `/workspace/rh-build/specs/arena/SPEC.md` §11 unlock gate
- Research: `/workspace/rh-build/research/pons-factory-views.md`

## Contracts
Foundry under `contracts/`. API: `resolveArenaYes(id)`, `resolveArenaNo(id)`, `resolveRace(id, winner)`, `cancelRace(id)` — all permissionless with factory gates. `lockArena`/`lockRace` keeper-only. Tests etch/pass `MockPonsFactory`.

## Web
Mock-first Vite app. How copy: resolve reads factory phase on-chain. Unlock still needs Reviewer + Pak.

## Watcher
`python3 scripts/pons_watcher.py --dry-resolve` — print-only; prefer checking factory phase over event-as-proof.

chainId 4663 · USDG 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168 · PONS 0x7eD598BcEf8bd9Edd8C97A195C6d13f40801EC7e · feeBps 100 · gracePeriod 1 days

## Out of scope
Live deploy until unlock phrase in ops/DEPLOYER.md.


## Modes
- Arena / Race — implemented (testnet smokes)
- **PONS Parlay** — Spec draft: `/workspace/rh-build/specs/arena/SPEC_PARLAY.md`
- Sports Fantasy — stub only: `SPEC_SPORTS_STUB.md`
