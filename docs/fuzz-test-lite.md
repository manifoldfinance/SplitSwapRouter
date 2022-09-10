# Fuzz test lite output

```rust
Running 17 tests for test/SplitSwapRouterLiteFuzz.t.sol:SplitSwapRouterLiteFuzzTest
[PASS] testGetAmountIn(uint112,uint112,uint112) (runs: 1000, μ: 16682, ~: 16682)
[PASS] testGetAmountOut(uint112,uint112,uint112) (runs: 1000, μ: 16117, ~: 16117)
[PASS] testGetAmountsIn(uint112) (runs: 1000, μ: 36213, ~: 36213)
[PASS] testGetAmountsOut(uint112) (runs: 1000, μ: 33089, ~: 33089)
[PASS] testLiquidityEth(uint256) (runs: 1000, μ: 636134, ~: 636136)
[PASS] testLiquidityEthSupportingFeeOnTransfer(uint256) (runs: 1000, μ: 637308, ~: 637310)
[PASS] testLiquidityTokens(uint256) (runs: 1000, μ: 632184, ~: 626713)
[PASS] testQuote(uint112,uint112,uint112) (runs: 1000, μ: 15973, ~: 15973)
[PASS] testSwapETHForExactTokens(uint256) (runs: 1000, μ: 249199, ~: 249823)
[PASS] testSwapExactETHForTokens(uint256) (runs: 1000, μ: 222877, ~: 222877)
[PASS] testSwapExactETHForTokensSupportingFeeOnTransferTokens(uint256) (runs: 1000, μ: 195139, ~: 195139)
[PASS] testSwapExactTokensForETH(uint256) (runs: 1000, μ: 398710, ~: 410503)
[PASS] testSwapExactTokensForETHSupportingFeeOnTransferTokens(uint256) (runs: 1000, μ: 379350, ~: 379349)
[PASS] testSwapExactTokensForTokens(uint256) (runs: 1000, μ: 369934, ~: 369933)
[PASS] testSwapExactTokensForTokensSupportingFeeOnTransferTokens(uint256) (runs: 1000, μ: 344813, ~: 344813)
[PASS] testSwapTokensForExactETH(uint256) (runs: 1000, μ: 402914, ~: 395113)
[PASS] testSwapTokensForExactTokens(uint256) (runs: 1000, μ: 379415, ~: 379415)
Test result: ok. 17 passed; 0 failed; finished in 49.16s
```