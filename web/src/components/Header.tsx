import { Link, useLocation } from 'react-router-dom'
import { useAccount, useConnect, useDisconnect } from 'wagmi'
import { CHAIN_ID, mockBalance, fmt } from '../data/mock'
import { shortAddr } from '../lib/inventory'
import { CoinG } from './Icons'

const arenaLinks = [
  { to: '/', label: 'Arenas' },
  { to: '/stake/a1', label: 'Stake' },
  { to: '/resolved', label: 'Resolved' },
  { to: '/race', label: 'Race' },
  { to: '/how', label: 'How' },
]

const modeCLinks = [
  { to: '/packs', label: 'Packs' },
  { to: '/cards', label: 'Cards' },
  { to: '/squad', label: 'Squad' },
  { to: '/match', label: 'Match' },
]

function isActive(pathname: string, to: string) {
  if (to === '/') return pathname === '/'
  return pathname === to || pathname.startsWith(to)
}

export function Header() {
  const { pathname } = useLocation()
  const { address, isConnected } = useAccount()
  const { connect, connectors, isPending } = useConnect()
  const { disconnect } = useDisconnect()
  const injected = connectors.find((c) => c.id === 'injected') ?? connectors[0]

  function onWalletClick() {
    if (isConnected) {
      disconnect()
      return
    }
    if (injected) connect({ connector: injected })
  }

  return (
    <header className="header">
      <Link to="/" className="logo">
        <img src="/art/logo-mark.png" alt="" className="logo-mark" />
        HOOD <span className="arena">ARENA</span>
      </Link>
      <nav className="nav">
        {arenaLinks.map((l) => (
          <Link key={l.to} to={l.to} className={isActive(pathname, l.to) ? 'active' : ''}>
            {l.label}
          </Link>
        ))}
        <span className="nav-sep" aria-hidden>
          |
        </span>
        {modeCLinks.map((l) => (
          <Link
            key={l.to}
            to={l.to}
            className={`mode-c-link ${isActive(pathname, l.to) ? 'active' : ''}`}
          >
            {l.label}
          </Link>
        ))}
      </nav>
      <div className="wallet-row">
        <div className="pill">
          <span className="dot" /> PONS
        </div>
        <div className="pill">
          <CoinG size={16} />
          <strong>{fmt(mockBalance)} USDG</strong>
          <span style={{ color: 'var(--lime)', fontWeight: 800 }}>+</span>
        </div>
        <div className="pill">
          <span className="dot" /> CHAIN {CHAIN_ID}
        </div>
        <div className="avatar-pill">
          <img src="/art/hood-alpha.png" alt="" className="art-avatar" width={28} height={28} />
          <span>{isConnected && address ? shortAddr(address) : '0xHood…Arena'}</span>
        </div>
        <button
          type="button"
          className="btn-connect"
          onClick={onWalletClick}
          disabled={isPending && !isConnected}
        >
          <img src="/icons/wallet.svg" alt="" className="pixel-icon" width={18} height={18} />
          {isConnected ? 'Disconnect' : isPending ? 'Connecting…' : 'Connect Wallet'}
        </button>
      </div>
    </header>
  )
}
