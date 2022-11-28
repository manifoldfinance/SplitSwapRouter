#!/usr/bin/env bash
# To load the variables in the .env file
source .env

# To deploy and verify our contract
forge script script/DeployLite.s.sol:DeployLiteScript --rpc-url $POLYGON_RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $POLYGONSCAN_API -vvvv