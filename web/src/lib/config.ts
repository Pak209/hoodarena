/** Chain + contract config — mock-first when addresses empty. */
export const CHAIN_ID = Number(import.meta.env.VITE_CHAIN_ID || 4663)
export const RPC_URL =
  import.meta.env.VITE_RPC_URL || 'https://rpc.mainnet.chain.robinhood.com'
export const PONS_FACTORY = (import.meta.env.VITE_PONS_FACTORY ||
  '0x7eD598BcEf8bd9Edd8C97A195C6d13f40801EC7e') as `0x${string}`
export const USDG_ADDRESS = (import.meta.env.VITE_USDG_ADDRESS ||
  '0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168') as `0x${string}`
export const ARENA_ADDRESS = (import.meta.env.VITE_ARENA_ADDRESS || '') as `0x${string}` | ''
export const RACE_ADDRESS = (import.meta.env.VITE_RACE_ADDRESS || '') as `0x${string}` | ''
export const PLAYER_CARD_ADDRESS = (import.meta.env.VITE_PLAYER_CARD_ADDRESS || '') as `0x${string}` | ''
export const CARD_PACK_ADDRESS = (import.meta.env.VITE_CARD_PACK_ADDRESS || '') as `0x${string}` | ''
export const FEE_BPS = 100

/** True when live contract addresses are configured; otherwise UI stays on mock data. */
export const isLiveContracts = Boolean(ARENA_ADDRESS && ARENA_ADDRESS.length === 42)
/** Mode C PlayerCard reads — address alone enables inventory (no buyPack required). */
export const isLivePlayerCard = Boolean(PLAYER_CARD_ADDRESS && PLAYER_CARD_ADDRESS.length === 42)
/** Mode C pack writes — need both PlayerCard + CardPack addresses. */
export const isLiveCards = Boolean(isLivePlayerCard && CARD_PACK_ADDRESS && CARD_PACK_ADDRESS.length === 42)

export const robinhoodChain = {
  id: CHAIN_ID,
  name: 'Robinhood Chain',
  nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
  rpcUrls: { default: { http: [RPC_URL] } },
} as const
