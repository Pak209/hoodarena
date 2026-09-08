import { Link } from 'react-router-dom'
import { FEE_BPS, PONS_FACTORY } from '../data/mock'

export function How() {
  return (
    <div className="how-page">
      <p className="muted" style={{ marginBottom: 8 }}>
        <Link to="/" style={{ color: 'var(--muted)', fontWeight: 600 }}>
          ← Arenas
        </Link>
      </p>
      <h1 className="heavy how-title">HOW IT WORKS</h1>
      <p className="how-lead">
        Hood Arena is an arcade + DeFi prediction layer on Robinhood Chain (4663). You stake{' '}
        <strong>USDG</strong> on whether a <strong>PONS</strong> launch graduates — resolve reads
        the PONS factory <strong>on-chain</strong> (<code>getLaunchedToken.phase == 2</code>{' '}
        PoolCreated), not a price duel and not a trusted-keeper attestation. Pak rejected
        trusted-keeper unlock; live deploy still needs Reviewer clear + Pak unlock.
      </p>

      <div className="how-grid">
        <section className="card how-card">
          <div className="badge">MODE A</div>
          <h2 className="heavy" style={{ fontSize: '1.05rem', margin: '0.6rem 0' }}>
            ARENA — YES / NO
          </h2>
          <ol className="how-steps">
            <li>Pick a live PONS arena and a side: <strong>YES GRADUATE</strong> or <strong>NO FAIL</strong>.</li>
            <li>Approve USDG → Stake (two-step wallet UX when live).</li>
            <li>Stakes lock until resolve or cancel rules fire.</li>
            <li>
              <strong>YES</strong> when factory <code>phase == 2</code> (PoolCreated) — permissionless.
              Clock: <code>now &lt;= T</code> <strong>or</strong> (<code>sweptAt != 0 && sweptAt &lt; T</code>).
              Intentional: swept before T and eventually PoolCreated (no on-chain{' '}
              <code>poolCreatedAt</code>).
            </li>
            <li>
              <strong>NO</strong> after <code>T</code>: before grace only if{' '}
              <code>phase == 0</code> or <code>phase == 3</code> (Swept must wait). After grace,{' '}
              <code>phase != 2</code> incl. stuck Swept — permissionless.
            </li>
            <li>
              <strong>Strand escape:</strong> after <code>T + grace</code>, if <code>phase == 2</code>{' '}
              but late YES fails, anyone may cancel + refund (neither side fair).
            </li>
            <li>Winners claim pro-rata from the losing pool minus protocol fee.</li>
          </ol>
          <Link to="/stake/a1" className="btn-lime" style={{ display: 'inline-block', marginTop: 12 }}>
            Open mock stake →
          </Link>
        </section>

        <section className="card how-card">
          <div className="badge">MODE B</div>
          <h2 className="heavy" style={{ fontSize: '1.05rem', margin: '0.6rem 0' }}>
            GRADUATION RACE
          </h2>
          <ol className="how-steps">
            <li>Three live PONS launches share one race lobby.</li>
            <li>Pick <strong>one</strong> token: “which graduates first?”</li>
            <li>Approve USDG → Stake on that pick.</li>
            <li>
              Winner = race member with factory <code>phase == 2</code>; among those, earliest{' '}
              <code>sweptAt</code>, then lowest token address on ties (permissionless).
            </li>
            <li>
              If any lane is Swept (<code>phase == 1</code>) with <code>sweptAt &lt; T</code>, race
              waits until <code>T + grace</code> before crowning another graduate.
            </li>
            <li>
              If none reach <code>phase == 2</code> (after grace when a Swept sibling was pending),
              race cancels / refunds (permissionless <code>cancelRace</code>).
            </li>
            <li>Do <strong>not</strong> use price or Dexscreener rank.</li>
          </ol>
          <Link to="/race" className="btn-lime" style={{ display: 'inline-block', marginTop: 12 }}>
            Open mock race →
          </Link>
        </section>
      </div>

      <section className="card how-resolve">
        <h2 className="heavy" style={{ fontSize: '1rem', marginTop: 0 }}>
          RESOLVE — PONS factory phase on-chain
        </h2>
        <p style={{ color: 'var(--muted)', fontSize: 14, lineHeight: 1.55 }}>
          Contracts call <code>getLaunchedToken(token)</code> on the PONS V2 factory. Docs say{' '}
          <strong>phase is authoritative</strong> — do not treat <code>PoolGraduated</code> event
          decode as proof. Unlock still requires Reviewer clear + Pak unlock; trusted-keeper model
          was rejected.
        </p>
        <dl className="how-dl">
          <div>
            <dt>Factory (ponsFactory)</dt>
            <dd>
              <code>{PONS_FACTORY}</code>
            </dd>
          </div>
          <div>
            <dt>YES unlock</dt>
            <dd>
              <code>phase == 2</code> (PoolCreated)
            </dd>
          </div>
          <div>
            <dt>YES clock</dt>
            <dd>
              <code>phase == 2</code> AND (<code>now &lt;= T</code> OR{' '}
              <code>sweptAt != 0 && sweptAt &lt; T</code>) — swept before T + eventually PoolCreated
            </dd>
          </div>
          <div>
            <dt>NO / grace</dt>
            <dd>
              Before <code>T + grace</code>: only phase 0/3. After grace: phase != 2 (stuck Swept OK).
              Strand: cancel+refund after grace if phase==2 but late YES fails.
            </dd>
          </div>
          <div>
            <dt>feeBps (locked)</dt>
            <dd>
              <code>{FEE_BPS}</code> ({FEE_BPS / 100}%) — immutable at deploy; max 1000 in code
            </dd>
          </div>
          <div>
            <dt>Permissionless</dt>
            <dd>
              Anyone may <code>resolveArenaYes</code> / <code>resolveArenaNo</code> /{' '}
              <code>resolveRace</code> / <code>cancelRace</code> when factory gates pass. Keepers
              only lock staking early.
            </dd>
          </div>
          <div>
            <dt>USDG</dt>
            <dd>
              Mainnet CA via <code>VITE_USDG_ADDRESS</code> / Spec lock — never invent; do not mix
              testnet
            </dd>
          </div>
        </dl>
      </section>

      <p className="trust-line" style={{ marginTop: 1.5 }}>
        <img src="/icons/shield.svg" alt="" className="pixel-icon" width={16} height={16} />
        Factory phase VIEW · dry package only — no live stakes, no deploy. CA glance ≠ full auditor.
      </p>
    </div>
  )
}
