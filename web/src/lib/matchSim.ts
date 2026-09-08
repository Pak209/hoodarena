/**
 * Client soft-rank AF match sim — cosmetic only.
 * Same seed + lineup + loadout ⇒ same result (honest LCG; not on-chain fairness).
 * Soft-rank only · no USDG escrow.
 */
import {
  cardOverall,
  type ImpactId,
  type PlayFocus,
  type PlayerCardItem,
} from '../data/mock'

export const MATCH_HONESTY = 'soft-rank only · no USDG escrow' as const

/**
 * Off-chain Impact / focus weight bumps (cosmetic soft-rank only).
 * Coefficients are honesty-documented; not on-chain fairness.
 */
export const IMPACT_WEIGHTS = {
  /** Run focus: +run conversion, +LINE_O / POW influence */
  focus_run: { runConversion: 0.12, lineOPow: 0.08 },
  /** Pass focus: +pass conversion, +QB ARM / SKILL HND influence */
  focus_pass: { passConversion: 0.12, qbArmSkillHnd: 0.08 },
  /** Blitz: +your def pressure / sack chance when them attacking */
  blitz: { defPressure: 0.15, sackChance: 0.1 },
  /** Deep Ball: +long TD chance on pass focus */
  deep_ball: { longTdChance: 0.14 },
  /** Power Run: +short TD / POW run chance on run focus */
  power_run: { shortTdChance: 0.14 },
  /** Hot Read: +quick completion / mid conversion */
  hot_read: { quickCompletion: 0.12, midConversion: 0.08 },
  /** Red Zone: +FG and short TD when in scoring-area ticks */
  redzone: { fgConversion: 0.15, shortTdConversion: 0.1 },
} as const

export type MatchSide = 'you' | 'them' | 'neutral'

/** AF event — tick = sequential drive/phase index; quarter 1–4 (0 = KO/HT/FINAL). */
export interface MatchEvent {
  tick: number
  quarter: number
  /** Display label e.g. "Q1", "HT", "FINAL" */
  clock: string
  side: MatchSide
  text: string
  /** Football points added this tick (TD=6, FG=3, XP=1); for live scoreboard */
  youPts?: number
  themPts?: number
}

export interface MatchResult {
  youScore: number
  themScore: number
  youOvr: number
  themOvr: number
  events: MatchEvent[]
  winner: 'you' | 'them' | 'draw'
  seed: number
  focus: PlayFocus
  impacts: ImpactId[]
}

export interface TeamStrength {
  attack: number
  mid: number
  def: number
  gk: number
  ovr: number
  /** AF-derived helpers for loadout bumps */
  arm: number
  hnd: number
  pow: number
  run: number
  pass: number
}

export interface SimulateMatchOpts {
  seed?: number
  focus?: PlayFocus
  impacts?: ImpactId[]
}

const TD_PTS = 6
const XP_PTS = 1
const FG_PTS = 3

/** Numerical LCG (Numerical Recipes) — deterministic soft PRNG. */
function makeLcg(seed: number) {
  let s = seed >>> 0
  if (s === 0) s = 0xdeadbeef
  return () => {
    s = (Math.imul(s, 1664525) + 1013904223) >>> 0
    return s / 0x100000000
  }
}

/**
 * AF strength bridge (SPD/ARM/HND/TCK/POW).
 *   QB/SKILL → attack · LINE_O → mid · LINE_D/DB → def · K → gk
 */
export function deriveStrength(lineup: PlayerCardItem[]): TeamStrength {
  const buckets = {
    attack: [] as number[],
    mid: [] as number[],
    def: [] as number[],
    gk: [] as number[],
    arm: [] as number[],
    hnd: [] as number[],
    pow: [] as number[],
  }

  for (const c of lineup) {
    const { spd, arm, hnd, tck, pow } = c.ratings
    buckets.arm.push(arm)
    buckets.hnd.push(hnd)
    buckets.pow.push(pow)
    switch (c.position) {
      case 'QB':
        buckets.attack.push(0.5 * arm + 0.25 * hnd + 0.15 * spd + 0.1 * pow)
        break
      case 'SKILL':
        buckets.attack.push(0.4 * spd + 0.35 * hnd + 0.15 * pow + 0.1 * arm)
        break
      case 'LINE_O':
        buckets.mid.push(0.5 * pow + 0.3 * tck + 0.2 * hnd)
        break
      case 'LINE_D':
        buckets.def.push(0.45 * tck + 0.4 * pow + 0.15 * spd)
        break
      case 'DB':
        buckets.def.push(0.45 * spd + 0.35 * tck + 0.2 * hnd)
        break
      case 'K':
        buckets.gk.push(0.55 * arm + 0.3 * pow + 0.15 * hnd)
        break
    }
  }

  const avg = (xs: number[], fallback: number) =>
    xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : fallback

  const mid = avg(buckets.mid, 70)
  const attack = avg(buckets.attack, 68) + mid * 0.3
  const def = avg(buckets.def, 70) + mid * 0.2
  const gk = avg(buckets.gk, 72)
  const arm = avg(buckets.arm, 70)
  const hnd = avg(buckets.hnd, 70)
  const pow = avg(buckets.pow, 70)
  const ovr =
    lineup.length > 0
      ? Math.round(lineup.reduce((a, c) => a + cardOverall(c), 0) / lineup.length)
      : 70

  return {
    attack,
    mid,
    def,
    gk,
    ovr,
    arm,
    hnd,
    pow,
    run: mid * 0.45 + pow * 0.35 + attack * 0.2,
    pass: attack * 0.45 + arm * 0.3 + hnd * 0.25,
  }
}

function pickName(
  lineup: PlayerCardItem[],
  prefer: PlayerCardItem['position'][],
  rnd: () => number,
): string {
  const preferred = lineup.filter((c) => prefer.includes(c.position))
  const pool = preferred.length ? preferred : lineup
  if (!pool.length) return 'a squad mate'
  return pool[Math.floor(rnd() * pool.length)]!.name
}

function cpuStrength(you: TeamStrength, rnd: () => number): TeamStrength {
  const jitter = (base: number) => base * (0.88 + rnd() * 0.24) + (rnd() * 6 - 3)
  return {
    attack: jitter(you.attack),
    mid: jitter(you.mid),
    def: jitter(you.def),
    gk: jitter(you.gk),
    arm: jitter(you.arm),
    hnd: jitter(you.hnd),
    pow: jitter(you.pow),
    run: jitter(you.run),
    pass: jitter(you.pass),
    ovr: Math.round(you.ovr * (0.9 + rnd() * 0.2) + (rnd() * 4 - 2)),
  }
}

function clamp01(n: number, lo = 0.05, hi = 0.78) {
  return Math.min(hi, Math.max(lo, n))
}

function hasImpact(impacts: ImpactId[], id: ImpactId) {
  return impacts.includes(id)
}

interface DriveMods {
  runConv: number
  passConv: number
  sack: number
  longTd: number
  shortTd: number
  quick: number
  midConv: number
  fg: number
  rzTd: number
  defPress: number
  youRunBias: number
  youPassBias: number
}

function buildMods(focus: PlayFocus, impacts: ImpactId[], you: TeamStrength): DriveMods {
  const W = IMPACT_WEIGHTS
  const mods: DriveMods = {
    runConv: 0,
    passConv: 0,
    sack: 0,
    longTd: 0,
    shortTd: 0,
    quick: 0,
    midConv: 0,
    fg: 0,
    rzTd: 0,
    defPress: 0,
    youRunBias: 0,
    youPassBias: 0,
  }

  if (focus === 'run') {
    mods.runConv += W.focus_run.runConversion
    mods.youRunBias += 0.1 + (you.pow / 400) * W.focus_run.lineOPow
    mods.shortTd += W.focus_run.lineOPow * 0.5
  } else {
    mods.passConv += W.focus_pass.passConversion
    mods.youPassBias += 0.1 + ((you.arm + you.hnd) / 800) * W.focus_pass.qbArmSkillHnd
    mods.quick += W.focus_pass.qbArmSkillHnd * 0.4
  }

  if (hasImpact(impacts, 'blitz')) {
    mods.defPress += W.blitz.defPressure
    mods.sack += W.blitz.sackChance
  }
  if (hasImpact(impacts, 'deep_ball') && focus === 'pass') {
    mods.longTd += W.deep_ball.longTdChance
  }
  if (hasImpact(impacts, 'power_run') && focus === 'run') {
    mods.shortTd += W.power_run.shortTdChance
  }
  if (hasImpact(impacts, 'hot_read')) {
    mods.quick += W.hot_read.quickCompletion
    mods.midConv += W.hot_read.midConversion
  }
  if (hasImpact(impacts, 'redzone')) {
    mods.fg += W.redzone.fgConversion
    mods.rzTd += W.redzone.shortTdConversion
  }

  return mods
}

function scoreLine(you: number, them: number) {
  return `${you}–${them}`
}

/**
 * Condensed AF soft-rank sim (~8–12 ticks across 4 quarters).
 * Kickoff → Q1/Q2 → HT → Q3/Q4 → Final. Soft CPU via seeded jitter.
 */
export function simulateMatch(
  lineup: PlayerCardItem[],
  opts?: SimulateMatchOpts,
): MatchResult {
  const focus: PlayFocus = opts?.focus ?? 'pass'
  const impacts = (opts?.impacts ?? []).slice(0, 3)
  const lineupHash = lineup.reduce((a, c) => a + cardOverall(c) * (c.tokenId + 1), 0)
  const loadHash =
    (focus === 'run' ? 17 : 31) +
    impacts.reduce((a, id, i) => a + (id.charCodeAt(0) + id.length) * (i + 3), 0)

  const resolvedSeed =
    opts?.seed !== undefined
      ? opts.seed >>> 0
      : (Date.now() ^ Math.imul(lineupHash ^ loadHash, 997)) >>> 0

  const rnd = makeLcg(resolvedSeed)
  const you = deriveStrength(lineup)
  const them = cpuStrength(you, rnd)
  const mods = buildMods(focus, impacts, you)

  const events: MatchEvent[] = []
  let youScore = 0
  let themScore = 0
  let tick = 0

  const push = (
    quarter: number,
    clock: string,
    side: MatchSide,
    text: string,
    pts?: { you?: number; them?: number },
  ) => {
    tick += 1
    events.push({
      tick,
      quarter,
      clock,
      side,
      text,
      youPts: pts?.you,
      themPts: pts?.them,
    })
  }

  push(
    0,
    'KO',
    'neutral',
    `Kickoff — Your 5 (OVR ${you.ovr}) vs Neon Rivals (OVR ${them.ovr}) · focus ${focus.toUpperCase()}${
      impacts.length ? ` · ${impacts.length} Impacts` : ''
    }`,
  )

  // 2 drives per quarter → 8 play ticks + KO/HT/FINAL ≈ 11 events
  const drivePlan: { quarter: number; clock: string; redzone: boolean }[] = [
    { quarter: 1, clock: 'Q1', redzone: false },
    { quarter: 1, clock: 'Q1', redzone: true },
    { quarter: 2, clock: 'Q2', redzone: false },
    { quarter: 2, clock: 'Q2', redzone: true },
    { quarter: 3, clock: 'Q3', redzone: false },
    { quarter: 3, clock: 'Q3', redzone: true },
    { quarter: 4, clock: 'Q4', redzone: false },
    { quarter: 4, clock: 'Q4', redzone: true },
  ]

  // Slight seed jitter on whether last drive fires (8–10 play ticks feel)
  const driveCount = 7 + Math.floor(rnd() * 2) // 7 or 8
  const drives = drivePlan.slice(0, driveCount)

  let halfInserted = false

  for (const drive of drives) {
    if (!halfInserted && drive.quarter >= 3) {
      push(0, 'HT', 'neutral', `Halftime ${scoreLine(youScore, themScore)} · ${MATCH_HONESTY}`)
      halfInserted = true
    }

    const youPossess =
      rnd() < 0.5 + (you.mid - them.mid) / 220 + mods.youRunBias * 0.15 + mods.youPassBias * 0.15

    if (youPossess) {
      resolveOffense({
        lineup,
        you,
        them,
        mods,
        focus,
        redzone: drive.redzone,
        rnd,
        clock: drive.clock,
        quarter: drive.quarter,
        onScore: (pts, text, side) => {
          if (side === 'you') {
            youScore += pts
            push(drive.quarter, drive.clock, 'you', `${text} — ${scoreLine(youScore, themScore)}`, {
              you: pts,
            })
          } else {
            // defensive score (INT/scoop rare) — treat as them
            themScore += pts
            push(drive.quarter, drive.clock, 'them', `${text} — ${scoreLine(youScore, themScore)}`, {
              them: pts,
            })
          }
        },
        onEvent: (side, text) => push(drive.quarter, drive.clock, side, text),
      })
    } else {
      resolveDefense({
        lineup,
        you,
        them,
        mods,
        rnd,
        clock: drive.clock,
        quarter: drive.quarter,
        redzone: drive.redzone,
        onScore: (pts, text) => {
          themScore += pts
          push(drive.quarter, drive.clock, 'them', `${text} — ${scoreLine(youScore, themScore)}`, {
            them: pts,
          })
        },
        onEvent: (side, text) => push(drive.quarter, drive.clock, side, text),
      })
    }
  }

  if (!halfInserted) {
    push(0, 'HT', 'neutral', `Halftime ${scoreLine(youScore, themScore)} · ${MATCH_HONESTY}`)
  }

  const winner: MatchResult['winner'] =
    youScore > themScore ? 'you' : themScore > youScore ? 'them' : 'draw'

  const ftLine =
    winner === 'you'
      ? `Final ${scoreLine(youScore, themScore)} — YOU WIN · ${MATCH_HONESTY}`
      : winner === 'them'
        ? `Final ${scoreLine(youScore, themScore)} — Neon Rivals edge it · ${MATCH_HONESTY}`
        : `Final ${scoreLine(youScore, themScore)} — DRAW · ${MATCH_HONESTY}`

  push(0, 'FINAL', 'neutral', ftLine)

  return {
    youScore,
    themScore,
    youOvr: you.ovr,
    themOvr: them.ovr,
    events,
    winner,
    seed: resolvedSeed,
    focus,
    impacts,
  }
}

interface OffenseCtx {
  lineup: PlayerCardItem[]
  you: TeamStrength
  them: TeamStrength
  mods: DriveMods
  focus: PlayFocus
  redzone: boolean
  rnd: () => number
  clock: string
  quarter: number
  onScore: (pts: number, text: string, side: 'you' | 'them') => void
  onEvent: (side: MatchSide, text: string) => void
}

function resolveOffense(ctx: OffenseCtx) {
  const { lineup, you, them, mods, focus, redzone, rnd, onScore, onEvent } = ctx
  const isRun = focus === 'run' ? rnd() < 0.72 + mods.youRunBias : rnd() < 0.28 + mods.youRunBias * 0.5

  if (isRun) {
    const press = you.run * 0.55 + you.pow * 0.25 + you.mid * 0.2
    const wall = them.def * 0.55 + them.mid * 0.25
    let p = clamp01((press - wall + 16) / 52 + mods.runConv + mods.midConv * 0.35 + (rnd() * 0.1 - 0.05))
    if (redzone) p = clamp01(p + mods.rzTd + mods.shortTd * 0.5 + mods.fg * 0.2)

    const runner = pickName(lineup, ['SKILL', 'LINE_O', 'QB'], rnd)
    const roll = rnd()

    if (redzone && roll < p * 0.42 + mods.shortTd) {
      onScore(TD_PTS + XP_PTS, `TD! ${runner} power plunge (+${TD_PTS}+XP)`, 'you')
    } else if (redzone && roll < p * 0.42 + mods.shortTd + 0.22 + mods.fg) {
      const kicker = pickName(lineup, ['K', 'QB', 'SKILL'], rnd)
      if (rnd() < 0.72 + mods.fg) {
        onScore(FG_PTS, `FG GOOD — ${kicker} from the hash (+${FG_PTS})`, 'you')
      } else {
        onEvent('you', `FG miss — ${kicker} pushes it wide`)
      }
    } else if (roll < p * 0.55) {
      onScore(TD_PTS + XP_PTS, `TD! ${runner} breaks contain (+${TD_PTS}+XP)`, 'you')
    } else if (roll < p) {
      onEvent('you', `${runner} churns a first down`)
    } else if (roll < p + 0.28) {
      onEvent('them', `Neon Rivals stuff the rush — ${runner} buried`)
    } else {
      onEvent('you', `${pickName(lineup, ['LINE_O'], rnd)} wins the trench; drive stalls → punt`)
    }
    return
  }

  // Pass drive
  const press = you.pass * 0.5 + you.arm * 0.3 + you.hnd * 0.2
  const wall = them.def * 0.5 + them.gk * 0.15 + them.mid * 0.2
  let p = clamp01(
    (press - wall + 16) / 52 + mods.passConv + mods.quick * 0.5 + mods.midConv + (rnd() * 0.1 - 0.05),
  )
  if (redzone) p = clamp01(p + mods.rzTd + mods.fg * 0.25)

  const qb = pickName(lineup, ['QB'], rnd)
  const skill = pickName(lineup, ['SKILL', 'QB'], rnd)
  const roll = rnd()

  // Hot-read / quick game first
  if (roll < mods.quick * 0.55) {
    onEvent('you', `HOT READ — ${qb} hits ${skill} on the slant`)
    if (rnd() < 0.35 + mods.passConv) {
      onScore(TD_PTS + XP_PTS, `TD! ${skill} walks in after the catch (+${TD_PTS}+XP)`, 'you')
    }
    return
  }

  if (redzone && roll < 0.2 + mods.fg) {
    const kicker = pickName(lineup, ['K', 'QB'], rnd)
    if (rnd() < 0.7 + mods.fg) {
      onScore(FG_PTS, `FG GOOD — ${kicker} chips it through (+${FG_PTS})`, 'you')
    } else {
      onEvent('you', `FG miss — ${kicker} hooks left`)
    }
    return
  }

  if (roll < p * 0.35 + mods.longTd) {
    onScore(TD_PTS + XP_PTS, `TD! ${qb} → ${skill} deep ball (+${TD_PTS}+XP)`, 'you')
  } else if (roll < p * 0.55 + mods.longTd * 0.3) {
    onEvent('you', `Big catch — ${skill} snags it from ${qb}`)
  } else if (roll < p) {
    onEvent('you', `${qb} finds ${skill} for a chunk gain`)
  } else if (roll < p + 0.18) {
    onEvent('them', `INT! Neon Rivals pick ${qb}`)
  } else if (roll < p + 0.35) {
    onEvent('them', `Neon Rivals sack ${qb}`)
  } else {
    onEvent('you', `${qb} checks down; drive stalls → punt`)
  }
}

interface DefenseCtx {
  lineup: PlayerCardItem[]
  you: TeamStrength
  them: TeamStrength
  mods: DriveMods
  rnd: () => number
  clock: string
  quarter: number
  redzone: boolean
  onScore: (pts: number, text: string) => void
  onEvent: (side: MatchSide, text: string) => void
}

function resolveDefense(ctx: DefenseCtx) {
  const { lineup, you, them, mods, rnd, redzone, onScore, onEvent } = ctx
  const press = them.attack * 0.5 + them.pass * 0.25 + them.run * 0.25
  const wall = you.def * 0.55 + you.mid * 0.2 + mods.defPress * 40
  let p = clamp01((press - wall + 14) / 52 - mods.sack * 0.35 + (rnd() * 0.1 - 0.05))
  if (redzone) p = clamp01(p + 0.06)

  const db = pickName(lineup, ['DB', 'LINE_D'], rnd)
  const rush = pickName(lineup, ['LINE_D', 'DB'], rnd)
  const roll = rnd()

  if (roll < mods.sack + 0.08) {
    onEvent('you', `SACK — ${rush} blows up the pocket`)
    return
  }

  if (roll < mods.sack + 0.08 + 0.12 + mods.defPress * 0.4) {
    onEvent('you', `INT! ${db} undercuts the route`)
    return
  }

  if (redzone && roll < p * 0.4) {
    onScore(TD_PTS + XP_PTS, `Neon Rivals TD in the red zone (+${TD_PTS}+XP)`)
  } else if (redzone && roll < p * 0.4 + 0.2) {
    if (rnd() < 0.65) onScore(FG_PTS, `Neon Rivals FG GOOD (+${FG_PTS})`)
    else onEvent('you', `${db} tips the kick — FG miss`)
  } else if (roll < p * 0.5) {
    onScore(TD_PTS + XP_PTS, `Neon Rivals punch in a TD (+${TD_PTS}+XP)`)
  } else if (roll < p) {
    onEvent('them', `Rival big catch downfield`)
  } else if (roll < p + 0.28) {
    onEvent('you', `${rush} stuffs the rush`)
  } else {
    onEvent('neutral', `Neon Rivals punt — field flips`)
  }
}
