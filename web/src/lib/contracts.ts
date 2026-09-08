import { parseUnits, type Address, type Abi } from 'viem'
import ArenaAbi from '../abi/Arena.json'
import { ARENA_ADDRESS, USDG_ADDRESS, isLiveContracts } from './config'

export const arenaAbi = ArenaAbi as Abi

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

export type StakePrepare =
  | { mode: 'mock'; message: string }
  | {
      mode: 'live'
      approve: { address: Address; abi: typeof erc20ApproveAbi; functionName: 'approve'; args: [Address, bigint] }
      stake: {
        address: Address
        abi: Abi
        functionName: 'stake'
        args: [bigint, boolean, bigint]
      }
    }

/** Prepare Approve→Stake writes when VITE_ARENA_ADDRESS set; else mock no-op. */
export function prepareStakeWrites(opts: {
  arenaId: bigint
  yes: boolean
  amountUsdg: string
}): StakePrepare {
  if (!isLiveContracts || !ARENA_ADDRESS) {
    return { mode: 'mock', message: 'Mock mode — set VITE_ARENA_ADDRESS to enable writes' }
  }
  const amount = parseUnits(opts.amountUsdg || '0', 6)
  return {
    mode: 'live',
    approve: {
      address: USDG_ADDRESS,
      abi: erc20ApproveAbi,
      functionName: 'approve',
      args: [ARENA_ADDRESS as Address, amount],
    },
    stake: {
      address: ARENA_ADDRESS as Address,
      abi: arenaAbi,
      functionName: 'stake',
      args: [opts.arenaId, opts.yes, amount],
    },
  }
}
