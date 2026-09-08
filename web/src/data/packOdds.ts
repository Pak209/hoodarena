import type { CardPosition, CardRarity } from './mock'

/** Spec §12c — bps out of 10_000 per position (must sum 10_000). Draft until Mint publishes on-chain. */
export const PACK_ODDS_BPS: Record<CardPosition, Record<CardRarity, number>> = {
  QB: { Common: 5500, Rare: 2700, Epic: 1400, Legend: 400 },
  SKILL: { Common: 6000, Rare: 2500, Epic: 1200, Legend: 300 },
  LINE_O: { Common: 6200, Rare: 2400, Epic: 1100, Legend: 300 },
  LINE_D: { Common: 6000, Rare: 2500, Epic: 1200, Legend: 300 },
  DB: { Common: 5800, Rare: 2600, Epic: 1300, Legend: 300 },
  K: { Common: 6500, Rare: 2300, Epic: 1000, Legend: 200 },
}

export const PACK_ODDS_POSITIONS: CardPosition[] = ['QB', 'SKILL', 'LINE_O', 'LINE_D', 'DB', 'K']
export const PACK_ODDS_RARITIES: CardRarity[] = ['Common', 'Rare', 'Epic', 'Legend']

export function bpsToPct(bps: number): string {
  return `${(bps / 100).toFixed(bps % 100 === 0 ? 0 : 1)}%`
}

export function assertOddsSum(): boolean {
  return PACK_ODDS_POSITIONS.every((pos) => {
    const sum = PACK_ODDS_RARITIES.reduce((a, r) => a + PACK_ODDS_BPS[pos][r], 0)
    return sum === 10_000
  })
}
