import { Link } from 'react-router-dom'
import { resolved, fmt } from '../data/mock'
import { SocialIcon } from '../components/Icons'

const tlIcons = [
  '/icons/flag.svg',
  '/icons/lock.svg',
  '/icons/shield.svg',
  '/icons/coin.svg',
]

export function Resolved() {
  const r = resolved
  return (
    <div>
      <div className="resolved-hero">
        <div className="glow-wrap">
          <div className="big">RESOLVED</div>
        </div>
        <div className="muted" style={{ marginTop: 8, fontSize: 13, letterSpacing: '0.14em' }}>
          PONS ARENA #{r.number}
        </div>
      </div>

      <div className="resolved-grid">
        <div className="win-card">
          <span className="winner-tag">🏆 WINNER</span>
          <h2
            className="display"
            style={{ color: 'var(--white)', margin: '2rem 0 0.75rem', fontSize: '1.45rem' }}
          >
            {r.winner}
          </h2>
          <img src="/art/icon-grad-cap.png" alt="" className="pixel-icon" width={88} height={88} />
        </div>

        <div className="outcome-center card" style={{ marginBottom: 0 }}>
          <div className="muted">Winning Outcome</div>
          <div className="heavy" style={{ color: 'var(--lime)', fontSize: '1.15rem', textShadow: 'var(--glow-lime)' }}>
            {r.winner}
          </div>
          <p style={{ color: 'var(--muted)', fontSize: 14, margin: '0.35rem 0 0.75rem' }}>{r.description}</p>
          <div className="payout">
            <img src="/icons/coin.svg" alt="" className="pixel-icon" width={28} height={28} />
            <span>
              TOTAL PAYOUT:{' '}
              <span style={{ color: 'var(--lime)' }}>+{fmt(r.payout)} USDG</span>
            </span>
          </div>
          <p className="muted" style={{ textTransform: 'none', letterSpacing: 0, marginTop: 8 }}>
            Claim your winnings in your wallet.
          </p>
        </div>

        <div className="lose-card">
          <img
            src="/art/icon-broken-heart.png"
            alt=""
            className="pixel-icon"
            width={72}
            height={72}
          />
          <h3 className="display" style={{ margin: '0.75rem 0 0.35rem', fontSize: '1.1rem' }}>
            NO GRADUATE
          </h3>
          <p style={{ margin: 0, fontSize: 13 }}>Losing side</p>
        </div>

        <aside className="share-panel">
          <h3 className="heavy" style={{ fontSize: '0.85rem', margin: 0, color: 'var(--lime)' }}>
            SHARE YOUR WIN
          </h3>
          <div className="share-preview">
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6 }}>
              <img src="/art/logo-mark.png" alt="" className="logo-mark" style={{ width: 16, height: 16 }} />
              <span className="pixel" style={{ color: 'var(--lime)', fontSize: 8 }}>
                HOOD ARENA #{r.number}
              </span>
            </div>
            <img
              src="/art/icon-share-win.png"
              alt=""
              className="share-win-art"
              width={96}
              height={96}
            />
            <div className="iwon">I WON</div>
            <div
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: 6,
                background: 'rgba(200,255,0,0.12)',
                border: '1px solid rgba(200,255,0,0.35)',
                borderRadius: 8,
                padding: '6px 10px',
                fontWeight: 800,
              }}
            >
              <img src="/icons/coin.svg" alt="" className="pixel-icon" width={18} height={18} /> +{fmt(r.payout)} USDG
            </div>
          </div>
          <div className="social-row">
            {(['x', 'discord', 'telegram', 'link'] as const).map((k) => (
              <button key={k} type="button" className="social-btn" aria-label={k}>
                <SocialIcon kind={k} />
              </button>
            ))}
          </div>
          <button type="button" className="btn-outline" style={{ width: '100%' }}>
            ↓ Download Card
          </button>
        </aside>
      </div>

      <div className="timeline-wrap">
        <h3 className="heavy">ARENA TIMELINE</h3>
        <div className="timeline">
          {r.timeline.map((t, i) => (
            <div key={t.label} className={`tl-step ${t.active ? 'active' : ''}`}>
              <div className="ico">
                <img src={tlIcons[i] ?? '/icons/shield.svg'} alt="" className="pixel-icon" width={20} height={20} />
              </div>
              <strong style={{ display: 'block', marginBottom: 4 }}>{t.label}</strong>
              <div className="muted" style={{ textTransform: 'none', letterSpacing: 0, fontSize: 11 }}>
                {t.detail}
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="action-row">
        <button type="button" className="btn-purple">
          <img src="/icons/swords.svg" alt="" className="pixel-icon" width={28} height={28} />
          <span style={{ flex: 1 }}>
            <span className="title">REMATCH</span>
            <span className="sub">Create a rematch arena with the same question.</span>
          </span>
          <span style={{ color: 'var(--purple)', fontSize: 20 }}>→</span>
        </button>
        <Link to="/" className="btn-action-lime">
          <img src="/icons/flag.svg" alt="" className="pixel-icon" width={28} height={28} />
          <span style={{ flex: 1 }}>
            <span className="title" style={{ color: 'var(--lime)' }}>
              NEXT PONS ARENA
            </span>
            <span className="sub">Explore and join the next PONS arena.</span>
          </span>
          <span style={{ color: 'var(--lime)', fontSize: 20 }}>→</span>
        </Link>
      </div>

      <p className="trust-line">
        <img src="/icons/shield.svg" alt="" className="pixel-icon" width={16} height={16} />
        Outcomes are resolved from on-chain PONS factory <code>phase == 2</code> (PoolCreated) —
        permissionless VIEW; trusted-keeper rejected. Unlock needs Reviewer + Pak.
      </p>
    </div>
  )
}
