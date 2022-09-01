# Fuzz test output

```rust
Running 16 tests for test/SplitOrderV3RouterFuzz.t.sol:SplitSwapV3RouterFuzzTest
[PASS] testGetAmountIn(uint112,uint112,uint112) (runs: 256, μ: 16691, ~: 16691)
[PASS] testGetAmountOut(uint112,uint112,uint112) (runs: 256, μ: 16104, ~: 16104)
[PASS] testGetAmountsIn(uint112) (runs: 256, μ: 104528, ~: 104170)
[PASS] testGetAmountsOut(uint112) (runs: 256, μ: 98714, ~: 98473)
[PASS] testLiquidityEth(uint256) (runs: 256, μ: 709763, ~: 679124)
[PASS] testLiquidityTokens(uint256) (runs: 256, μ: 802537, ~: 729707)
[PASS] testQuote(uint112,uint112,uint112) (runs: 256, μ: 15954, ~: 15954)
[PASS] testSwapETHForExactTokens(uint256) (runs: 256, μ: 337283, ~: 312196)
[PASS] testSwapExactETHForTokens(uint256) (runs: 256, μ: 303669, ~: 282888)
[PASS] testSwapExactETHForTokensSupportingFeeOnTransferTokens(uint256) (runs: 256, μ: 273029, ~: 273097)
[PASS] testSwapExactTokensForETH(uint256) (runs: 256, μ: 489231, ~: 482892)
[PASS] testSwapExactTokensForETHSupportingFeeOnTransferTokens(uint256) (runs: 256, μ: 605402, ~: 652476)
[PASS] testSwapExactTokensForTokens(uint256) (runs: 256, μ: 383459, ~: 390459)
[PASS] testSwapExactTokensForTokensSupportingFeeOnTransferTokens(uint256) (runs: 256, μ: 574735, ~: 614701)
[PASS] testSwapTokensForExactETH(uint256) (runs: 256, μ: 537873, ~: 515584)
[PASS] testSwapTokensForExactTokens(uint256) (runs: 256, μ: 613900, ~: 587195)
Test result: ok. 16 passed; 0 failed; finished in 26.36s
```