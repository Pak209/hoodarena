import { Link, useLocation } from 'react-router-dom'

const chips = [
  { to: '/packs', label: 'PACKS' },
  { to: '/cards', label: 'CARDS' },
  { to: '/squad', label: 'SQUAD' },
  { to: '/match', label: 'MATCH' },
] as const

export function ModeCNav() {
  const { pathname } = useLocation()
  return (
    <div className="mode-tabs mode-c-tabs" aria-label="Mode C Cards">
      <span className="chip mode-c-label">MODE C</span>
      {chips.map((c) => (
        <Link
          key={c.to}
          to={c.to}
          className={`chip ${pathname === c.to || pathname.startsWith(c.to) ? 'active' : ''}`}
        >
          {c.label}
        </Link>
      ))}
      <span className="chip mode-c-soft">COSMETIC MATCH · NO ESCROW</span>
    </div>
  )
}
