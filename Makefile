# Hood Arena dry helpers. NEVER add --broadcast targets.
RH_RPC ?= https://rpc.mainnet.chain.robinhood.com
.PHONY: forge-test forge-build anvil-fork export-abi
forge-build:
	cd contracts && forge build
forge-test:
	cd contracts && forge test -vv
anvil-fork:
	bash scripts/anvil-fork.sh
anvil-fork-testnet:
	bash scripts/anvil-fork-testnet.sh
export-abi: forge-build
	python3 scripts/export_abi.py
forge-test-fork:
	cd contracts && forge test -vv --fork-url $(RH_RPC)
