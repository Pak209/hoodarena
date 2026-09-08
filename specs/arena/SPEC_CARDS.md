# HOOD ARENA — Mode C: Big Win–style Player Cards + Packs (Spec draft)

**Status:** LOCKED for v1 — Pak 2026-09-07 packs/cards on-chain + cosmetic matches; **AF flavor package LOCKED Pak 2026-09-07 evening**  
**Inspiration:** iOS *Big Win Football* — players as cards, pack pulls, then play with your roster  
**Primary fantasy:** **American football** (soccer-neon stubs replaced; not dual skins in v1)  
**Parent:** Hood Arena (`SPEC.md`) — same arcade+DeFi shell, USDG economy  
**Chain:** Robinhood EVM `4663` (mainnet Spec); testnet for dry  
**Live:** locked

## 1. One-liner
Pull **player card NFTs** from USDG packs, build a squad, and play short matches / challenges inside Hood Arena — cards are the inventory; Arena/Race stay the prediction modes.

## 2. Product shape (v1)
| Layer | What |
|-------|------|
| **Packs** | Buy with USDG (or testnet WETH/NFLX for smoke). Open on-chain → mint 3–5 cards (ERC-721 or ERC-1155). |
| **Cards** | Player NFTs: rarity, position, ratings (pace/shoot/defend/…), art. Tradeable on any RH marketplace later. |
| **Squad** | Off-chain or on-chain lineup of N cards for a match. |
| **Play** | Short PvE or PvP match using card stats (sim). |
| **Hook to Arena** | Optional: burn/lock a card or pack ticket to enter a featured Arena/Race; or win packs from Arena claim streaks / share cards. |

## 3. Why this fits RH + Arena better than sports parlays
- **No sports oracle** — pack RNG + card ownership are on-chain; match sim can be constrained (see resolve).
- Uses **USDG sink** (packs) next to Arena stake (predictions).
- Arcade fantasy (cards, packs, neon) matches Hood Arena art direction.
- Keeps stock-token / RHJ / crash / slots **off limits** as outcomes.

## 4. On-chain vs off-chain split (important)
### Must be on-chain
- Pack purchase (USDG transfer)
- Pack open → VRF/commit-reveal card mint
- Card ownership, transfer, marketplace list
- Optional: lock card as Arena entry bond

### Can start off-chain (with honesty)
- Match animation / Big Win–like gameplay UX
- Soft rankings / seasons leaderboard

### Resolve for *staked* matches (if USDG is on the line)
Cannot use trusted-keeper theater. Options for v1:
1. **Cosmetic play only** — matches don’t escrow USDG; packs/cards are the economy (simplest, ship first).
2. **Commit-reveal PvP** — both clients commit actions; on-chain referee verifies transcript hash (heavier).
3. **Deterministic sim from seed** — `matchSeed = keccak(block, lineup hashes)`; anyone re-runs sim; dispute if client lied (medium).

**v1 LOCK:** (1) packs + cards on-chain, matches cosmetic / soft-ranked only. Deterministic wager matches **deferred** (not v1).

## 5. Pack economics (draft locks — Pak can tune)
| Param | Draft |
|-------|--------|
| Pack price | e.g. 5–25 USDG (TBD) |
| Cards per pack | 3–5 |
| Rarity curve | Common / Rare / Epic / Legend — published weights |
| Duplicate policy | ERC-1155 stack **or** burn-dupe → shards |
| Fee | `feeBps=100` to treasury on pack sale (align Arena) |
| RNG | Chainlink VRF if on RH later; else commit-reveal from opener + block entropy with delay (document bias) |

## 6. Card schema (LOCKED AF)
```text
tokenId
name / kit art URI
position: compressed AF set — QB | SKILL | LINE_O | LINE_D | DB | K
  // 5-hero / compressed units (not full 22 drag slots in v1)
ratings: uint8[5]  // SPD ARM HND TCK POW  (same width; soccer PAC/SHO/PAS/DEF/PHY retired)
rarity: uint8      // Common | Rare | Epic | Legend
season: uint16
```
Art: Grok GenerateImage + SVG frames (same workflow as Arena art). Kit reissues RH-culture AF archetypes (no NFL IP).

## 7. UX routes
- `/cards` — inventory grid
- `/packs` — buy / open (pack burst animation)
- `/squad` — drag lineup
- `/match` — play (cosmetic v1)
- Home chip: **CARDS** next to Arena / Race

## 8. Integration with existing Arena modes
- **Pack drop from Arena** — optional: claiming a win rolls a small free common pack (rate-limited).
- **Card-gated Arena** — optional: must hold ≥1 Rare to stake above X USDG (anti-sybil light).
- **Do not** replace PONS resolve with card matches.

## 9. Out of scope v1
- Licensed real NFL/FIFA player IP (use original / parody / RH-culture characters unless licensed)
- Real-world sports result oracles (scratched)
- PONS Parlay / sportsbook parlays (scratched)
- Autobuy packs with bot custody
- Energy gates, contracts, injuries, dual soft/hard currency P2W, ads/offerwalls
- FIFA-style chemistry graphs
- Mid-drive play-calling / on-chain match escrow

## 10. Compliance note
Loot-box / pack RNG can be regulated by jurisdiction. Ship with published odds, no cash-out of random rewards as “prize,” and counsel review before mainnet pack sales.

## 11. Build order (after Pak approve)
1. Spec visual mocks (pack + card grid + squad)
2. `PlayerCard.sol` (721/1155) + `CardPack.sol` (USDG → open → mint)
3. Dry UI under `hood-arena/web`
4. Testnet mint smoke
5. Cosmetic match sim only (no wagering in v1)

## 12. Locked (Pak 2026-09-07)
| Item | Lock |
|------|------|
| Economy | Packs + cards on-chain; USDG pack purchase |
| Matches | **Cosmetic / soft-rank only** in v1 — no USDG wager on match outcome |
| Arena modes | Arena + Race unchanged (PONS); cards are companion collection layer |
| Arena win to free pack | **Not** in v1 lock (can add later) |
| Wager matches | Deferred |

## 12b. AF flavor package LOCKED (Pak 2026-09-07 evening)
| # | Item | Lock |
|---|------|------|
| 1 | Sport flavor | **American football primary** — soccer stubs replaced (not dual skins in v1) |
| 2 | Roster model | **Compressed / 5-hero** skill-position model (not full ~22 drag slots day one) |
| 3 | Rating vector | Keep `uint8[5]`; relabel **SPD / ARM / HND / TCK / POW** |
| 4 | Big Impacts | **Off-chain cosmetic only** — ≤3 pre-match modifiers (not mintable consumables in v1) |
| 5 | Pre-match agency | Impacts + Run/Pass focus — **no** mid-drive play-calling |
| 6 | Match length UX | Short tick / drive log (≤90s watch feel); always **Skip to final** |
| 7 | Soft-rank | **Local history first**; daily bowl / friends later |
| 8 | Starter pack | Guarantees enough AF positions to play `/match` immediately |
| 9 | Sample art | Kit **reissues** RH-culture AF archetypes (retire soccer sample names/URIs for Mode C) |
| 10 | Attrition | Contracts / injuries / energy **OUT** for v1 |
| 11 | Chemistry | **None** for v1 |
| 12 | Build order | Deck/Pitch mock AF **in parallel**; Mint updates position enum before any pack testnet broadcast; Reviewer before CardPack broadcast |

Research: `/workspace/rh-build/hood-arena/cards-desk/BIG_WIN_FOOTBALL_RESEARCH.md`



## 12c. Rarity per position LOCKED (Pak 2026-09-07 — finish Mode C)
Global curve still applies to **each** compressed slot independently so a Legend QB ≠ Common QB.

| Position | Common | Rare | Epic | Legend | Notes |
|----------|--------|------|------|--------|-------|
| QB | 5500 | 2700 | 1400 | 400 | Slightly juicier chase (face of franchise) |
| SKILL | 6000 | 2500 | 1200 | 300 | Baseline (= global) |
| LINE_O | 6200 | 2400 | 1100 | 300 | Slightly more commons |
| LINE_D | 6000 | 2500 | 1200 | 300 | Baseline |
| DB | 5800 | 2600 | 1300 | 300 | Mild chase |
| K | 6500 | 2300 | 1000 | 200 | Specialist; rarer Legend |

Weights are **bps out of 10_000 per position** (must sum 10_000). Published in UI odds sheet before mainnet; draft OK on testnet.

Rating floors (keep existing shape): `floor = 40 + rarity*12`, `span = 20 + rarity*4` (SPD/ARM/HND/TCK/POW). Position biases which stats get the high rolls (Mint).

Art: Kit delivers rarity chrome variants per slug (`player-{slug}-{common|rare|epic|legend}.png` or frame overlay already — prefer stronger frame + optional foil overlay). Starter pack still guarantees one of each QB…DB (positions distinct); rarity independent per card.

Marketplace: **after** A-table playable (separate Spec later).

## 13. Still open (defaults if silent)
| Item | Default until Pak overrides |
|------|------------------------------|
| Roster IP | Original / RH-culture characters — **not** licensed NFL/FIFA |
| Token standard | **ERC-721** unique cards first |
| Pack price | TBD (placeholder 10 USDG) |
| RNG | Commit-reveal + block delay on testnet; VRF if available on RH later |
| Exact compressed position enum labels | Draft QB/SKILL/LINE_O/LINE_D/DB/K — Mint may refine names without widening ratings array |
| Pack rarity weights | Must publish before mainnet; draft OK on testnet |
