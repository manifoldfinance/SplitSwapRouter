#!/usr/bin/env bash
# To load the variables in the .env file
source .env

# To deploy and verify our contract
forge script Deploy.s.sol:DeployScript --rpc-url $POLYGON_RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $POLYGONSCAN_KEY -vvvv