/** Pixel/arcade SVG sprites for Hood Arena */

type IconProps = { size?: number; className?: string; color?: string }

export function PixelAlien({ size = 28, className, color = '#C8FF00' }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" className={className} shapeRendering="crispEdges" aria-hidden>
      <rect x="4" y="2" width="8" height="2" fill={color} />
      <rect x="2" y="4" width="12" height="2" fill={color} />
      <rect x="2" y="6" width="2" height="4" fill={color} />
      <rect x="12" y="6" width="2" height="4" fill={color} />
      <rect x="4" y="6" width="2" height="2" fill="#0D0D0D" />
      <rect x="10" y="6" width="2" height="2" fill="#0D0D0D" />
      <rect x="6" y="6" width="4" height="4" fill={color} />
      <rect x="4" y="10" width="2" height="2" fill={color} />
      <rect x="10" y="10" width="2" height="2" fill={color} />
      <rect x="2" y="12" width="2" height="2" fill={color} />
      <rect x="12" y="12" width="2" height="2" fill={color} />
    </svg>
  )
}

export function HoodAvatar({
  size = 56,
  accent = '#C8FF00',
  eyes = 'x' as 'x' | 'dot',
  className,
}: {
  size?: number
  accent?: string
  eyes?: 'x' | 'dot'
  className?: string
}) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64" className={className} aria-hidden>
      <defs>
        <filter id={`glow-${accent.replace('#', '')}`} x="-40%" y="-40%" width="180%" height="180%">
          <feDropShadow dx="0" dy="0" stdDeviation="2.5" floodColor={accent} floodOpacity="0.85" />
        </filter>
      </defs>
      <circle cx="32" cy="32" r="30" fill="#141414" stroke={accent} strokeWidth="3" filter={`url(#glow-${accent.replace('#', '')})`} />
      {/* hood */}
      <path d="M14 40 C14 18 50 18 50 40 L50 52 C50 56 14 56 14 52 Z" fill="#1a1a1a" stroke={accent} strokeWidth="1.5" />
      <path d="M18 38 C20 24 44 24 46 38 L44 48 C40 52 24 52 20 48 Z" fill="#0a0a0a" />
      {/* face */}
      <ellipse cx="32" cy="38" rx="10" ry="11" fill="#1e1e1e" />
      {eyes === 'x' ? (
        <>
          <path d="M24 34 L28 38 M28 34 L24 38" stroke={accent} strokeWidth="2.2" strokeLinecap="round" />
          <path d="M36 34 L40 38 M40 34 L36 38" stroke={accent} strokeWidth="2.2" strokeLinecap="round" />
        </>
      ) : (
        <>
          <circle cx="26" cy="36" r="2.2" fill={accent} />
          <circle cx="38" cy="36" r="2.2" fill={accent} />
        </>
      )}
      <path d="M28 44 Q32 47 36 44" stroke={accent} strokeWidth="1.5" fill="none" opacity="0.5" />
    </svg>
  )
}

export function CrossedSwords({ size = 22, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" className={className} aria-hidden>
      <g stroke="#E8E8E8" strokeWidth="2" fill="none" strokeLinecap="round">
        <path d="M5 19 L19 5" />
        <path d="M15 5 L19 5 L19 9" />
        <path d="M5 15 L5 19 L9 19" />
        <path d="M19 19 L5 5" />
        <path d="M9 5 L5 5 L5 9" />
        <path d="M19 15 L19 19 L15 19" />
      </g>
      <circle cx="12" cy="12" r="2" fill="#C8FF00" />
    </svg>
  )
}

export function PixelTrophy({ size = 28, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" className={className} shapeRendering="crispEdges" aria-hidden>
      <rect x="6" y="1" width="4" height="2" fill="#D4AF37" />
      <rect x="4" y="3" width="8" height="5" fill="#E8C547" />
      <rect x="2" y="4" width="2" height="3" fill="#D4AF37" />
      <rect x="12" y="4" width="2" height="3" fill="#D4AF37" />
      <rect x="7" y="8" width="2" height="3" fill="#C8A032" />
      <rect x="5" y="11" width="6" height="2" fill="#D4AF37" />
      <rect x="4" y="13" width="8" height="2" fill="#E8C547" />
    </svg>
  )
}

export function GradCap({ size = 72, className, color = '#C8FF00' }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 96 72" className={className} aria-hidden>
      <polygon points="48,8 88,28 48,48 8,28" fill="#F5F5F5" stroke={color} strokeWidth="2" />
      <rect x="28" y="28" width="40" height="18" fill="#E8E8E8" />
      <path d="M28 46 Q48 56 68 46" fill="#D0D0D0" />
      <line x1="72" y1="28" x2="72" y2="52" stroke={color} strokeWidth="3" />
      <circle cx="72" cy="54" r="5" fill={color} />
      <ellipse cx="48" cy="58" rx="22" ry="6" fill={color} opacity="0.35" />
    </svg>
  )
}

export function BrokenHeart({ size = 56, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64" className={className} aria-hidden>
      <path
        d="M32 54 C12 40 8 26 16 18 C22 12 30 14 32 20 C34 14 42 12 48 18 C56 26 52 40 32 54 Z"
        fill="#3a3a3a"
        stroke="#888"
        strokeWidth="2"
      />
      <path d="M30 22 L34 30 L28 36 L36 44" stroke="#FF007F" strokeWidth="2.5" fill="none" opacity="0.7" />
    </svg>
  )
}

export function CoinG({ size = 22, className }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" className={className} aria-hidden>
      <circle cx="12" cy="12" r="11" fill="#C8FF00" />
      <circle cx="12" cy="12" r="8" fill="#0D0D0D" stroke="#A3E635" strokeWidth="1.5" />
      <text x="12" y="16" textAnchor="middle" fontSize="11" fontWeight="800" fill="#C8FF00" fontFamily="Inter,sans-serif">
        G
      </text>
    </svg>
  )
}

export function CheckeredFlag({ size = 18, className }: IconProps) {
  const cells = []
  for (let y = 0; y < 4; y++) {
    for (let x = 0; x < 6; x++) {
      if ((x + y) % 2 === 0) cells.push(<rect key={`${x}-${y}`} x={x * 3} y={y * 3} width="3" height="3" fill="#C8FF00" />)
    }
  }
  return (
    <svg width={size} height={(size * 12) / 18} viewBox="0 0 18 12" className={className} aria-hidden>
      {cells}
    </svg>
  )
}

export function PixelQuestion({ size = 56, ring = '#C8FF00', className }: { size?: number; ring?: string; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64" className={className} shapeRendering="crispEdges" aria-hidden>
      <circle cx="32" cy="32" r="30" fill="#121212" stroke={ring} strokeWidth="4" />
      <rect x="22" y="14" width="20" height="6" fill={ring} />
      <rect x="36" y="20" width="6" height="10" fill={ring} />
      <rect x="28" y="28" width="8" height="8" fill={ring} />
      <rect x="28" y="42" width="8" height="8" fill={ring} />
    </svg>
  )
}

export function TugSquad({ side, className }: { side: 'yes' | 'no'; className?: string }) {
  const c = side === 'yes' ? '#C8FF00' : '#FF007F'
  return (
    <svg viewBox="0 0 180 100" className={className} width="100%" height="100" aria-hidden>
      {[0, 1, 2].map((i) => {
        const x = 20 + i * 42
        return (
          <g key={i} transform={`translate(${x},10)`}>
            <ellipse cx="22" cy="78" rx="16" ry="6" fill={c} opacity="0.25" />
            <path d="M8 70 C8 30 36 30 36 70 Z" fill="#161616" stroke={c} strokeWidth="2" />
            <ellipse cx="22" cy="48" rx="10" ry="12" fill="#0c0c0c" />
            <circle cx="17" cy="46" r="2" fill={c} />
            <circle cx="27" cy="46" r="2" fill={c} />
            <path d="M4 55 L-6 62" stroke={c} strokeWidth="3" strokeLinecap="round" />
            <path d="M40 55 L50 62" stroke={c} strokeWidth="3" strokeLinecap="round" />
          </g>
        )
      })}
      <line
        x1={side === 'yes' ? 10 : 20}
        y1="68"
        x2={side === 'yes' ? 160 : 170}
        y2="68"
        stroke={c}
        strokeWidth="4"
        strokeLinecap="round"
        opacity="0.9"
      />
    </svg>
  )
}

export function Sparkline({ pct, color = '#C8FF00' }: { pct: number; color?: string }) {
  const pts = [8, 18, 14, 28, 22, 35, 30, Math.max(8, Math.min(38, pct * 0.4))]
  const d = pts.map((y, i) => `${i === 0 ? 'M' : 'L'}${i * 12},${40 - y}`).join(' ')
  return (
    <svg width="96" height="28" viewBox="0 0 96 40" aria-hidden>
      <path d={`${d} L84 40 L0 40 Z`} fill={color} opacity="0.25" />
      <path d={d} fill="none" stroke={color} strokeWidth="2" />
    </svg>
  )
}

export function SocialIcon({ kind }: { kind: 'x' | 'discord' | 'telegram' | 'link' }) {
  const paths: Record<string, string> = {
    x: 'M6 6 L18 18 M18 6 L6 18',
    discord: 'M7 9 C9 6 15 6 17 9 L18 16 C16 18 8 18 6 16 Z M10 12 h0.01 M14 12 h0.01',
    telegram: 'M5 12 L19 6 L15 18 L11 13 Z',
    link: 'M9 12 H15 M8 9 H11 M13 15 H16',
  }
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" aria-hidden>
      <path d={paths[kind]} stroke="#aaa" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}
