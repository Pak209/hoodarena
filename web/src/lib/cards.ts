import type { Abi, Address } from 'viem'
import PlayerCardAbi from '../abi/PlayerCard.json'
import CardPackAbi from '../abi/CardPack.json'
import {
  CARD_PACK_ADDRESS,
  PLAYER_CARD_ADDRESS,
  USDG_ADDRESS,
  isLiveCards,
} from './config'

export const playerCardAbi = PlayerCardAbi as Abi
export const cardPackAbi = CardPackAbi as Abi

const erc20ApproveAbi = [
  {
    type: 'function',
    name: 'approve',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'spender', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    outputs: [{ type: 'bool' }],
  },
] as const

export type PackBuyPrepare =
  | { mode: 'mock'; message: string }
  | {
      mode: 'live'
      pack: Address
      cards: Address
      approve: {
        address: Address
        abi: typeof erc20ApproveAbi
        functionName: 'approve'
        args: [Address, bigint]
      }
      buyPack: {
        address: Address
        abi: Abi
        functionName: 'buyPack'
        args: []
      }
    }

/** Approve USDG → buyPack when Mode C addresses set; else mock. */
export function prepareBuyPack(amountRaw: bigint): PackBuyPrepare {
  if (!isLiveCards || !CARD_PACK_ADDRESS || !PLAYER_CARD_ADDRESS) {
    return {
      mode: 'mock',
      message: 'Mock mode — set VITE_PLAYER_CARD_ADDRESS + VITE_CARD_PACK_ADDRESS after Mint testnet deploy',
    }
  }
  return {
    mode: 'live',
    pack: CARD_PACK_ADDRESS as Address,
    cards: PLAYER_CARD_ADDRESS as Address,
    approve: {
      address: USDG_ADDRESS,
      abi: erc20ApproveAbi,
      functionName: 'approve',
      args: [CARD_PACK_ADDRESS as Address, amountRaw],
    },
    buyPack: {
      address: CARD_PACK_ADDRESS as Address,
      abi: cardPackAbi,
      functionName: 'buyPack',
      args: [],
    },
  }
}

export { isLiveCards, PLAYER_CARD_ADDRESS, CARD_PACK_ADDRESS }
