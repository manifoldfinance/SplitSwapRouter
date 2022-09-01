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

[Uniswap V3 virtual reserves calculation](docs/virtual-reserves.md)

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

[Fuzz test result](docs/fuzz-test.md)

## Benchmarking against 1-Inch v4

Benchmark transactions from 1-Inch v4:
- https://etherscan.io/tx/0x3e506fb505c538805752e419356c3a6ce8b05a29d34ca563c95e894fda75bf80
- https://etherscan.io/tx/0x36eeb2248b7fc1f95bfbbf3be467ac70018a7c53120e3ec4da716707e08c01f0
- https://etherscan.io/tx/0xa9d979dc02f5a5293431d015e0eb6c9eea963dbe4a00cccd556d703eb3b91bb1
- https://etherscan.io/tx/0xf2c30b239cd6f77427b2998b930eff3c0eb4bb50a92f7993d379484161c89480
- https://etherscan.io/tx/0xd851a00e54dace8f77cd7e6f25c28818177ac3e1f5a3b18795a9c747723cb7a9

`SplitSwapRouter` uses ~20% of the gas of 1-Inch with an output within ~ 1%

### Run the tests

Benchmarks
```sh
forge test -f "$ETH_RPC_URL" -vvvvv --match-contract SplitSwapV3RouterVS1inchTest --etherscan-api-key $ETHERSCAN_API
```

[Benchmark test result](docs/benchmark-test.md)

Dynamic Api
```sh
source ./script/1inch-api-test.sh
```

[Dynamic api test result](docs/1inch-test.md)

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

- [ ] Gas checks for adding splits (more efficient method needed)
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
- [x] 1inch v4 dynamic api test
- [x] Documentation of derived math and code 