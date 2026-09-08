# Hood Arena — Cards Desk vault (Mode C)

**Controller:** Kakashi  
**Channel:** Arena Chat  
**Spec (source of truth):** `/workspace/rh-build/specs/arena/SPEC_CARDS.md`  
**Parent product:** `/workspace/rh-build/hood-arena/` + `/workspace/rh-build/specs/arena/SPEC.md`

## v1 locks (Pak 2026-09-07)
- Packs + player card NFTs **on-chain** (USDG purchase on mainnet Spec; testnet may smoke with WETH/NFLX)
- Matches **cosmetic / soft-rank only** — no USDG escrow on match results
- Arena + Graduation Race stay PONS prediction modes
- PONS Parlay / sports oracles **SCRATCHED**
- No licensed NFL/FIFA IP by default — original / RH-culture roster
- ERC-721 unique cards first
- Mainnet deploy still unlock-gated; dry/testnet OK under existing testnet unlock for contracts that aren't mainnet broadcast
- Never custody keys; never enable live mainnet without Pak unlock phrase

## Agents
| Agent | Owns | Never |
|-------|------|-------|
| Mint | `PlayerCard.sol` + `CardPack.sol` + forge tests | UI, art, match sim, mainnet broadcast |
| Deck | `/packs` `/cards` `/squad` `/match` web routes in hood-arena/web | Contracts, RNG weights invention |
| Kit | Card/pack art (Grok GenerateImage + SVG frames) → `web/public/art` / `icons` | Solidity, deploy |
| Pitch | Cosmetic match loop / feel (client-side sim) | On-chain wager resolve, oracle |
| Kakashi | Routing, Reviewer gate, deploy unlock, channel | Doing all jobs alone |

## Handoff order
Kit roster frames → Mint contracts (schema matches art metadata) → Deck wires ABI + pages → Pitch plugs cosmetic match into Deck. Kakashi coordinates. Reviewer (existing) on contracts before any testnet pack broadcast beyond dry.

## Work roots
- Specs: `/workspace/rh-build/specs/arena/`
- App: `/workspace/rh-build/hood-arena/`
- This vault: `/workspace/rh-build/hood-arena/cards-desk/`

## Live IDs (2026-09-07)
- Channel Arena Chat: `7042def2-b906-471e-b0c9-98118ba5102a`
- Mint: `ce606645-d951-43b6-9c40-7cfe0855dbf3`
- Deck: `078f6b0a-6567-402d-9248-c73f66edef61`
- Kit: `31bca7d2-215c-429b-95e0-3d3afc51fa9e`
- Pitch: `0bd02198-6bd9-4f01-ac0a-be5e314d0f8c`
- Reviewer (security gate): `1f330d2c-dbd1-4fa3-8053-4a54f4bfaa87`
- Controller Kakashi: `09f4db79-aa58-458a-ada1-cca865cc7190`

## Roster note (2026-09-07 evening)
Arena Chat temporarily seats **Playbook** (`db030d7d`) instead of Reviewer for Big Win Football research sprint. Reviewer returns before CardPack testnet broadcast.

## AF Spec package LOCKED (Pak 2026-09-07 evening)
See SPEC_CARDS.md §12b. Short form:
- AF primary (not dual skins)
- Compressed / 5-hero roster
- uint8[5] = SPD/ARM/HND/TCK/POW
- Impacts off-chain ≤3 + Run/Pass focus
- Tick/drive log + Skip; soft-rank local first
- Starter pack playable; Kit AF reissue
- No attrition / chemistry
- Parallel mock AF; Mint enum before pack testnet; Reviewer before broadcast

## Roster note (2026-09-07 late)
Arena Chat reseated **Reviewer** (Playbook out) for CardPack security gate.
Pak locked **pixel** (not voxel) gameplay anims for each AF player; Kit owns sheets under `web/public/art/sprites/{slug}/`; Pitch wires MatchPlay.

## Backlog locks (Pak 2026-09-07 late)
- **Rarity per position:** every AF position (QB…K) can roll Common→Legend; publish weights; chase Legends per slot so rips feel juicy (beyond global rarity-only).
- **Marketplace:** AFTER table-done (Reviewer clear → pack testnet → rip/inventory/equip/anim playable). Spec already said “tradeable on any RH marketplace later” — own `/market` or external RH marketplace TBD.
