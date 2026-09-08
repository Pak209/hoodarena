import { ModeCNav } from '../components/ModeCNav'
import { mockCards, cardOverall, POS_ICON } from '../data/mock'

const rarityClass: Record<string, string> = {
  Common: 'rarity-common',
  Rare: 'rarity-rare',
  Epic: 'rarity-epic',
  Legend: 'rarity-legend',
}

const rarityIcon: Record<string, string> = {
  Common: '/icons/rarity-common.svg',
  Rare: '/icons/rarity-rare.svg',
  Epic: '/icons/rarity-epic.svg',
  Legend: '/icons/rarity-legend.svg',
}

export function Cards() {
  return (
    <div>
      <ModeCNav />
      <div className="hero">
        <div>
          <h1 className="heavy">
            <span style={{ color: 'var(--pink)' }}>PLAYER</span> CARDS
          </h1>
          <p>AF inventory · Kit slugs neon-arm…street-pick · SPD/ARM/HND/TCK/POW</p>
        </div>
        <div className="score-box">
          <div className="label">Owned</div>
          <div className="val pixel">{String(mockCards.length).padStart(4, '0')}</div>
        </div>
      </div>

      <div className="card-grid">
        {mockCards.map((c) => (
          <article key={c.tokenId} className={`player-card ${rarityClass[c.rarity]}`}>
            <div className="pc-frame">
              <img
                src={c.art}
                alt=""
                className="pc-art"
                onError={(e) => {
                  ;(e.target as HTMLImageElement).src = '/art/hood-alpha.png'
                }}
              />
              <img src={c.frame} alt="" className="pc-frame-overlay" />
              <div className="pc-ovr pixel">{cardOverall(c)}</div>
            </div>
            <div className="pc-body">
              <div className="pc-name">{c.name}</div>
              <div className="pc-tags">
                <span className="badge">
                  <img src={POS_ICON[c.position]} alt="" className="pixel-icon" width={12} height={12} />{' '}
                  {c.position}
                </span>
                <span className={`badge ${c.rarity === 'Legend' || c.rarity === 'Epic' ? 'pink' : ''}`}>
                  <img src={rarityIcon[c.rarity]} alt="" className="pixel-icon" width={12} height={12} />{' '}
                  {c.rarity}
                </span>
              </div>
              <div className="pc-stats">
                {(
                  [
                    ['SPD', c.ratings.spd],
                    ['ARM', c.ratings.arm],
                    ['HND', c.ratings.hnd],
                    ['TCK', c.ratings.tck],
                    ['POW', c.ratings.pow],
                  ] as const
                ).map(([k, v]) => (
                  <div key={k}>
                    <span>{k}</span>
                    <strong>{v}</strong>
                  </div>
                ))}
              </div>
              <div className="muted" style={{ fontSize: 11, marginTop: 6 }}>
                #{c.tokenId} · S{c.season} · {c.slug}
              </div>
            </div>
          </article>
        ))}
      </div>
    </div>
  )
}
