import { useState } from 'react'
import { FOCUS_ICON, mockImpacts, type ImpactId, type PlayFocus } from '../data/mock'

const MAX_IMPACTS = 3

export interface PreMatchLoadoutValue {
  focus: PlayFocus
  impacts: ImpactId[]
}

export interface PreMatchLoadoutProps {
  value?: PreMatchLoadoutValue
  onChange?: (next: PreMatchLoadoutValue) => void
}

export function PreMatchLoadout({ value, onChange }: PreMatchLoadoutProps) {
  const [focus, setFocus] = useState<PlayFocus>(value?.focus ?? 'pass')
  const [impacts, setImpacts] = useState<ImpactId[]>(value?.impacts ?? [])

  function emit(nextFocus: PlayFocus, nextImpacts: ImpactId[]) {
    setFocus(nextFocus)
    setImpacts(nextImpacts)
    onChange?.({ focus: nextFocus, impacts: nextImpacts })
  }

  function toggleImpact(id: ImpactId) {
    const has = impacts.includes(id)
    let next: ImpactId[]
    if (has) next = impacts.filter((x) => x !== id)
    else if (impacts.length >= MAX_IMPACTS) return
    else next = [...impacts, id]
    emit(focus, next)
  }

  return (
    <section className="card prematch-panel">
      <div className="prematch-head">
        <strong>PRE-MATCH LOADOUT</strong>
        <span className="muted" style={{ fontSize: 12 }}>
          Off-chain · ≤{MAX_IMPACTS} Impacts · no mid-drive calling
        </span>
      </div>

      <div className="prematch-focus">
        <span className="muted" style={{ fontSize: 11 }}>
          FOCUS
        </span>
        <div className="chip-row" style={{ margin: 0 }}>
          <button
            type="button"
            className={`chip ${focus === 'run' ? 'active' : ''}`}
            onClick={() => emit('run', impacts)}
          >
            <img src={FOCUS_ICON.run} alt="" className="pixel-icon" width={14} height={14} /> RUN
          </button>
          <button
            type="button"
            className={`chip ${focus === 'pass' ? 'active' : ''}`}
            onClick={() => emit('pass', impacts)}
          >
            <img src={FOCUS_ICON.pass} alt="" className="pixel-icon" width={14} height={14} /> PASS
          </button>
        </div>
      </div>

      <div className="prematch-impacts">
        <div className="muted" style={{ fontSize: 11, marginBottom: 8 }}>
          BIG IMPACTS {impacts.length}/{MAX_IMPACTS}
        </div>
        <div className="impact-grid">
          {mockImpacts.map((imp) => {
            const on = impacts.includes(imp.id)
            return (
              <button
                key={imp.id}
                type="button"
                className={`impact-chip ${on ? 'on' : ''}`}
                onClick={() => toggleImpact(imp.id)}
                disabled={!on && impacts.length >= MAX_IMPACTS}
              >
                <img
                  src={imp.art}
                  alt=""
                  className="impact-thumb"
                  onError={(e) => {
                    ;(e.target as HTMLImageElement).style.display = 'none'
                  }}
                />
                <span className="pixel" style={{ fontSize: 10 }}>
                  {imp.name}
                </span>
                <span className="muted" style={{ fontSize: 11 }}>
                  {imp.blurb}
                </span>
              </button>
            )
          })}
        </div>
      </div>
    </section>
  )
}
