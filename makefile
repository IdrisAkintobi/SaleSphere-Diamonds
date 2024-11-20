# Load environment variables from .env
include .env
export $(shell sed 's/=.*//' .env)

# Formatting and Testing prerequisite
.PHONY: check
check:
	forge fmt
	forge build --sizes
	forge test

# Deployment targets
DeployDiamond: check
	forge script script/DeployDiamond.s.sol --rpc-url holesky --account dev --broadcast --verify

