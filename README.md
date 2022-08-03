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
```bash
Running 17 tests for test/SplitOrderRouterFuzz.t.sol:SplitOrderRouterFuzzTest
[PASS] testGetAmountIn(uint112,uint112,uint112) (runs: 1000, μ: 16660, ~: 16660)
[PASS] testGetAmountOut(uint112,uint112,uint112) (runs: 1000, μ: 16116, ~: 16116)
[PASS] testGetAmountsIn(uint112) (runs: 1000, μ: 36133, ~: 36133)
[PASS] testGetAmountsOut(uint112) (runs: 1000, μ: 33033, ~: 33033)
[PASS] testLiquidityEth(uint256) (runs: 1000, μ: 614922, ~: 611395)
[PASS] testLiquidityEthSupportingFeeOnTransfer(uint256) (runs: 1000, μ: 617579, ~: 612604)
[PASS] testLiquidityTokens(uint256) (runs: 1000, μ: 636588, ~: 642472)
[PASS] testQuote(uint112,uint112,uint112) (runs: 1000, μ: 15966, ~: 15966)
[PASS] testSwapETHForExactTokens(uint256) (runs: 1000, μ: 244810, ~: 249713)
[PASS] testSwapExactETHForTokens(uint256) (runs: 1000, μ: 206066, ~: 192096)
[PASS] testSwapExactETHForTokensSupportingFeeOnTransferTokens(uint256) (runs: 1000, μ: 194981, ~: 194981)
[PASS] testSwapExactTokensForETH(uint256) (runs: 1000, μ: 379847, ~: 373627)
[PASS] testSwapExactTokensForETHSupportingFeeOnTransferTokens(uint256) (runs: 1000, μ: 362968, ~: 370557)
[PASS] testSwapExactTokensForTokens(uint256) (runs: 1000, μ: 316265, ~: 323441)
[PASS] testSwapExactTokensForTokensSupportingFeeOnTransferTokens(uint256) (runs: 1000, μ: 357806, ~: 367636)
[PASS] testSwapTokensForExactETH(uint256) (runs: 1000, μ: 387861, ~: 382940)
[PASS] testSwapTokensForExactTokens(uint256) (runs: 1000, μ: 419880, ~: 441076)
Test result: ok. 17 passed; 0 failed; finished in 50.81s
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