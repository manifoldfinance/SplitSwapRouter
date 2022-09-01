#!/usr/bin/env bash
# sudo apt install jq

# NB to export vars, run with source ./1inch-api-test.sh
source .env

chain='1'

fromTokenAddress='0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE' # eth

toTokenAddress='0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48' # usdc

amount='500000000000000000000' # 500 eth

fromAddress='0xDA9dfA130Df4dE4673b89022EE50ff26f6EA73Cf' # large eth address (kraken)

slippage='1' # 1 %

destReceiver="${fromAddress}"

url="https://api.1inch.io/v4.0/${chain}/swap?"

url="${url}fromTokenAddress=${fromTokenAddress}"

url="${url}&toTokenAddress=${toTokenAddress}"

url="${url}&amount=${amount}"

url="${url}&fromAddress=${fromAddress}"

url="${url}&slippage=${slippage}"

url="${url}&destReceiver=${destReceiver}"

swap_info=$(curl -s "${url}" | jq '.')

# echo $swap_info

amount_out=$(echo $swap_info | /usr/bin/jq --raw-output '.toTokenAmount')

# echo $amount_out

protocols=$(echo $swap_info | /usr/bin/jq --raw-output '.protocols')

# echo $protocols

tx_details=$(echo $swap_info | /usr/bin/jq --raw-output '.tx')

# echo $tx_details

data=$(echo $tx_details | /usr/bin/jq --raw-output '.data')

# echo $data

export toTokenAddress 

export amount

export amount_out

export data

forge test -f "$ETH_RPC_URL" -vvvvv --match-contract SplitSwapV3RouterVS1inchTestApi --etherscan-api-key $ETHERSCAN_API

