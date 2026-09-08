set -euo pipefail
export PATH="$PATH:$HOME/.foundry/bin"
RH_RPC="${RH_RPC_URL:-https://rpc.mainnet.chain.robinhood.com}"
cmd="${1:-help}"
case "$cmd" in
  forge-test) cd /workspace/rh-build/hood-arena/contracts && forge test -vv ;;
  forge-build) cd /workspace/rh-build/hood-arena/contracts && forge build ;;
  forge-test-fork) cd /workspace/rh-build/hood-arena/contracts && forge test -vv --fork-url "$RH_RPC" ;;
  anvil-fork) exec anvil --fork-url "$RH_RPC" --chain-id 4663 ;;
  anvil-fork-testnet) exec anvil --fork-url "${RH_TESTNET_RPC_URL:-https://rpc.testnet.chain.robinhood.com}" --chain-id 46630 ;;
  export-abi) cd /workspace/rh-build/hood-arena/contracts && forge build && python3 /workspace/rh-build/hood-arena/scripts/export_abi.py ;;
  *) echo "usage: dry-helpers.sh [forge-test|forge-build|forge-test-fork|anvil-fork|anvil-fork-testnet|export-abi]" ;;
esac
