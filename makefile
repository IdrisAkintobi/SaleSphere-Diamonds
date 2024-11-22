# Load environment variables from .env
include .env
export $(shell sed 's/=.*//' .env)

# Variables for contract verification
RPC_URL := https://rpc.sepolia-api.lisk.com
VERIFIER := blockscout
VERIFIER_URL := https://sepolia-blockscout.lisk.com/api
CONTRACT_PATH := ./src/Diamond.sol:Diamond
OPTIMIZER_RUNS := 200

# Formatting and Testing prerequisite
.PHONY: check
check:
	forge fmt
	forge build --sizes
	forge test

# Deployment targets ----> You'll have yo setup the account using cast `cast wallet import -i`
DeployDiamond: check
	forge script script/DeployDiamond.s.sol --rpc-url lisk-sepolia --account dev --broadcast --verify

DeployDiamondLocal: check
	forge script script/DeployDiamond.s.sol --rpc-url localhost --account foundry-local --broadcast

DeployDiamondFactory: check
	forge script script/DeployDiamondFactory.s.sol --rpc-url holesky --account dev --broadcast --verify

DeployViaFactory:
	forge script script/DeployViaFactory.s.sol --rpc-url holesky --broadcast

DeployDiamondFactoryLocal: check
	forge script script/DeployDiamondFactory.s.sol --rpc-url localhost --account foundry-local --broadcast

mergeAbis:
	bun run script/helpers/mergeAbis.ts

verify:
	@echo "Verifying contract with address: $(address)"
	@if [ -z "$(address)" ]; then \
		echo "Error: address variable is not set. Use 'make verify address=<contract_address>'"; \
		exit 1; \
	fi
	forge verify-contract \
		--rpc-url $(RPC_URL) \
		--verifier $(VERIFIER) \
		--verifier-url $(VERIFIER_URL) \
		--optimizer-runs $(OPTIMIZER_RUNS) \
		"$(address)" $(CONTRACT_PATH)