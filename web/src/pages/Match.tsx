import { useMemo, useState } from 'react'
import { ModeCNav } from '../components/ModeCNav'
import { MatchPlay } from '../components/MatchPlay'
import { PreMatchLoadout, type PreMatchLoadoutValue } from '../components/PreMatchLoadout'
import { useInventory } from '../lib/useInventory'
import { useSquadLineup } from '../lib/useSquadLineup'

export function Match() {
  const { cards, source, address, isLoading } = useInventory()
  const { lineup: lineupIds } = useSquadLineup(cards, address, source)
  const lineup = useMemo(
    () =>
      lineupIds
        .map((id) => (id != null ? cards.find((c) => c.tokenId === id) : undefined))
        .filter((c): c is NonNullable<typeof c> => Boolean(c)),
    [lineupIds, cards],
  )
  const [loadout, setLoadout] = useState<PreMatchLoadoutValue>({ focus: 'pass', impacts: [] })

  return (
    <div>
      <ModeCNav />
      <div className="hero">
        <div>
          <h1 className="heavy">
            <span style={{ color: 'var(--pink)' }}>COSMETIC</span> MATCH
          </h1>
          <p>
            AF soft-rank · drive tick + Skip · focus {loadout.focus.toUpperCase()}
            {loadout.impacts.length ? ` · ${loadout.impacts.length} Impacts` : ''} · no USDG escrow
            {' · '}
            <span className={`badge ${source === 'live' ? 'pink' : ''}`}>
              {source === 'live' ? 'LIVE' : 'MOCK'}
            </span>
          </p>
        </div>
        <div className="win-hint">
          <img src="/icons/swords.svg" alt="" className="pixel-icon" width={28} height={28} />
          <div>
            <strong style={{ color: 'var(--lime)' }}>NO ESCROW</strong>
            <div style={{ color: 'var(--muted)', fontSize: 12 }}>v1 soft-rank only</div>
          </div>
        </div>
      </div>

      {isLoading ? <p className="muted">Loading squad…</p> : null}

      <PreMatchLoadout value={loadout} onChange={setLoadout} />
      <div style={{ marginTop: 12 }}>
        <MatchPlay lineup={lineup} loadout={loadout} />
      </div>
    </div>
  )
}
