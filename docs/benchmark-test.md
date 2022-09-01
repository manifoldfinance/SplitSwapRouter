# Benchmark test output

```rust
Running 6 tests for test/SplitOrderV3RouterVS1inch.t.sol:SplitSwapV3RouterVS1inchTest
[PASS] testSwapExactETHForTokens1() (gas: 5085791)
Traces:
  [141168] SplitSwapV3RouterVS1inchTest::setUp()
    ├─ [0] VM::envString("ETH_RPC_URL")
    │   └─ ← "<eth_rpc>"
    ├─ [0] VM::createFork("<eth_rpc>", 15347843)
    │   └─ ← 1
    ├─ [0] VM::createFork("<eth_rpc>", 15408222)
    │   └─ ← 2
    ├─ [0] VM::createFork("<eth_rpc>", 15409161)
    │   └─ ← 3
    ├─ [0] VM::createFork("<eth_rpc>", 15409149)
    │   └─ ← 4
    ├─ [0] VM::createFork("<eth_rpc>", 15396936)
    │   └─ ← 5
    ├─ [0] VM::createFork("<eth_rpc>", 15414959)
    │   └─ ← 6
    └─ ← ()

  [5085791] SplitSwapV3RouterVS1inchTest::testSwapExactETHForTokens1()
    ├─ [0] VM::selectFork(1)
    │   └─ ← ()
    ├─ [4756515] → new SplitSwapV3Router@"0xce71…c246"
    │   └─ ← 23749 bytes of code
    ├─ [249240] SplitSwapV3Router::swapExactETHForTokens{value: 449000000000000000000}(0, [0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2, 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48], SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 1660591832)
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
    │   │   ├─ emit Deposit(dst: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], wad: 449000000000000000000)
    │   │   └─ ← ()
    │   ├─ [94754] UniswapV3Pool::swap(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], false, 382197471311556834445, 1461446703485210103287273052203988822378723970341, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000bb8)
    │   │   ├─ [44017] FiatTokenProxy::transfer(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 722836993123)
    │   │   │   ├─ [36728] FiatTokenV2_1::transfer(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 722836993123) [delegatecall]
    │   │   │   │   ├─ emit Transfer(src: UniswapV3Pool: [0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8], dst: SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], wad: 722836993123)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← true
    │   │   ├─ [2534] WETH9::balanceOf(UniswapV3Pool: [0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8]) [staticcall]
    │   │   │   └─ ← 46901016594031876375051
    │   │   ├─ [8177] SplitSwapV3Router::uniswapV3SwapCallback(-722836993123, 382197471311556834445, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000bb8)
    │   │   │   ├─ [6062] WETH9::transfer(UniswapV3Pool: [0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8], 382197471311556834445)
    │   │   │   │   ├─ emit Transfer(src: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], dst: UniswapV3Pool: [0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8], wad: 382197471311556834445)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← ()
    │   │   ├─ [534] WETH9::balanceOf(UniswapV3Pool: [0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8]) [staticcall]
    │   │   │   └─ ← 47283214065343433209496
    │   │   ├─ emit Swap(sender: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], recipient: SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], amount0: -722836993123, amount1: 382197471311556834445, sqrtPriceX96: 1820391988671700416740242753754581, liquidity: 11475991976130259545, tick: 200854)
    │   │   └─ ← -722836993123, 382197471311556834445
    │   ├─ [43189] 0x88e6…5640::swap(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], false, 66802528688443165555, 1461446703485210103287273052203988822378723970341, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480001f4)
    │   │   ├─ [11617] FiatTokenProxy::transfer(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 126493005024)
    │   │   │   ├─ [10828] FiatTokenV2_1::transfer(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 126493005024) [delegatecall]
    │   │   │   │   ├─ emit Transfer(src: 0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640, dst: SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], wad: 126493005024)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← true
    │   │   ├─ [2534] WETH9::balanceOf(0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640) [staticcall]
    │   │   │   └─ ← 48370083805654930689242
    │   │   ├─ [6542] SplitSwapV3Router::uniswapV3SwapCallback(-126493005024, 66802528688443165555, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480001f4)
    │   │   │   ├─ [4850] WETH9::transfer(0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640, 66802528688443165555)
    │   │   │   │   ├─ emit Transfer(src: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], dst: 0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640, wad: 66802528688443165555)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← ()
    │   │   ├─ [534] WETH9::balanceOf(0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640) [staticcall]
    │   │   │   └─ ← 48436886334343373854797
    │   │   ├─ emit Swap(sender: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], recipient: SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], amount0: -126493005024, amount1: 66802528688443165555, sqrtPriceX96: 1820396395138458743447433514808271, liquidity: 19852527481115232045, tick: 200854)
    │   │   └─ ← -126493005024, 66802528688443165555
    │   └─ ← [449000000000000000000, 849329998147]
    └─ ← ()

[PASS] testSwapExactETHForTokens2() (gas: 5040137)
Traces:
  [141168] SplitSwapV3RouterVS1inchTest::setUp()
    ├─ [0] VM::envString("ETH_RPC_URL")
    │   └─ ← "<eth_rpc>"
    ├─ [0] VM::createFork("<eth_rpc>", 15347843)
    │   └─ ← 1
    ├─ [0] VM::createFork("<eth_rpc>", 15408222)
    │   └─ ← 2
    ├─ [0] VM::createFork("<eth_rpc>", 15409161)
    │   └─ ← 3
    ├─ [0] VM::createFork("<eth_rpc>", 15409149)
    │   └─ ← 4
    ├─ [0] VM::createFork("<eth_rpc>", 15396936)
    │   └─ ← 5
    ├─ [0] VM::createFork("<eth_rpc>", 15414959)
    │   └─ ← 6
    └─ ← ()

  [5040137] SplitSwapV3RouterVS1inchTest::testSwapExactETHForTokens2()
    ├─ [0] VM::selectFork(2)
    │   └─ ← ()
    ├─ [4756515] → new SplitSwapV3Router@"0xce71…c246"
    │   └─ ← 23749 bytes of code
    ├─ [205687] SplitSwapV3Router::swapExactETHForTokens{value: 797000000000000000000}(0, [0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2, 0x2260fac5e5542a773aa44fbcfedf7c193bc2c599], SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 1661418329)
    │   ├─ [2517] UniswapV2Pair::getReserves() [staticcall]
    │   │   └─ ← 51490068836, 6547333474618025889750, 1661417367
    │   ├─ [2504] UniswapV2Pair::getReserves() [staticcall]
    │   │   └─ ← 33380409422, 4248518377307404059410, 1661417533
    │   ├─ [2696] UniswapV3Pool::slot0() [staticcall]
    │   │   └─ ← 28254621959605664847140676632393524, 255701, 85, 200, 200, 0, true
    │   ├─ [2428] UniswapV3Pool::liquidity() [staticcall]
    │   │   └─ ← 1413003517022466615
    │   ├─ [2696] 0x4585…20c0::slot0() [staticcall]
    │   │   └─ ← 28244248889694198743498090019420776, 255694, 290, 300, 300, 0, true
    │   ├─ [2428] 0x4585…20c0::liquidity() [staticcall]
    │   │   └─ ← 434332932241701651
    │   ├─ [2696] 0x6ab3…526f::slot0() [staticcall]
    │   │   └─ ← 28392174205479535399373269335552436, 255798, 0, 1, 1, 0, true
    │   ├─ [2428] 0x6ab3…526f::liquidity() [staticcall]
    │   │   └─ ← 864246127809874
    │   ├─ [23974] WETH9::deposit{value: 797000000000000000000}()
    │   │   ├─ emit Deposit(dst: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], wad: 797000000000000000000)
    │   │   └─ ← ()
    │   ├─ [94064] UniswapV3Pool::swap(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], false, 797000000000000000000, 1461446703485210103287273052203988822378723970341, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc22260fac5e5542a773aa44fbcfedf7c193bc2c599000bb8)
    │   │   ├─ [32803] WBTC::transfer(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 6238649442)
    │   │   │   ├─ emit Transfer(src: UniswapV3Pool: [0xcbcdf9626bc03e24f779434178a73a0b4bad62ed], dst: SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], wad: 6238649442)
    │   │   │   └─ ← true
    │   │   ├─ [2534] WETH9::balanceOf(UniswapV3Pool: [0xcbcdf9626bc03e24f779434178a73a0b4bad62ed]) [staticcall]
    │   │   │   └─ ← 42198089552152400417103
    │   │   ├─ [6542] SplitSwapV3Router::uniswapV3SwapCallback(-6238649442, 797000000000000000000, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc22260fac5e5542a773aa44fbcfedf7c193bc2c599000bb8)
    │   │   │   ├─ [4850] WETH9::transfer(UniswapV3Pool: [0xcbcdf9626bc03e24f779434178a73a0b4bad62ed], 797000000000000000000)
    │   │   │   │   ├─ emit Transfer(src: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], dst: UniswapV3Pool: [0xcbcdf9626bc03e24f779434178a73a0b4bad62ed], wad: 797000000000000000000)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← ()
    │   │   ├─ [534] WETH9::balanceOf(UniswapV3Pool: [0xcbcdf9626bc03e24f779434178a73a0b4bad62ed]) [staticcall]
    │   │   │   └─ ← 42995089552152400417103
    │   │   ├─ emit Swap(sender: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], recipient: SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], amount0: -6238649442, amount1: 797000000000000000000, sqrtPriceX96: 28292668708300078033391207953945049, liquidity: 2185683388389467014, tick: 255728)
    │   │   └─ ← -6238649442, 797000000000000000000
    │   └─ ← [797000000000000000000, 6238649442]
    └─ ← ()

[PASS] testSwapExactETHForTokens3() (gas: 5103955)
Traces:
  [141168] SplitSwapV3RouterVS1inchTest::setUp()
    ├─ [0] VM::envString("ETH_RPC_URL")
    │   └─ ← "<eth_rpc>"
    ├─ [0] VM::createFork("<eth_rpc>", 15347843)
    │   └─ ← 1
    ├─ [0] VM::createFork("<eth_rpc>", 15408222)
    │   └─ ← 2
    ├─ [0] VM::createFork("<eth_rpc>", 15409161)
    │   └─ ← 3
    ├─ [0] VM::createFork("<eth_rpc>", 15409149)
    │   └─ ← 4
    ├─ [0] VM::createFork("<eth_rpc>", 15396936)
    │   └─ ← 5
    ├─ [0] VM::createFork("<eth_rpc>", 15414959)
    │   └─ ← 6
    └─ ← ()

  [5103955] SplitSwapV3RouterVS1inchTest::testSwapExactETHForTokens3()
    ├─ [0] VM::selectFork(3)
    │   └─ ← ()
    ├─ [4756515] → new SplitSwapV3Router@"0xce71…c246"
    │   └─ ← 23749 bytes of code
    ├─ [267478] SplitSwapV3Router::swapExactETHForTokens{value: 100000000000000000000}(0, [0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2, 0x6b175474e89094c44da98b954eedeac495271d0f], SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 1661431460)
    │   ├─ [2517] UniswapV2Pair::getReserves() [staticcall]
    │   │   └─ ← 4817014680458033823729229, 2819444437840966827564, 1661431184
    │   ├─ [2504] UniswapV2Pair::getReserves() [staticcall]
    │   │   └─ ← 7807203673472598381415798, 4568174770780986650760, 1661431460
    │   ├─ [2696] UniswapV3Pool::slot0() [staticcall]
    │   │   └─ ← 1916557774996704133476413426, -74440, 460, 1500, 1500, 0, true
    │   ├─ [2428] UniswapV3Pool::liquidity() [staticcall]
    │   │   └─ ← 1291095823875226684386652
    │   ├─ [2696] 0x6059…a270::slot0() [staticcall]
    │   │   └─ ← 1918822844832283982932430842, -74417, 76, 80, 80, 0, true
    │   ├─ [2428] 0x6059…a270::liquidity() [staticcall]
    │   │   └─ ← 1315790333319669538068379
    │   ├─ [2696] 0xa809…6c1e::slot0() [staticcall]
    │   │   └─ ← 1923356580897347640892110379, -74369, 26, 50, 50, 0, true
    │   ├─ [2428] 0xa809…6c1e::liquidity() [staticcall]
    │   │   └─ ← 14998111865754107483386
    │   ├─ [23974] WETH9::deposit{value: 100000000000000000000}()
    │   │   ├─ emit Deposit(dst: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], wad: 100000000000000000000)
    │   │   └─ ← ()
    │   ├─ [110838] UniswapV3Pool::swap(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], false, 68183836759779141043, 1461446703485210103287273052203988822378723970341, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc26b175474e89094c44da98b954eedeac495271d0f000bb8)
    │   │   ├─ [30174] Dai::transfer(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 115917585482178601024415)
    │   │   │   ├─ emit Transfer(src: UniswapV3Pool: [0xc2e9f25be6257c210d7adf0d4cd6e3e881ba25f8], dst: SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], wad: 115917585482178601024415)
    │   │   │   └─ ← true
    │   │   ├─ [2534] WETH9::balanceOf(UniswapV3Pool: [0xc2e9f25be6257c210d7adf0d4cd6e3e881ba25f8]) [staticcall]
    │   │   │   └─ ← 5694883628871145801926
    │   │   ├─ [8177] SplitSwapV3Router::uniswapV3SwapCallback(-115917585482178601024415, 68183836759779141043, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc26b175474e89094c44da98b954eedeac495271d0f000bb8)
    │   │   │   ├─ [6062] WETH9::transfer(UniswapV3Pool: [0xc2e9f25be6257c210d7adf0d4cd6e3e881ba25f8], 68183836759779141043)
    │   │   │   │   ├─ emit Transfer(src: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], dst: UniswapV3Pool: [0xc2e9f25be6257c210d7adf0d4cd6e3e881ba25f8], wad: 68183836759779141043)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← ()
    │   │   ├─ [534] WETH9::balanceOf(UniswapV3Pool: [0xc2e9f25be6257c210d7adf0d4cd6e3e881ba25f8]) [staticcall]
    │   │   │   └─ ← 5763067465630924942969
    │   │   ├─ emit Swap(sender: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], recipient: SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], amount0: -115917585482178601024415, amount1: 68183836759779141043, sqrtPriceX96: 1920644567741634647034986936, liquidity: 1689477886564497068379350, tick: -74398)
    │   │   └─ ← -115917585482178601024415, 68183836759779141043
    │   ├─ [44442] 0x6059…a270::swap(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], false, 31816163240220858957, 1461446703485210103287273052203988822378723970341, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc26b175474e89094c44da98b954eedeac495271d0f0001f4)
    │   │   ├─ [8274] Dai::transfer(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 54161021089956308178456)
    │   │   │   ├─ emit Transfer(src: 0x60594a405d53811d3bc4766596efd80fd545a270, dst: SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], wad: 54161021089956308178456)
    │   │   │   └─ ← true
    │   │   ├─ [2534] WETH9::balanceOf(0x60594a405d53811d3bc4766596efd80fd545a270) [staticcall]
    │   │   │   └─ ← 2255967495612356299383
    │   │   ├─ [6542] SplitSwapV3Router::uniswapV3SwapCallback(-54161021089956308178456, 31816163240220858957, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc26b175474e89094c44da98b954eedeac495271d0f0001f4)
    │   │   │   ├─ [4850] WETH9::transfer(0x60594a405d53811d3bc4766596efd80fd545a270, 31816163240220858957)
    │   │   │   │   ├─ emit Transfer(src: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], dst: 0x60594a405d53811d3bc4766596efd80fd545a270, wad: 31816163240220858957)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← ()
    │   │   ├─ [534] WETH9::balanceOf(0x60594a405d53811d3bc4766596efd80fd545a270) [staticcall]
    │   │   │   └─ ← 2287783658852577158340
    │   │   ├─ emit Swap(sender: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], recipient: SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], amount0: -54161021089956308178456, amount1: 31816163240220858957, sqrtPriceX96: 1920737645176913501965689326, liquidity: 1315790333319669538068379, tick: -74397)
    │   │   └─ ← -54161021089956308178456, 31816163240220858957
    │   └─ ← [100000000000000000000, 170078606572134909202871]
    └─ ← ()

[PASS] testSwapExactETHForTokens4() (gas: 5145520)
Traces:
  [141168] SplitSwapV3RouterVS1inchTest::setUp()
    ├─ [0] VM::envString("ETH_RPC_URL")
    │   └─ ← "<eth_rpc>"
    ├─ [0] VM::createFork("<eth_rpc>", 15347843)
    │   └─ ← 1
    ├─ [0] VM::createFork("<eth_rpc>", 15408222)
    │   └─ ← 2
    ├─ [0] VM::createFork("<eth_rpc>", 15409161)
    │   └─ ← 3
    ├─ [0] VM::createFork("<eth_rpc>", 15409149)
    │   └─ ← 4
    ├─ [0] VM::createFork("<eth_rpc>", 15396936)
    │   └─ ← 5
    ├─ [0] VM::createFork("<eth_rpc>", 15414959)
    │   └─ ← 6
    └─ ← ()

  [5145520] SplitSwapV3RouterVS1inchTest::testSwapExactETHForTokens4()
    ├─ [0] VM::selectFork(4)
    │   └─ ← ()
    ├─ [4756515] → new SplitSwapV3Router@"0xce71…c246"
    │   └─ ← 23749 bytes of code
    ├─ [308903] SplitSwapV3Router::swapExactETHForTokens{value: 123000000000000000000}(0, [0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2, 0xdac17f958d2ee523a2206206994597c13d831ec7], SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 1661431268)
    │   ├─ [2517] UniswapV2Pair::getReserves() [staticcall]
    │   │   └─ ← 7729595940218979687002, 13216191467768, 1661431184
    │   ├─ [2504] UniswapV2Pair::getReserves() [staticcall]
    │   │   └─ ← 10037419668989874368001, 17136802549547, 1661431226
    │   ├─ [2696] UniswapV3Pool::slot0() [staticcall]
    │   │   └─ ← 3274840300951376439958653, -201887, 34, 50, 50, 0, true
    │   ├─ [2428] UniswapV3Pool::liquidity() [staticcall]
    │   │   └─ ← 4440973164564952173
    │   ├─ [2696] UniswapV3Pool::slot0() [staticcall]
    │   │   └─ ← 3276562189852458820859666, -201876, 75, 80, 80, 0, true
    │   ├─ [2428] UniswapV3Pool::liquidity() [staticcall]
    │   │   └─ ← 2020323101133356451
    │   ├─ [2696] 0xc5af…a71d::slot0() [staticcall]
    │   │   └─ ← 3262326558161184149716945, -201964, 34, 50, 50, 0, true
    │   ├─ [2428] 0xc5af…a71d::liquidity() [staticcall]
    │   │   └─ ← 12044627380680732
    │   ├─ [23974] WETH9::deposit{value: 123000000000000000000}()
    │   │   ├─ emit Deposit(dst: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], wad: 123000000000000000000)
    │   │   └─ ← ()
    │   ├─ [8062] WETH9::transfer(UniswapV2Pair: [0x0d4a11d5eeaac28ec3f61d100daf4d40471f1852], 2460512591592478933)
    │   │   ├─ emit Transfer(src: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], dst: UniswapV2Pair: [0x0d4a11d5eeaac28ec3f61d100daf4d40471f1852], wad: 2460512591592478933)
    │   │   └─ ← true
    │   ├─ [74062] UniswapV2Pair::swap(0, 4187186763, SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 0x)
    │   │   ├─ [41601] TetherToken::transfer(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 4187186763)
    │   │   │   ├─ emit Transfer(src: UniswapV2Pair: [0x0d4a11d5eeaac28ec3f61d100daf4d40471f1852], dst: SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], wad: 4187186763)
    │   │   │   └─ ← ()
    │   │   ├─ [534] WETH9::balanceOf(UniswapV2Pair: [0x0d4a11d5eeaac28ec3f61d100daf4d40471f1852]) [staticcall]
    │   │   │   └─ ← 10039880181581466846934
    │   │   ├─ [1031] TetherToken::balanceOf(UniswapV2Pair: [0x0d4a11d5eeaac28ec3f61d100daf4d40471f1852]) [staticcall]
    │   │   │   └─ ← 17132615362784
    │   │   ├─ emit Sync(reserve0: 10039880181581466846934, reserve1: 17132615362784)
    │   │   ├─ emit Swap(sender: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], amount0In: 2460512591592478933, amount1In: 0, amount0Out: 0, amount1Out: 4187186763, to: SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84])
    │   │   └─ ← ()
    │   ├─ [59806] UniswapV3Pool::swap(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], true, 65195624691637422527, 4295128740, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2dac17f958d2ee523a2206206994597c13d831ec7000bb8)
    │   │   ├─ [11701] TetherToken::transfer(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 110986979263)
    │   │   │   ├─ emit Transfer(src: UniswapV3Pool: [0x4e68ccd3e89f51c3074ca5072bbac773960dfa36], dst: SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], wad: 110986979263)
    │   │   │   └─ ← ()
    │   │   ├─ [2534] WETH9::balanceOf(UniswapV3Pool: [0x4e68ccd3e89f51c3074ca5072bbac773960dfa36]) [staticcall]
    │   │   │   └─ ← 21867304445048036988040
    │   │   ├─ [8190] SplitSwapV3Router::uniswapV3SwapCallback(65195624691637422527, -110986979263, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2dac17f958d2ee523a2206206994597c13d831ec7000bb8)
    │   │   │   ├─ [6062] WETH9::transfer(UniswapV3Pool: [0x4e68ccd3e89f51c3074ca5072bbac773960dfa36], 65195624691637422527)
    │   │   │   │   ├─ emit Transfer(src: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], dst: UniswapV3Pool: [0x4e68ccd3e89f51c3074ca5072bbac773960dfa36], wad: 65195624691637422527)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← ()
    │   │   ├─ [534] WETH9::balanceOf(UniswapV3Pool: [0x4e68ccd3e89f51c3074ca5072bbac773960dfa36]) [staticcall]
    │   │   │   └─ ← 21932500069739674410567
    │   │   ├─ emit Swap(sender: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], recipient: SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], amount0: 65195624691637422527, amount1: -110986979263, sqrtPriceX96: 3272860263219954044083043, liquidity: 4440973164564952173, tick: -201899)
    │   │   └─ ← 65195624691637422527, -110986979263
    │   ├─ [43126] UniswapV3Pool::swap(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], true, 55343862716770098540, 4295128740, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2dac17f958d2ee523a2206206994597c13d831ec70001f4)
    │   │   ├─ [11701] TetherToken::transfer(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 94501444235)
    │   │   │   ├─ emit Transfer(src: UniswapV3Pool: [0x11b815efb8f581194ae79006d24e0d814b7697f6], dst: SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], wad: 94501444235)
    │   │   │   └─ ← ()
    │   │   ├─ [2534] WETH9::balanceOf(UniswapV3Pool: [0x11b815efb8f581194ae79006d24e0d814b7697f6]) [staticcall]
    │   │   │   └─ ← 6168243550873571826975
    │   │   ├─ [6552] SplitSwapV3Router::uniswapV3SwapCallback(55343862716770098540, -94501444235, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2dac17f958d2ee523a2206206994597c13d831ec70001f4)
    │   │   │   ├─ [4850] WETH9::transfer(UniswapV3Pool: [0x11b815efb8f581194ae79006d24e0d814b7697f6], 55343862716770098540)
    │   │   │   │   ├─ emit Transfer(src: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], dst: UniswapV3Pool: [0x11b815efb8f581194ae79006d24e0d814b7697f6], wad: 55343862716770098540)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← ()
    │   │   ├─ [534] WETH9::balanceOf(UniswapV3Pool: [0x11b815efb8f581194ae79006d24e0d814b7697f6]) [staticcall]
    │   │   │   └─ ← 6223587413590341925515
    │   │   ├─ emit Swap(sender: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], recipient: SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], amount0: 55343862716770098540, amount1: -94501444235, sqrtPriceX96: 3272856259955655382911356, liquidity: 2020323101133356451, tick: -201899)
    │   │   └─ ← 55343862716770098540, -94501444235
    │   └─ ← [123000000000000000000, 209675610261]
    └─ ← ()

[PASS] testSwapExactETHForTokens6() (gas: 5015124)
Traces:
  [141168] SplitSwapV3RouterVS1inchTest::setUp()
    ├─ [0] VM::envString("ETH_RPC_URL")
    │   └─ ← "<eth_rpc>"
    ├─ [0] VM::createFork("<eth_rpc>", 15347843)
    │   └─ ← 1
    ├─ [0] VM::createFork("<eth_rpc>", 15408222)
    │   └─ ← 2
    ├─ [0] VM::createFork("<eth_rpc>", 15409161)
    │   └─ ← 3
    ├─ [0] VM::createFork("<eth_rpc>", 15409149)
    │   └─ ← 4
    ├─ [0] VM::createFork("<eth_rpc>", 15396936)
    │   └─ ← 5
    ├─ [0] VM::createFork("<eth_rpc>", 15414959)
    │   └─ ← 6
    └─ ← ()

  [5015124] SplitSwapV3RouterVS1inchTest::testSwapExactETHForTokens6()
    ├─ [0] VM::selectFork(6)
    │   └─ ← ()
    ├─ [4756515] → new SplitSwapV3Router@"0xce71…c246"
    │   └─ ← 23749 bytes of code
    ├─ [178551] SplitSwapV3Router::swapExactETHForTokens{value: 65000000000000000000}(0, [0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2, 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48], SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 1661511459)
    │   ├─ [2517] UniswapV2Pair::getReserves() [staticcall]
    │   │   └─ ← 29782156120454, 18024763100780932283383, 1661511383
    │   ├─ [2504] UniswapV2Pair::getReserves() [staticcall]
    │   │   └─ ← 57357087592678, 34718391136743730616370, 1661511414
    │   ├─ [2696] UniswapV3Pool::slot0() [staticcall]
    │   │   └─ ← 1949161989756490332112985287869167, 202221, 137, 1440, 1440, 0, true
    │   ├─ [2428] UniswapV3Pool::liquidity() [staticcall]
    │   │   └─ ← 12626257621510955940
    │   ├─ [2696] 0x88e6…5640::slot0() [staticcall]
    │   │   └─ ← 1949176052846863774689606246572836, 202221, 353, 720, 720, 0, true
    │   ├─ [2428] 0x88e6…5640::liquidity() [staticcall]
    │   │   └─ ← 13700095385128499359
    │   ├─ [2696] UniswapV3Pool::slot0() [staticcall]
    │   │   └─ ← 1944541577665197083418141932566278, 202174, 15, 30, 30, 0, true
    │   ├─ [2428] UniswapV3Pool::liquidity() [staticcall]
    │   │   └─ ← 680985369554880916
    │   ├─ [23974] WETH9::deposit{value: 65000000000000000000}()
    │   │   ├─ emit Deposit(dst: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], wad: 65000000000000000000)
    │   │   └─ ← ()
    │   ├─ [70360] 0x88e6…5640::swap(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], false, 65000000000000000000, 1461446703485210103287273052203988822378723970341, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480001f4)
    │   │   ├─ [44017] FiatTokenProxy::transfer(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 107317237531)
    │   │   │   ├─ [36728] FiatTokenV2_1::transfer(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 107317237531) [delegatecall]
    │   │   │   │   ├─ emit Transfer(from: 0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640, to: SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], value: 107317237531)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← true
    │   │   ├─ [2534] WETH9::balanceOf(0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640) [staticcall]
    │   │   │   └─ ← 62958293110284383049126
    │   │   ├─ [6542] SplitSwapV3Router::uniswapV3SwapCallback(-107317237531, 65000000000000000000, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480001f4)
    │   │   │   ├─ [4850] WETH9::transfer(0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640, 65000000000000000000)
    │   │   │   │   ├─ emit Transfer(from: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], to: 0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640, value: 65000000000000000000)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← ()
    │   │   ├─ [534] WETH9::balanceOf(0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640) [staticcall]
    │   │   │   └─ ← 63023293110284383049126
    │   │   ├─ emit Swap(sender: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], recipient: SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], amount0: -107317237531, amount1: 65000000000000000000, sqrtPriceX96: 1949551762322122817926250657218929, liquidity: 13700095385128499359, tick: 202225)
    │   │   └─ ← -107317237531, 65000000000000000000
    │   └─ ← [65000000000000000000, 107317237531]
    └─ ← ()

[PASS] testSwapExactTokensForETH5() (gas: 5096608)
Traces:
  [141168] SplitSwapV3RouterVS1inchTest::setUp()
    ├─ [0] VM::envString("ETH_RPC_URL")
    │   └─ ← "<eth_rpc>"
    ├─ [0] VM::createFork("<eth_rpc>", 15347843)
    │   └─ ← 1
    ├─ [0] VM::createFork("<eth_rpc>", 15408222)
    │   └─ ← 2
    ├─ [0] VM::createFork("<eth_rpc>", 15409161)
    │   └─ ← 3
    ├─ [0] VM::createFork("<eth_rpc>", 15409149)
    │   └─ ← 4
    ├─ [0] VM::createFork("<eth_rpc>", 15396936)
    │   └─ ← 5
    ├─ [0] VM::createFork("<eth_rpc>", 15414959)
    │   └─ ← 6
    └─ ← ()

  [5096608] SplitSwapV3RouterVS1inchTest::testSwapExactTokensForETH5()
    ├─ [0] VM::selectFork(5)
    │   └─ ← ()
    ├─ [4756515] → new SplitSwapV3Router@"0xce71…c246"
    │   └─ ← 23749 bytes of code
    ├─ [0] VM::record()
    │   └─ ← ()
    ├─ [2715] DSToken::balanceOf(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84]) [staticcall]
    │   └─ ← 0
    ├─ [0] VM::accesses(DSToken: [0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2])
    │   └─ ← [0x4471cc5cac2b64523530417b5fc41f30128f5b073ab87ef99ba1de02e6bb9deb], []
    ├─ [0] VM::load(DSToken: [0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2], 0x4471cc5cac2b64523530417b5fc41f30128f5b073ab87ef99ba1de02e6bb9deb)
    │   └─ ← 0x0000000000000000000000000000000000000000000000000000000000000000
    ├─ emit WARNING_UninitedSlot(who: DSToken: [0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2], slot: 30958337876683475042314438792783957128374275924904037665556120005971243933163)
    ├─ emit SlotFound(who: DSToken: [0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2], fsig: 0x70a08231, keysHash: 0x187a2ad3b11081a3050671ee16cc42acca7475835edc3ec15a30507fff0991e9, slot: 30958337876683475042314438792783957128374275924904037665556120005971243933163)
    ├─ [715] DSToken::balanceOf(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84]) [staticcall]
    │   └─ ← 0
    ├─ [0] VM::load(DSToken: [0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2], 0x4471cc5cac2b64523530417b5fc41f30128f5b073ab87ef99ba1de02e6bb9deb)
    │   └─ ← 0x0000000000000000000000000000000000000000000000000000000000000000
    ├─ [0] VM::store(DSToken: [0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2], 0x4471cc5cac2b64523530417b5fc41f30128f5b073ab87ef99ba1de02e6bb9deb, 0x0000000000000000000000000000000000000000000000008ac7230489e80000)
    │   └─ ← ()
    ├─ [26729] DSToken::approve(SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], 2771813428670135738)
    │   ├─ emit Approval(src: SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], guy: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], wad: 2771813428670135738)
    │   └─ ← true
    ├─ [162556] SplitSwapV3Router::swapExactTokensForETH(2771813428670135738, 0, [0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2, 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2], SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], 1661262648)
    │   ├─ [2517] UniswapV2Pair::getReserves() [staticcall]
    │   │   └─ ← 227244174059871617036, 119303084096919156797, 1661255585
    │   ├─ [2504] UniswapV2Pair::getReserves() [staticcall]
    │   │   └─ ← 1075483973529477824516, 566350745129303877834, 1661262391
    │   ├─ [2696] 0xe8c6…e531::3850c7bd() [staticcall]
    │   │   └─ ← 0x0000000000000000000000000000000000000000b9a82032ff188362cb38536effffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe6e6000000000000000000000000000000000000000000000000000000000000006a0000000000000000000000000000000000000000000000000000000000000096000000000000000000000000000000000000000000000000000000000000009600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
    │   ├─ [2428] 0xe8c6…e531::1a686502() [staticcall]
    │   │   └─ ← 0x0000000000000000000000000000000000000000000000a9138636761ba04115
    │   ├─ [2696] 0x8860…daf6::3850c7bd() [staticcall]
    │   │   └─ ← 0x0000000000000000000000000000000000000000d99b1c73a36bf93532bff125fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff34e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
    │   ├─ [2428] 0x8860…daf6::1a686502() [staticcall]
    │   │   └─ ← 0x0000000000000000000000000000000000000000000000000000000000000000
    │   ├─ [2696] 0x3afd…0316::3850c7bd() [staticcall]
    │   │   └─ ← 0x0000000000000000000000000000000000000000b8b315bfbcf2a26f0c768801ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe67e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
    │   ├─ [2428] 0x3afd…0316::1a686502() [staticcall]
    │   │   └─ ← 0x000000000000000000000000000000000000000000000000095a4426697b3900
    │   ├─ [21341] DSToken::transferFrom(SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], 2771813428670135738)
    │   │   ├─ emit Transfer(src: SplitSwapV3RouterVS1inchTest: [0xb4c79dab8f259c7aee6e5b2aa729821864227e84], dst: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], wad: 2771813428670135738)
    │   │   └─ ← true
    │   ├─ [65608] 0xe8c6…e531::128acb08(000000000000000000000000ce71065d4017f316ec606fe4422e11eb2c47c2460000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000267775a0af8a7dba00000000000000000000000000000000000000000000000000000001000276a400000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000002b9f8f72aa9304c8b593d555f12ef6589cc3a579a2c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000bb8000000000000000000000000000000000000000000)
    │   │   ├─ [29962] WETH9::transfer(SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], 1452518556449785724)
    │   │   │   ├─ emit Transfer(src: 0xe8c6c9227491c0a8156a0106a0204d881bb7e531, dst: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], wad: 1452518556449785724)
    │   │   │   └─ ← true
    │   │   ├─ [2715] DSToken::balanceOf(0xe8c6c9227491c0a8156a0106a0204d881bb7e531) [staticcall]
    │   │   │   └─ ← 10077792385433250847555
    │   │   ├─ [7148] SplitSwapV3Router::uniswapV3SwapCallback(2771813428670135738, -1452518556449785724, 0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000bb8)
    │   │   │   ├─ [5445] DSToken::transfer(0xe8c6c9227491c0a8156a0106a0204d881bb7e531, 2771813428670135738)
    │   │   │   │   ├─ emit Transfer(src: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], dst: 0xe8c6c9227491c0a8156a0106a0204d881bb7e531, wad: 2771813428670135738)
    │   │   │   │   └─ ← true
    │   │   │   └─ ← ()
    │   │   ├─ [715] DSToken::balanceOf(0xe8c6c9227491c0a8156a0106a0204d881bb7e531) [staticcall]
    │   │   │   └─ ← 10080564198861920983293
    │   │   ├─  emit topic 0: 0xc42079f94a6350d7e6235f29174924f928cc2ac818eb64fed8004e115fbcca67
    │   │   │       topic 1: 0x000000000000000000000000ce71065d4017f316ec606fe4422e11eb2c47c246
    │   │   │       topic 2: 0x000000000000000000000000ce71065d4017f316ec606fe4422e11eb2c47c246
    │   │   │           data: 0x000000000000000000000000000000000000000000000000267775a0af8a7dbaffffffffffffffffffffffffffffffffffffffffffffffffebd79e119525b8840000000000000000000000000000000000000000b9899ad07d22781ed3df35290000000000000000000000000000000000000000000000a9138636761ba04115ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe6d9
    │   │   └─ ← 0x000000000000000000000000000000000000000000000000267775a0af8a7dbaffffffffffffffffffffffffffffffffffffffffffffffffebd79e119525b884
    │   ├─ [7362] WETH9::withdraw(1452518556449785724)
    │   │   ├─ [62] SplitSwapV3Router::fallback{value: 1452518556449785724}()
    │   │   │   └─ ← ()
    │   │   ├─ emit Withdrawal(src: SplitSwapV3Router: [0xce71065d4017f316ec606fe4422e11eb2c47c246], wad: 1452518556449785724)
    │   │   └─ ← ()
    │   ├─ [67] SplitSwapV3RouterVS1inchTest::fallback{value: 1452518556449785724}()
    │   │   └─ ← ()
    │   └─ ← [2771813428670135738, 1452518556449785724]
    └─ ← ()

Test result: ok. 6 passed; 0 failed; finished in 18.39s
```