# Fuzz test lite output

```rust
Running 17 tests for test/SplitSwapRouterLiteFuzz.t.sol:SplitSwapRouterLiteFuzzTest
[PASS] testGetAmountIn(uint112,uint112,uint112) (runs: 1000, μ: 16688, ~: 16688)
[PASS] testGetAmountOut(uint112,uint112,uint112) (runs: 1000, μ: 16123, ~: 16123)
[PASS] testGetAmountsIn(uint112) (runs: 1000, μ: 36120, ~: 36120)
[PASS] testGetAmountsOut(uint112) (runs: 1000, μ: 32999, ~: 32999)
[PASS] testLiquidityEth(uint256) (runs: 1000, μ: 607034, ~: 602941)
[PASS] testLiquidityEthSupportingFeeOnTransfer(uint256) (runs: 1000, μ: 609072, ~: 604155)
[PASS] testLiquidityTokens(uint256) (runs: 1000, μ: 626712, ~: 620830)
[PASS] testQuote(uint112,uint112,uint112) (runs: 1000, μ: 15979, ~: 15979)
[PASS] testSwapETHForExactTokens(uint256) (runs: 1000, μ: 222826, ~: 228830)
[PASS] testSwapExactETHForTokens(uint256) (runs: 1000, μ: 193578, ~: 201849)
[PASS] testSwapExactETHForTokensSupportingFeeOnTransferTokens(uint256) (runs: 1000, μ: 184468, ~: 184468)
[PASS] testSwapExactTokensForETH(uint256) (runs: 1000, μ: 359685, ~: 356953)
[PASS] testSwapExactTokensForETHSupportingFeeOnTransferTokens(uint256) (runs: 1000, μ: 344735, ~: 337685)
[PASS] testSwapExactTokensForTokens(uint256) (runs: 1000, μ: 307280, ~: 312945)
[PASS] testSwapExactTokensForTokensSupportingFeeOnTransferTokens(uint256) (runs: 1000, μ: 345506, ~: 350878)
[PASS] testSwapTokensForExactETH(uint256) (runs: 1000, μ: 372683, ~: 366278)
[PASS] testSwapTokensForExactTokens(uint256) (runs: 1000, μ: 413018, ~: 420278)
Test result: ok. 17 passed; 0 failed; finished in 31.44s
```