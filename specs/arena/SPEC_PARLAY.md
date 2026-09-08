# SCRATCHED — PONS Parlay

**Status:** SCRATCHED by Pak 2026-09-07 — do not build.  
**Reason:** Real-game / oracle / Polymarket-mirror path too heavy; pivoting to NFT player-card packs (Big Win–style) under Arena.

---

# HOOD ARENA — Mode C: PONS Parlay (Spec draft)

**Status:** DRAFT — awaiting Pak visual/UX approve before contracts  
**Date:** 2026-09-07 (PT)  
**Parent:** `SPEC.md` (Arena + Graduation Race)  
**Chain:** Robinhood EVM `4663` (mainnet Spec); testnet smoke OK with MockPons  
**Stake:** USDG only on mainnet; testnet may use WETH/NFLX for dry smoke only  
**Live:** locked (no mainnet deploy)

## 1. One-liner
Multi-leg **parlay** on PONS graduations: pick YES/NO on 2–5 launches in one ticket, stake USDG once, win only if **every** leg is correct. Resolve is permissionless via the same factory VIEW as Arena (`phase == 2`).

## 2. Why it fits
- Same wedge vs HoodWars (pad events, not price PvP)
- Reuses `ponsFactory`, grace, Swept wait, feeBps=100, cancel/refund patterns
- Stronger arcade “ticket” fantasy than binary Arena / 3-up Race
- No sports oracle required for v1 of this mode

## 3. Locked decisions (Parlay)
| Decision | Lock |
|----------|------|
| Legs | **2–5** PONS tokens; each leg is YES (graduates under Arena YES clock) or NO (fails under Arena NO rules) |
| Ticket win | **All legs must hit** (classic parlay). Partial = lose |
| Stake | Single USDG amount on the ticket (not per-leg pots in v1) |
| Payout | Parimutuel among winning tickets on that **slate** minus `feeBps` — **not** fixed sportsbook odds in v1 |
| Resolve | Permissionless; each leg evaluated with Arena YES/NO factory rules |
| Create | Owner/keeper posts a **slate** of tokens + shared deadline `T` + grace |
| Stock tokens / RHJ / crash / slots | Still **off limits** as legs |
| Trusted keeper | Still **REJECTED** |

## 4. Loop
1. `/parlay` lobby lists open **slates** (neon ticket cards: 2–5 legs, pot, timer).
2. User toggles YES/NO per leg → builds ticket → Approve USDG → Stake.
3. After `T` (+ grace where Swept pending), anyone calls `resolveParlay(slateId)`.
4. Winners claim share of losing tickets’ pool (minus fee); if no winners → cancel + refund all (no fee).
5. Share card: “X-leg PONS parlay hit.”

## 5. Objects
### Slate
- `legs[2..5]` — `{ token, /* implied both YES and NO available per ticket */ }`
- `deadline` — unix `T`
- `gracePeriod` — same default `1 days` as Arena
- `pot` / accounting — total USDG staked across tickets
- `status` — `Open | Locked | Resolved | Cancelled`
- `ponsFactory` — immutable pin (same as Arena)

### Ticket (per user per slate)
- `picks[]` — bool yes per leg (length = legs)
- `amount` — USDG staked
- `claimed` — bool

## 6. Resolve rules (per leg)
Reuse Arena semantics exactly:
- **YES leg hits** iff `exists && phase==2` AND (`now <= T` OR (`sweptAt != 0 && sweptAt < T`))
- **NO leg hits** iff after `T`: before grace only `phase==0|3`; Swept waits; after grace `phase!=2`
- If any leg is still **pending Swept** (`phase==1`, `sweptAt < T`) before `T+grace` → resolve reverts / wait (mirror Race sibling wait)
- After grace, evaluate all legs; ticket wins only if every pick matches
- Empty winner set → `Cancelled` + full refund

## 7. Fees
- `feeBps = 100` (1%) on losing pool when there is ≥1 winning ticket
- Fee recipient = same pattern as Arena/Race
- Cancel/refund: **no fee**

## 8. UX
- Route: `/parlay`
- Visual: same arcade + DeFi shell; ticket stub art (Grok GenerateImage + SVG)
- Home: third mode chip next to Arena / Race
- Mock filename (to generate after approve): `mocks/10-pons-parlay.png`

## 9. Contract sketch (dry — not built yet)
- `PonsParlay.sol` — escrow + slate/ticket storage + `resolveParlay` + `claim`
- Shared libs optional later (`PonsResolve.sol` for YES/NO predicates)
- Tests: all-hit win, one-miss lose, Swept wait, cancel none-win, fee math, max 5 legs

## 10. Out of scope (Parlay v1)
- Fixed decimal odds / sportsbook juice
- Correlated-leg pricing models
- Live in-leg cashout
- Mixing non-PONS pads
- Sports outcomes (see `SPEC_SPORTS_STUB.md`)

## 11. Next after Pak approve
1. Dry `PonsParlay.sol` + forge tests  
2. UI `/parlay` shell wired to mock then ABI  
3. Reviewer pass  
4. Testnet deploy (MockPons) — mainnet still unlock-gated  
