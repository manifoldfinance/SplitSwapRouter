/// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

/**
Optimal split order library to support SplitOrderV3Router
Based on UniswapV2Library: https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
*/

import "../interfaces/IUniswapV3Pool.sol";
import "../interfaces/IUniswapV3Factory.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "./Babylonian.sol";

/// @title SplitOrderLibrary
/// @author Sandy Bradley <sandy@manifoldx.com>, Sam Bacha <sam@manifoldfinance.com>
/// @notice Optimal MEV library to support SplitOrderV3Router
library SplitOrderV3Library {
    error Overflow();
    error ZeroAmount();
    error InvalidPath();
    error ZeroAddress();
    error IdenticalAddresses();
    error InsufficientLiquidity();

    struct Reserve {
        uint256 reserveIn;
        uint256 reserveOut;
    }

    struct Pool {
        // bool isV3; // is pool / pair uniV3, if false assumed V2 pool
        // uint24 fee; // pool fee % * 10000 (e.g 0.3% -> 3000)
        address pair; // pair (sushi, univ2, univ3 (4 pools))
        uint256 amountIn; // amount In for each pair
        uint256 amountOut; // amount Out for each pair
    }

    struct Swap {
        bool isReverse;
        address tokenIn;
        address tokenOut;
        Pool[6] pools; // 6 pools (sushi, univ2, univ3 (4 pools))
    }

    address internal constant UNIV3_FACTORY =
        0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address internal constant SUSHI_FACTORY =
        0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    bytes32 internal constant SUSHI_FACTORY_HASH =
        0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303;
    bytes32 internal constant BACKUP_FACTORY_HASH =
        0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;
    uint256 internal constant FF_SUSHI_FACTORY =
        0xFFC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac0000000000000000000000;
    uint256 internal constant FF_BACKUP_FACTORY =
        0xFF5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f0000000000000000000000;
    uint256 internal constant MINIMUM_LIQUIDITY = 1000;
    uint256 internal constant EST_SWAP_GAS_USED = 100000;

    function uniswapV3PoolAddress(
        address token0,
        address token1,
        uint24 fee
    ) internal returns (address pool) {
        // TODO: re-write in assembly
        bytes32 POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
        bytes32 pubKey = keccak256(
            abi.encodePacked(
                hex"ff",
                address(UNIV3_FACTORY),
                keccak256(abi.encode(token0, token1, fee)),
                POOL_INIT_CODE_HASH
            )
        );

        //bytes32 to address:
        assembly ("memory-safe") {
            let ptr := mload(0x40) // get free memory pointer
            mstore(ptr, pubKey)
            pool := mload(ptr)
        }
    }

    function quickSort(uint256[6] memory data)
        internal
        pure
        returns (uint256[6] memory index)
    {
        index = new uint256[6] = [0, 1, 2, 3, 4, 5];
        return quickPart(data, 0, 5, index);
    }

    function quickPart(
        uint256[6] memory data,
        uint256 low,
        uint256 high,
        uint256[6] memory index
    ) internal pure returns (uint256[6] memory index2) {
        if (low < high) {
            uint256 pivotVal = data[(low + high) / 2];

            uint256 low1 = low;
            uint256 high1 = high;
            for (;;) {
                while (data[low1] < pivotVal) low1++;
                while (data[high1] > pivotVal) high1--;
                if (low1 >= high1) break;
                (data[low1], data[high1]) = (data[high1], data[low1]);
                (index[low1], index[high1]) = (index[high1], index[low1]);
                low1++;
                high1--;
            }
            if (low < high1) index2 = quickPart(data, low, high1, index);
            high1++;
            if (high1 < high) index2 = quickPart(data, high1, high, index);
        }
        index2 = index;
    }

    /// @notice Retreive factoryCodeHash from factory address
    /// @param factory Dex factory
    /// @return initCodeHash factory code hash for pair address calculation
    /// @return ffFactory formatted factory address prefixed with 0xff and shifted for abi encoding
    function factoryHash(address factory)
        internal
        pure
        returns (bytes32 initCodeHash, uint256 ffFactory)
    {
        if (factory == SUSHI_FACTORY) {
            initCodeHash = SUSHI_FACTORY_HASH;
            ffFactory = FF_SUSHI_FACTORY;
        } else {
            initCodeHash = BACKUP_FACTORY_HASH;
            ffFactory = FF_BACKUP_FACTORY;
        }
    }

    /// @custom:assembly Sort tokens, zero address check
    /// @notice Returns sorted token addresses, used to handle return values from pairs sorted in this order
    /// @dev Require replaced with revert custom error
    /// @param tokenA Pool token
    /// @param tokenB Pool token
    /// @return token0 First token in pool pair
    /// @return token1 Second token in pool pair
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        if (tokenA == tokenB) revert IdenticalAddresses();
        bool isZeroAddress;

        assembly ("memory-safe") {
            switch lt(shl(96, tokenA), shl(96, tokenB)) // sort tokens
            case 0 {
                token0 := tokenB
                token1 := tokenA
            }
            default {
                token0 := tokenA
                token1 := tokenB
            }
            isZeroAddress := iszero(token0)
        }
        if (isZeroAddress) revert ZeroAddress();
    }

    /// @notice Calculates the CREATE2 address for a pair without making any external calls
    /// @dev Factory passed in directly because we have multiple factories. Format changes for new solidity spec.
    /// @param factory Factory address for dex
    /// @param tokenA Pool token
    /// @param tokenB Pool token
    /// @return pair Pair pool address
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = _asmPairFor(factory, token0, token1);
    }

    /// @custom:assembly Calculates the CREATE2 address for a pair without making any external calls from pre-sorted tokens
    /// @notice Calculates the CREATE2 address for a pair without making any external calls from pre-sorted tokens
    /// @dev Factory passed in directly because we have multiple factories. Format changes for new solidity spec.
    /// @param factory Factory address for dex
    /// @param token0 Pool token
    /// @param token1 Pool token
    /// @return pair Pair pool address
    function _asmPairFor(
        address factory,
        address token0,
        address token1
    ) internal pure returns (address pair) {
        (bytes32 initCodeHash, uint256 ffFactory) = factoryHash(factory);
        // There is one contract for every combination of tokens,
        // which is deployed using CREATE2.
        // The derivation of this address is given by:
        //   address(keccak256(abi.encodePacked(
        //       bytes(0xFF),
        //       address(UNISWAP_FACTORY_ADDRESS),
        //       keccak256(abi.encodePacked(token0, token1)),
        //       bytes32(UNISWAP_PAIR_INIT_CODE_HASH),
        //   )));
        assembly ("memory-safe") {
            let ptr := mload(0x40) // get free memory pointer
            mstore(ptr, shl(96, token0))
            mstore(add(ptr, 0x14), shl(96, token1))
            let salt := keccak256(ptr, 0x28) // keccak256(token0, token1)
            mstore(ptr, ffFactory) // factory address prefixed with 0xFF as a bigendian uint
            mstore(add(ptr, 0x15), salt)
            mstore(add(ptr, 0x35), initCodeHash) // factory init code hash
            pair := keccak256(ptr, 0x55)
        }
    }

    /// @notice Fetches and sorts the reserves for a pair
    /// @param factory Factory address for dex
    /// @param tokenA Pool token
    /// @param tokenB Pool token
    /// @return reserveA Reserves for tokenA
    /// @return reserveB Reserves for tokenB
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            _asmPairFor(factory, token0, token1)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    /// @notice Given some asset amount and reserves, returns an amount of the other asset representing equivalent value
    /// @dev Require replaced with revert custom error
    /// @param amountA Amount of token A
    /// @param reserveA Reserves for tokenA
    /// @param reserveB Reserves for tokenB
    /// @return amountB Amount of token B returned
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        if (_isZero(amountA)) revert ZeroAmount();
        if (_isZero(reserveA) || _isZero(reserveB))
            revert InsufficientLiquidity();
        amountB = (amountA * reserveB) / reserveA;
    }

    /// @notice Given an input asset amount, returns the maximum output amount of the other asset (accounting for fees) given reserves
    /// @dev Require replaced with revert custom error
    /// @param amountIn Amount of token in
    /// @param reserveIn Reserves for token in
    /// @param reserveOut Reserves for token out
    /// @return amountOut Amount of token out returned
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        if (_isZero(amountIn)) revert ZeroAmount();
        if (reserveIn < MINIMUM_LIQUIDITY || reserveOut < MINIMUM_LIQUIDITY)
            revert InsufficientLiquidity();
        // save gas, perform internal overflow check
        unchecked {
            uint256 amountInWithFee = amountIn * uint256(997);
            uint256 numerator = amountInWithFee * reserveOut;
            if (reserveOut != numerator / amountInWithFee) revert Overflow();
            uint256 denominator = (reserveIn * uint256(1000)) + amountInWithFee;
            amountOut = numerator / denominator;
        }
    }

    /// @notice Given an input asset amount, returns the maximum output amount of the other asset (accounting for fees) given reserves
    /// @dev Require replaced with revert custom error
    /// @param amountIn Amount of token in
    /// @param reserveIn Reserves for token in
    /// @param reserveOut Reserves for token out
    /// @return amountOut Amount of token out returned
    function getAmountOutFee(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) internal pure returns (uint256 amountOut) {
        if (_isZero(amountIn)) revert ZeroAmount();
        if (reserveIn < MINIMUM_LIQUIDITY || reserveOut < MINIMUM_LIQUIDITY)
            revert InsufficientLiquidity();
        // save gas, perform internal overflow check
        unchecked {
            uint256 amountInWithFee = amountIn * (1000000 - fee);
            uint256 numerator = amountInWithFee * reserveOut;
            if (reserveOut != numerator / amountInWithFee) revert Overflow();
            uint256 denominator = (reserveIn * 1000000) + amountInWithFee;
            amountOut = numerator / denominator;
        }
    }

    /// @notice Returns the minimum input asset amount required to buy the given output asset amount (accounting for fees) given reserves
    /// @dev Require replaced with revert custom error
    /// @param amountOut Amount of token out wanted
    /// @param reserveIn Reserves for token in
    /// @param reserveOut Reserves for token out
    /// @return amountIn Amount of token in required
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        if (_isZero(amountOut)) revert ZeroAmount();
        if (
            reserveIn < MINIMUM_LIQUIDITY ||
            reserveOut < MINIMUM_LIQUIDITY ||
            reserveOut <= amountOut
        ) revert InsufficientLiquidity();
        // save gas, perform internal overflow check
        unchecked {
            uint256 numerator = reserveIn * amountOut * uint256(1000);
            if ((reserveIn * uint256(1000)) != numerator / amountOut)
                revert Overflow();
            uint256 denominator = (reserveOut - amountOut) * uint256(997);
            amountIn = (numerator / denominator) + 1;
        }
    }

    /// @notice Given an input asset amount and an array of token addresses, calculates all subsequent maximum output token amounts by calling getReserves for each pair of token addresses in the path in turn, and using these to call getAmountOut
    /// @dev Require replaced with revert custom error
    /// @param factory Factory address of dex
    /// @param amountIn Amount of token in
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        uint256 length = path.length;
        if (length < 2) revert InvalidPath();
        amounts = new uint256[](length);
        amounts[0] = amountIn;
        for (uint256 i; i < _dec(length); i = _inc(i)) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[_inc(i)]
            );
            amounts[_inc(i)] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    /// @notice Fetches swap data for each pair and amounts given a desired output and path
    /// @param factory1 Backup Factory address for dex
    /// @param amountIn Amount in for first token in path
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @return swaps Array Swap data for each user swap in path
    function getSwapsOut(
        address weth,
        address factory1,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (Swap[] memory swaps) {
        uint256 length = path.length;
        if (length < 2) revert InvalidPath();
        swaps = new Swap[](_dec(length));
        for (uint256 i; i < _dec(length); i = _inc(i)) {
            if (_isNonZero(i))
                amountIn =
                    swaps[_dec(i)].pools[0].amountOut +
                    swaps[_dec(i)].pools[1].amountOut +
                    swaps[_dec(i)].pools[2].amountOut +
                    swaps[_dec(i)].pools[3].amountOut +
                    swaps[_dec(i)].pools[4].amountOut +
                    swaps[_dec(i)].pools[5].amountOut; // gather split swap amounts
            {
                (address token0, address token1) = sortTokens(
                    path[i],
                    path[_inc(i)]
                );
                swaps[i].pools[0].pair = _asmPairFor(
                    SUSHI_FACTORY,
                    token0,
                    token1
                ); // sushi
                swaps[i].pools[1].pair = _asmPairFor(factory1, token0, token1); // univ2
                swaps[i].pools[2].pair = uniswapV3PoolAddress(
                    token0,
                    token1,
                    3000
                ); // univ3 0.3 %
                swaps[i].pools[3].pair = uniswapV3PoolAddress(
                    token0,
                    token1,
                    500
                ); // univ3 0.05 %
                swaps[i].pools[4].pair = uniswapV3PoolAddress(
                    token0,
                    token1,
                    100
                ); // univ3 0.01 %
                swaps[i].pools[5].pair = uniswapV3PoolAddress(
                    token0,
                    token1,
                    10000
                ); // univ3 1 %
                swaps[i].isReverse = path[i] == token1;
            }
            swaps[i].tokenIn = path[i];
            swaps[i].tokenOut = path[_inc(i)];
            Reserve[6] memory reserves;
            {
                (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
                    swaps[i].pools[0].pair
                ).getReserves();
                (reserves[0].reserveIn, reserves[0].reserveOut) = swaps[i]
                    .isReverse
                    ? (reserve1, reserve0)
                    : (reserve0, reserve1);
                (reserve0, reserve1, ) = IUniswapV2Pair(swaps[i].pools[1].pair)
                    .getReserves();
                (reserves[1].reserveIn, reserves[1].reserveOut) = swaps[i]
                    .isReverse
                    ? (reserve1, reserve0)
                    : (reserve0, reserve1);
                uint256 sqrtPriceX96 = IUniswapV3Pool(swaps[i].pools[2].pair)
                    .slot0();
                uint256 liquidity = IUniswapV3Pool(swaps[i].pools[2].pair)
                    .liquidity();
                (reserve0, reserve1) = (
                    liquidity / sqrtPriceX96,
                    liquidity * sqrtPriceX96
                );
                (reserves[2].reserveIn, reserves[2].reserveOut) = swaps[i]
                    .isReverse
                    ? (reserve1, reserve0)
                    : (reserve0, reserve1);
                sqrtPriceX96 = IUniswapV3Pool(swaps[i].pools[3].pair).slot0();
                liquidity = IUniswapV3Pool(swaps[i].pools[3].pair).liquidity();
                (reserve0, reserve1) = (
                    liquidity / sqrtPriceX96,
                    liquidity * sqrtPriceX96
                );
                (reserves[3].reserveIn, reserves[3].reserveOut) = swaps[i]
                    .isReverse
                    ? (reserve1, reserve0)
                    : (reserve0, reserve1);
                sqrtPriceX96 = IUniswapV3Pool(swaps[i].pools[4].pair).slot0();
                liquidity = IUniswapV3Pool(swaps[i].pools[4].pair).liquidity();
                (reserve0, reserve1) = (
                    liquidity / sqrtPriceX96,
                    liquidity * sqrtPriceX96
                );
                (reserves[4].reserveIn, reserves[4].reserveOut) = swaps[i]
                    .isReverse
                    ? (reserve1, reserve0)
                    : (reserve0, reserve1);
                sqrtPriceX96 = IUniswapV3Pool(swaps[i].pools[5].pair).slot0();
                liquidity = IUniswapV3Pool(swaps[i].pools[5].pair).liquidity();
                (reserve0, reserve1) = (
                    liquidity / sqrtPriceX96,
                    liquidity * sqrtPriceX96
                );
                (reserves[5].reserveIn, reserves[5].reserveOut) = swaps[i]
                    .isReverse
                    ? (reserve1, reserve0)
                    : (reserve0, reserve1);
            }
            // find optimal route
            (swaps[i].pools) = _optimalRoute(
                weth,
                swaps[i].tokenOut,
                amountIn,
                reserves
            );
        }
    }

    /// @notice Given an output asset amount and an array of token addresses, calculates all preceding minimum input token amounts by calling getReserves for each pair of token addresses in the path in turn, and using these to call getAmountIn
    /// @dev Require replaced with revert custom error
    /// @param factory Factory address of dex
    /// @param amountOut Amount of token out wanted
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        uint256 length = path.length;
        if (length < 2) revert InvalidPath();
        amounts = new uint256[](length);
        amounts[_dec(length)] = amountOut;
        for (uint256 i = _dec(length); _isNonZero(i); i = _dec(i)) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[_dec(i)],
                path[i]
            );
            amounts[_dec(i)] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    /// @notice Fetches swap data for each pair and amounts given a desired output and path
    /// @param factory1 Factory address for dex
    /// @param amountOut Amount out for last token in path
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @return swaps Array Swap data for each user swap in path
    function getSwapsIn(
        address weth,
        address factory1,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (Swap[] memory swaps) {
        uint256 length = path.length;
        if (length < 2) revert InvalidPath();
        swaps = new Swap[](_dec(length));
        for (uint256 i = _dec(length); _isNonZero(i); i = _dec(i)) {
            if (i < _dec(length))
                amountOut = swaps[i].amountIn0 + swaps[i].amountIn1; // gather split swap amounts
            {
                (address token0, address token1) = sortTokens(
                    path[_dec(i)],
                    path[i]
                );
                swaps[_dec(i)].pair0 = _asmPairFor(
                    SUSHI_FACTORY,
                    token0,
                    token1
                );
                swaps[_dec(i)].pair1 = _asmPairFor(factory1, token0, token1);
                swaps[_dec(i)].isReverse = path[i] == token0;
            }
            swaps[_dec(i)].tokenIn = path[_dec(i)];
            swaps[_dec(i)].tokenOut = path[i];
            uint256 reserveIn0;
            uint256 reserveOut0;
            uint256 reserveIn1;
            uint256 reserveOut1;
            {
                (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
                    swaps[_dec(i)].pair0
                ).getReserves();
                (reserveIn0, reserveOut0) = swaps[_dec(i)].isReverse
                    ? (reserve1, reserve0)
                    : (reserve0, reserve1);
                (reserve0, reserve1, ) = IUniswapV2Pair(swaps[_dec(i)].pair1)
                    .getReserves();
                (reserveIn1, reserveOut1) = swaps[_dec(i)].isReverse
                    ? (reserve1, reserve0)
                    : (reserve0, reserve1);
            }
            // find optimal route
            (
                swaps[_dec(i)].amountIn0,
                swaps[_dec(i)].amountOut0,
                swaps[_dec(i)].amountIn1,
                swaps[_dec(i)].amountOut1
            ) = _optimalRouteIn(
                weth,
                swaps[_dec(i)].tokenIn,
                amountOut,
                reserveIn0,
                reserveOut0,
                reserveIn1,
                reserveOut1
            );
        }
    }

    function _optimalRoute(
        address weth,
        address tokenOut,
        uint256 amountIn,
        Reserve[6] memory reserves
    ) internal view returns (Pool[6] memory pools) {
        uint256[6] memory amountsOut;
        // first 3 pools have fee of 0.3%
        for (uint256 i; i < 2; i = _inc(i)) {
            amountsOut[i] = getAmountOut(
                amountIn,
                reserves[i].reserveIn,
                reserves[i].reserveOut
            );
        }
        // next 3 pools have variable rates
        amountsOut[3] = getAmountOutFee(
            amountIn,
            reserves[3].reserveIn,
            reserves[3].reserveOut,
            500
        );
        amountsOut[4] = getAmountOutFee(
            amountIn,
            reserves[4].reserveIn,
            reserves[4].reserveOut,
            100
        );
        amountsOut[5] = getAmountOutFee(
            amountIn,
            reserves[5].reserveIn,
            reserves[5].reserveOut,
            10000
        );

        uint256[6] memory index = quickSort(amountsOut); // sorts in ascending order (i.e. best price is last)
        pools[index[5]].amountIn = amountIn; // set best price as default, before splitting
        pools[index[5]].amountOut = amountsOut[index[5]];
        // loop through split pairs
        for (uint256 i = 4; _isNonZero(0); i = _dec(i)) {
            uint256 poolIndex = index[i];
            if (_isNonZero(amountsOut[poolIndex])) {
                // split route
                (
                    uint256 amountIn0,
                    uint256 amountOut0,
                    uint256 amountIn1,
                    uint256 amountOut1
                ) = _splitRoute(
                        weth,
                        tokenOut,
                        amountIn,
                        amountsOut[_inc(poolIndex)],
                        reserves[_inc(poolIndex)].reserveIn,
                        reserves[_inc(poolIndex)].reserveOut,
                        reserves[poolIndex].reserveIn,
                        reserves[poolIndex].reserveOut
                    );
                if (_isNonZero(amountIn1)) {
                    // route split
                    pools[_inc(poolIndex)].amountIn = amountIn0;
                    pools[_inc(poolIndex)].amountOut = amountOut0;
                    pools[poolIndex].amountIn = amountIn1;
                    pools[poolIndex].amountOut = amountOut1;
                    amountIn = amountIn - amountIn0; // TODO: improve logic here
                }
            }
        }
    }

    function _splitRoute(
        address weth,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutOnePair,
        uint256 reserveIn0,
        uint256 reserveOut0,
        uint256 reserveIn1,
        uint256 reserveOut1
    )
        internal
        view
        returns (
            uint256 amountIn0,
            uint256 amountOut0,
            uint256 amountIn1,
            uint256 amountOut1
        )
    {
        // set single swap at best rate as default
        amountIn0 = amountIn;
        amountOut0 = amountOutOnePair;
        uint256 amount0 = _amountToSyncPrices(
            reserveIn0,
            reserveOut0,
            reserveIn1,
            reserveOut1
        );
        if (amount0 < amountIn - MINIMUM_LIQUIDITY) {
            // reserveOut0 =
            //     reserveOut0 -
            //     getAmountOut(amount0, reserveIn0, reserveOut0);
            // reserveIn0 = reserveIn0 + amount0;
            uint256 amountInFirstPair = amount0 +
                ((amountIn - amount0) * (reserveIn0 + amount0)) /
                (reserveIn0 + amount0 + reserveIn1);
            uint256 amountOutFirstPair = getAmountOut(
                amountInFirstPair,
                reserveIn0,
                reserveOut0
            );
            uint256 amountOutSecondPair = getAmountOut(
                amountIn - amountInFirstPair,
                reserveIn1,
                reserveOut1
            );
            if (
                _isNonZero(
                    amountOutFirstPair + amountOutSecondPair - amountOutOnePair
                ) &&
                _wethAmount(
                    weth,
                    tokenOut,
                    amountOutFirstPair + amountOutSecondPair - amountOutOnePair
                ) >
                block.basefee * EST_SWAP_GAS_USED
            ) {
                // split route better than extra gas cost
                amountIn0 = amountInFirstPair;
                amountIn1 = amountIn - amountInFirstPair;
                amountOut0 = amountOutFirstPair;
                amountOut1 = amountOutSecondPair;
            }
        }
    }

    function _optimalRouteIn(
        address weth,
        address tokenIn,
        uint256 amountOut,
        uint256 reserveIn0,
        uint256 reserveOut0,
        uint256 reserveIn1,
        uint256 reserveOut1
    )
        internal
        view
        returns (
            uint256 amountIn0,
            uint256 amountOut0,
            uint256 amountIn1,
            uint256 amountOut1
        )
    {
        uint256 uniAmountIn;
        uint256 sushiAmountIn;
        if (_isNonZero(reserveOut1))
            uniAmountIn = getAmountIn(amountOut, reserveIn1, reserveOut1);
        if (_isNonZero(reserveOut0))
            sushiAmountIn = getAmountIn(amountOut, reserveIn0, reserveOut0);
        if (uniAmountIn > sushiAmountIn && _isNonZero(sushiAmountIn)) {
            // sushi (dex0) better price
            amountOut0 = amountOut;
            amountIn0 = sushiAmountIn;
            if (_isNonZero(uniAmountIn)) {
                // split route
                (amountIn0, amountOut0, amountIn1, amountOut1) = _splitRouteIn(
                    weth,
                    tokenIn,
                    amountOut,
                    sushiAmountIn,
                    reserveIn0,
                    reserveOut0,
                    reserveIn1,
                    reserveOut1
                );
            }
        } else if (_isNonZero(uniAmountIn)) {
            // uni (dex1) better price
            amountIn1 = uniAmountIn;
            amountOut1 = amountOut;
            if (_isNonZero(sushiAmountIn)) {
                // split route
                (amountIn1, amountOut1, amountIn0, amountOut0) = _splitRouteIn(
                    weth,
                    tokenIn,
                    amountOut,
                    uniAmountIn,
                    reserveIn1,
                    reserveOut1,
                    reserveIn0,
                    reserveOut0
                );
            }
        }
    }

    function _splitRouteIn(
        address weth,
        address tokenIn,
        uint256 amountOut,
        uint256 amountInOnePair,
        uint256 reserveIn0,
        uint256 reserveOut0,
        uint256 reserveIn1,
        uint256 reserveOut1
    )
        internal
        view
        returns (
            uint256 amountIn0,
            uint256 amountOut0,
            uint256 amountIn1,
            uint256 amountOut1
        )
    {
        // set single swap at best rate as default
        amountIn0 = amountInOnePair;
        amountOut0 = amountOut;
        uint256 amount0 = _amountToSyncPrices(
            reserveIn0,
            reserveOut0,
            reserveIn1,
            reserveOut1
        );
        if (
            _isNonZero(amount0) && amount0 < amountInOnePair - MINIMUM_LIQUIDITY
        ) {
            // reserveOut0 =
            //     reserveOut0 -
            //     getAmountOut(amount0, reserveIn0, reserveOut0);
            // reserveIn0 = reserveIn0 + amount0;
            uint256 amountInFirstPair;
            unchecked {
                amountInFirstPair =
                    amount0 +
                    ((amountInOnePair - amount0) * (reserveIn0 + amount0)) /
                    (reserveIn0 + amount0 + reserveIn1);
            }

            uint256 amountOutFirstPair = getAmountOut(
                amountInFirstPair,
                reserveIn0,
                reserveOut0
            );
            uint256 amountOutSecondPair = amountOut - amountOutFirstPair;
            uint256 amountInSecondPair = getAmountIn(
                amountOutSecondPair,
                reserveIn1,
                reserveOut1
            );
            if (
                _isNonZero(
                    amountInOnePair - amountInFirstPair - amountInSecondPair
                ) &&
                _wethAmount(
                    weth,
                    tokenIn,
                    amountInOnePair - amountInFirstPair - amountInSecondPair
                ) >
                block.basefee * EST_SWAP_GAS_USED
            ) {
                // split route better than extra gas cost
                amountIn0 = amountInFirstPair;
                amountIn1 = amountInSecondPair;
                amountOut0 = amountOutFirstPair;
                amountOut1 = amountOutSecondPair;
            }
        }
    }

    function _amountToSyncPrices(
        uint256 x1,
        uint256 y1,
        uint256 x2,
        uint256 y2
    ) internal pure returns (uint256) {
        unchecked {
            return
                (x1 *
                    (Babylonian.sqrt(9 + ((1000000 * x2 * y1) / (y2 * x1))) -
                        1997)) / 1994;
        }
    }

    /// @notice Calculate eth value of a token amount
    /// @param token Address of token
    /// @param amount Amount of token
    /// @return eth value
    function _wethAmount(
        address weth,
        address token,
        uint256 amount
    ) internal view returns (uint256) {
        if (token == weth) return amount;
        address pair;
        bool isReverse;
        {
            (address token0, address token1) = sortTokens(token, weth);
            pair = _asmPairFor(SUSHI_FACTORY, token0, token1);
            isReverse = weth == token0;
        }
        {
            (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair)
                .getReserves();
            (uint112 reserveIn, uint112 reserveOut) = isReverse
                ? (reserve1, reserve0)
                : (reserve0, reserve1);
            return getAmountOut(amount, reserveIn, reserveOut);
        }
    }

    /// @custom:gas Uint256 zero check gas saver
    /// @notice Uint256 zero check gas saver
    /// @param value Number to check
    function _isZero(uint256 value) internal pure returns (bool boolValue) {
        assembly ("memory-safe") {
            boolValue := iszero(value)
        }
    }

    /// @custom:gas Uint256 not zero check gas saver
    /// @notice Uint256 not zero check gas saver
    /// @param value Number to check
    function _isNonZero(uint256 value) internal pure returns (bool boolValue) {
        assembly ("memory-safe") {
            boolValue := iszero(iszero(value))
        }
    }

    /// @custom:gas Unchecked increment gas saver
    /// @notice Unchecked increment gas saver for loops
    /// @param i Number to increment
    function _inc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    /// @custom:gas Unchecked decrement gas saver
    /// @notice Unchecked decrement gas saver for loops
    /// @param i Number to decrement
    function _dec(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i - 1;
        }
    }
}