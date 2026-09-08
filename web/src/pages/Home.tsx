import { Link } from 'react-router-dom'
import { arenas, fmt } from '../data/mock'

const ringArt = {
  lime: '/art/icon-q-lime.png',
  pink: '/art/icon-q-pink.png',
  teal: '/art/icon-q-teal.png',
} as const

export function Home() {
  return (
    <div>
      <div className="mode-tabs" style={{ marginBottom: 8 }}>
        <span className="chip active">ARENA</span>
        <Link to="/race" className="chip">
          RACE
        </Link>
        <Link to="/packs" className="chip mode-c-chip">
          CARDS
        </Link>
      </div>

      <div className="hero">
        <div>
          <h1 className="heavy">
            <span style={{ color: 'var(--lime)' }}>LIVE</span> PONS ARENAS
          </h1>
          <p>Predict. Play. Power PONS.</p>
        </div>
        <div className="score-box">
          <div className="label">PONS Score</div>
          <div className="val pixel">
            0025{' '}
            <img src="/icons/trophy.svg" alt="" className="pixel-icon" width={26} height={26} />
          </div>
        </div>
      </div>

      {arenas.map((a) => (
        <article key={a.id} className="card arena-card">
          <div className="arena-left">
            <img
              src={ringArt[a.ring]}
              alt=""
              className="art-avatar arena-q-art"
              width={64}
              height={64}
            />
            <div>
              <div className="arena-q">{a.question}</div>
              <div className="muted" style={{ marginTop: 10, display: 'flex', alignItems: 'center', gap: 6 }}>
                <img src="/icons/clock.svg" alt="" className="pixel-icon" width={14} height={14} />
                Time Remaining
              </div>
              <div className="timer pixel">{a.timeRemaining}</div>
            </div>
          </div>

          <div className="tug-wrap">
            <div className="muted">Total Pot</div>
            <div className="pot-line">
              <img src="/icons/coin.svg" alt="" className="pixel-icon" width={18} height={18} />
              {fmt(a.yesPool + a.noPool)} USDG
            </div>
            <div className="tug-stats">
              <span className="y">YES {a.yesPct}%</span>
              <span className="n">NO {a.noPct}%</span>
            </div>
            <div className="tug">
              <div className="yes" style={{ width: `${a.yesPct}%` }} />
              <div className="no" style={{ width: `${a.noPct}%` }} />
              <div className="tug-swords" style={{ left: `${a.yesPct}%` }}>
                <img src="/icons/swords.svg" alt="" className="pixel-icon" width={16} height={16} />
              </div>
            </div>
            <div className="tug-stats" style={{ fontWeight: 600, fontSize: '0.75rem', opacity: 0.85 }}>
              <span className="y">{fmt(a.yesPool)} USDG</span>
              <span className="n">{fmt(a.noPool)} USDG</span>
            </div>
          </div>

          <div style={{ textAlign: 'right' }}>
            <div className="muted" style={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: 6 }}>
              <img src="/icons/players.svg" alt="" className="pixel-icon" width={14} height={14} />
              Players
            </div>
            <div style={{ fontWeight: 800, marginBottom: 10, fontSize: '1.05rem' }}>{fmt(a.players)}</div>
            <Link to={`/stake/${a.id}`} className="btn-outline">
              Play Now
            </Link>
            <div className="muted" style={{ marginTop: 8 }}>
              Predict YES or NO
            </div>
          </div>
        </article>
      ))}

      <footer className="footer-bar">
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <img src="/icons/flag.svg" alt="" className="pixel-icon" width={20} height={20} />
          <span>
            RESOLVE = PONS factory <code>phase == 2</code> (PoolCreated) on-chain
          </span>
        </div>
        <div>
          Permissionless VIEW resolve — trusted-keeper rejected. Unlock needs Reviewer + Pak.
        </div>
        <div>
          <a href="https://pons.fun" target="_blank" rel="noreferrer">
            Learn more ↗
          </a>
        </div>
      </footer>
    </div>
  )
}
