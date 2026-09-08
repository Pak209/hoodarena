import { encodePacked, keccak256, type Abi, type Address, type Hex } from 'viem'
import PlayerCardAbi from '../abi/PlayerCard.json'
import CardPackAbi from '../abi/CardPack.json'
import {
  CARD_PACK_ADDRESS,
  PLAYER_CARD_ADDRESS,
  USDG_ADDRESS,
  isLiveCards,
  isLivePlayerCard,
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

export type PackSecrets = {
  secret: Hex
  salt: Hex
  packId: bigint
  commitHash: Hex
}

/** Match CardPack.commitHashOf: keccak256(secret, salt, packId, buyer). */
export function commitHashOf(
  secret: Hex,
  salt: Hex,
  packId: bigint,
  buyer: Address,
): Hex {
  return keccak256(encodePacked(['bytes32', 'bytes32', 'uint256', 'address'], [secret, salt, packId, buyer]))
}

export function randomBytes32(): Hex {
  const bytes = new Uint8Array(32)
  crypto.getRandomValues(bytes)
  return `0x${Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('')}` as Hex
}

/** Build secrets for the next pack id (read nextPackId first; race = BadCommit on reveal). */
export function makePackSecrets(packId: bigint, buyer: Address): PackSecrets {
  const secret = randomBytes32()
  const salt = randomBytes32()
  return {
    secret,
    salt,
    packId,
    commitHash: commitHashOf(secret, salt, packId, buyer),
  }
}

export type PackBuyPrepare =
  | { mode: 'mock'; message: string }
  | {
      mode: 'live'
      pack: Address
      cards: Address
      secrets: PackSecrets
      approve: {
        address: Address
        abi: typeof erc20ApproveAbi
        functionName: 'approve'
        args: [Address, bigint]
      }
      buyAndCommit: {
        address: Address
        abi: Abi
        functionName: 'buyAndCommit'
        args: [Hex]
      }
    }

export type PackRevealPrepare =
  | { mode: 'mock'; message: string }
  | {
      mode: 'live'
      reveal: {
        address: Address
        abi: Abi
        functionName: 'reveal'
        args: [bigint, Hex, Hex]
      }
    }

/** Approve USDG → buyAndCommit(commitHash). Requires addresses + buyer + predicted packId. */
export function prepareBuyAndCommit(opts: {
  amountRaw: bigint
  buyer: Address
  nextPackId: bigint
}): PackBuyPrepare {
  if (!isLiveCards || !CARD_PACK_ADDRESS || !PLAYER_CARD_ADDRESS) {
    return {
      mode: 'mock',
      message:
        'Mock mode — set VITE_PLAYER_CARD_ADDRESS + VITE_CARD_PACK_ADDRESS after Mint A2 deploy',
    }
  }
  const secrets = makePackSecrets(opts.nextPackId, opts.buyer)
  return {
    mode: 'live',
    pack: CARD_PACK_ADDRESS as Address,
    cards: PLAYER_CARD_ADDRESS as Address,
    secrets,
    approve: {
      address: USDG_ADDRESS,
      abi: erc20ApproveAbi,
      functionName: 'approve',
      args: [CARD_PACK_ADDRESS as Address, opts.amountRaw],
    },
    buyAndCommit: {
      address: CARD_PACK_ADDRESS as Address,
      abi: cardPackAbi,
      functionName: 'buyAndCommit',
      args: [secrets.commitHash],
    },
  }
}

/** reveal(packId, secret, salt) after unlockBlock mined. */
export function prepareReveal(opts: {
  packId: bigint
  secret: Hex
  salt: Hex
}): PackRevealPrepare {
  if (!isLiveCards || !CARD_PACK_ADDRESS) {
    return { mode: 'mock', message: 'Mock mode — no CardPack address' }
  }
  return {
    mode: 'live',
    reveal: {
      address: CARD_PACK_ADDRESS as Address,
      abi: cardPackAbi,
      functionName: 'reveal',
      args: [opts.packId, opts.secret, opts.salt],
    },
  }
}

/** @deprecated prefer prepareBuyAndCommit */
export function prepareBuyPack(amountRaw: bigint): PackBuyPrepare | { mode: 'mock'; message: string } {
  if (!isLiveCards || !CARD_PACK_ADDRESS || !PLAYER_CARD_ADDRESS) {
    return {
      mode: 'mock',
      message:
        'Mock mode — set VITE_PLAYER_CARD_ADDRESS + VITE_CARD_PACK_ADDRESS after Mint A2 deploy',
    }
  }
  void amountRaw
  return {
    mode: 'mock',
    message: 'Use prepareBuyAndCommit with wallet address + nextPackId (buyPack alone leaves Purchased sink)',
  }
}

export { isLiveCards, isLivePlayerCard, PLAYER_CARD_ADDRESS, CARD_PACK_ADDRESS, USDG_ADDRESS }
