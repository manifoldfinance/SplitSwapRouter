# Fuzz test output

```rust
Running 16 tests for test/SplitSwapRouterFuzz.t.sol:SplitSwapRouterFuzzTest
[PASS] testGetAmountIn(uint112,uint112,uint112) (runs: 1000, μ: 16688, ~: 16688)
[PASS] testGetAmountOut(uint112,uint112,uint112) (runs: 1000, μ: 16101, ~: 16101)
[PASS] testGetAmountsIn(uint112) (runs: 1000, μ: 102235, ~: 101554)
[PASS] testGetAmountsOut(uint112) (runs: 1000, μ: 97074, ~: 96674)
[PASS] testLiquidityEth(uint256) (runs: 1000, μ: 689469, ~: 677930)
[PASS] testLiquidityTokens(uint256) (runs: 1000, μ: 800085, ~: 728057)
[PASS] testQuote(uint112,uint112,uint112) (runs: 1000, μ: 15957, ~: 15957)
[PASS] testSwapETHForExactTokens(uint256) (runs: 1000, μ: 329363, ~: 318829)
[PASS] testSwapExactETHForTokens(uint256) (runs: 1000, μ: 287312, ~: 281482)
[PASS] testSwapExactETHForTokensSupportingFeeOnTransferTokens(uint256) (runs: 1000, μ: 271184, ~: 271298)
[PASS] testSwapExactTokensForETH(uint256) (runs: 1000, μ: 487868, ~: 492442)
[PASS] testSwapExactTokensForETHSupportingFeeOnTransferTokens(uint256) (runs: 1000, μ: 628878, ~: 649603)
[PASS] testSwapExactTokensForTokens(uint256) (runs: 1000, μ: 382724, ~: 388252)
[PASS] testSwapExactTokensForTokensSupportingFeeOnTransferTokens(uint256) (runs: 1000, μ: 589369, ~: 611763)
[PASS] testSwapTokensForExactETH(uint256) (runs: 1000, μ: 531020, ~: 528012)
[PASS] testSwapTokensForExactTokens(uint256) (runs: 1000, μ: 603714, ~: 582375)
Test result: ok. 16 passed; 0 failed; finished in 156.47s
```