import { http, createConfig } from 'wagmi'
import { injected } from 'wagmi/connectors'
import { defineChain } from 'viem'
import { CHAIN_ID, RPC_URL } from './config'

const robinhood = defineChain({
  id: CHAIN_ID,
  name: 'Robinhood Chain',
  nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
  rpcUrls: { default: { http: [RPC_URL] } },
})

export const wagmiConfig = createConfig({
  chains: [robinhood],
  connectors: [injected()],
  transports: { [robinhood.id]: http(RPC_URL) },
})
