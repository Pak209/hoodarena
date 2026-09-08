import { useCallback, useState } from 'react'
import {
  useAccount,
  useReadContract,
  useWaitForTransactionReceipt,
  useWriteContract,
} from 'wagmi'
import { parseUnits, type Hex } from 'viem'
import { cardPackAbi, prepareBuyAndCommit, prepareReveal, isLiveCards } from './cards'
import { CARD_PACK_ADDRESS } from './config'
import { mockPack } from '../data/mock'

const SECRET_KEY = 'hood-arena-pack-secrets'

type StoredSecrets = { packId: string; secret: Hex; salt: Hex; commitHash: Hex }

function loadSecrets(): StoredSecrets | null {
  try {
    const raw = sessionStorage.getItem(SECRET_KEY)
    return raw ? (JSON.parse(raw) as StoredSecrets) : null
  } catch {
    return null
  }
}

function saveSecrets(s: StoredSecrets | null) {
  if (!s) sessionStorage.removeItem(SECRET_KEY)
  else sessionStorage.setItem(SECRET_KEY, JSON.stringify(s))
}

/**
 * Live path: approve → buyAndCommit → wait unlock → reveal.
 * Mock when addresses unset. No writes until isLiveCards.
 */
export function usePackOpen() {
  const { address, isConnected } = useAccount()
  const [msg, setMsg] = useState('')
  const [burst, setBurst] = useState(false)
  const [pendingSecrets, setPendingSecrets] = useState<StoredSecrets | null>(() => loadSecrets())

  const nextIdQ = useReadContract({
    address: CARD_PACK_ADDRESS || undefined,
    abi: cardPackAbi,
    functionName: 'nextPackId',
    query: { enabled: isLiveCards },
  })

  const packQ = useReadContract({
    address: CARD_PACK_ADDRESS || undefined,
    abi: cardPackAbi,
    functionName: 'packs',
    args: pendingSecrets ? [BigInt(pendingSecrets.packId)] : undefined,
    query: { enabled: isLiveCards && Boolean(pendingSecrets) },
  })

  const { writeContractAsync, data: txHash, isPending } = useWriteContract()
  const { isLoading: confirming } = useWaitForTransactionReceipt({ hash: txHash })

  const buy = useCallback(async () => {
    if (!isLiveCards || !address) {
      setBurst(true)
      setMsg(
        isLiveCards
          ? 'Connect wallet to buyAndCommit'
          : 'Mock open — waiting on Mint A2 addresses (VITE_PLAYER_CARD_ADDRESS + VITE_CARD_PACK_ADDRESS)',
      )
      return
    }
    const nextPackId = (nextIdQ.data as bigint | undefined) ?? 1n
    const prep = prepareBuyAndCommit({
      amountRaw: parseUnits(String(mockPack.priceUsdg), 6),
      buyer: address,
      nextPackId,
    })
    if (prep.mode !== 'live') {
      setMsg(prep.message)
      return
    }
    try {
      setMsg('Approving USDG…')
      await writeContractAsync(prep.approve)
      setMsg('buyAndCommit…')
      await writeContractAsync(prep.buyAndCommit)
      const stored: StoredSecrets = {
        packId: prep.secrets.packId.toString(),
        secret: prep.secrets.secret,
        salt: prep.secrets.salt,
        commitHash: prep.secrets.commitHash,
      }
      saveSecrets(stored)
      setPendingSecrets(stored)
      setBurst(true)
      setMsg(`Committed pack #${stored.packId} — wait past unlockBlock, then Reveal`)
    } catch (e) {
      setMsg(e instanceof Error ? e.message : 'buyAndCommit failed')
    }
  }, [address, nextIdQ.data, writeContractAsync])

  const reveal = useCallback(async () => {
    const s = pendingSecrets ?? loadSecrets()
    if (!s || !isLiveCards) {
      setMsg('No pending commit secrets (buy first in this session)')
      return
    }
    const prep = prepareReveal({
      packId: BigInt(s.packId),
      secret: s.secret,
      salt: s.salt,
    })
    if (prep.mode !== 'live') {
      setMsg(prep.message)
      return
    }
    try {
      setMsg(`Revealing pack #${s.packId}…`)
      await writeContractAsync(prep.reveal)
      saveSecrets(null)
      setPendingSecrets(null)
      setBurst(true)
      setMsg(`Revealed pack #${s.packId} — check /cards inventory`)
    } catch (e) {
      setMsg(e instanceof Error ? e.message : 'reveal failed')
    }
  }, [pendingSecrets, writeContractAsync])

  const unlockBlock =
    packQ.data && Array.isArray(packQ.data)
      ? Number((packQ.data as unknown as { unlockBlock?: bigint })[4] ?? 0)
      : packQ.data && typeof packQ.data === 'object' && packQ.data !== null && 'unlockBlock' in (packQ.data as object)
        ? Number((packQ.data as { unlockBlock: bigint }).unlockBlock)
        : undefined

  // packs() returns tuple — viem may give array: buyer, status, commitHash, commitBlock, unlockBlock, abandonBlock, purchasedBlock, paid
  const unlockFromTuple = (() => {
    const d = packQ.data as unknown
    if (Array.isArray(d) && d.length >= 5) return Number(d[4])
    return unlockBlock
  })()

  return {
    isLive: isLiveCards,
    isConnected,
    buy,
    reveal,
    burst,
    msg,
    busy: isPending || confirming,
    pendingPackId: pendingSecrets?.packId,
    unlockBlock: unlockFromTuple,
    refetchNextId: nextIdQ.refetch,
  }
}
