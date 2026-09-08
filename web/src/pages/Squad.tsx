import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { ModeCNav } from '../components/ModeCNav'
import {
  mockCards,
  mockSquadIds,
  SQUAD_SLOTS,
  cardOverall,
  POS_ICON,
  type PlayerCardItem,
} from '../data/mock'

export function Squad() {
  const byId = useMemo(() => new Map(mockCards.map((c) => [c.tokenId, c])), [])
  const [lineup, setLineup] = useState<(number | null)[]>([...mockSquadIds])

  function pick(slot: number, tokenId: number) {
    setLineup((prev) => {
      const next = [...prev]
      next[slot] = tokenId
      return next
    })
  }

  const filled = lineup.filter(Boolean).length

  return (
    <div>
      <ModeCNav />
      <div className="hero">
        <div>
          <h1 className="heavy">
            <span style={{ color: 'var(--lime)' }}>BUILD</span> SQUAD
          </h1>
          <p>Compressed 5-hero · QB · SKILL · LINE_O · LINE_D · DB · no chemistry</p>
        </div>
        <div className="score-box">
          <div className="label">Lineup</div>
          <div className="val pixel">{filled}/5</div>
        </div>
      </div>

      <div className="squad-pitch">
        {SQUAD_SLOTS.map((slot, i) => {
          const id = lineup[i]
          const card: PlayerCardItem | undefined = id ? byId.get(id) : undefined
          const preferred = mockCards.filter((c) => c.position === slot)
          const pool = preferred.length ? preferred : mockCards
          return (
            <div key={slot} className="squad-slot">
              <div className="muted" style={{ fontSize: 11, marginBottom: 6, display: 'flex', alignItems: 'center', gap: 6 }}>
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
