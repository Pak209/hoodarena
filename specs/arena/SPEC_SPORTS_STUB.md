# SCRATCHED — Sports Fantasy / Parlay stub

**Status:** SCRATCHED by Pak 2026-09-07 — do not build.  
**Reason:** Real-game / oracle / Polymarket-mirror path too heavy; pivoting to NFT player-card packs (Big Win–style) under Arena.

---

# HOOD ARENA — Sports Fantasy / Parlay (STUB only)

**Status:** STUB — **not** v1 build; no contracts  
**Date:** 2026-09-07 (PT)  
**Parent:** Hood Arena site shell only when resurrected

## Intent
Real-world sports fantasy and/or multi-leg sports parlays (football first), USDG stake, arcade UI — “Fantasy Football + DeFi” on Robinhood Chain.

## Why stubbed
Pak requires **on-chain-verifiable** resolve (trusted-keeper REJECTED). Sports outcomes need a pinned oracle (e.g. Chainlink Sports / UMA / similar) that is:
- Live or clearly available on RH `4663`
- Legible on-chain without admin fiat
- Mapped to concrete markets (gameId → home/away/spread/total)

Until that pin exists, do **not** ship sports resolve.

## Placeholder product shape (when unlocked)
| Piece | Sketch |
|-------|--------|
| Modes | **Slate Fantasy** (draft N players / props) and/or **Sports Parlay** (2–5 legs ML/spread/total) |
| Stake | USDG |
| Resolve | Oracle-attested finalization only — no keeper “Chiefs won” |
| UX | `/fantasy`, `/sports-parlay` under same Hood Arena chrome |
| Risk | Geo/compliance, oracle downtime, voided games → cancel+refund rules |

## Explicit non-goals until unlock
- No admin override resolve  
- No stock-token “fantasy roster” as a substitute for sports (RHJ still off-limits as outcomes)  
- No build, deploy, or Reviewer cycle on this stub  

## Wake condition
Pak names an oracle + market source and says to promote this stub to a full Spec.
