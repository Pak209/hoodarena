# Hood Arena contracts (dry)

**On-chain factory VIEW resolve** — `getLaunchedToken(token).phase == 2` (PoolCreated).
Trusted-keeper / freeform `graduatedAt` **REJECTED**. LIVE LOCKED — no broadcast.

`ponsFactory` immutable (default `0x7eD598BcEf8bd9Edd8C97A195C6d13f40801EC7e`). Tests pass `MockPonsFactory`.

**r5 CRITICAL:** Swept-NO wait before grace; YES = swept-before-T + eventually PoolCreated; race address tie-break; strand cancel+refund after grace; race waits on Swept sibling.

| Path | Role |
|------|------|
| `src/Arena.sol` | Binary YES/NO; grace-gated NO + strand escape |
| `src/GraduationRace.sol` | 3-up; earliest sweptAt + address tie-break; Swept wait |
| `src/interfaces/IPonsV2LaunchFactory.sol` | Factory VIEW ABI |
| `src/interfaces/IResolveKeeper.sol` | Permissionless resolve surface |
| `src/mocks/MockPonsFactory.sol` | setPhase / setSweptAt / exists |

```bash
forge test
```

## Mode C — Cards (Mint)

| Path | Role |
|------|------|
| `src/PlayerCard.sol` | ERC-721 unique player cards (schema Spec §6) |
| `src/CardPack.sol` | USDG buy → commit-reveal → mint 5 cards; `feeBps=100` |
| `test/CardPack.t.sol` | Pack fee / RNG commit / mint / abandon / reentrancy surface |

RNG: commit-reveal + `blockhash(commitBlock + revealDelay)` — bias documented in `CardPack` NatSpec. No mainnet broadcast.
ABIs exported to `web/src/abi/PlayerCard.json` + `CardPack.json` for Deck.
