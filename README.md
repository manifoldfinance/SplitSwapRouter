# Split Swap Router ![Foundry](https://github.com/manifoldfinance/SplitOrderRouter/actions/workflows/test.yml/badge.svg?branch=main)

### Optimal Swap split between Sushiswap, Uniswap V3 and Uniswap V2 

Based on math derived in [MEV paper by Liyi Zhou et al.](https://arxiv.org/pdf/2106.07371.pdf)

Pools 
- Sushiswap
- Uniswap V2
- Uniswap V3 0.30%
- Uniswap V3 0.05%
- Uniswap V3 1.00%

## Ethereum, Polygon, Optimism, Arbitrum
Using the path given, `SplitOrderV3Router` optimally splits swaps across pools from Uniswap V3, Uniswap V2 and Sushiswap.

## Avalanche and Fantom
Using the path given, `SplitOrderRouter` optimally splits swaps across pools from TraderJoe / Spookyswap and Sushiswap.

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

## Benchmark vs 1 Inch v4
[Transaction benchmark from 1-Inch V4: 449 ether -> 850,817 USDC costing 1,264,492 gas](https://etherscan.io/tx/0x3e506fb505c538805752e419356c3a6ce8b05a29d34ca563c95e894fda75bf80)

`SplitSwapRouter` uses ~20% of the gas of 1 inch with a 0.17% decreased output: 449 ether -> 849,326 USDC costing 277,589 gas

Run the test
```sh
forge test -f "$ETH_RPC_URL" --fork-block-number 15347843 -vvvvv --match-contract SplitOrderV3RouterVS1inchTest --etherscan-api-key $ETHERSCAN_API
```

Chain transactions
```rust
  [277589] SplitOrderV3RouterVS1inchTest::testSwapExactETHForTokens()
    ├─ [248235] SplitOrderV3Router::swapExactETHForTokens{value: 449000000000000000000}(0, [0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2, 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48], SplitOrderV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 1660591832)
    │   ├─ [2517] UniswapV2Pair::getReserves() [staticcall]
    │   │   └─ ← 29800467727588, 15692584833150907761259, 1660591809
    │   ├─ [2504] UniswapV2Pair::getReserves() [staticcall]
    │   │   └─ ← 63265997858813, 33308906660044246182962, 1660591831
    │   ├─ [2696] UniswapV3Pool::slot0() [staticcall]
    │   │   └─ ← 1817761282670659431568460586316205, 200825, 75, 1440, 1440, 0, true
    │   ├─ [2428] UniswapV3Pool::liquidity() [staticcall]
    │   │   └─ ← 11475991976130259545
    │   ├─ [2696] 0x88e6…5640::slot0() [staticcall]
    │   │   └─ ← 1820129930564437916297232768105936, 200851, 218, 720, 720, 0, true
    │   ├─ [2428] 0x88e6…5640::liquidity() [staticcall]
    │   │   └─ ← 19852527481115232045
    │   ├─ [2696] UniswapV3Pool::slot0() [staticcall]
    │   │   └─ ← 1813499478702189733074207916888890, 200778, 5, 30, 30, 0, true
    │   ├─ [2428] UniswapV3Pool::liquidity() [staticcall]
    │   │   └─ ← 840960033691554474
    │   ├─ [23974] WETH9::deposit{value: 449000000000000000000}()
    │   │   ├─ emit Deposit(dst: SplitOrderV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], wad: 449000000000000000000)
    │   │   └─ ← ()
    │   ├─ [94754] UniswapV3Pool::swap(SplitOrderV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], false, 382956522005176006460, 1461446703485210103287273052203988822378723970341, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000bb8)
    │   │   ├─ [44017] FiatTokenProxy::transfer(SplitOrderV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 724270481018)
    │   │   │   ├─ [36728] FiatTokenV2_1::transfer(SplitOrderV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 724270481018) [delegatecall]
    │   │   │   │   ├─ emit Transfer(from: UniswapV3Pool: [0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8], to: SplitOrderV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], value: 724270481018)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← true
    │   │   ├─ [2534] WETH9::balanceOf(UniswapV3Pool: [0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8]) [staticcall]
    │   │   │   └─ ← 46901016594031876375051
    │   │   ├─ [8177] SplitOrderV3Router::uniswapV3SwapCallback(-724270481018, 382956522005176006460, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000bb8)
    │   │   │   ├─ [6062] WETH9::transfer(UniswapV3Pool: [0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8], 382956522005176006460)
    │   │   │   │   ├─ emit Transfer(from: SplitOrderV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], to: UniswapV3Pool: [0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8], value: 382956522005176006460)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← ()
    │   │   ├─ [534] WETH9::balanceOf(UniswapV3Pool: [0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8]) [staticcall]
    │   │   │   └─ ← 47283973116037052381511
    │   │   ├─ emit Swap(sender: SplitOrderV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], recipient: SplitOrderV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], amount0: -724270481018, amount1: 382956522005176006460, sqrtPriceX96: 1820397213298666016179840158083371, liquidity: 11475991976130259545, tick: 200854)
    │   │   └─ ← -724270481018, 382956522005176006460
    │   ├─ [43189] 0x88e6…5640::swap(SplitOrderV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], false, 66043477994823993540, 1461446703485210103287273052203988822378723970341, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480001f4)
    │   │   ├─ [11617] FiatTokenProxy::transfer(SplitOrderV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 125055923069)
    │   │   │   ├─ [10828] FiatTokenV2_1::transfer(SplitOrderV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 125055923069) [delegatecall]
    │   │   │   │   ├─ emit Transfer(from: 0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640, to: SplitOrderV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], value: 125055923069)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← true
    │   │   ├─ [2534] WETH9::balanceOf(0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640) [staticcall]
    │   │   │   └─ ← 48370083805654930689242
    │   │   ├─ [6542] SplitOrderV3Router::uniswapV3SwapCallback(-125055923069, 66043477994823993540, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480001f4)
    │   │   │   ├─ [4850] WETH9::transfer(0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640, 66043477994823993540)
    │   │   │   │   ├─ emit Transfer(from: SplitOrderV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], to: 0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640, value: 66043477994823993540)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← ()
    │   │   ├─ [534] WETH9::balanceOf(0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640) [staticcall]
    │   │   │   └─ ← 48436127283649754682782
    │   │   ├─ emit Swap(sender: SplitOrderV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], recipient: SplitOrderV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], amount0: -125055923069, amount1: 66043477994823993540, sqrtPriceX96: 1820393367406968536594775935825062, liquidity: 19852527481115232045, tick: 200854)
    │   │   └─ ← -125055923069, 66043477994823993540
    │   └─ ← [449000000000000000000, 849326404087]
    ├─ emit log(: "Error: a >= b not satisfied [uint]")
    ├─ emit log_named_uint(key: "  Value a", val: 849326404087)
    ├─ emit log_named_uint(key: "  Value b", val: 850817000000)
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