import { useCallback, useEffect, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import { cardOverall, type PlayerCardItem } from '../data/mock'
import type { PreMatchLoadoutValue } from './PreMatchLoadout'
import {
  MATCH_HONESTY,
  simulateMatch,
  type MatchEvent,
  type MatchResult,
} from '../lib/matchSim'

type Phase = 'idle' | 'playing' | 'done'

/** Reveal cadence — full watch ≈ 20–40s for ~10–12 ticks (≤90s feel). */
const TICK_MS = 400

export interface MatchPlayProps {
  lineup: PlayerCardItem[]
  loadout: PreMatchLoadoutValue
}

export function MatchPlay({ lineup, loadout }: MatchPlayProps) {
  const [phase, setPhase] = useState<Phase>('idle')
  const [result, setResult] = useState<MatchResult | null>(null)
  const [visible, setVisible] = useState<MatchEvent[]>([])
  const [liveYou, setLiveYou] = useState(0)
  const [liveThem, setLiveThem] = useState(0)
  const timerRef = useRef<number | null>(null)
  const resultRef = useRef<MatchResult | null>(null)

  const clearTimer = useCallback(() => {
    if (timerRef.current !== null) {
      window.clearInterval(timerRef.current)
      timerRef.current = null
    }
  }, [])

  useEffect(() => () => clearTimer(), [clearTimer])

  function recountScore(evs: MatchEvent[]) {
    let y = 0
    let t = 0
    for (const e of evs) {
      y += e.youPts ?? 0
      t += e.themPts ?? 0
      // Fallback markers if pts omitted
      if (!e.youPts && e.side === 'you') {
        if (/\bTD!/.test(e.text)) y += 7
        else if (/FG GOOD/i.test(e.text)) y += 3
      }
      if (!e.themPts && e.side === 'them') {
        if (/\bTD\b/i.test(e.text) && /Neon Rivals/i.test(e.text)) t += 7
        else if (/FG GOOD/i.test(e.text)) t += 3
      }
    }
    setLiveYou(y)
    setLiveThem(t)
  }

  function finishWith(sim: MatchResult) {
    clearTimer()
    setVisible(sim.events)
    setLiveYou(sim.youScore)
    setLiveThem(sim.themScore)
    setPhase('done')
  }

  function play() {
    clearTimer()
    const sim = simulateMatch(lineup, {
      focus: loadout.focus,
      impacts: loadout.impacts,
    })
    resultRef.current = sim
    setResult(sim)
    setVisible([])
    setLiveYou(0)
    setLiveThem(0)
    setPhase('playing')

    let i = 0
    timerRef.current = window.setInterval(() => {
      i += 1
      const slice = sim.events.slice(0, i)
      setVisible(slice)
      recountScore(slice)
      if (i >= sim.events.length) {
        finishWith(sim)
      }
    }, TICK_MS)
  }

  function skip() {
    const sim = resultRef.current
    if (!sim || phase !== 'playing') return
    finishWith(sim)
  }

  const banner =
    phase === 'done' && result
      ? result.winner === 'you'
        ? 'YOU WIN'
        : result.winner === 'them'
          ? 'RIVALS WIN'
          : 'DRAW'
      : phase === 'playing'
        ? 'LIVE'
        : 'READY'

  const impactLabel =
    loadout.impacts.length === 0
      ? '0 Impacts'
      : `${loadout.impacts.length} Impact${loadout.impacts.length === 1 ? '' : 's'}`

  return (
    <article className={`card match-board match-play${phase === 'playing' ? ' is-playing' : ''}`}>
      <div className="match-honesty" role="status">
        <span className="pixel">COSMETIC</span>
        <span>·</span>
        <span className="pixel">NO ESCROW</span>
        <span>·</span>
        <span>{MATCH_HONESTY}</span>
      </div>

      <div className="match-loadout-chip muted" style={{ fontSize: 12, marginBottom: 10 }}>
        Focus <strong style={{ color: 'var(--lime)' }}>{loadout.focus.toUpperCase()}</strong>
        {' · '}
        {impactLabel}
        {' · '}
        drive tick + Skip
      </div>

      <div className="match-sides">
        <div className="match-side">
          <div className="muted">YOUR SQUAD</div>
          <ul className="match-roster-thumbs">
            {lineup.map((c, idx) => (
              <li key={`${c.tokenId}-${idx}`} className="match-thumb">
                <div className="match-thumb-art">
                  <img src={c.art} alt="" width={40} height={40} />
                </div>
                <div>
                  <strong>{c.name}</strong>
                  <div className="muted" style={{ fontSize: 11 }}>
                    {c.position} · OVR {cardOverall(c)}
                  </div>
                </div>
              </li>
            ))}
          </ul>
        </div>

        <div className="match-vs pixel">VS</div>

        <div className="match-side match-side-them">
          <div className="muted">CPU</div>
          <div className="match-cpu-name heavy">Neon Rivals</div>
          <div className="muted" style={{ fontSize: 13 }}>
            Soft opponent · not on-chain
          </div>
          {result && (
            <div className="muted" style={{ fontSize: 12, marginTop: 8 }}>
              Soft OVR ~{result.themOvr}
            </div>
          )}
        </div>
      </div>

      <div className="match-scoreboard" aria-live="polite">
        <div className="match-score-you pixel">{liveYou}</div>
        <div className="match-score-sep">—</div>
        <div className="match-score-them pixel">{liveThem}</div>
        <div className={`match-banner pixel match-banner-${phase}`}>{banner}</div>
      </div>

      <div className="chip-row" style={{ marginTop: 12 }}>
        <button
          type="button"
          className="btn-outline match-play-btn"
          onClick={play}
          disabled={phase === 'playing' || lineup.length === 0}
        >
          {phase === 'idle' ? 'Play match' : phase === 'playing' ? 'Sim running…' : 'Rematch'}
        </button>
        {phase === 'playing' && (
          <button type="button" className="btn-outline match-skip-btn" onClick={skip}>
            Skip
          </button>
        )}
        <Link to="/squad" className="btn-outline">
          Edit squad
        </Link>
      </div>

      <div className="match-ticker">
        <div className="match-ticker-label muted">DRIVE TICK LOG</div>
        {visible.length === 0 ? (
          <p className="muted" style={{ fontSize: 13, margin: '0.4rem 0 0' }}>
            Hit Play for a short AF drive-tick soft sim (≤90s feel). Skip jumps to Final.
          </p>
        ) : (
          <ol className="match-event-log">
            {visible.map((e, i) => (
              <li
                key={`${e.tick}-${i}-${e.text.slice(0, 12)}`}
                className={`match-event match-event-${e.side}${i === visible.length - 1 ? ' is-fresh' : ''}`}
              >
                <span className="match-quarter pixel">{e.clock}</span>
                <span>{e.text}</span>
              </li>
            ))}
          </ol>
        )}
      </div>

      {phase === 'done' && result && (
        <div className="match-result">
          <p className="muted" style={{ fontSize: 12, margin: 0 }}>
            Seed {result.seed} · {result.youScore}–{result.themScore} · soft OVR {result.youOvr} ·{' '}
            {MATCH_HONESTY}
          </p>
        </div>
      )}
    </article>
  )
}
