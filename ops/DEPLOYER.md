# Deployer wallet runbook

**TESTNET UNLOCKED (2026-09-06).** Pak said: `UNLOCK HOOD ARENA BROADCAST testnet 46630`.

**MAINNET STILL LOCKED.** No `--broadcast` to chain `4663` until a separate unlock names mainnet.

## Wallet policy

| Rule | Detail |
|------|--------|
| Dedicated gas wallet | Separate EOA used only for deploy / keeper gas — not a user custody wallet |
| Asset | **ETH only** for gas on Robinhood Chain |
| Never | Store, receive, or custody **user USDG** in the bot/deployer wallet |
| Keys | Operator keeps the private key offline / in their own secret store — **never commit keys to this repo or write them under `/workspace/rh-build/`** |

## Create a wallet locally (operator machine)

Run on **your** laptop (not in shared agent scratch if avoidable):

```bash
cast wallet new
```

- Copy the address into your password manager / ops notes.  
- Store the private key in a local encrypted secret manager (1Password, age, etc.).  
- **Do not** paste the private key into chat, `.env` in-repo, git, or CI logs.  
- Fund with a small amount of ETH for gas only when unlock is near.

Optional check (address only):

```bash
cast wallet address --private-key <PASTE_ONLY_IN_LOCAL_SHELL_HISTORY_YOU_CONTROL>
```

Prefer hardware wallet / `cast wallet` interactive import over files in the monorepo.

## Dry deploy sketch (allowed now)

```bash
export PATH="$PATH:$HOME/.foundry/bin"
cd /workspace/rh-build/hood-arena/contracts
forge script script/DeploySketch.s.sol
# NEVER add --broadcast until unlocked
```

Constructor sketch: USDG mainnet `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168`, `feeBps=100`, fee recipient = treasury multisig (TBD).

Testnet USDG (never mix): `0x7E955252E15c84f5768B83c41a71F9eba181802F` on chain `46630`.

## Unlock phrase (required before any `--broadcast`)

Broadcast / live deploy is forbidden unless Pak (or designated owner) explicitly says:

> **`UNLOCK HOOD ARENA BROADCAST`**

plus names the target (**testnet `46630`** or **mainnet `4663`**).

Until that exact unlock:

- No `forge script ... --broadcast`  
- No `cast send` to create Arena/Race  
- No keeper auto-send  
- Dry-only: `forge test`, anvil fork, print scripts, `--dry-resolve`

If unlock is revoked, treat as locked again immediately.


## Testnet broadcast (46630 only)

PONS mainnet factory is **not** on testnet. Deploy deploys `MockPonsFactory` + `Arena` + `GraduationRace` with testnet USDG.

```bash
export PATH="$PATH:$HOME/.foundry/bin"
cd /workspace/rh-build/hood-arena/contracts
# PRIVATE_KEY from operator secret store — never commit
forge script script/DeployTestnet.s.sol:DeployTestnet \
  --rpc-url https://rpc.testnet.chain.robinhood.com \
  --broadcast \
  --chain-id 46630
```

Record addresses into `ops/TESTNET_ADDRESSES.md` and `web/.env.testnet` after success.
Fee recipient / owner / keeper = deployer EOA for smoke (swap to multisig before mainnet).
