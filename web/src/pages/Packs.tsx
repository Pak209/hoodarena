import { Link } from 'react-router-dom'
import { ModeCNav } from '../components/ModeCNav'
import { PackOdds } from '../components/PackOdds'
import { mockPack, fmt } from '../data/mock'
import { usePackOpen } from '../lib/usePackOpen'

export function Packs() {
  const { isLive, isConnected, buy, reveal, burst, msg, busy, pendingPackId, unlockBlock } =
    usePackOpen()

  return (
    <div>
      <ModeCNav />
      <div className="hero">
        <div>
          <h1 className="heavy">
            <span style={{ color: 'var(--lime)' }}>OPEN</span> PACKS
          </h1>
          <p>
            AF starter · approve → buyAndCommit → reveal · mint {mockPack.cardsPerPack} (QB…DB) ·
            feeBps={mockPack.feeBps}
          </p>
        </div>
        <div className="score-box">
          <div className="label">Mode</div>
          <div className="val pixel" style={{ fontSize: 12 }}>
            {isLive ? 'LIVE' : 'MOCK'}
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
            <img
              src="/icons/pack.svg"
              alt=""
              className="pixel-icon"
              width={14}
              height={14}
              style={{ marginRight: 6 }}
            />
            {mockPack.name}
          </div>
          <div className="muted" style={{ marginTop: 8, fontSize: 12 }}>
            UI = {mockPack.cardsPerPack} cards/pack. Prefer buyAndCommit (Reviewer: avoid Purchased sink).
          </div>
          <div className="pot-line" style={{ marginTop: 12 }}>
            <img src="/icons/coin.svg" alt="" className="pixel-icon" width={18} height={18} />
            {fmt(mockPack.priceUsdg)} USDG
          </div>
          <p className="muted" style={{ marginTop: 10, lineHeight: 1.5 }}>
            {isLive
              ? 'Live ABIs ready — Connect wallet, Buy/Commit, wait unlock, Reveal. No mainnet.'
              : 'Mock until Mint A2 drops VITE_PLAYER_CARD_ADDRESS + VITE_CARD_PACK_ADDRESS.'}
          </p>
          <div className="chip-row">
            <button type="button" className="btn-outline" disabled={busy} onClick={() => void buy()}>
              {busy ? 'Pending…' : isLive ? (isConnected ? 'Buy + Commit' : 'Connect to buy') : 'Buy / Open (mock)'}
            </button>
            {isLive && pendingPackId ? (
              <button type="button" className="btn-outline" disabled={busy} onClick={() => void reveal()}>
                Reveal #{pendingPackId}
                {unlockBlock ? ` (unlock ${unlockBlock})` : ''}
              </button>
            ) : null}
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

      <div style={{ marginTop: 16 }}>
        <PackOdds />
      </div>
    </div>
  )
}
