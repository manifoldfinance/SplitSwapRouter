```rust
Running 1 test for test/SplitSwapRouterInvest.t.sol:SplitSwapRouterInvestTest
[PASS] testInvest() (gas: 594921)
Traces:
  [4037165] SplitSwapRouterInvestTest::setUp()
    ├─ [3978051] → new SplitSwapRouter@0xCe71065D4017F316EC606Fe4422e11eB2c47c246
    │   └─ ← 19862 bytes of code
    └─ ← ()
​
  [594921] SplitSwapRouterInvestTest::testInvest()
    ├─ [207800] SplitSwapRouter::swapExactETHForTokens{value: 84000000000000000000}(0, [0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xd084944d3c05CD115C09d072B9F44bA3E0E45921], SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], 1663245179)
    │   ├─ [2517] UniswapV2Pair::getReserves() [staticcall]
    │   │   └─ ← 464638301836138645772, 9034685971864936407686, 1663245071
    │   ├─ [2696] 0x5eCEf3b72Cb00DBD8396EBAEC66E0f87E9596e97::slot0() [staticcall]
    │   │   └─ ← 348702734872635727025421346899, 29639, 0, 1, 1, 0, true
    │   ├─ [2428] 0x5eCEf3b72Cb00DBD8396EBAEC66E0f87E9596e97::liquidity() [staticcall]
    │   │   └─ ← 260371980826776287904
    │   ├─ [23974] WETH9::deposit{value: 84000000000000000000}()
    │   │   ├─ emit Deposit(dst: SplitSwapRouter: [0xCe71065D4017F316EC606Fe4422e11eB2c47c246], wad: 84000000000000000000)
    │   │   └─ ← ()
    │   ├─ [8062] WETH9::transfer(UniswapV2Pair: [0xA914a9b9E03b6aF84F9c6bd2e0e8d27D405695Db], 74628385604805736605)
    │   │   ├─ emit Transfer(src: SplitSwapRouter: [0xCe71065D4017F316EC606Fe4422e11eB2c47c246], dst: UniswapV2Pair: [0xA914a9b9E03b6aF84F9c6bd2e0e8d27D405695Db], wad: 74628385604805736605)
    │   │   └─ ← true
    │   ├─ [65287] UniswapV2Pair::swap(0, 1247064785194473435940, SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], 0x)
    │   │   ├─ [32698] FixedToken::transfer(SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], 1247064785194473435940)
    │   │   │   ├─ [30020] FixedToken::transfer(SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], 1247064785194473435940) [delegatecall]
    │   │   │   │   ├─ emit Transfer(src: UniswapV2Pair: [0xA914a9b9E03b6aF84F9c6bd2e0e8d27D405695Db], dst: SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], wad: 1247064785194473435940)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← true
    │   │   ├─ [534] WETH9::balanceOf(UniswapV2Pair: [0xA914a9b9E03b6aF84F9c6bd2e0e8d27D405695Db]) [staticcall]
    │   │   │   └─ ← 539266687440944382377
    │   │   ├─ [659] FixedToken::balanceOf(UniswapV2Pair: [0xA914a9b9E03b6aF84F9c6bd2e0e8d27D405695Db]) [staticcall]
    │   │   │   ├─ [487] FixedToken::balanceOf(UniswapV2Pair: [0xA914a9b9E03b6aF84F9c6bd2e0e8d27D405695Db]) [delegatecall]
    │   │   │   │   └─ ← 7787621186670462971746
    │   │   │   └─ ← 7787621186670462971746
    │   │   ├─ emit Sync(reserve0: 539266687440944382377, reserve1: 7787621186670462971746)
    │   │   ├─ emit Swap(sender: SplitSwapRouter: [0xCe71065D4017F316EC606Fe4422e11eB2c47c246], amount0In: 74628385604805736605, amount1In: 0, amount0Out: 0, amount1Out: 1247064785194473435940, to: SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84])
    │   │   └─ ← ()
    │   ├─ [44318] 0x5eCEf3b72Cb00DBD8396EBAEC66E0f87E9596e97::swap(SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], true, 9371614395194263395, 4295128740, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2d084944d3c05cd115c09d072b9f44ba3e0e45921002710)
    │   │   ├─ [8298] FixedToken::transfer(SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], 155357181343163217218)
    │   │   │   ├─ [8120] FixedToken::transfer(SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], 155357181343163217218) [delegatecall]
    │   │   │   │   ├─ emit Transfer(src: 0x5eCEf3b72Cb00DBD8396EBAEC66E0f87E9596e97, dst: SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], wad: 155357181343163217218)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← true
    │   │   ├─ [2534] WETH9::balanceOf(0x5eCEf3b72Cb00DBD8396EBAEC66E0f87E9596e97) [staticcall]
    │   │   │   └─ ← 16205988301181520879
    │   │   ├─ [6572] SplitSwapRouter::uniswapV3SwapCallback(9371614395194263395, -155357181343163217218, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2d084944d3c05cd115c09d072b9f44ba3e0e45921002710)
    │   │   │   ├─ [4850] WETH9::transfer(0x5eCEf3b72Cb00DBD8396EBAEC66E0f87E9596e97, 9371614395194263395)
    │   │   │   │   ├─ emit Transfer(src: SplitSwapRouter: [0xCe71065D4017F316EC606Fe4422e11eB2c47c246], dst: 0x5eCEf3b72Cb00DBD8396EBAEC66E0f87E9596e97, wad: 9371614395194263395)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← ()
    │   │   ├─ [534] WETH9::balanceOf(0x5eCEf3b72Cb00DBD8396EBAEC66E0f87E9596e97) [staticcall]
    │   │   │   └─ ← 25577602696375784274
    │   │   ├─ emit Swap(sender: SplitSwapRouter: [0xCe71065D4017F316EC606Fe4422e11eB2c47c246], recipient: SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], amount0: 9371614395194263395, amount1: -155357181343163217218, sqrtPriceX96: 301429353258647693625766383249, liquidity: 260371980826776287904, tick: 26725)
    │   │   └─ ← 9371614395194263395, -155357181343163217218
    │   └─ ← [84000000000000000000, 1402421966537636653158]
    ├─ [306499] SplitSwapRouter::swapExactETHForTokens{value: 56000000000000000000}(0, [0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xd084944d3c05CD115C09d072B9F44bA3E0E45921], SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], 1663245179)
    │   ├─ [2517] UniswapV2Pair::getReserves() [staticcall]
    │   │   └─ ← 20527068638223, 12874571844701710545992, 1663245167
    │   ├─ [2504] UniswapV2Pair::getReserves() [staticcall]
    │   │   └─ ← 45327094326287, 28425138994563187872445, 1663245167
    │   ├─ [2696] UniswapV3Pool::slot0() [staticcall]
    │   │   └─ ← 1984061475444756067020901326119424, 202576, 564, 1440, 1440, 0, true
    │   ├─ [2428] UniswapV3Pool::liquidity() [staticcall]
    │   │   └─ ← 10998083670914421742
    │   ├─ [2696] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640::slot0() [staticcall]
    │   │   └─ ← 1982864144907156572975318694572728, 202564, 536, 720, 720, 0, true
    │   ├─ [2428] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640::liquidity() [staticcall]
    │   │   └─ ← 15256678496822766232
    │   ├─ [2696] UniswapV3Pool::slot0() [staticcall]
    │   │   └─ ← 1985470229576809958374658057398154, 202590, 28, 30, 30, 0, true
    │   ├─ [2428] UniswapV3Pool::liquidity() [staticcall]
    │   │   └─ ← 688729138705754798
    │   ├─ [2696] UniswapV3Pool::slot0() [staticcall]
    │   │   └─ ← 9444525145681139109088055020172795, 233783, 0, 1, 1, 0, true
    │   ├─ [2428] UniswapV3Pool::liquidity() [staticcall]
    │   │   └─ ← 0
    │   ├─ [2696] UniswapV3Pool::slot0() [staticcall]
    │   │   └─ ← 8804247244108575263669016556500974, 232379, 54, 76, 76, 0, true
    │   ├─ [2428] UniswapV3Pool::liquidity() [staticcall]
    │   │   └─ ← 211288207155670148
    │   ├─ [21974] WETH9::deposit{value: 56000000000000000000}()
    │   │   ├─ emit Deposit(dst: SplitSwapRouter: [0xCe71065D4017F316EC606Fe4422e11eB2c47c246], wad: 56000000000000000000)
    │   │   └─ ← ()
    │   ├─ [75872] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640::swap(SplitSwapRouter: [0xCe71065D4017F316EC606Fe4422e11eB2c47c246], false, 56000000000000000000, 1461446703485210103287273052203988822378723970341, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480001f4)
    │   │   ├─ [44017] FiatTokenProxy::transfer(SplitSwapRouter: [0xCe71065D4017F316EC606Fe4422e11eB2c47c246], 89347090756)
    │   │   │   ├─ [36728] FiatTokenV2_1::transfer(SplitSwapRouter: [0xCe71065D4017F316EC606Fe4422e11eB2c47c246], 89347090756) [delegatecall]
    │   │   │   │   ├─ emit Transfer(src: 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640, dst: SplitSwapRouter: [0xCe71065D4017F316EC606Fe4422e11eB2c47c246], wad: 89347090756)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← true
    │   │   ├─ [2534] WETH9::balanceOf(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640) [staticcall]
    │   │   │   └─ ← 34415587031823226405094
    │   │   ├─ [6567] SplitSwapRouter::uniswapV3SwapCallback(-89347090756, 56000000000000000000, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480001f4)
    │   │   │   ├─ [4850] WETH9::transfer(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640, 56000000000000000000)
    │   │   │   │   ├─ emit Transfer(src: SplitSwapRouter: [0xCe71065D4017F316EC606Fe4422e11eB2c47c246], dst: 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640, wad: 56000000000000000000)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← ()
    │   │   ├─ [534] WETH9::balanceOf(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640) [staticcall]
    │   │   │   └─ ← 34471587031823226405094
    │   │   ├─ emit Swap(sender: SplitSwapRouter: [0xCe71065D4017F316EC606Fe4422e11eB2c47c246], recipient: SplitSwapRouter: [0xCe71065D4017F316EC606Fe4422e11eB2c47c246], amount0: -89347090756, amount1: 56000000000000000000, sqrtPriceX96: 1983154808350918064653368279368380, liquidity: 15256678496822766232, tick: 202567)
    │   │   └─ ← -89347090756, 56000000000000000000
    │   ├─ [74172] UniswapV3Pool::swap(SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], true, 89347090756, 4295128740, 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48d084944d3c05cd115c09d072b9f44ba3e0e45921002710)
    │   │   ├─ [8298] FixedToken::transfer(SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], 1043733424642189799346)
    │   │   │   ├─ [8120] FixedToken::transfer(SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], 1043733424642189799346) [delegatecall]
    │   │   │   │   ├─ emit Transfer(src: UniswapV3Pool: [0xe081EEAB0AdDe30588bA8d5B3F6aE5284790F54A], dst: SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], wad: 1043733424642189799346)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← true
    │   │   ├─ [3315] FiatTokenProxy::balanceOf(UniswapV3Pool: [0xe081EEAB0AdDe30588bA8d5B3F6aE5284790F54A]) [staticcall]
    │   │   │   ├─ [2529] FiatTokenV2_1::balanceOf(UniswapV3Pool: [0xe081EEAB0AdDe30588bA8d5B3F6aE5284790F54A]) [delegatecall]
    │   │   │   │   └─ ← 233096581870
    │   │   │   └─ ← 233096581870
    │   │   ├─ [9416] SplitSwapRouter::uniswapV3SwapCallback(89347090756, -1043733424642189799346, 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48d084944d3c05cd115c09d072b9f44ba3e0e45921002710)
    │   │   │   ├─ [7694] FiatTokenProxy::transfer(UniswapV3Pool: [0xe081EEAB0AdDe30588bA8d5B3F6aE5284790F54A], 89347090756)
    │   │   │   │   ├─ [7063] FiatTokenV2_1::transfer(UniswapV3Pool: [0xe081EEAB0AdDe30588bA8d5B3F6aE5284790F54A], 89347090756) [delegatecall]
    │   │   │   │   │   ├─ emit Transfer(src: SplitSwapRouter: [0xCe71065D4017F316EC606Fe4422e11eB2c47c246], dst: UniswapV3Pool: [0xe081EEAB0AdDe30588bA8d5B3F6aE5284790F54A], wad: 89347090756)
    │   │   │   │   │   └─ ← true
    │   │   │   │   └─ ← true
    │   │   │   └─ ← ()
    │   │   ├─ [1315] FiatTokenProxy::balanceOf(UniswapV3Pool: [0xe081EEAB0AdDe30588bA8d5B3F6aE5284790F54A]) [staticcall]
    │   │   │   ├─ [529] FiatTokenV2_1::balanceOf(UniswapV3Pool: [0xe081EEAB0AdDe30588bA8d5B3F6aE5284790F54A]) [delegatecall]
    │   │   │   │   └─ ← 322443672626
    │   │   │   └─ ← 322443672626
    │   │   ├─ emit Swap(sender: SplitSwapRouter: [0xCe71065D4017F316EC606Fe4422e11eB2c47c246], recipient: SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], amount0: 89347090756, amount1: -1043733424642189799346, sqrtPriceX96: 8412426657701871510025919301630220, liquidity: 209583447266701831, tick: 231469)
    │   │   └─ ← 89347090756, -1043733424642189799346
    │   └─ ← [56000000000000000000, 89347090756, 1043733424642189799346]
    ├─ [0] VM::roll(15539119)
    │   └─ ← ()
    ├─ [47633] UniswapV2Router02::swapExactETHForTokens{value: 140000000000000000000}(0, [0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xd084944d3c05CD115C09d072B9F44bA3E0E45921], SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], 1663245179)
    │   ├─ [517] UniswapV2Pair::getReserves() [staticcall]
    │   │   └─ ← 539266687440944382377, 7787621186670462971746, 1663245179
    │   ├─ [23974] WETH9::deposit{value: 140000000000000000000}()
    │   │   ├─ emit Deposit(dst: UniswapV2Router02: [0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F], wad: 140000000000000000000)
    │   │   └─ ← ()
    │   ├─ [2610] WETH9::transfer(UniswapV2Pair: [0xA914a9b9E03b6aF84F9c6bd2e0e8d27D405695Db], 140000000000000000000)
    │   │   ├─ emit Transfer(src: UniswapV2Router02: [0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F], dst: UniswapV2Pair: [0xA914a9b9E03b6aF84F9c6bd2e0e8d27D405695Db], wad: 140000000000000000000)
    │   │   └─ ← true
    │   ├─ [14227] UniswapV2Pair::swap(0, 1601239551353081342484, SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], 0x)
    │   │   ├─ [3498] FixedToken::transfer(SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], 1601239551353081342484)
    │   │   │   ├─ [3320] FixedToken::transfer(SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], 1601239551353081342484) [delegatecall]
    │   │   │   │   ├─ emit Transfer(src: UniswapV2Pair: [0xA914a9b9E03b6aF84F9c6bd2e0e8d27D405695Db], dst: SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84], wad: 1601239551353081342484)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← true
    │   │   ├─ [534] WETH9::balanceOf(UniswapV2Pair: [0xA914a9b9E03b6aF84F9c6bd2e0e8d27D405695Db]) [staticcall]
    │   │   │   └─ ← 679266687440944382377
    │   │   ├─ [659] FixedToken::balanceOf(UniswapV2Pair: [0xA914a9b9E03b6aF84F9c6bd2e0e8d27D405695Db]) [staticcall]
    │   │   │   ├─ [487] FixedToken::balanceOf(UniswapV2Pair: [0xA914a9b9E03b6aF84F9c6bd2e0e8d27D405695Db]) [delegatecall]
    │   │   │   │   └─ ← 6186381635317381629262
    │   │   │   └─ ← 6186381635317381629262
    │   │   ├─ emit Sync(reserve0: 679266687440944382377, reserve1: 6186381635317381629262)
    │   │   ├─ emit Swap(sender: UniswapV2Router02: [0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F], amount0In: 140000000000000000000, amount1In: 0, amount0Out: 0, amount1Out: 1601239551353081342484, to: SplitSwapRouterInvestTest: [0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84])
    │   │   └─ ← ()
    │   └─ ← [140000000000000000000, 1601239551353081342484]
    └─ ← ()
​
Test result: ok. 1 passed; 0 failed; finished in 31.23s
```