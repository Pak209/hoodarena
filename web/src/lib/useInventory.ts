import { useMemo } from 'react'
import { useAccount, useReadContract, useReadContracts } from 'wagmi'
import type { Abi, Address } from 'viem'
import { mockCards, type PlayerCardItem } from '../data/mock'
import { PLAYER_CARD_ADDRESS, isLivePlayerCard } from './config'
import { playerCardAbi } from './cards'
import {
  mapOnChainCard,
  type InventorySource,
  type OnChainCardData,
} from './inventory'

export type { InventorySource }

export interface InventoryResult {
  source: InventorySource
  address: `0x${string}` | undefined
  isConnected: boolean
  cards: PlayerCardItem[]
  isLoading: boolean
  isLiveConfigured: boolean
  error: Error | null
  refetch: () => void
}

/**
 * Mode C inventory.
 * Mock when PlayerCard address unset or wallet disconnected.
 * Live: tokensOfOwner(address) then batched getCard.
 * (Pack address not required for read-only inventory — see isLiveCards for buyPack.)
 */
export function useInventory(): InventoryResult {
  const { address, isConnected } = useAccount()
  const isLiveConfigured = isLivePlayerCard && Boolean(PLAYER_CARD_ADDRESS)
  // Spec: mock unless live addresses + wallet address available
  const liveReady = isLiveConfigured && Boolean(address)

  const {
    data: tokenIdsRaw,
    isLoading: loadingIds,
    error: idsError,
    refetch: refetchIds,
  } = useReadContract({
    address: PLAYER_CARD_ADDRESS as Address,
    abi: playerCardAbi,
    functionName: 'tokensOfOwner',
    args: address ? [address] : undefined,
    query: { enabled: liveReady },
  })

  const tokenIds = useMemo(() => {
    if (!liveReady || !tokenIdsRaw) return [] as bigint[]
    return tokenIdsRaw as bigint[]
  }, [liveReady, tokenIdsRaw])

  const cardCalls = useMemo(
    () =>
      tokenIds.map((id) => ({
        address: PLAYER_CARD_ADDRESS as Address,
        abi: playerCardAbi as Abi,
        functionName: 'getCard' as const,
        args: [id] as const,
      })),
    [tokenIds],
  )

  const {
    data: cardResults,
    isLoading: loadingCards,
    error: cardsError,
    refetch: refetchCards,
  } = useReadContracts({
    contracts: cardCalls,
    query: { enabled: liveReady && tokenIds.length > 0 },
  })

  const liveCards = useMemo(() => {
    if (!liveReady || tokenIds.length === 0 || !cardResults) return [] as PlayerCardItem[]
    const out: PlayerCardItem[] = []
    for (let i = 0; i < tokenIds.length; i++) {
      const row = cardResults[i]
      if (!row || row.status !== 'success' || row.result == null) continue
      out.push(mapOnChainCard(tokenIds[i]!, row.result as OnChainCardData))
    }
    return out
  }, [liveReady, tokenIds, cardResults])

  if (!liveReady) {
    return {
      source: 'mock',
      address: address as `0x${string}` | undefined,
      isConnected,
      cards: mockCards,
      isLoading: false,
      isLiveConfigured,
      error: null,
      refetch: () => {},
    }
  }

  const isLoading = loadingIds || (tokenIds.length > 0 && loadingCards)
  const err = (idsError ?? cardsError) as Error | null

  return {
    source: 'live',
    address: address as `0x${string}`,
    isConnected,
    cards: liveCards,
    isLoading,
    isLiveConfigured: true,
    error: err,
    refetch: () => {
      void refetchIds()
      void refetchCards()
    },
  }
}
