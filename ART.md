# Hood Arena — art inventory

**Workflow:** Grok `GenerateImage` for raster pieces → `web/public/art/`. SVG pixel icons → `web/public/icons/` (plus optional React SVG sprites in `web/src/components/Icons.tsx` where needed).

## `web/public/art/` (raster)

| File | Purpose |
|------|--------|
| `logo-mark.png` | Header / share-card logo mark |
| `tug-hero.png` | Stake page tug-of-war hero illustration |
| `hood-alpha.png` | Hood avatar (header / ALPHA lane) |
| `hood-beta.png` | Hood avatar (BETA) |
| `hood-gamma.png` | Hood avatar (GAMMA) |
| `icon-grad-cap.png` | Resolved winner graduation cap |
| `icon-broken-heart.png` | Resolved **NO** / loser card |
| `icon-share-win.png` | Share-your-win card art |
| `icon-q-lime.png` | Home arena question mark (lime ring) |
| `icon-q-pink.png` | Home arena question mark (pink ring) |
| `icon-q-teal.png` | Home arena question mark (teal ring) |

## Mode C Cards — AF lock (2026-09-07 Kit)

Soccer samples retired to `web/public/art/retired-soccer/` (no longer Mode C live art).

| File | Purpose | Slug / pos |
|------|--------|-------------|
| `player-neon-arm.png` | QB — Neon Arm | `neon-arm` |
| `player-chain-slash.png` | SKILL — Chain Slash | `chain-slash` |
| `player-vault-wall.png` | LINE_O — Vault Wall | `vault-wall` |
| `player-rh-rush.png` | LINE_D — RH Rush | `rh-rush` |
| `player-street-pick.png` | DB — Street Pick | `street-pick` |
| `impact-neon-blitz.png` | Off-chain Impact PASS RUSH+ | |
| `impact-chain-grab.png` | Off-chain Impact HANDS+ | |
| `impact-vault-lock.png` | Off-chain Impact LINE HOLD+ | |
| `impact-street-pick.png` | Off-chain Impact INT+ | |
| `impact-rh-cannon.png` | Off-chain Impact DEEP BALL+ | |

Icons: `pos-{qb,skill,line-o,line-d,db,k}.svg`, `focus-run.svg`, `focus-pass.svg`.
Pack rasters + rarity frames unchanged.

## Mode C Cards (2026-09-07 Kit sprint 1) — soccer, retired

| File | Purpose |
|------|--------|
| `pack-closed.png` | Sealed Mode C foil pack |
| `pack-open.png` | Pack burst / open state |
| `frame-common.png` | Common rarity empty frame |
| `frame-rare.png` | Rare rarity empty frame |
| `frame-epic.png` | Epic rarity empty frame |
| `frame-legend.png` | Legend rarity empty frame |
| `player-neon-striker.png` | Sample FWD — Neon Striker |
| `player-chain-sweeper.png` | Sample DEF — Chain Sweeper |
| `player-vault-keeper.png` | Sample GK — Vault Keeper |
| `player-rh-jammer.png` | Sample MID — RH Jammer |

Mode C icons: `pack.svg`, `rarity-{common,rare,epic,legend}.svg` in `web/public/icons/`.

## `web/public/icons/` (SVG)

| File | Purpose |
|------|--------|
| `hood-mark.svg` | Compact hood mark |
| `swords.svg` | YES / rematch / VS chrome |
| `shield.svg` | No / safety / timeline |
| `coin.svg` | USDG / pot / payout |
| `clock.svg` | Timer |
| `flag.svg` | Arena opened / next arena |
| `lock.svg` | Stakes locked |
| `trophy.svg` | Winner accents |
| `wallet.svg` | Connect wallet |
| `players.svg` | Bettor count |

## React sprites (`Icons.tsx`)

Inline SVG helpers still used where convenient (`CoinG`, `SocialIcon`, `PixelAlien`, etc.). Prefer public SVG/PNG assets for page-visible art so the Grok + SVG workflow stays file-based.
