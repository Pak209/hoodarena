import { useState } from 'react'
import { raceLanes, fmt } from '../data/mock'
import { Sparkline } from '../components/Icons'

const hoodArtByTicker: Record<string, string> = {
  ALPHA: '/art/hood-alpha.png',
  BETA: '/art/hood-beta.png',
  GAMMA: '/art/hood-gamma.png',
}

const hoodArtFallback = ['/art/hood-alpha.png', '/art/hood-beta.png', '/art/hood-gamma.png']

function hoodSrc(ticker: string, index: number) {
  return hoodArtByTicker[ticker] ?? hoodArtFallback[index % hoodArtFallback.length]
}

export function Race() {
  const [pick, setPick] = useState(0)
  const [stake, setStake] = useState('100')

  return (
    <div>
      <div className="mode-tabs">
        <span className="chip" style={{ opacity: 0.5, pointerEvents: 'none' }}>
          MODE
        </span>
        <span className="chip">BATTLE</span>
        <span className="chip active">
          <img src="/icons/flag.svg" alt="" className="pixel-icon" width={14} height={14} style={{ marginRight: 4 }} />
          RACE
        </span>
        <span className="chip">SURVIVAL</span>
      </div>

      <div className="hero">
        <div>
          <h1 className="display" style={{ margin: 0, fontSize: 'clamp(1.8rem, 4.5vw, 2.6rem)' }}>
            <span style={{ color: 'var(--lime)', textShadow: 'var(--glow-lime)' }}>GRADUATION</span>{' '}
            <span style={{ color: 'var(--pink)', textShadow: 'var(--glow-pink)' }}>RACE</span>
          </h1>
          <p>Which PON launches first and graduates?</p>
        </div>
        <div className="win-hint">
          <img src="/art/icon-grad-cap.png" alt="" className="pixel-icon" width={40} height={40} />
          <div>
            <strong style={{ color: 'var(--lime)' }}>FACTORY PHASE FIRST GRADUATE</strong>
            <div style={{ color: 'var(--muted)', fontSize: 12 }}>
              phase==2 · earliest sweptAt
            </div>
          </div>
        </div>
      </div>

      <section className="race-board">
        {raceLanes.map((lane, i) => {
          const accent = lane.color === 'pink' ? '#FF007F' : '#C8FF00'
          const art = hoodSrc(lane.ticker, i)
          return (
            <div key={lane.ticker} className="lane">
              <div className={`lane-card ${lane.color === 'pink' ? 'pink' : ''}`}>
                <img src={art} alt="" className="art-avatar" width={48} height={48} />
                <div className="lane-meta">
                  <div className={`lane-ticker ${lane.color}`}>${lane.ticker}</div>
                  <div className={`badge ${lane.color === 'pink' ? 'pink' : ''}`} style={{ marginTop: 4 }}>
                    LIVE PON LAUNCH
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 6 }}>
                    <span className="muted" style={{ fontSize: 10 }}>
                      Curve Fill
                    </span>
                    <strong style={{ color: accent, fontSize: 12 }}>{lane.fill}%</strong>
                  </div>
                  <Sparkline pct={lane.fill} color={accent} />
                  <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>
                    TIME {lane.elapsed} · STAKE {lane.stake} USDG
                  </div>
                </div>
              </div>

              <div className="track">
                <div
                  className={`track-fill ${lane.color === 'pink' ? 'pink' : ''}`}
                  style={{ width: `${lane.fill}%`, color: accent }}
                >
                  <div className="track-runner">
                    <img src={art} alt="" className="art-avatar" width={28} height={28} />
                  </div>
                  <span className="track-pct">{lane.fill}%</span>
                </div>
              </div>

              <div className="finish-col">
                <img src="/icons/flag.svg" alt="" className="pixel-icon finish-flag" width={28} height={28} />
                <div className="finish-label">GRADUATE</div>
              </div>
            </div>
          )
        })}
      </section>

      <section className="pick-section">
        <h3 className="display" style={{ color: 'var(--lime)', fontSize: '1.1rem', margin: '0 0 0.85rem' }}>
          PICK THE WINNER
        </h3>
        <div className="pick-row">
          {raceLanes.map((lane, i) => {
            const accent = lane.color === 'pink' ? '#FF007F' : '#C8FF00'
            return (
              <button
                key={lane.ticker}
                type="button"
                className={`pick-card ${pick === i ? 'selected' : ''}`}
                onClick={() => setPick(i)}
                style={pick === i ? undefined : { borderColor: `${accent}55` }}
              >
                {pick === i && <span className="check">✓</span>}
                <img src={hoodSrc(lane.ticker, i)} alt="" className="art-avatar" width={40} height={40} />
                <div className="heavy" style={{ marginTop: 6, fontSize: '0.9rem', color: accent }}>
                  ${lane.ticker}
                </div>
                <div className="pick-mult">{lane.multiplier.toFixed(2)}x</div>
              </button>
            )
          })}
          <div className="stake-confirm">
            <div className="muted">Your Stake</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <img src="/icons/coin.svg" alt="" className="pixel-icon" width={20} height={20} />
              <input
                className="input"
                value={stake}
                onChange={(e) => setStake(e.target.value)}
                style={{ margin: 0 }}
              />
              <span style={{ fontSize: 12, color: 'var(--muted)', fontWeight: 700 }}>USDG</span>
            </div>
            <button type="button" className="btn-lime" style={{ width: '100%', marginTop: 4 }}>
              Confirm Pick →
            </button>
          </div>
        </div>
      </section>

      <footer className="footer-bar">
        <div style={{ color: 'var(--lime)', fontWeight: 700 }}>HOW IT WORKS</div>
        <div>
          Curve-fill UI is hint only. Resolve = factory <code>phase == 2</code> with earliest{' '}
          <code>sweptAt</code> then lowest address on ties; waits on Swept siblings until grace
          (permissionless). After T (+ grace if Swept pending), cancel if none reached phase 2.
        </div>
        <div style={{ color: 'var(--lime)', fontWeight: 700 }}>
          REFRESHES IN 10s · mock pot {fmt(750)} USDG
        </div>
      </footer>
    </div>
  )
}
