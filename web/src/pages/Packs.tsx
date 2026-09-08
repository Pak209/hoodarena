import { useState } from 'react'
import { Link } from 'react-router-dom'
import { ModeCNav } from '../components/ModeCNav'
import { mockPack, fmt } from '../data/mock'
import { prepareBuyPack, isLiveCards } from '../lib/cards'
import { parseUnits } from 'viem'

export function Packs() {
  const [burst, setBurst] = useState(false)
  const [msg, setMsg] = useState('')

  function onBuy() {
    const prep = prepareBuyPack(parseUnits(String(mockPack.priceUsdg), 6))
    if (prep.mode === 'mock') {
      setBurst(true)
      setMsg(prep.message)
      return
    }
    setMsg('Live buy path ready — wire wagmi write after testnet addresses.')
  }

  return (
    <div>
      <ModeCNav />
      <div className="hero">
        <div>
          <h1 className="heavy">
            <span style={{ color: 'var(--lime)' }}>OPEN</span> PACKS
          </h1>
          <p>AF starter · USDG → commit-reveal → mint {mockPack.cardsPerPack} (QB…DB) · feeBps={mockPack.feeBps}</p>
        </div>
        <div className="score-box">
          <div className="label">Mode</div>
          <div className="val pixel" style={{ fontSize: 12 }}>
            {isLiveCards ? 'LIVE' : 'MOCK'}
          </div>
        </div>
      </div>

      <article className="card pack-hero">
        <div className="pack-art-wrap">
          <img
            src={burst ? mockPack.artOpen : mockPack.artClosed}
            alt=""
            className={`pack-art ${burst ? 'burst' : ''}`}
            width={220}
            height={280}
            onError={(e) => {
              ;(e.target as HTMLImageElement).style.opacity = '0.25'
            }}
          />
          <div className="pack-placeholder pixel">{burst ? 'OPEN' : 'PACK'}</div>
        </div>
        <div className="pack-meta">
          <div className="badge">
            <img src="/icons/pack.svg" alt="" className="pixel-icon" width={14} height={14} style={{ marginRight: 6 }} />
            {mockPack.name}
          </div>
          <div className="muted" style={{ marginTop: 8, fontSize: 12 }}>
            UI copy = {mockPack.cardsPerPack} cards/pack (Mint). Foil “12” on pack art is decorative — no re-bake needed unless you want pixel-perfect.
          </div>
          <div className="pot-line" style={{ marginTop: 12 }}>
            <img src="/icons/coin.svg" alt="" className="pixel-icon" width={18} height={18} />
            {fmt(mockPack.priceUsdg)} USDG
          </div>
          <p className="muted" style={{ marginTop: 10, lineHeight: 1.5 }}>
            On-chain buy + reveal (Mint). UI stays mock until{' '}
            <code>VITE_CARD_PACK_ADDRESS</code> lands. Starter pack playable on /match immediately (Mint). Matches cosmetic — no escrow.
          </p>
          <div className="chip-row">
            <button type="button" className="btn-outline" onClick={onBuy}>
              {burst ? 'Mock open ✓' : 'Buy / Open (mock)'}
            </button>
            <Link to="/cards" className="btn-outline">
              View inventory
            </Link>
          </div>
          {msg && (
            <div className="muted" style={{ marginTop: 12, fontSize: 13 }}>
              {msg}
            </div>
          )}
        </div>
      </article>
    </div>
  )
}
