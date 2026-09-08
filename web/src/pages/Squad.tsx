import { useMemo } from 'react'
import { Link } from 'react-router-dom'
import { ModeCNav } from '../components/ModeCNav'
import { SQUAD_SLOTS, cardOverall, POS_ICON, type PlayerCardItem } from '../data/mock'
import { useInventory } from '../lib/useInventory'
import { useSquadLineup } from '../lib/useSquadLineup'

export function Squad() {
  const { cards, source, address, isLoading } = useInventory()
  const { lineup, setLineup } = useSquadLineup(cards, address, source)
  const byId = useMemo(() => new Map(cards.map((c) => [c.tokenId, c])), [cards])

  function pick(slot: number, tokenId: number) {
    setLineup((prev) => {
      const next = [...prev]
      next[slot] = tokenId
      return next
    })
  }

  const filled = lineup.filter((id) => id != null).length

  return (
    <div>
      <ModeCNav />
      <div className="hero">
        <div>
          <h1 className="heavy">
            <span style={{ color: 'var(--lime)' }}>BUILD</span> SQUAD
          </h1>
          <p>
            Compressed 5-hero · QB · SKILL · LINE_O · LINE_D · DB · no chemistry
            {' · '}
            <span className={`badge ${source === 'live' ? 'pink' : ''}`}>
              {source === 'live' ? 'LIVE' : 'MOCK'}
            </span>
          </p>
        </div>
        <div className="score-box">
          <div className="label">Lineup</div>
          <div className="val pixel">{filled}/5</div>
        </div>
      </div>

      {isLoading ? <p className="muted">Loading cards…</p> : null}

      {!isLoading && source === 'live' && cards.length === 0 ? (
        <div className="win-hint" style={{ marginBottom: 16 }}>
          <strong style={{ color: 'var(--lime)' }}>EMPTY INVENTORY</strong>
          <div className="muted" style={{ fontSize: 12 }}>
            No on-chain cards to equip — check Packs / Cards after Mint deploy.
          </div>
        </div>
      ) : null}

      <div className="squad-pitch">
        {SQUAD_SLOTS.map((slot, i) => {
          const id = lineup[i]
          const card: PlayerCardItem | undefined = id != null ? byId.get(id) : undefined
          const preferred = cards.filter((c) => c.position === slot)
          const pool = preferred.length ? preferred : cards
          return (
            <div key={slot} className="squad-slot">
              <div
                className="muted"
                style={{ fontSize: 11, marginBottom: 6, display: 'flex', alignItems: 'center', gap: 6 }}
              >
                <img src={POS_ICON[slot]} alt="" className="pixel-icon" width={14} height={14} />
                {slot}
              </div>
              {card ? (
                <div className="squad-card-mini">
                  <strong>{card.name}</strong>
                  <div className="muted" style={{ fontSize: 12 }}>
                    OVR {cardOverall(card)} · {card.position}
                  </div>
                </div>
              ) : (
                <div className="squad-empty">Empty</div>
              )}
              <select
                className="squad-select"
                value={id ?? ''}
                onChange={(e) => pick(i, Number(e.target.value))}
                disabled={cards.length === 0}
              >
                <option value="">— pick —</option>
                {pool.map((c) => (
                  <option key={`${slot}-${c.tokenId}`} value={c.tokenId}>
                    {c.name} ({c.position} {cardOverall(c)})
                  </option>
                ))}
              </select>
            </div>
          )
        })}
      </div>

      <div className="chip-row" style={{ marginTop: 16 }}>
        <Link to="/match" className="btn-outline">
          Pre-match loadout
        </Link>
        <Link to="/cards" className="btn-outline">
          Inventory
        </Link>
      </div>
    </div>
  )
}
