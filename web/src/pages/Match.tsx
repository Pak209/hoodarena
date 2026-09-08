import { useMemo, useState } from 'react'
import { ModeCNav } from '../components/ModeCNav'
import { MatchPlay } from '../components/MatchPlay'
import { PreMatchLoadout, type PreMatchLoadoutValue } from '../components/PreMatchLoadout'
import { mockCards, mockSquadIds } from '../data/mock'

export function Match() {
  const lineup = useMemo(
    () => mockSquadIds.map((id) => mockCards.find((c) => c.tokenId === id)!).filter(Boolean),
    [],
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

      <PreMatchLoadout value={loadout} onChange={setLoadout} />
      <div style={{ marginTop: 12 }}>
        <MatchPlay lineup={lineup} loadout={loadout} />
      </div>
    </div>
  )
}
