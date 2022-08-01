# Split Order Router ![Foundry](https://github.com/manifoldfinance/SplitOrderRouter/actions/workflows/test.yml/badge.svg?branch=main)

### Optimal Order split between 2 UniV2 style markets (eg Sushiswap and Uniswap V2)

Based on math derived in [MEV paper by Liyi Zhou et al.](https://arxiv.org/pdf/2106.07371.pdf)

This router does not find the best liquidity pair path. It uses the path given to compare pools. Nor does it use Curve, Balancer, Uni V3 pools. These are the major improvements to work on for a full smart order router.

## Setup
Copy `.env-example` to `.env` and fill in `ETH_RPC_URL`.
```bash
source .env
```

## Build
```bash
forge build
```

## Fuzz test
```bash
forge test -f "$ETH_RPC_URL" -vvv
```

## Test deploy
```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url $ETH_RPC_URL
```
```bash
Script ran successfully.

==========================

Estimated total gas used for script: 1644061

Estimated amount required: 0.028836324059142178 ETH

==========================

SIMULATION COMPLETE. To broadcast these transactions, add --broadcast and wallet configuration(s) to the previous command. See forge script --help for more.

Transactions saved to: broadcast/Deploy.s.sol/1/run-latest.json
```

## Deploy and verify on etherscan
Fill in `PRIVATE_KEY` and `ETHERSCAN_KEY` in `.env`.

```bash
./deploy.sh
```