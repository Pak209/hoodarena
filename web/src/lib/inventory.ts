import type { Address } from 'viem'
import {
  type CardPosition,
  type CardRarity,
  type PlayerCardItem,
  positionLabel,
  rarityLabel,
} from '../data/mock'

export type OnChainCardData = {
  name: string
  uri: string
  position: number
  rarity: number
  season: number
  spd: number
  arm: number
  hnd: number
  tck: number
  pow: number
}

export type InventorySource = 'live' | 'mock'

const FRAME: Record<CardRarity, string> = {
  Common: '/art/frame-common.png',
  Rare: '/art/frame-rare.png',
  Epic: '/art/frame-epic.png',
  Legend: '/art/frame-legend.png',
}

const FOIL: Record<CardRarity, string> = {
  Common: '/art/foil-common.png',
  Rare: '/art/foil-rare.png',
  Epic: '/art/foil-epic.png',
  Legend: '/art/foil-legend.png',
}

const FALLBACK_ART = '/art/hood-alpha.png'

/** Resolve Kit art from on-chain uri / slug; fall back to hood-alpha. */
export function resolveCardArt(uri: string, name: string, rarity?: CardRarity): { art: string; slug: string } {
  const trimmed = (uri || '').trim()
  const nameSlug =
    name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '') || 'unknown'

  if (!trimmed) return { art: FALLBACK_ART, slug: nameSlug }

  // Mint baseUri alone (e.g. `/art/`) — build Kit path from name slug
  if (trimmed.replace(/\/+$/, '') === '/art') {
    return { art: `/art/player-${nameSlug}.png`, slug: nameSlug }
  }

  const playerMatch = trimmed.match(/player-([a-z0-9-]+)\.png/i)
  if (playerMatch) {
    const art = trimmed.startsWith('http')
      ? trimmed
      : trimmed.startsWith('/')
        ? trimmed
        : `/art/player-${playerMatch[1]}.png`
    return { art, slug: playerMatch[1] }
  }

  if (/^[a-z0-9-]+$/i.test(trimmed)) {
    return { art: `/art/player-${trimmed}.png`, slug: trimmed }
  }

  if (trimmed.startsWith('/') || trimmed.startsWith('http') || trimmed.endsWith('.png')) {
    const art = trimmed.startsWith('http') || trimmed.startsWith('/') ? trimmed : `/${trimmed}`
    return { art, slug: nameSlug }
  }

  return { art: FALLBACK_ART, slug: nameSlug }
}


/** Prefer Kit `player-{slug}-{rarity}.png`; <img onError> can fall back to base slug art. */
export function preferRarityArt(slug: string, rarity: CardRarity, fallback: string): string {
  const base = slug.replace(/-(common|rare|epic|legend)$/i, '')
  if (!base || base === 'unknown') return fallback
  return `/art/player-${base}-${rarity.toLowerCase()}.png`
}

export function mapOnChainCard(tokenId: bigint | number, raw: OnChainCardData): PlayerCardItem {
  const rarity = rarityLabel(Number(raw.rarity))
  const position = positionLabel(Number(raw.position)) as CardPosition
  const resolved = resolveCardArt(raw.uri, raw.name, rarity)
  const slug = resolved.slug.replace(/-(common|rare|epic|legend)$/i, '')
  return {
    tokenId: Number(tokenId),
    name: raw.name || slug,
    slug,
    position,
    rarity,
    season: Number(raw.season),
    ratings: {
      spd: Number(raw.spd),
      arm: Number(raw.arm),
      hnd: Number(raw.hnd),
      tck: Number(raw.tck),
      pow: Number(raw.pow),
    },
    art: preferRarityArt(slug, rarity, resolved.art),
    frame: FRAME[rarity],
    foil: FOIL[rarity],
  }
}

export function shortAddr(addr: Address | string | undefined): string {
  if (!addr) return ''
  return `${addr.slice(0, 6)}…${addr.slice(-4)}`
}
