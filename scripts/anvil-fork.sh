set -euo pipefail
export PATH="$PATH:$HOME/.foundry/bin"
RPC="${RH_RPC_URL:-https://rpc.mainnet.chain.robinhood.com}"
echo "Starting anvil fork chainId=4663 rpc=$RPC (LIVE LOCKED — local only)"
exec anvil --fork-url "$RPC" --chain-id 4663 "$@"
