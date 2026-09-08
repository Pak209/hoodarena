Kit AF pixel sprite sheets — Mode C MatchPlay
==============================================
Drop horizontal 4×1 PNG strips here as:

  {slug}.png

Slugs: neon-arm, chain-slash, vault-wall, rh-rush, street-pick

Sheet layout:
  - Each frame: 96×96 px
  - Full sheet: 384×96 px (4 frames wide × 1 tall)
  - Columns L→R index 0..3: idle | run | action | celebrate

CSS math (MatchPlay / SpriteActor):
  background-image: url(/art/sprites/{slug}.png)
  background-size: 384px 96px
  background-position: -N*96px 0   (N = frame index)

Until PNGs land, MatchPlay falls back to card static portrait art.

Note: Kit may stage per-frame sources under {slug}/{idle,run,action,celebrate}.png.
Runtime MatchPlay only loads the flat strip path: {slug}.png (384×96).
