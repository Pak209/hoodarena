import {
  PACK_ODDS_BPS,
  PACK_ODDS_POSITIONS,
  PACK_ODDS_RARITIES,
  assertOddsSum,
  bpsToPct,
} from '../data/packOdds'
import { POS_ICON } from '../data/mock'

export function PackOdds() {
  const ok = assertOddsSum()
  return (
    <section className="card pack-odds" aria-label="Published pack odds">
      <div className="prematch-head">
        <strong>PACK ODDS · PER POSITION</strong>
        <span className="muted" style={{ fontSize: 12 }}>
          Spec §12c · bps / 10_000 · draft until Mint publishes on-chain
        </span>
      </div>
      {!ok && (
        <p style={{ color: 'var(--pink)', fontSize: 12 }}>Odds table does not sum to 10_000 — check Spec.</p>
      )}
      <div className="odds-table-wrap">
        <table className="odds-table">
          <thead>
            <tr>
              <th>POS</th>
              {PACK_ODDS_RARITIES.map((r) => (
                <th key={r}>{r}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {PACK_ODDS_POSITIONS.map((pos) => (
              <tr key={pos}>
                <td>
                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
                    <img src={POS_ICON[pos]} alt="" className="pixel-icon" width={14} height={14} />
                    {pos}
                  </span>
                </td>
                {PACK_ODDS_RARITIES.map((r) => (
                  <td key={r}>
                    <span className="pixel" style={{ fontSize: 10 }}>
                      {bpsToPct(PACK_ODDS_BPS[pos][r])}
                    </span>
                    <div className="muted" style={{ fontSize: 10 }}>
                      {PACK_ODDS_BPS[pos][r]}
                    </div>
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p className="muted" style={{ fontSize: 12, marginTop: 10, lineHeight: 1.45 }}>
        Starter pack still guarantees one of each QB…DB (positions distinct); rarity rolls independent per card.
        No buyPack writes until Mint addresses + Reviewer.
      </p>
    </section>
  )
}
