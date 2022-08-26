# Split Swap Router ![Foundry](https://github.com/manifoldfinance/SplitSwapRouter/actions/workflows/test.yml/badge.svg?branch=main)

### Optimal Swap split between Sushiswap, Uniswap V3 and Uniswap V2 

Based on math derived in [MEV paper by Liyi Zhou et al.](https://arxiv.org/pdf/2106.07371.pdf)

[Math derivations for application in EVM](docs/math.md)

[Algorithm applying derived math](docs/algo.md)

Pools 
- Sushiswap
- Uniswap V2
- Uniswap V3 0.30%
- Uniswap V3 0.05%
- Uniswap V3 1.00%

## Ethereum, Polygon, Optimism, Arbitrum
Using the path given, `SplitSwapV3Router` optimally splits swaps across pools from Uniswap V3, Uniswap V2 and Sushiswap.

## Avalanche and Fantom
Using the path given, `SplitSwapRouter` optimally splits swaps across pools from TraderJoe / Spookyswap and Sushiswap.

## Setup
Copy `.env-example` to `.env` and fill in `ETH_RPC_URL`.
```sh
source .env
```

## Build
```sh
forge build
```

## Fuzz test
```sh
forge test -f "$ETH_RPC_URL" -vvv
```
```sh
Running 17 tests for test/SplitSwapRouterFuzz.t.sol:SplitSwapRouterFuzzTest
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

## Benchmarking against 1-Inch v4

Benchmark transactions from 1-Inch v4:
- https://etherscan.io/tx/0x3e506fb505c538805752e419356c3a6ce8b05a29d34ca563c95e894fda75bf80
- https://etherscan.io/tx/0x36eeb2248b7fc1f95bfbbf3be467ac70018a7c53120e3ec4da716707e08c01f0
- https://etherscan.io/tx/0xa9d979dc02f5a5293431d015e0eb6c9eea963dbe4a00cccd556d703eb3b91bb1
- https://etherscan.io/tx/0xf2c30b239cd6f77427b2998b930eff3c0eb4bb50a92f7993d379484161c89480
- https://etherscan.io/tx/0xd851a00e54dace8f77cd7e6f25c28818177ac3e1f5a3b18795a9c747723cb7a9

`SplitSwapRouter` uses ~20% of the gas of 1-Inch with a decreased output within ~ 1%

Run the test
```sh
forge test -f "$ETH_RPC_URL" -vvvvv --match-contract SplitSwapV3RouterVS1inchTest --etherscan-api-key $ETHERSCAN_API
```

## Test deploy
```sh
forge script script/Deploy.s.sol:DeployScript --rpc-url $ETH_RPC_URL
```

## Deploy and verify on etherscan
Fill in `PRIVATE_KEY` and `ETHERSCAN_KEY` in `.env`.

```sh
./deploy.sh
```

### Todo

- [ ] Documentation of derived math and code 
- [ ] Gas checks for adding splits (more efficient method needed)
- [ ] Add income potential (retain % of coins gained from split)
- [ ] MockERC20 and factories for faster fuzz testing
- [ ] Weth10 integration
- [ ] Gas optimisation

### In Progress


### Done ✓

- [x] Derived uint equation for amounts to sync prices and optimally splitting equal price markets via cumulative reserve ratios
- [x] IUniswapV2Router compatible
- [x] Split swaps between Sushiswap, Uniswap V2 and Uniswap V3
- [x] Edge case handling
- [x] Testing
- [x] Cross-chain compatible
- [x] Benchmark performance vs 1inch v4