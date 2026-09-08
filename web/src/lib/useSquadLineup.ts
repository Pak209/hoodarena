import { useCallback, useEffect, useMemo, useState } from 'react'
import { mockSquadIds, SQUAD_SLOTS, type PlayerCardItem } from '../data/mock'

function storageKey(address: string | undefined, source: 'mock' | 'live'): string {
  if (source === 'live' && address) return `squad:${address}`
  return `squad:${address ?? 'mock'}`
}

function defaultLineup(cards: PlayerCardItem[], source: 'mock' | 'live'): (number | null)[] {
  if (source === 'mock' && cards.length >= 5) return [...mockSquadIds]
  const byPos = new Map<string, PlayerCardItem>()
  for (const c of cards) {
    if (!byPos.has(c.position)) byPos.set(c.position, c)
  }
  return SQUAD_SLOTS.map((slot) => byPos.get(slot)?.tokenId ?? null)
}

function readStored(key: string): (number | null)[] | null {
  try {
    const raw = localStorage.getItem(key)
    if (!raw) return null
    const parsed = JSON.parse(raw) as unknown
    if (!Array.isArray(parsed) || parsed.length !== 5) return null
    return parsed.map((v) => (v == null || v === '' ? null : Number(v)))
  } catch {
    return null
  }
}

/** Persist 5-slot lineup in localStorage keyed by squad:{address|mock}. */
export function useSquadLineup(
  cards: PlayerCardItem[],
  address: string | undefined,
  source: 'mock' | 'live',
) {
  const key = useMemo(() => storageKey(address, source), [address, source])

  const [lineup, setLineupState] = useState<(number | null)[]>(() => {
    if (typeof window === 'undefined') return defaultLineup(cards, source)
    return readStored(key) ?? defaultLineup(cards, source)
  })

  useEffect(() => {
    const stored = readStored(key)
    setLineupState(stored ?? defaultLineup(cards, source))
    // re-seed on wallet/source key change only
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key, source])

  useEffect(() => {
    if (source !== 'live') return
    setLineupState((prev) => {
      if (cards.length === 0) return prev.map(() => null)
      const owned = new Set(cards.map((c) => c.tokenId))
      const pruned = prev.map((id) => (id != null && owned.has(id) ? id : null))
      if (pruned.every((id) => id == null)) return defaultLineup(cards, source)
      return pruned
    })
  }, [source, cards])

  const setLineup = useCallback(
    (next: (number | null)[] | ((prev: (number | null)[]) => (number | null)[])) => {
      setLineupState((prev) => {
        const value = typeof next === 'function' ? next(prev) : next
        try {
          localStorage.setItem(key, JSON.stringify(value))
        } catch {
          /* ignore */
        }
        return value
      })
    },
    [key],
  )

  useEffect(() => {
    try {
      localStorage.setItem(key, JSON.stringify(lineup))
    } catch {
      /* ignore */
    }
  }, [key, lineup])

  return { lineup, setLineup, storageKey: key }
}
