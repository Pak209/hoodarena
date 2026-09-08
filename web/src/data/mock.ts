/** Mock-data mode — no wallet required. Live stakes locked until VITE_ARENA_ADDRESS set. */
export {
  CHAIN_ID,
  RPC_URL,
  PONS_FACTORY,
  FEE_BPS,
  USDG_ADDRESS,
  isLiveContracts,
} from '../lib/config'

export type ArenaStatus = 'Open' | 'Locked' | 'ResolvedYes' | 'ResolvedNo' | 'Cancelled'

export interface ArenaItem {
  id: string
  ticker: string
  token: string
  question: string
  timeRemaining: string
  yesPct: number
  noPct: number
  yesPool: number
  noPool: number
  players: number
  status: ArenaStatus
  ring: 'lime' | 'pink' | 'teal'
}

export interface ResolvedArena {
  id: string
  number: number
  winner: 'YES GRADUATE' | 'NO FAIL'
  description: string
  payout: number
  timeline: { label: string; detail: string; active?: boolean }[]
}

export interface RaceLane {
  ticker: string
  fill: number
  elapsed: string
  stake: number
  color: 'lime' | 'pink'
  multiplier: number
}

export const mockBalance = 1234.56

export const arenas: ArenaItem[] = [
  {
    id: 'a1',
    ticker: 'ALPHA',
    token: '0xA11A100000000000000000000000000000000001',
    question: 'Will $ALPHA graduate on PONS before the timer runs out?',
    timeRemaining: '02:45:18',
    yesPct: 62,
    noPct: 38,
    yesPool: 7654,
    noPool: 4691,
    players: 1234,
    status: 'Open',
    ring: 'lime',
  },
  {
    id: 'a2',
    ticker: 'BETA',
    token: '0xBE7A000000000000000000000000000000000002',
    question: 'Will $BETA graduate on PONS before the timer runs out?',
    timeRemaining: '00:58:02',
    yesPct: 48,
    noPct: 52,
    yesPool: 4200,
    noPool: 4550,
    players: 812,
    status: 'Open',
    ring: 'pink',
  },
  {
    id: 'a3',
    ticker: 'GAMMA',
    token: '0xCA11A00000000000000000000000000000000003',
    question: 'Will $GAMMA graduate on PONS before the timer runs out?',
    timeRemaining: '05:12:40',
    yesPct: 71,
    noPct: 29,
    yesPool: 9800,
    noPool: 4012,
    players: 2104,
    status: 'Open',
    ring: 'teal',
  },
]

export const resolved: ResolvedArena = {
  id: 'r45',
  number: 45,
  winner: 'YES GRADUATE',
  description: 'Factory phase==2 PoolCreated (on-chain VIEW).',
  payout: 1250.75,
  timeline: [
    { label: 'Arena Opened', detail: 'May 2025' },
    { label: 'Stakes Locked', detail: 'Staking closed' },
    { label: 'Factory Resolved', detail: 'phase==2 PoolCreated', active: true },
    { label: 'Claim Available', detail: 'Winnings ready' },
  ],
}

export const raceLanes: RaceLane[] = [
  { ticker: 'ALPHA', fill: 62.4, elapsed: '07:32', stake: 250, color: 'lime', multiplier: 2.1 },
  { ticker: 'BETA', fill: 48.1, elapsed: '07:32', stake: 180, color: 'pink', multiplier: 2.8 },
  { ticker: 'GAMMA', fill: 71.0, elapsed: '07:32', stake: 320, color: 'lime', multiplier: 1.9 },
]

export function fmt(n: number) {
  return n.toLocaleString(undefined, { maximumFractionDigits: 2 })
}

/* ——— Mode C: Player Cards (AF Spec §12b — mock until Mint addresses / Kit art) ——— */

export type CardPosition = 'QB' | 'SKILL' | 'LINE_O' | 'LINE_D' | 'DB' | 'K'
export type CardRarity = 'Common' | 'Rare' | 'Epic' | 'Legend'
export type RatingKey = 'spd' | 'arm' | 'hnd' | 'tck' | 'pow'

export interface PlayerCardItem {
  tokenId: number
  name: string
  position: CardPosition
  rarity: CardRarity
  season: number
  ratings: Record<RatingKey, number>
  /** Art path — Kit AF rasters */
  art: string
  frame: string
  slug: string
}

export interface PackOffer {
  id: string
  name: string
  priceUsdg: number
  cardsPerPack: number
  feeBps: number
  artClosed: string
  artOpen: string
  status: 'mock' | 'buyable'
}

export type ImpactId = 'blitz' | 'deep_ball' | 'power_run' | 'hot_read' | 'redzone'
export type PlayFocus = 'run' | 'pass'

export interface ImpactCard {
  id: ImpactId
  name: string
  blurb: string
  art: string
}

const POS: CardPosition[] = ['QB', 'SKILL', 'LINE_O', 'LINE_D', 'DB', 'K']
const RARITY: CardRarity[] = ['Common', 'Rare', 'Epic', 'Legend']

/** Compressed starter five (Mint: QB…DB; K not in starter pack) — Kit AF art */
export const mockCards: PlayerCardItem[] = [
  {
    tokenId: 1,
    name: 'Neon Arm',
    slug: 'neon-arm',
    position: 'QB',
    rarity: 'Rare',
    season: 1,
    ratings: { spd: 72, arm: 88, hnd: 70, tck: 38, pow: 64 },
    art: '/art/player-neon-arm.png',
    frame: '/art/frame-rare.png',
  },
  {
    tokenId: 2,
    name: 'Chain Slash',
    slug: 'chain-slash',
    position: 'SKILL',
    rarity: 'Common',
    season: 1,
    ratings: { spd: 90, arm: 42, hnd: 84, tck: 40, pow: 68 },
    art: '/art/player-chain-slash.png',
    frame: '/art/frame-common.png',
  },
  {
    tokenId: 3,
    name: 'Vault Wall',
    slug: 'vault-wall',
    position: 'LINE_O',
    rarity: 'Epic',
    season: 1,
    ratings: { spd: 55, arm: 30, hnd: 62, tck: 78, pow: 92 },
    art: '/art/player-vault-wall.png',
    frame: '/art/frame-epic.png',
  },
  {
    tokenId: 4,
    name: 'RH Rush',
    slug: 'rh-rush',
    position: 'LINE_D',
    rarity: 'Legend',
    season: 1,
    ratings: { spd: 68, arm: 28, hnd: 48, tck: 90, pow: 88 },
    art: '/art/player-rh-rush.png',
    frame: '/art/frame-legend.png',
  },
  {
    tokenId: 5,
    name: 'Street Pick',
    slug: 'street-pick',
    position: 'DB',
    rarity: 'Rare',
    season: 1,
    ratings: { spd: 91, arm: 35, hnd: 74, tck: 82, pow: 60 },
    art: '/art/player-street-pick.png',
    frame: '/art/frame-rare.png',
  },
]

export const mockPack: PackOffer = {
  id: 'starter',
  name: 'HOOD AF STARTER PACK',
  priceUsdg: 10,
  cardsPerPack: 5,
  feeBps: 100,
  artClosed: '/art/pack-closed.png',
  artOpen: '/art/pack-open.png',
  status: 'mock',
}

/** Compressed 5-hero lineup: QB · SKILL · LINE_O · LINE_D · DB */
export const mockSquadIds = [1, 2, 3, 4, 5] as const
export const SQUAD_SLOTS: CardPosition[] = ['QB', 'SKILL', 'LINE_O', 'LINE_D', 'DB']

export const mockImpacts: ImpactCard[] = [
  { id: 'blitz', name: 'NEON BLITZ', blurb: '+ pressure / sack weight', art: '/art/impact-neon-blitz.png' },
  { id: 'deep_ball', name: 'RH CANNON', blurb: '+ vertical pass weight', art: '/art/impact-rh-cannon.png' },
  { id: 'power_run', name: 'VAULT LOCK', blurb: '+ downhill run weight', art: '/art/impact-vault-lock.png' },
  { id: 'hot_read', name: 'CHAIN GRAB', blurb: '+ quick-game weight', art: '/art/impact-chain-grab.png' },
  { id: 'redzone', name: 'STREET PICK', blurb: '+ scoring-area weight', art: '/art/impact-street-pick.png' },
]

/** Kit position glyphs */
export const POS_ICON: Record<CardPosition, string> = {
  QB: '/icons/pos-qb.svg',
  SKILL: '/icons/pos-skill.svg',
  LINE_O: '/icons/pos-line-o.svg',
  LINE_D: '/icons/pos-line-d.svg',
  DB: '/icons/pos-db.svg',
  K: '/icons/pos-k.svg',
}

export const FOCUS_ICON: Record<PlayFocus, string> = {
  run: '/icons/focus-run.svg',
  pass: '/icons/focus-pass.svg',
}

export function cardOverall(c: PlayerCardItem): number {
  const { spd, arm, hnd, tck, pow } = c.ratings
  return Math.round((spd + arm + hnd + tck + pow) / 5)
}

export function rarityLabel(r: number): CardRarity {
  return RARITY[Math.min(3, Math.max(0, r))] ?? 'Common'
}

export function positionLabel(p: number): CardPosition {
  return POS[Math.min(POS.length - 1, Math.max(0, p))] ?? 'SKILL'
}
