#!/usr/bin/env bash
# To load the variables in the .env file
source .env

# To deploy and verify our contract
forge script DeployLite.s.sol:DeployLiteScript --rpc-url $FANTOM_RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $FTMSCAN_KEY -vvvv