import { useMemo, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { useWriteContract } from 'wagmi'
import { arenas, fmt, mockBalance, PONS_FACTORY } from '../data/mock'
import { isLiveContracts } from '../lib/config'
import { prepareStakeWrites } from '../lib/contracts'

export function Stake() {
  const { id } = useParams()
  const arena = useMemo(() => arenas.find((a) => a.id === id) ?? arenas[0], [id])
  const [side, setSide] = useState<'YES' | 'NO'>('YES')
  const [amount, setAmount] = useState('25')
  const [approved, setApproved] = useState(false)
  const [statusMsg, setStatusMsg] = useState<string | null>(null)
  const { writeContractAsync, isPending } = useWriteContract()

  const arenaIdBig = useMemo(() => {
    // mock ids are strings like a1 — live would use numeric on-chain id from env/query
    const n = Number(String(id || '').replace(/\D/g, '')) || 1
    return BigInt(n)
  }, [id])

  async function onApprove() {
    const prep = prepareStakeWrites({
      arenaId: arenaIdBig,
      yes: side === 'YES',
      amountUsdg: amount,
    })
    if (prep.mode === 'mock') {
      setApproved(true)
      setStatusMsg(prep.message)
      return
    }
    try {
      await writeContractAsync(prep.approve)
      setApproved(true)
      setStatusMsg('USDG approved')
    } catch (e) {
      setStatusMsg(e instanceof Error ? e.message : 'Approve failed')
    }
  }

  async function onStake() {
    const prep = prepareStakeWrites({
      arenaId: arenaIdBig,
      yes: side === 'YES',
      amountUsdg: amount,
    })
    if (prep.mode === 'mock') {
      setStatusMsg('Mock mode — stake no-op (set VITE_ARENA_ADDRESS)')
      return
    }
    try {
      await writeContractAsync(prep.stake)
      setStatusMsg('Stake submitted')
    } catch (e) {
      setStatusMsg(e instanceof Error ? e.message : 'Stake failed')
    }
  }

  return (
    <div>
      {!isLiveContracts && (
        <div className="banner-warn" style={{ marginBottom: 12 }} role="status">
          <span>◎</span>
          <span>
            <strong>Mock mode</strong> — no VITE_ARENA_ADDRESS. Approve→Stake are no-ops until
            contracts are configured. LIVE LOCKED.
          </span>
        </div>
      )}
      <div style={{ marginBottom: 12 }}>
        <Link to="/" style={{ color: 'var(--muted)', fontSize: 13, fontWeight: 600 }}>
          ← Arenas
        </Link>
      </div>
      <div className="layout-2">
        <section className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span className="badge">◈ PONS</span>
            <span style={{ color: 'var(--lime)', fontWeight: 700, fontSize: 13, display: 'inline-flex', alignItems: 'center', gap: 6 }}>
              <img src="/icons/clock.svg" alt="" className="pixel-icon" width={14} height={14} />
              ENDS IN {arena.timeRemaining}
            </span>
          </div>
          <h1 className="heavy stake-hero-title">
            WILL THIS <span className="pons">PONS</span> LAUNCH GRADUATE?
          </h1>
          <p className="muted" style={{ textTransform: 'none', letterSpacing: 0, fontSize: 13, lineHeight: 1.5 }}>
            This market resolves to YES when the PONS factory reports{' '}
            <code>getLaunchedToken</code> <code>phase == 2</code> (PoolCreated) for $
            {arena.ticker} — permissionless on-chain VIEW.
          </p>

          <div className="hero-art-wrap">
            <img src="/art/tug-hero.png" alt="" className="hero-art" />
          </div>

          <div className="vs-art">
            <div className="side-panel yes">
              <img src="/icons/swords.svg" alt="" className="pixel-icon" width={48} height={48} />
              <div className="side-label side-yes">YES GRADUATE</div>
              <div className="side-yes" style={{ fontWeight: 700, marginTop: 4 }}>
                ODDS {arena.yesPct}%
              </div>
              <div style={{ color: 'var(--muted)', fontSize: 13, display: 'inline-flex', alignItems: 'center', gap: 4, justifyContent: 'center' }}>
                <img src="/icons/coin.svg" alt="" className="pixel-icon" width={14} height={14} />
                ${fmt(arena.yesPool)}
              </div>
            </div>
            <div className="vs-badge">
              <img src="/icons/swords.svg" alt="" className="pixel-icon" width={22} height={22} />
            </div>
            <div className="side-panel no">
              <img src="/icons/shield.svg" alt="" className="pixel-icon" width={48} height={48} />
              <div className="side-label side-no">NO FAIL</div>
              <div className="side-no" style={{ fontWeight: 700, marginTop: 4 }}>
                ODDS {arena.noPct}%
              </div>
              <div style={{ color: 'var(--muted)', fontSize: 13, display: 'inline-flex', alignItems: 'center', gap: 4, justifyContent: 'center' }}>
                <img src="/icons/coin.svg" alt="" className="pixel-icon" width={14} height={14} />
                ${fmt(arena.noPool)}
              </div>
            </div>
          </div>

          <div className="tug fat">
            <div className="yes" style={{ width: `${arena.yesPct}%` }} />
            <div className="no" style={{ width: `${arena.noPct}%` }} />
            <div className="vs-mid">VS</div>
          </div>
          <div style={{ textAlign: 'center', marginTop: 14 }}>
            <div className="heavy" style={{ fontSize: '1.25rem', display: 'inline-flex', alignItems: 'center', gap: 8 }}>
              <img src="/icons/coin.svg" alt="" className="pixel-icon" width={22} height={22} />
              TOTAL POT ${fmt(arena.yesPool + arena.noPool)}
            </div>
            <div className="muted" style={{ marginTop: 4 }}>
              {fmt(arena.players)} bettors
            </div>
          </div>

          <div className="info-grid">
            <div className="info-box">
              <div className="ibox-title">🎯 Resolution Source</div>
              Factory VIEW <code>phase == 2</code> at{' '}
              {PONS_FACTORY.slice(0, 10)}… (on-chain VIEW)
            </div>
            <div className="info-box">
              <div className="ibox-title" style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <img src="/icons/shield.svg" alt="" className="pixel-icon" width={16} height={16} />
                Factory phase
              </div>
              Stakes on-chain; resolve reads factory phase (feeBps only, no house edge).
            </div>
          </div>
        </section>

        <aside className="card">
          <h2 className="heavy" style={{ fontSize: '0.95rem', marginTop: 0 }}>
            STAKE ON OUTCOME
          </h2>
          <div className="chip-row">
            <button
              type="button"
              className={`chip ${side === 'YES' ? 'active' : ''}`}
              onClick={() => setSide('YES')}
            >
              ● YES GRADUATE
            </button>
            <button
              type="button"
              className={`chip ${side === 'NO' ? 'pink-active' : ''}`}
              onClick={() => setSide('NO')}
            >
              ● NO FAIL
            </button>
          </div>

          <div className="muted">Stake Amount (USDG)</div>
          <div style={{ fontSize: 12, color: 'var(--muted)', margin: '4px 0 8px' }}>
            BALANCE: {fmt(mockBalance)} USDG
          </div>
          <input
            className="input"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            inputMode="decimal"
          />
          <div className="chip-row">
            {['5', '25', '100', 'MAX'].map((c) => (
              <button
                key={c}
                type="button"
                className={`chip ${
                  amount === c || (c === 'MAX' && amount === String(mockBalance)) ? 'active' : ''
                }`}
                onClick={() => setAmount(c === 'MAX' ? String(mockBalance) : c)}
              >
                {c}
              </button>
            ))}
          </div>

          <div className="step-block">
            <div className="muted">Step 1 — Approve USDG</div>
            <button
              type="button"
              className="btn-lime"
              style={{ width: '100%', marginTop: 8 }}
              onClick={() => void onApprove()}
              disabled={approved || isPending}
            >
              {approved ? 'Approved ✓' : isPending ? 'Pending…' : 'Approve'}
            </button>
          </div>
          <div className="step-arrow">↓</div>
          <div className="step-block">
            <div className="muted">Step 2 — Stake on {side}</div>
            <button
              type="button"
              className="btn-lime"
              style={{ width: '100%', marginTop: 8 }}
              disabled={!approved || isPending}
              onClick={() => void onStake()}
            >
              Stake
            </button>
          </div>

          {statusMsg && (
            <p className="muted" style={{ textTransform: 'none', fontSize: 12, marginTop: 8 }}>
              {statusMsg}
            </p>
          )}

          <div className="trade-details">
            YOU WILL RECEIVE: <strong>0.00 {side}</strong>
            <br />
            YOUR ODDS:{' '}
            <span className="hl">{side === 'YES' ? arena.yesPct : arena.noPct}%</span>
            <br />
            POT SHARE: —
            <br />
            PRICE IMPACT: —
          </div>

          <div className="ca-safety-strip" role="note">
            <div className="ca-safety-head">
              <img src="/icons/shield.svg" alt="" className="pixel-icon" width={18} height={18} />
              <span className="ca-safety-title">SCAN CABINET — CA GLANCE</span>
              <span className="ca-safety-soft">not an auditor</span>
            </div>
            <div className="ca-safety-rows">
              <div>
                <span className="ca-k">Token CA</span>
                <code className="ca-v">{arena.token}</code>
              </div>
              <div>
                <span className="ca-k">PONS factory</span>
                <code className="ca-v">{PONS_FACTORY}</code>
              </div>
              <div>
                <span className="ca-k">Resolve</span>
                <span className="ca-v">
                  Factory phase==2 VIEW · permissionless · trusted-keeper rejected
                </span>
              </div>
            </div>
            <p className="ca-safety-note">
              Soft glance for factory membership / resolve source —{' '}
              <strong>not a full security audit</strong>. Always verify on explorer before live stakes.
              {' '}
              <a
                href={`https://robinhoodchain.blockscout.com/address/${PONS_FACTORY}`}
                target="_blank"
                rel="noreferrer"
              >
                VIEW FACTORY ↗
              </a>
            </p>
          </div>

          <button
            type="button"
            className="btn-lime"
            style={{ width: '100%' }}
            disabled={!approved || isPending}
            onClick={() => void onStake()}
          >
            Confirm Stake
          </button>
          <p className="muted" style={{ textTransform: 'none', marginTop: 10, letterSpacing: 0, fontSize: 12 }}>
            {isLiveContracts
              ? 'Live wiring enabled — wallet must be on chain 4663.'
              : 'Mock mode — no wallet required. By confirming you agree to the terms of use.'}
          </p>
        </aside>
      </div>
      <div className="banner-warn">
        <span>⚠</span>
        <span>
          Bet responsibly. Only risk what you can afford to lose. HOOD ARENA is a permissionless
          protocol. <a href="#terms" style={{ color: 'var(--pink)', fontWeight: 700 }}>terms</a>
        </span>
      </div>
    </div>
  )
}
