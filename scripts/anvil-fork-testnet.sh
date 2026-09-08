set -euo pipefail
export PATH="$PATH:$HOME/.foundry/bin"
RPC="${RH_TESTNET_RPC_URL:-https://rpc.testnet.chain.robinhood.com}"
echo "Starting anvil fork chainId=46630 rpc=$RPC (LIVE LOCKED — local only)"
exec anvil --fork-url "$RPC" --chain-id 46630 "$@"
