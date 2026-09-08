# Big Win Football → Hood Arena Mode C (American football variant)

**Research date:** 2026-09-07 (PT)  
**Audience:** Kakashi + Cards Desk (Mint / Deck / Pitch / Kit)  
**Output path:** `/workspace/rh-build/hood-arena/cards-desk/BIG_WIN_FOOTBALL_RESEARCH.md`  
**Spec source of truth:** `/workspace/rh-build/specs/arena/SPEC_CARDS.md` + vault locks in `VAULT.md`  
**Hard constraints honored:** original / RH-culture roster only (no NFL/FIFA IP, no real athlete likenesses); packs+cards on-chain; matches cosmetic / soft-rank only (no USDG match escrow); **no new Spec locks invented** — open items go to Kakashi.

---

## TLDR

1. **What it is:** *Big Win Football* is a Hothead Games → Fresh Build Games mobile title (sibling of *Big Win Soccer*), **not** NaturalMotion. Fake/customizable players; GM/card-collector loop, not Madden on-field control.
2. **Core loop:** starter pack → buy packs (coins / premium “Big Bucks”) → slot players + permanent skill boosts + consumable **Big Impact** cards → set lineup → **watch or skip** a simmed gridiron match → earn coins/fans → Daily Big Bowl / tournaments → rinse.
3. **Match UX:** Pre-match choose up to **3 Big Impact** cards (before seeing opponent loadout). Match is largely **passive** (~**10–12 min** watch, or skip-to-end / skip-to-Q4). Later builds add soft “offensive/defensive focus”; players still beg for real play-calling. Feel = cartoon drive log + TD/FG scoring, not FIFA minutes.
4. **Cards:** Full American football starter (~22–23): QB, RB, FB, WR×2, TE, OL×5, DL×4, LB×3, DB×4 (incl. FS), K. Rarity Bronze→Platinum (+ All-Star / Superstar / Legend in modern builds). Position-tied attrs (e.g. **Arm / Run / Hands / Leg / Vision**); up to **4 locked-in skill boosts** per player. Contracts + injuries as attrition sinks. **No strong FIFA-style chemistry** documented — boost-to-position fit is the real “synergy.”
5. **Copy carefully:** Keep pack→squad→cosmetic watch-match dopamine. **Avoid** dual-currency P2W walls, energy choke, contract/injury coin sinks, opaque mismatch slaughter, irreversible regret-boosts, ads/offerwalls as progression.
6. **vs current Mode C:** Hood Arena is **soccer-flavored** today — positions `GK|DEF|MID|FWD`, ratings `PAC/SHO/PAS/DEF/PHY`, 5-slot squad, soccer tick sim (`matchSim.ts`). AF variant needs either **expanded positions** or a **compressed unit model** (e.g. skill positions + line units) — **Kakashi must choose** before Mint schema churn.
7. **Build asks:** Deck (AF squad UI + pre-match Impact picker); Pitch (quarters / yards / TD-FG event log, not soccer minutes); Kit (helmet/pads art + AF position glyphs); Mint (position enum + optional Impact item type — **schema delta TBD**).
8. **v1 fit:** Spec already locked packs/cards on-chain + cosmetic matches — Big Win’s watch-or-skip sim maps cleanly. Do **not** port energy, contracts, or USDG-on-match.

---

## 0. Product identity (correct the NaturalMotion guess)

| Claim | Finding |
|-------|---------|
| Developer | **Hothead Games** originally; current store seller **Fresh Build Games Inc.** (Vancouver). Marks still cite Hothead / Big Win Sports. |
| NaturalMotion? | **No.** Unrelated. Common confusion with other sports/mobile brands. |
| Sibling titles | *Big Win Soccer*, *Big Win Baseball*, *Big Win Hockey*, etc. — same pack → boost → Big Impact → watch-match DNA. |
| Player IP | **Fake players** + cosmetic customization (name, number, nationality, hair, skin). Community often *renames* after real athletes; game does not ship licensed NFL likenesses as the core catalog. |
| Store | [App Store — Big Win Football 2026](https://apps.apple.com/us/app/big-win-football-2026/id937922348) · [Google Play — Big Win Football: Manager](https://play.google.com/store/apps/details?id=com.hotheadgames.google.free.bigwinfootball2&hl=en_US) |

**Hood Arena implication:** Spec’s “original / RH-culture roster” is *aligned* with Big Win’s fake-player DNA — lean into Hood names/kits, never NFL clubs or athlete likenesses.

---

## 1. Core loop: packs → cards → squad → match → progression

```text
Starter pack (full-ish roster + a few Big Impacts)
        ↓
My Team: swap starters, apply Skill Boosts, manage contracts/injuries
        ↓
Store: Bronze/Silver (coins) · Gold/Premium/Player packs (Big Bucks)
        ↓
Pre-match: pick ≤3 Big Impact cards (blind to opponent Impacts)
        ↓
Match: auto-sim driven by OVR + boosts + Impacts + RNG
        ↓
Rewards: coins, fans (XP), sometimes Big Bucks from bowl placement
        ↓
Modes: Quick Play · Daily Big Bowl (~9 peers, ≤12 games/day) · Friends Bowl · Tournaments
```

### Loop beats (concrete)

| Beat | What players do | What systems do |
|------|-----------------|-----------------|
| **Onboard** | Open starter pack (~23 players: both sides of ball + K) | Enough to field offense + defense immediately |
| **Collect** | Buy packs with soft (coins) / hard (Big Bucks) currency | Mix of players, skill boosts, contracts, Big Impacts |
| **Build** | Swap higher OVR into slots; apply ≤4 boosts per player (permanent) | Team OVR rises → match win odds rise |
| **Prime** | Choose 3 Big Impacts for the next game | Temporary match modifiers (INT rate, catch rate, shed blocks, deep ball, etc.) |
| **Play** | Watch or skip; no (or minimal) mid-drive control in classic design | Drive outcomes from stats × Impacts × luck |
| **Progress** | Fans / level bar; Daily Big Bowl standings | Soft-rank ladders + premium drip from top placements |
| **Attrition** | Renew contracts; heal injuries (coins) | Forces pack churn / spend if you want peak OVR every day |

**Sources:** [Gamezebo walkthrough](https://www.gamezebo.com/walkthroughs/big-win-football-walkthrough/), [Gamezebo review](https://www.gamezebo.com/reviews/big-win-football-review/), [WriterParty beginner guide](https://writerparty.com/party/how-to-play-big-win-football-for-ios-walkthrough-faq-and-beginners-guide/), [LevelWinner 2015 tips](https://www.levelwinner.com/big-win-football-2015-cheats-6-tips-hints-to-help-you-coach-that-winning-team/), store listings above.

---

## 2. Match UX: phases, play-calling, timers, event log, scoring feel, length

### 2.1 What the match actually is

- **Manager-lite / watch-sim**, not a skill-stick football game.
- Outcome determined **before/as** the sim runs from roster stats + chosen Big Impacts + RNG. Watching does **not** change the result (classic design).
- UX affordances:
  - **Watch full game** (~**10–12 minutes** cited for a complete watch).
  - **Skip to end** anytime (volume / tilt escape).
  - Community tip: skip to **4th quarter** if you want some drama without the full watch.
- Presentation: playful cartoon gridiron — fans with “D-fence” signs, goalpost-cam on kicks, highlight-ish drive moments. Soft scoreboard football scoring (TDs, FGs, etc.), not soccer 0–0 ticks.

### 2.2 Play-calling / agency (version-dependent — report carefully)

| Era / source | Agency |
|--------------|--------|
| Classic (Gamezebo / 148Apps) | **None mid-match.** Agency = roster build + pre-match Big Impact picks. |
| 2015 tip guides | Advise “call plays” biased to Run vs Hands strengths — implies **some** play-selection or focus UI in that build. |
| Modern store reviews (2024–2026) | Players mention **offensive/defensive focus** dials (often buggy); repeatedly **request** real play-calling, playbooks, critical-situation calls. Community consensus: still too passive. |
| Marketing copy | “Lead them with Big Impact cards” / “Flick, Tap, and Score” — marketing louder than actual control depth. |

**Adaptation takeaway for Pitch:** For Hood Arena v1 cosmetic matches, **pre-match dials + Impact-like consumables + watchable event log** is enough and Spec-aligned. Mid-drive play-calling is a **product question**, not a researched Spec lock.

### 2.3 Phases / timers (as experienced)

- Match structured like a football game (quarters; clock often criticized as “too fast” in modern reviews).
- Pre-match: Impact selection (≤3).
- In-match: auto drives / plays; player is spectator + skip controls.
- Post-match: coins/fans; injuries/contracts update; return to My Team / next bowl game.
- **Energy** gate: consecutive games drain energy; notifications when refilled (session throttle — **do not copy** into USDG cosmetic Mode C without Kakashi OK).

### 2.4 Event log / scoring feel

- Feel target: **drive narrative** — big catch, sack, pick, FG wobble, late TD — not continuous possession meters.
- Big Impacts surface narratively (“Iron Curtain” sheds blocks; “The Cannon” deep-pass accuracy in late game).
- Frustration pattern in reviews: **OVR gaps ignored by RNG** (98 OVR loses to 39; legends feel as slow as bronze). Soft-rank honesty matters for Hood Arena’s cosmetic promise.

### 2.5 Length targets (adaptation)

| Mode | Big Win reference | Hood Arena suggestion (Pitch — not Spec-locked) |
|------|-------------------|--------------------------------------------------|
| Full watch | ~10–12 min | Too long for arcade cabinet; target **45–90s** animated or **6–12 event ticks** (current soccer sim already ~6–10 ticks) |
| Skip / results | Instant | Keep **Skip to final** |
| Highlight | Skip to Q4 | Optional “2-minute drill” shortened half |

---

## 3. Card schema: positions, ratings, rarity, chemistry

### 3.1 Starter roster shape (documented)

From WriterParty + Gamezebo (~22–23 cards to field both sides + specialist):

| Side | Positions (counts) |
|------|--------------------|
| Offense | QB, RB, FB, WR×2, TE, OL×5 |
| Defense | DL×4, LB×3, DB×4 (guides cite free safety among DBs) |
| Special | K (kicker/punter combined in early writeups) |

**Total:** ~22–23 starters — much larger than Mode C’s current **5-slot** `GK/DEF/MID/FWD/FLEX` soccer lineup.

### 3.2 Rarity / tiers

| Tier family | Notes |
|-------------|-------|
| Bronze → Silver → Gold → Platinum | Classic pack ladder; Platinum = top early-game chase |
| All-Star / Superstar / Legend | Modern store marketing tiers layered on top |
| Pack contents | Players + skill boosts + contracts + Big Impacts mixed in |

Hood Arena Spec already drafts **Common / Rare / Epic / Legend** — close enough to map Platinum≈Legend chase without inventing new Spec rarity names.

### 3.3 Rating stats (position-tied)

Documented attribute examples (not a full official schema dump):

| Attribute | Example roles |
|-----------|----------------|
| **Arm** | QB (can dump all boosts into Arm — “Jay Cutler plan” joke in Gamezebo) |
| **Run** | RB / backfield; call more run if high |
| **Hands** | RB/WR catch/handles; call more pass if high |
| **Leg** | Kicker |
| **Vision** | Kicker (and likely skill-position awareness) |
| Strength / agility | Mentioned in 2015 boost tips as passive skills |

Each player has a visible **overall** number. Skill boosts raise **one of the position’s attributes**; **up to four boosts** per player; **locked once applied** (no respec) — high regret UX.

### 3.4 Big Impact cards (match consumables)

- Pick **up to 3** before kickoff.
- Blind to opponent’s picks → strategic guesswork.
- Examples named in press/tips: **Iron Curtain** (D shed blocks), **The Cannon** (deep pass accuracy).
- Consumed per use / per game (save for tough bowls).
- Playing with **zero** Impacts is a known disadvantage.

### 3.5 Chemistry

**Finding:** Sources do **not** describe a FIFA Ultimate Team–style chemistry graph (nation/club links). What exists instead:

- **Positional fitness** of skill boosts (“don’t put Hands on a DL”).
- **Line balance** tips (boost OL so QB has time).
- Later complaints about **locked position swapping** after updates (roster rigidity ≠ chemistry).

**Adaptation:** If Hood wants “chemistry,” it would be a **new design**, not a Big Win port. Flag for Kakashi — do not assume Spec chemistry.

### 3.6 Attrition systems (schema-adjacent)

| System | Behavior | Port? |
|--------|----------|-------|
| **Contracts** | Games until decay; half ability when expired; historically ~5 renewals then retire | **Avoid for v1** (extra economy + UX debt; not Spec-locked) |
| **Injuries** | More common after losses; half ability; ~100 coins to heal | **Avoid for v1** |
| **Duplicates** | Pack filler → replace or sit | Spec already has duplicate policy draft (721 vs burn-shards) |

---

## 4. Monetization / UX patterns — steal vs avoid

### Steal (feel / structure)

- Instant fieldable starter pack → first match in minutes.
- Pack burst + rarity chase as the **economy spine** (maps to on-chain USDG packs).
- Pre-match **loadout choices** (Impacts / focus) so watching isn’t pure wallpaper.
- Watch **or** skip — respect time.
- Soft daily ladder (Big Bowl analogue) as **cosmetic / soft-rank** only under Spec v1.
- Fake-player customization culture → Hood nicknames / kits.

### Avoid copying blindly

| Pattern | Why it hurts | Hood Arena stance |
|---------|--------------|-------------------|
| Dual soft/hard currency with **gold packs hard-gated** | Classic P2W wall; reviews hammer it | Packs = USDG only (Spec); no second “Big Bucks” paywall for better RNG |
| **Energy** for matches | Artificial session choke | Cosmetic matches should not need energy; soft-rank can rate-limit without fake stamina |
| Contract expiry / injury **coin sinks** | Churn disguised as realism | Out of scope unless Kakashi explicitly wants attrition |
| Irreversible 4-boost lock with no respec | Whale regret + support burden | Prefer immutable NFT ratings at mint; upgrades only if Spec’d later |
| Opaque mismatch (lvl 50 vs lvl 3) | Feels rigged → spend prompts | Soft-rank by squad OVR bands |
| Ads / Tapjoy offerwalls | Trust nuke on RH/DeFi audience | Never |
| Mid-match spend prompts after a loss | Predatory | Cosmetic match cannot upsell USDG escrow (locked off) |
| Loot boxes without published odds | Compliance + Spec §10 | Spec already requires published weights |

---

## 5. Adaptation map vs current Hood Arena Mode C

### 5.1 Current Mode C (as built / drafted)

| Layer | Today |
|-------|-------|
| Positions | `GK \| DEF \| MID \| FWD` (+ UI `FLEX` slot) |
| Sample roster | Neon Striker (FWD), Chain Sweeper (DEF), Vault Keeper (GK), RH Jammer (MID) |
| Ratings | `PAC / SHO / PAS / DEF / PHY` (FIFA-ish) |
| Squad size | **5** cards default (`mockSquadIds`) |
| Match | Client LCG sim, soccer **goals**, minute-flavored event log (`web/src/lib/matchSim.ts`) |
| Economy | USDG packs on-chain (Mint); matches **cosmetic / soft-rank only** |
| Art | Soccer/neon player cards + foil pack frames (Kit sprint 1) |

### 5.2 Big Win Football → Mode C mapping

| Big Win concept | Soccer Mode C now | AF variant options (open) |
|-----------------|-------------------|---------------------------|
| 22–23 starters | 5-slot mini squad | **A)** Expand slots/positions · **B)** Compress to units (QB+skill+OL-unit+DL-unit+DB-unit+K) · **C)** Keep 5 “heroes” as skill-position stars, lines as derived OVR |
| Arm/Run/Hands/Leg/Vision | PAC/SHO/PAS/DEF/PHY | Remap labels (e.g. SPD/ARM/HND/TCK/POW) **or** keep 5-vector with AF weights |
| Big Impact ×3 | Not implemented | Cosmetic pre-match modifiers (off-chain OK under Spec) |
| Daily Big Bowl | Soft-rank TBD | Optional soft daily ladder — no USDG escrow |
| Contracts/injuries | None | Leave out unless Spec’d |
| Watch 10–12 min | ~6–10 ticks | Keep short arcade length; AF **copy** (yards, downs, TD/FG) |
| Chemistry | None | Don’t invent without Kakashi |

### 5.3 Recommended direction (research opinion — **not a Spec lock**)

For v1 ship speed under existing Spec:

1. **Keep** pack → card NFT → squad → cosmetic match spine.
2. **Reskin** match language to American football (Pitch).
3. **Either** expand Mint `position` enum to AF set **or** adopt a **compressed unit model** so Deck UI does not need 22 drag slots on day one.
4. Treat **Big Impacts** as off-chain cosmetic modifiers first (no new escrow).
5. Replace soccer sample names with RH-culture AF archetypes (Kit) — e.g. neon QB / chain LB / vault K — still original IP.

---

## 6. Build asks by desk

### Deck (routes / UI) — `hood-arena/web`

- `/packs` `/cards` `/squad` `/match` already stubbed — extend copy + layout for AF.
- Squad: position slots matching Kakashi’s chosen model (full, compressed, or hybrid).
- Pre-match panel: **≤3 Impact** picker + optional Run/Pass or Off/Def focus dials.
- Soft-rank results card (W/L, score, OVR delta) — no payout UI.
- Inventory filters by AF position + rarity.
- **Never** invent RNG pack weights in UI — read Mint published weights.

### Pitch (client sim)

- Replace soccer strength buckets with AF drive model:
  - Quarters or shortened halves; event types: run stuff, deep ball, sack, INT, FG, TD, turnover on downs.
  - Score: points (6/3/2/1…) not goals.
- Keep deterministic seed honesty (`matchSeed` style) for soft-rank reproducibility.
- Target **≤90s** watch or tick-based log with Skip.
- Wire Impact modifiers as temporary weight bumps (documented coefficients in code comments).
- **Do not** add USDG escrow / oracle resolve.

### Kit (art / positions)

- New AF player frames still Common→Legend.
- Position glyphs: QB / RB / WR / TE / OL / DL / LB / CB / S / K (or compressed set).
- RH-culture characters only — helmets, pads, neon hood energy; **no** NFL club marks, no real athlete faces.
- Impact card art set (3–8 named powers) separate from player cards.
- Pack art can stay foil; optional football silhouette variant.

### Mint (schema deltas — **propose, don’t lock**)

Current Spec draft:

```text
position: GK | DEF | MID | FWD
ratings: uint8[5]  // PAC SHO PAS DEF PHY
rarity: uint8
```

AF needs Kakashi decision on:

| Delta | Options |
|-------|---------|
| `position` enum | Expand to AF list **or** keep 4 buckets with AF labels **or** add `unit` + `role` fields |
| `ratings[5]` labels | Remap semantics without changing array width (least chain churn) vs new widths |
| Impact items | Off-chain only vs ERC-1155 consumables (heavier; probably **not** v1) |
| Squad size metadata | Not necessarily on-chain — lineup can stay client-side for cosmetic matches |

**Do not deploy schema changes without Kakashi + Reviewer path.**

---

## 7. Spec questions for Kakashi

*Do not treat answers below as defaults unless Spec is updated.*

1. **Sport flavor for Mode C v1:** Stay soccer-neon (current stubs) · switch primary fantasy to **American football** · or support **both skins** on one card schema?
2. **Roster model:** Full ~11-on-field slots per side · compressed **unit** cards · or **5-hero** skill-position model with abstracted lines?
3. **Rating vector:** Keep `uint8[5]` and only relabel (SPD/ARM/HND/TCK/POW) · or Spec a new AF attribute set?
4. **Big Impact layer:** Cosmetic off-chain modifiers only · mintable consumables · or defer entirely?
5. **Pre-match agency:** Impacts only · Impacts + Run/Pass focus · or light play-calling on key downs (Pitch scope creep)?
6. **Match length UX:** Tick log (~current) · 60–90s watch · optional “full half” later?
7. **Soft-rank surface:** Local history only · daily bowl leaderboard · friends challenge codes (Big Win Friends Bowl analogue)?
8. **Starter pack composition:** How many AF positions guaranteed on first open so `/match` is playable immediately?
9. **Sample roster rename:** Keep Neon Striker / Chain Sweeper / Vault Keeper / RH Jammer as soccer · or Kit reissue AF archetypes under new token art URIs (metadata migrate plan)?
10. **Attrition systems:** Confirm **out** for v1 (contracts/injuries/energy) — or any wanted as soft UX without on-chain state?
11. **Chemistry:** Explicitly **none** for v1, or design a Hood-native link bonus (not Big Win-faithful)?
12. **Schema freeze timing:** Can Deck/Pitch proceed on mock AF types before Mint enum change, or wait for `PlayerCard.sol` position enum update first?

---

## 8. Sources

| Source | URL | Used for |
|--------|-----|----------|
| Gamezebo Walkthrough | https://www.gamezebo.com/walkthroughs/big-win-football-walkthrough/ | Loop, packs, energy, contracts, Impacts, bowls |
| Gamezebo Review | https://www.gamezebo.com/reviews/big-win-football-review/ | Starter 23, fake players, boosts, 10–12 min watch, P2W notes |
| 148Apps Review | https://www.148apps.com/big-win-football/big-win-football-review/ | Passive match critique, GM framing |
| WriterParty Beginner Guide | https://writerparty.com/party/how-to-play-big-win-football-for-ios-walkthrough-faq-and-beginners-guide/ | Full position list / counts |
| LevelWinner 2015 Tips | https://www.levelwinner.com/big-win-football-2015-cheats-6-tips-hints-to-help-you-coach-that-winning-team/ | Play bias Run/Hands, Impacts×3, injuries |
| SuperCheats FAQ thread | https://www.supercheats.com/android/big-win-football/index.htm | Big Bowl 12 games, skip-to-Q4, contract renew debate |
| App Store | https://apps.apple.com/us/app/big-win-football-2026/id937922348 | Current publisher, modes, IAP, loot-box age label |
| Google Play | https://play.google.com/store/apps/details?id=com.hotheadgames.google.free.bigwinfootball2&hl=en_US | Fresh Build ownership, focus-dial / matchmaking complaints |
| iofreeonline / App mirror writeups | https://www.iofreeonline.com/IOS/game/Big-Win-Football-2026.html | Modern tips, Iron Curtain / The Cannon, community play-calling asks |
| Big Win Soccer Play listing | https://play.google.com/store/apps/details?id=com.hotheadgames.google.free.bigwinsoccer&hl=en | Sibling series confirmation |
| Hood Spec Cards | `/workspace/rh-build/specs/arena/SPEC_CARDS.md` | v1 locks / schema draft |
| Cards Desk vault | `/workspace/rh-build/hood-arena/cards-desk/VAULT.md` | Agent ownership |
| Mode C mocks / sim | `hood-arena/web/src/data/mock.ts`, `lib/matchSim.ts` | Current soccer Mode C baseline |

---

## 9. One-page adaptation brief (for channel paste)

**Big Win Football** = Hothead/Fresh Build card-GM football: pack chase → boost roster → pick 3 Impacts → watch/skip a soft sim. Fake players. Passive mid-drive control. Heavy freemium attrition.

**Hood Arena Mode C** already has the right economy split (on-chain packs/cards, cosmetic matches). Current build is **soccer-neon mini-squad**. AF variant is mostly **schema + sim language + art**, not a new product.

**Ship path if Kakashi picks compressed AF:** Mint keeps `uint8[5]` + new position enum subset → Kit AF archetypes → Deck Impact picker + AF squad → Pitch TD/FG tick sim. **No** energy/contracts/NFL IP/USDG match escrow.

**Blocked on:** Kakashi answers in §7 (especially sport flavor + roster model + schema freeze).
