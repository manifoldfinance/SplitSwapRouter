/// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

/**
Optimal split swap library to support SplitSwapV3Router
Based on UniswapV2Library: https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
*/

import "../interfaces/IUniswapV3Pool.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "./Babylonian.sol";

/// @title SplitSwapV3Library
/// @author Sandy Bradley <@sandybradley>, ControlCplusControlV <@ControlCplusControlV>
/// @notice Optimal MEV library to support SplitSwapV3Router
library SplitSwapV3Library {
    error Overflow();
    error ZeroAmount();
    error InvalidPath();
    error ZeroAddress();
    error IdenticalAddresses();
    error InsufficientLiquidity();

    /// @notice struct for pool reserves
    /// @param reserveIn amount of reserves (or virtual reserves) in pool for tokenIn
    /// @param reserveOut amount of reserves (or virtual reserves) in pool for tokenOut
    struct Reserve {
        uint256 reserveIn;
        uint256 reserveOut;
    }

    /// @notice struct for pool swap info
    /// @param pair pair / pool address (sushi, univ2, univ3 (3 pools))
    /// @param amountIn amount In for swap
    /// @param amountOut amount Out for swap
    struct Pool {
        address pair;
        uint256 amountIn;
        uint256 amountOut;
    }

    /// @notice struct for swap info
    /// @param isReverse true if token0 == tokenOut
    /// @param tokenIn address of token In
    /// @param tokenOut address of token Out
    /// @param pools 5 element array of pool split swap info
    struct Swap {
        bool isReverse;
        address tokenIn;
        address tokenOut;
        Pool[5] pools; // 5 pools (sushi, univ2, univ3 (3 pools))
    }

    /// @dev Ethereum mainnet, Optimism, Arbitrum, Polygon address
    address internal constant UNIV3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    /// @dev /// @dev Minimum pool liquidity to interact with
    uint256 internal constant MINIMUM_LIQUIDITY = 1000;
    /// @dev Estimated gas used for average single swap
    uint256 internal constant EST_SWAP_GAS_USED = 140000;

    /// @dev calculate uinswap v3 pool address
    /// @param token0 address of token0
    /// @param token1 address of token1
    /// @param fee pool fee as ratio of 1000000
    function uniswapV3PoolAddress(
        address token0,
        address token1,
        uint24 fee
    ) internal pure returns (address pool) {
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

    /// @dev get fee for pool as a fraction of 1000000 (i.e. 0.3% -> 3000)
    /// @param index Reference order is hard coded as sushi, univ2, univ3 (0.3%), univ3 (0.05%), univ3 (1%)
    function getFee(uint256 index) internal pure returns (uint256) {
        if (index <= 2) return 3000;
        // sushi, univ2 and 0.3% univ3
        else if (index == 3) return 500;
        else return 10000;
    }

    /// @custom:assembly Sort tokens, zero address check
    /// @notice Returns sorted token addresses, used to handle return values from pairs sorted in this order
    /// @dev Require replaced with revert custom error
    /// @param tokenA Pool token
    /// @param tokenB Pool token
    /// @return token0 First token in pool pair
    /// @return token1 Second token in pool pair
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
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
        address tokenB,
        bytes32 factoryHash
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = _asmPairFor(factory, token0, token1, factoryHash);
    }

    /// @custom:assembly Calculates the CREATE2 address for a pair without making any external calls from pre-sorted tokens
    /// @notice Calculates the CREATE2 address for a pair without making any external calls from pre-sorted tokens
    /// @dev Factory passed in directly because we have multiple factories. Format changes for new solidity spec.
    /// @param factory Factory address for dex
    /// @param token0 Pool token
    /// @param token1 Pool token
    /// @param factoryHash Init code hash for factory
    /// @return pair Pair pool address
    function _asmPairFor(
        address factory,
        address token0,
        address token1,
        bytes32 factoryHash
    ) internal pure returns (address pair) {
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
            mstore(ptr, 0xFF00000000000000000000000000000000000000000000000000000000000000) // buffered 0xFF prefix
            mstore(add(ptr, 0x01), shl(96, factory)) // factory address prefixed
            mstore(add(ptr, 0x15), salt)
            mstore(add(ptr, 0x35), factoryHash) // factory init code hash
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
        address tokenB,
        bytes32 factoryHash
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_asmPairFor(factory, token0, token1, factoryHash))
            .getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
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
        if (_isZero(reserveA) || _isZero(reserveB)) revert InsufficientLiquidity();
        amountB = (amountA * reserveB) / reserveA;
    }

    function quoteFee(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB,
        uint256 fee
    ) internal pure returns (uint256 amountB) {
        if (_isZero(amountA)) revert ZeroAmount();
        if (_isZero(reserveA) || _isZero(reserveB)) revert InsufficientLiquidity();
        amountB = ((1000000 - fee) * amountA * reserveB) / (1000000 * reserveA);
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
        if (reserveIn < MINIMUM_LIQUIDITY || reserveOut < MINIMUM_LIQUIDITY) revert InsufficientLiquidity();
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
        if (reserveIn < MINIMUM_LIQUIDITY || reserveOut < MINIMUM_LIQUIDITY) revert InsufficientLiquidity();
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
        if (reserveIn < MINIMUM_LIQUIDITY || reserveOut < MINIMUM_LIQUIDITY || reserveOut <= amountOut)
            revert InsufficientLiquidity();
        // save gas, perform internal overflow check
        unchecked {
            uint256 numerator = reserveIn * amountOut * uint256(1000);
            if ((reserveIn * uint256(1000)) != numerator / amountOut) revert Overflow();
            uint256 denominator = (reserveOut - amountOut) * uint256(997);
            amountIn = (numerator / denominator) + 1;
        }
    }

    /// @notice Returns the minimum input asset amount required to buy the given output asset amount (accounting for fees) given reserves
    /// @dev Require replaced with revert custom error
    /// @param amountOut Amount of token out wanted
    /// @param reserveIn Reserves for token in
    /// @param reserveOut Reserves for token out
    /// @return amountIn Amount of token in required
    function getAmountInFee(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) internal pure returns (uint256 amountIn) {
        if (_isZero(amountOut)) revert ZeroAmount();
        if (reserveIn < MINIMUM_LIQUIDITY || reserveOut < MINIMUM_LIQUIDITY || reserveOut <= amountOut)
            revert InsufficientLiquidity();
        // save gas, perform internal overflow check
        unchecked {
            uint256 numerator = reserveIn * amountOut * uint256(1000000);
            if ((reserveIn * uint256(1000000)) != numerator / amountOut) revert Overflow();
            uint256 denominator = (reserveOut - amountOut) * (1000000 - fee);
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
        bytes32 factoryHash,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        uint256 length = path.length;
        if (length < 2) revert InvalidPath();
        amounts = new uint256[](length);
        amounts[0] = amountIn;
        for (uint256 i; i < _dec(length); i = _inc(i)) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[_inc(i)], factoryHash);
            amounts[_inc(i)] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    /// @dev checks codesize for contract existence
    /// @param _addr address of contract to check
    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    /// @dev populates and returns Reserve struct array for each pool address
    /// @param isReverse true if token0 == tokenOut
    /// @param pools 5 element array of Pool structs populated with pool addresses
    function _getReserves(bool isReverse, Pool[5] memory pools) internal view returns (Reserve[5] memory reserves) {
        // 2 V2 pools
        for (uint256 i; i < 2; i = _inc(i)) {
            if (!isContract(pools[i].pair)) continue;
            (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pools[i].pair).getReserves();
            (reserves[i].reserveIn, reserves[i].reserveOut) = isReverse ? (reserve1, reserve0) : (reserve0, reserve1);
        }
        // 4 V3 pools
        for (uint256 i = 2; i < 5; i = _inc(i)) {
            if (!isContract(pools[i].pair)) continue;
            uint160 sqrtPriceX96 = uint160(IUniswapV3Pool(pools[i].pair).slot0());
            // if (sqrtPriceX96 < 2**96) continue; // price too small
            // sqrtPriceX96 = (sqrtPriceX96 / uint160(2**96)) + uint160(1); // account for rounding error
            uint256 liquidity = uint256(IUniswapV3Pool(pools[i].pair).liquidity());
            if (_isNonZero(liquidity) && _isNonZero(sqrtPriceX96)) {
                unchecked {
                    uint256 reserve0 = (liquidity * uint256(2**96)) / uint256(sqrtPriceX96);
                    uint256 reserve1 = (liquidity * uint256(sqrtPriceX96)) / uint256(2**96);
                    (reserves[i].reserveIn, reserves[i].reserveOut) = isReverse
                        ? (reserve1, reserve0)
                        : (reserve0, reserve1);
                }
            }
        }
    }

    /// @dev calculate pool addresses for token0/1 & factory/fee
    function _getPools(
        address factory0,
        address factory1,
        address token0,
        address token1,
        bytes32 factoryHash0,
        bytes32 factoryHash1
    ) internal pure returns (Pool[5] memory pools) {
        pools[0].pair = _asmPairFor(factory0, token0, token1, factoryHash0); // sushi
        pools[1].pair = _asmPairFor(factory1, token0, token1, factoryHash1); // univ2
        pools[2].pair = uniswapV3PoolAddress(token0, token1, 3000); // univ3 0.3 %
        pools[3].pair = uniswapV3PoolAddress(token0, token1, 500); // univ3 0.05 %
        pools[4].pair = uniswapV3PoolAddress(token0, token1, 10000); // univ3 1 %
    }

    /// @notice Fetches swap data for each pair and amounts given a desired output and path
    /// @param factory1 Backup Factory address for dex
    /// @param amountIn Amount in for first token in path
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @return swaps Array Swap data for each user swap in path
    function getSwapsOut(
        address factory0,
        address factory1,
        uint256 amountIn,
        bytes32 factoryHash0,
        bytes32 factoryHash1,
        address[] memory path
    ) internal view returns (Swap[] memory swaps) {
        uint256 length = path.length;
        if (length < 2) revert InvalidPath();
        swaps = new Swap[](_dec(length));
        for (uint256 i; i < _dec(length); i = _inc(i)) {
            if (_isNonZero(i)) {
                amountIn = 0; // reset amountIn
                for (uint256 j; j < 5; j = _inc(j)) {
                    amountIn = amountIn + swaps[_dec(i)].pools[j].amountOut;
                }
            }
            {
                (address token0, address token1) = sortTokens(path[i], path[_inc(i)]);
                swaps[i].pools = _getPools(factory0, factory1, token0, token1, factoryHash0, factoryHash1);
                swaps[i].isReverse = path[i] == token1;
            }
            swaps[i].tokenIn = path[i];
            swaps[i].tokenOut = path[_inc(i)];
            uint256[5] memory amountsIn;
            uint256[5] memory amountsOut;
            {
                Reserve[5] memory reserves = _getReserves(swaps[i].isReverse, swaps[i].pools);
                // find optimal route
                (amountsIn, amountsOut) = _optimalRouteOut(amountIn, reserves);
            }

            for (uint256 j; j < 5; j = _inc(j)) {
                swaps[i].pools[j].amountIn = amountsIn[j];
                swaps[i].pools[j].amountOut = amountsOut[j];
            }
        }
    }

    /// @dev sorts possible swaps by best price, then assigns optimal split
    function _optimalRouteOut(uint256 amountIn, Reserve[5] memory reserves)
        internal
        pure
        returns (uint256[5] memory amountsIn, uint256[5] memory amountsOut)
    {
        // calculate best rate for a single swap (i.e. no splitting)
        uint256[5] memory amountsOutSingleSwap;
        // first 3 pools have fee of 0.3%
        for (uint256 i; i < 3; i = _inc(i)) {
            if (reserves[i].reserveOut > MINIMUM_LIQUIDITY) {
                amountsOutSingleSwap[i] = getAmountOut(amountIn, reserves[i].reserveIn, reserves[i].reserveOut);
            }
        }
        // next 2 pools have variable rates
        for (uint256 i = 3; i < 5; i = _inc(i)) {
            if (reserves[i].reserveOut > MINIMUM_LIQUIDITY) {
                amountsOutSingleSwap[i] = getAmountOutFee(
                    amountIn,
                    reserves[i].reserveIn,
                    reserves[i].reserveOut,
                    getFee(i)
                );
                if (i == 3 && _isNonZero(amountsOutSingleSwap[i])) {
                    // 0.05 % pool potentially crosses more ticks, lowering expected output (add margin of error 0.1% of amountIn)
                    amountsOutSingleSwap[i] = amountsOutSingleSwap[i] - amountsOutSingleSwap[i] / 1000;
                }
            }
        }
        (amountsIn, amountsOut) = _splitSwapOut(amountIn, amountsOutSingleSwap, reserves);
    }

    /// @notice assigns optimal route for maximum amount out, given pool reserves
    function _splitSwapOut(
        uint256 amountIn,
        uint256[5] memory amountsOutSingleSwap,
        Reserve[5] memory reserves
    ) internal pure returns (uint256[5] memory amountsIn, uint256[5] memory amountsOut) {
        uint256[5] memory index = _sortArray(amountsOutSingleSwap); // sorts in ascending order (i.e. best price is last)
        if (_isNonZero(amountsOutSingleSwap[index[4]])) {
            amountsIn[index[4]] = amountIn; // set best price as default, before splitting
            amountsOut[index[4]] = amountsOutSingleSwap[index[4]];
            uint256[5] memory amountsToSyncPrices;
            uint256 cumulativeAmount;
            uint256 cumulativeReserveIn = reserves[index[4]].reserveIn;
            uint256 cumulativeReserveOut = reserves[index[4]].reserveOut;
            uint256 numSplits;
            // uint256 prevAmountOut = amountsOutSingleSwap[index[4]];
            // calculate amount to sync prices cascading through each pool with best prices first, while cumulative amount < amountIn
            // iteratevly assign splits, testing against extra gas of each split
            for (uint256 i = 4; _isNonZero(i); i = _dec(i)) {
                if (_isZero(amountsOutSingleSwap[index[_dec(i)]])) break;
                amountsToSyncPrices[index[i]] = _amountToSyncPricesFee(
                    cumulativeReserveIn,
                    cumulativeReserveOut,
                    reserves[index[_dec(i)]].reserveIn,
                    reserves[index[_dec(i)]].reserveOut,
                    getFee(index[i])
                );
                if (_isZero(amountsToSyncPrices[index[i]])) break; // skip edge case
                cumulativeAmount = cumulativeAmount + amountsToSyncPrices[index[i]];
                if (amountIn <= cumulativeAmount) break; // keep prior setting and break loop
                numSplits = _inc(numSplits);
                cumulativeReserveOut =
                    cumulativeReserveOut +
                    reserves[index[_dec(i)]].reserveOut -
                    getAmountOut(amountsToSyncPrices[index[i]], cumulativeReserveIn, cumulativeReserveOut);
                cumulativeReserveIn =
                    cumulativeReserveIn +
                    reserves[index[_dec(i)]].reserveIn +
                    amountsToSyncPrices[index[i]];
            }
            // assign optimal route
            // TODO: clean up code into for loop
            if (numSplits == 1) {
                amountsIn[index[4]] =
                    amountsToSyncPrices[index[4]] +
                    ((amountIn - amountsToSyncPrices[index[4]]) *
                        (reserves[index[4]].reserveIn + amountsToSyncPrices[index[4]])) /
                    cumulativeReserveIn;
                amountsIn[index[3]] = amountIn - amountsIn[index[4]];
                amountsOut[index[4]] = getAmountOutFee(
                    amountsIn[index[4]],
                    reserves[index[4]].reserveIn,
                    reserves[index[4]].reserveOut,
                    getFee(index[4])
                );
                amountsOut[index[3]] = getAmountOutFee(
                    amountsIn[index[3]],
                    reserves[index[3]].reserveIn,
                    reserves[index[3]].reserveOut,
                    getFee(index[3])
                );
            } else if (numSplits == 2) {
                uint256 partAmountIn = (amountsToSyncPrices[index[3]] *
                    (reserves[index[4]].reserveIn + amountsToSyncPrices[index[4]])) /
                    (reserves[index[4]].reserveIn + amountsToSyncPrices[index[4]] + reserves[index[3]].reserveIn);
                amountsIn[index[4]] =
                    amountsToSyncPrices[index[4]] +
                    partAmountIn +
                    ((amountIn - amountsToSyncPrices[index[4]] - amountsToSyncPrices[index[3]]) *
                        (reserves[index[4]].reserveIn + amountsToSyncPrices[index[4]] + partAmountIn)) /
                    cumulativeReserveIn;
                partAmountIn =
                    (amountsToSyncPrices[index[3]] * reserves[index[3]].reserveIn) /
                    (reserves[index[4]].reserveIn + amountsToSyncPrices[index[4]] + reserves[index[3]].reserveIn);
                amountsIn[index[3]] =
                    partAmountIn +
                    ((amountIn - amountsToSyncPrices[index[4]] - amountsToSyncPrices[index[3]]) *
                        (reserves[index[3]].reserveIn + partAmountIn)) /
                    cumulativeReserveIn;
                amountsIn[index[2]] = amountIn - amountsIn[index[3]] - amountsIn[index[4]];
                amountsOut[index[4]] = getAmountOutFee(
                    amountsIn[index[4]],
                    reserves[index[4]].reserveIn,
                    reserves[index[4]].reserveOut,
                    getFee(index[4])
                );
                amountsOut[index[3]] = getAmountOutFee(
                    amountsIn[index[3]],
                    reserves[index[3]].reserveIn,
                    reserves[index[3]].reserveOut,
                    getFee(index[3])
                );
                amountsOut[index[2]] = getAmountOutFee(
                    amountsIn[index[2]],
                    reserves[index[2]].reserveIn,
                    reserves[index[2]].reserveOut,
                    getFee(index[2])
                );
            } else if (numSplits == 3) {
                uint256 partAmountIn = (amountsToSyncPrices[index[3]] *
                    (reserves[index[4]].reserveIn + amountsToSyncPrices[index[4]])) /
                    (reserves[index[4]].reserveIn + amountsToSyncPrices[index[4]] + reserves[index[3]].reserveIn);
                partAmountIn =
                    partAmountIn +
                    (amountsToSyncPrices[index[2]] *
                        (reserves[index[4]].reserveIn + amountsToSyncPrices[index[4]] + partAmountIn)) /
                    (reserves[index[4]].reserveIn +
                        amountsToSyncPrices[index[4]] +
                        reserves[index[3]].reserveIn +
                        amountsToSyncPrices[index[3]] +
                        reserves[index[2]].reserveIn);
                amountsIn[index[4]] =
                    amountsToSyncPrices[index[4]] +
                    partAmountIn +
                    ((amountIn -
                        amountsToSyncPrices[index[4]] -
                        amountsToSyncPrices[index[3]] -
                        amountsToSyncPrices[index[2]]) *
                        (reserves[index[4]].reserveIn + amountsToSyncPrices[index[4]] + partAmountIn)) /
                    cumulativeReserveIn;
                partAmountIn =
                    (amountsToSyncPrices[index[3]] * reserves[index[3]].reserveIn) /
                    (reserves[index[4]].reserveIn + amountsToSyncPrices[index[4]] + reserves[index[3]].reserveIn);
                partAmountIn =
                    partAmountIn +
                    (amountsToSyncPrices[index[2]] * (reserves[index[3]].reserveIn + partAmountIn)) /
                    (reserves[index[4]].reserveIn +
                        amountsToSyncPrices[index[4]] +
                        reserves[index[3]].reserveIn +
                        amountsToSyncPrices[index[3]] +
                        reserves[index[2]].reserveIn);
                amountsIn[index[3]] =
                    partAmountIn +
                    ((amountIn -
                        amountsToSyncPrices[index[4]] -
                        amountsToSyncPrices[index[3]] -
                        amountsToSyncPrices[index[2]]) * (reserves[index[3]].reserveIn + partAmountIn)) /
                    cumulativeReserveIn;
                partAmountIn =
                    (amountsToSyncPrices[index[2]] * reserves[index[2]].reserveIn) /
                    (reserves[index[4]].reserveIn +
                        amountsToSyncPrices[index[4]] +
                        reserves[index[3]].reserveIn +
                        amountsToSyncPrices[index[3]] +
                        reserves[index[2]].reserveIn);
                amountsIn[index[2]] =
                    partAmountIn +
                    ((amountIn -
                        amountsToSyncPrices[index[4]] -
                        amountsToSyncPrices[index[3]] -
                        amountsToSyncPrices[index[2]]) * (reserves[index[2]].reserveIn + partAmountIn)) /
                    cumulativeReserveIn;
                amountsIn[index[1]] = amountIn - amountsIn[index[2]] - amountsIn[index[3]] - amountsIn[index[4]];
                amountsOut[index[4]] = getAmountOutFee(
                    amountsIn[index[4]],
                    reserves[index[4]].reserveIn,
                    reserves[index[4]].reserveOut,
                    getFee(index[4])
                );
                amountsOut[index[3]] = getAmountOutFee(
                    amountsIn[index[3]],
                    reserves[index[3]].reserveIn,
                    reserves[index[3]].reserveOut,
                    getFee(index[3])
                );
                amountsOut[index[2]] = getAmountOutFee(
                    amountsIn[index[2]],
                    reserves[index[2]].reserveIn,
                    reserves[index[2]].reserveOut,
                    getFee(index[2])
                );
                amountsOut[index[1]] = getAmountOutFee(
                    amountsIn[index[1]],
                    reserves[index[1]].reserveIn,
                    reserves[index[1]].reserveOut,
                    getFee(index[1])
                );
            } else if (numSplits == 4) {
                uint256 partAmountIn = (amountsToSyncPrices[index[3]] *
                    (reserves[index[4]].reserveIn + amountsToSyncPrices[index[4]])) /
                    (reserves[index[4]].reserveIn + amountsToSyncPrices[index[4]] + reserves[index[3]].reserveIn);
                partAmountIn =
                    partAmountIn +
                    (amountsToSyncPrices[index[2]] *
                        (reserves[index[4]].reserveIn + amountsToSyncPrices[index[4]] + partAmountIn)) /
                    (reserves[index[4]].reserveIn +
                        amountsToSyncPrices[index[4]] +
                        reserves[index[3]].reserveIn +
                        amountsToSyncPrices[index[3]] +
                        reserves[index[2]].reserveIn);
                partAmountIn =
                    partAmountIn +
                    (amountsToSyncPrices[index[1]] *
                        (reserves[index[4]].reserveIn + amountsToSyncPrices[index[4]] + partAmountIn)) /
                    (reserves[index[4]].reserveIn +
                        amountsToSyncPrices[index[4]] +
                        reserves[index[3]].reserveIn +
                        amountsToSyncPrices[index[3]] +
                        reserves[index[2]].reserveIn +
                        amountsToSyncPrices[index[2]] +
                        reserves[index[1]].reserveIn);
                amountsIn[index[4]] =
                    amountsToSyncPrices[index[4]] +
                    partAmountIn +
                    ((amountIn -
                        amountsToSyncPrices[index[4]] -
                        amountsToSyncPrices[index[3]] -
                        amountsToSyncPrices[index[2]] -
                        amountsToSyncPrices[index[1]]) *
                        (reserves[index[4]].reserveIn + amountsToSyncPrices[index[4]] + partAmountIn)) /
                    cumulativeReserveIn;
                partAmountIn =
                    (amountsToSyncPrices[index[3]] * reserves[index[3]].reserveIn) /
                    (reserves[index[4]].reserveIn + amountsToSyncPrices[index[4]] + reserves[index[3]].reserveIn);
                partAmountIn =
                    partAmountIn +
                    (amountsToSyncPrices[index[2]] * (reserves[index[3]].reserveIn + partAmountIn)) /
                    (reserves[index[4]].reserveIn +
                        amountsToSyncPrices[index[4]] +
                        reserves[index[3]].reserveIn +
                        amountsToSyncPrices[index[3]] +
                        reserves[index[2]].reserveIn);
                partAmountIn =
                    partAmountIn +
                    (amountsToSyncPrices[index[1]] * (reserves[index[3]].reserveIn + partAmountIn)) /
                    (reserves[index[4]].reserveIn +
                        amountsToSyncPrices[index[4]] +
                        reserves[index[3]].reserveIn +
                        amountsToSyncPrices[index[3]] +
                        reserves[index[2]].reserveIn +
                        amountsToSyncPrices[index[2]] +
                        reserves[index[1]].reserveIn);
                amountsIn[index[3]] =
                    partAmountIn +
                    ((amountIn -
                        amountsToSyncPrices[index[4]] -
                        amountsToSyncPrices[index[3]] -
                        amountsToSyncPrices[index[2]] -
                        amountsToSyncPrices[index[1]]) * (reserves[index[3]].reserveIn + partAmountIn)) /
                    cumulativeReserveIn;
                partAmountIn =
                    (amountsToSyncPrices[index[2]] * reserves[index[2]].reserveIn) /
                    (reserves[index[4]].reserveIn +
                        amountsToSyncPrices[index[4]] +
                        reserves[index[3]].reserveIn +
                        amountsToSyncPrices[index[3]] +
                        reserves[index[2]].reserveIn);
                partAmountIn =
                    partAmountIn +
                    (amountsToSyncPrices[index[1]] * (reserves[index[2]].reserveIn + partAmountIn)) /
                    (reserves[index[4]].reserveIn +
                        amountsToSyncPrices[index[4]] +
                        reserves[index[3]].reserveIn +
                        amountsToSyncPrices[index[3]] +
                        reserves[index[2]].reserveIn +
                        amountsToSyncPrices[index[2]] +
                        reserves[index[1]].reserveIn);
                amountsIn[index[2]] =
                    partAmountIn +
                    ((amountIn -
                        amountsToSyncPrices[index[4]] -
                        amountsToSyncPrices[index[3]] -
                        amountsToSyncPrices[index[2]] -
                        amountsToSyncPrices[index[1]]) * (reserves[index[2]].reserveIn + partAmountIn)) /
                    cumulativeReserveIn;
                partAmountIn =
                    (amountsToSyncPrices[index[1]] * reserves[index[1]].reserveIn) /
                    (reserves[index[4]].reserveIn +
                        amountsToSyncPrices[index[4]] +
                        reserves[index[3]].reserveIn +
                        amountsToSyncPrices[index[3]] +
                        reserves[index[2]].reserveIn +
                        amountsToSyncPrices[index[2]] +
                        reserves[index[1]].reserveIn);
                amountsIn[index[1]] =
                    partAmountIn +
                    ((amountIn -
                        amountsToSyncPrices[index[4]] -
                        amountsToSyncPrices[index[3]] -
                        amountsToSyncPrices[index[2]] -
                        amountsToSyncPrices[index[1]]) * (reserves[index[1]].reserveIn + partAmountIn)) /
                    cumulativeReserveIn;
                amountsIn[index[0]] =
                    amountIn -
                    amountsIn[index[1]] -
                    amountsIn[index[2]] -
                    amountsIn[index[3]] -
                    amountsIn[index[4]];
                amountsOut[index[4]] = getAmountOutFee(
                    amountsIn[index[4]],
                    reserves[index[4]].reserveIn,
                    reserves[index[4]].reserveOut,
                    getFee(index[4])
                );
                amountsOut[index[3]] = getAmountOutFee(
                    amountsIn[index[3]],
                    reserves[index[3]].reserveIn,
                    reserves[index[3]].reserveOut,
                    getFee(index[3])
                );
                amountsOut[index[2]] = getAmountOutFee(
                    amountsIn[index[2]],
                    reserves[index[2]].reserveIn,
                    reserves[index[2]].reserveOut,
                    getFee(index[2])
                );
                amountsOut[index[1]] = getAmountOutFee(
                    amountsIn[index[1]],
                    reserves[index[1]].reserveIn,
                    reserves[index[1]].reserveOut,
                    getFee(index[1])
                );
                amountsOut[index[0]] = getAmountOutFee(
                    amountsIn[index[0]],
                    reserves[index[0]].reserveIn,
                    reserves[index[0]].reserveOut,
                    getFee(index[0])
                );
            }
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
        bytes32 factoryHash,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        uint256 length = path.length;
        if (length < 2) revert InvalidPath();
        amounts = new uint256[](length);
        amounts[_dec(length)] = amountOut;
        for (uint256 i = _dec(length); _isNonZero(i); i = _dec(i)) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[_dec(i)], path[i], factoryHash);
            amounts[_dec(i)] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    /// @notice Fetches swap data for each pair and amounts given a desired output and path
    /// @param factory1 Factory address for dex
    /// @param amountOut Amount out for last token in path
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @return swaps Array Swap data for each user swap in path
    function getSwapsIn(
        address factory0,
        address factory1,
        uint256 amountOut,
        bytes32 factoryHash0,
        bytes32 factoryHash1,
        address[] memory path
    ) internal view returns (Swap[] memory swaps) {
        uint256 length = path.length;
        if (length < 2) revert InvalidPath();
        swaps = new Swap[](_dec(length));
        for (uint256 i = _dec(length); _isNonZero(i); i = _dec(i)) {
            if (i < _dec(length)) {
                amountOut = 0;
                for (uint256 j; j < 5; j = _inc(j)) {
                    amountOut = amountOut + swaps[i].pools[j].amountIn;
                }
            }
            {
                (address token0, address token1) = sortTokens(path[_dec(i)], path[i]);
                swaps[_dec(i)].pools = _getPools(factory0, factory1, token0, token1, factoryHash0, factoryHash1);
                swaps[_dec(i)].isReverse = path[i] == token0;
            }
            swaps[_dec(i)].tokenIn = path[_dec(i)];
            swaps[_dec(i)].tokenOut = path[i];
            uint256[5] memory amountsIn;
            uint256[5] memory amountsOut;
            {
                Reserve[5] memory reserves = _getReserves(swaps[_dec(i)].isReverse, swaps[_dec(i)].pools);
                // find optimal route
                (amountsIn, amountsOut) = _optimalRouteIn(amountOut, reserves);
            }

            for (uint256 j; j < 5; j = _inc(j)) {
                swaps[_dec(i)].pools[j].amountIn = amountsIn[j];
                swaps[_dec(i)].pools[j].amountOut = amountsOut[j];
            }
        }
    }

    function _splitSwapIn(
        uint256 amountOut,
        uint256[5] memory amountsInSingleSwap,
        Reserve[5] memory reserves
    ) internal pure returns (uint256[5] memory amountsIn, uint256[5] memory amountsOut) {
        uint256[5] memory amountsToSyncPrices;
        uint256[5] memory index = _sortArray(amountsInSingleSwap); // sorts in ascending order (i.e. best price is first)
        uint256 cumulativeAmount;
        uint256 cumulativeReserveIn;
        uint256 cumulativeReserveOut;
        uint256 prevAmountIn;
        uint256 numSplits;
        // calculate amount to sync prices cascading through each pool with best prices first, while cumulative amount < amountIn
        // iteratevly assign splits, testing against extra gas of each split
        for (uint256 i = 0; i < 4; i = _inc(i)) {
            if (_isZero(amountsInSingleSwap[index[i]])) continue;
            if (_isZero(prevAmountIn)) {
                prevAmountIn = amountsInSingleSwap[index[i]];
                cumulativeReserveOut = reserves[index[i]].reserveOut;
                cumulativeReserveIn = reserves[index[i]].reserveIn;
                amountsIn[index[i]] = prevAmountIn;
                amountsOut[index[i]] = amountOut;
            }
            amountsToSyncPrices[index[i]] = _amountToSyncPricesFee(
                cumulativeReserveIn,
                cumulativeReserveOut,
                reserves[index[_inc(i)]].reserveIn,
                reserves[index[_inc(i)]].reserveOut,
                getFee(index[i])
            );
            if (_isZero(amountsToSyncPrices[index[i]])) break; // skip edge case
            cumulativeAmount = cumulativeAmount + amountsToSyncPrices[index[i]];
            if (prevAmountIn <= cumulativeAmount) break; // keep prior setting and break loop
            numSplits = _inc(numSplits);
            cumulativeReserveOut =
                cumulativeReserveOut +
                reserves[index[_inc(i)]].reserveOut -
                getAmountOut(amountsToSyncPrices[index[i]], cumulativeReserveIn, cumulativeReserveOut);
            cumulativeReserveIn =
                cumulativeReserveIn +
                reserves[index[_inc(i)]].reserveIn +
                amountsToSyncPrices[index[i]];
        }
        // assign optimal route
        // TODO: clean up code into for loop
        if (numSplits == 1) {
            amountsIn[index[0]] =
                amountsToSyncPrices[index[0]] +
                ((prevAmountIn - amountsToSyncPrices[index[0]]) *
                    (reserves[index[0]].reserveIn + amountsToSyncPrices[index[0]])) /
                cumulativeReserveIn;

            amountsOut[index[0]] = getAmountOutFee(
                amountsIn[index[0]],
                reserves[index[0]].reserveIn,
                reserves[index[0]].reserveOut,
                getFee(index[0])
            );
            amountsOut[index[1]] = amountOut - amountsOut[index[0]];
            amountsIn[index[1]] = getAmountInFee(
                amountsOut[index[1]],
                reserves[index[1]].reserveIn,
                reserves[index[1]].reserveOut,
                getFee(index[1])
            );
        } else if (numSplits == 2) {
            uint256 partAmountIn = (amountsToSyncPrices[index[1]] *
                (reserves[index[0]].reserveIn + amountsToSyncPrices[index[0]])) /
                (reserves[index[0]].reserveIn + amountsToSyncPrices[index[0]] + reserves[index[1]].reserveIn);
            amountsIn[index[0]] =
                amountsToSyncPrices[index[0]] +
                partAmountIn +
                ((prevAmountIn - amountsToSyncPrices[index[0]] - amountsToSyncPrices[index[1]]) *
                    (reserves[index[0]].reserveIn + amountsToSyncPrices[index[0]] + partAmountIn)) /
                cumulativeReserveIn;
            partAmountIn =
                (amountsToSyncPrices[index[1]] * reserves[index[1]].reserveIn) /
                (reserves[index[0]].reserveIn + amountsToSyncPrices[index[0]] + reserves[index[1]].reserveIn);
            amountsIn[index[1]] =
                partAmountIn +
                ((prevAmountIn - amountsToSyncPrices[index[0]] - amountsToSyncPrices[index[1]]) *
                    (reserves[index[1]].reserveIn + partAmountIn)) /
                cumulativeReserveIn;

            amountsOut[index[0]] = getAmountOutFee(
                amountsIn[index[0]],
                reserves[index[0]].reserveIn,
                reserves[index[0]].reserveOut,
                getFee(index[0])
            );
            amountsOut[index[1]] = getAmountOutFee(
                amountsIn[index[1]],
                reserves[index[1]].reserveIn,
                reserves[index[1]].reserveOut,
                getFee(index[1])
            );
            amountsOut[index[2]] = amountOut - amountsOut[index[1]] - amountsOut[index[0]];
            amountsIn[index[2]] = getAmountInFee(
                amountsOut[index[2]],
                reserves[index[2]].reserveIn,
                reserves[index[2]].reserveOut,
                getFee(index[2])
            );
        } else if (numSplits == 3) {
            uint256 partAmountIn = (amountsToSyncPrices[index[1]] *
                (reserves[index[0]].reserveIn + amountsToSyncPrices[index[0]])) /
                (reserves[index[0]].reserveIn + amountsToSyncPrices[index[0]] + reserves[index[1]].reserveIn);
            partAmountIn =
                partAmountIn +
                (amountsToSyncPrices[index[2]] *
                    (reserves[index[0]].reserveIn + amountsToSyncPrices[index[0]] + partAmountIn)) /
                (reserves[index[0]].reserveIn +
                    amountsToSyncPrices[index[0]] +
                    reserves[index[1]].reserveIn +
                    amountsToSyncPrices[index[1]] +
                    reserves[index[2]].reserveIn);
            amountsIn[index[0]] =
                amountsToSyncPrices[index[0]] +
                partAmountIn +
                ((prevAmountIn -
                    amountsToSyncPrices[index[0]] -
                    amountsToSyncPrices[index[1]] -
                    amountsToSyncPrices[index[2]]) *
                    (reserves[index[0]].reserveIn + amountsToSyncPrices[index[0]] + partAmountIn)) /
                cumulativeReserveIn;
            partAmountIn =
                (amountsToSyncPrices[index[1]] * reserves[index[1]].reserveIn) /
                (reserves[index[0]].reserveIn + amountsToSyncPrices[index[0]] + reserves[index[1]].reserveIn);
            partAmountIn =
                partAmountIn +
                (amountsToSyncPrices[index[2]] * (reserves[index[1]].reserveIn + partAmountIn)) /
                (reserves[index[0]].reserveIn +
                    amountsToSyncPrices[index[0]] +
                    reserves[index[1]].reserveIn +
                    amountsToSyncPrices[index[1]] +
                    reserves[index[2]].reserveIn);
            amountsIn[index[1]] =
                partAmountIn +
                ((prevAmountIn -
                    amountsToSyncPrices[index[0]] -
                    amountsToSyncPrices[index[1]] -
                    amountsToSyncPrices[index[2]]) * (reserves[index[1]].reserveIn + partAmountIn)) /
                cumulativeReserveIn;
            partAmountIn =
                (amountsToSyncPrices[index[2]] * reserves[index[2]].reserveIn) /
                (reserves[index[0]].reserveIn +
                    amountsToSyncPrices[index[0]] +
                    reserves[index[1]].reserveIn +
                    amountsToSyncPrices[index[1]] +
                    reserves[index[2]].reserveIn);
            amountsIn[index[2]] =
                partAmountIn +
                ((prevAmountIn -
                    amountsToSyncPrices[index[0]] -
                    amountsToSyncPrices[index[1]] -
                    amountsToSyncPrices[index[2]]) * (reserves[index[2]].reserveIn + partAmountIn)) /
                cumulativeReserveIn;

            amountsOut[index[0]] = getAmountOutFee(
                amountsIn[index[0]],
                reserves[index[0]].reserveIn,
                reserves[index[0]].reserveOut,
                getFee(index[0])
            );
            amountsOut[index[1]] = getAmountOutFee(
                amountsIn[index[1]],
                reserves[index[1]].reserveIn,
                reserves[index[1]].reserveOut,
                getFee(index[1])
            );
            amountsOut[index[2]] = getAmountOutFee(
                amountsIn[index[2]],
                reserves[index[2]].reserveIn,
                reserves[index[2]].reserveOut,
                getFee(index[2])
            );
            amountsOut[index[3]] = amountOut - amountsOut[index[2]] - amountsOut[index[1]] - amountsOut[index[0]];
            if (_isNonZero(amountsOut[index[3]])){
                amountsIn[index[3]] = getAmountInFee(
                    amountsOut[index[3]],
                    reserves[index[3]].reserveIn,
                    reserves[index[3]].reserveOut,
                    getFee(index[3])
                );
            }            
        } else if (numSplits == 4) {
            uint256 partAmountIn = (amountsToSyncPrices[index[1]] *
                (reserves[index[0]].reserveIn + amountsToSyncPrices[index[0]])) /
                (reserves[index[0]].reserveIn + amountsToSyncPrices[index[0]] + reserves[index[1]].reserveIn);
            partAmountIn =
                partAmountIn +
                (amountsToSyncPrices[index[2]] *
                    (reserves[index[0]].reserveIn + amountsToSyncPrices[index[0]] + partAmountIn)) /
                (reserves[index[0]].reserveIn +
                    amountsToSyncPrices[index[0]] +
                    reserves[index[1]].reserveIn +
                    amountsToSyncPrices[index[1]] +
                    reserves[index[2]].reserveIn);
            partAmountIn =
                partAmountIn +
                (amountsToSyncPrices[index[1]] *
                    (reserves[index[0]].reserveIn + amountsToSyncPrices[index[0]] + partAmountIn)) /
                (reserves[index[0]].reserveIn +
                    amountsToSyncPrices[index[0]] +
                    reserves[index[1]].reserveIn +
                    amountsToSyncPrices[index[1]] +
                    reserves[index[2]].reserveIn +
                    amountsToSyncPrices[index[2]] +
                    reserves[index[3]].reserveIn);
            amountsIn[index[0]] =
                amountsToSyncPrices[index[0]] +
                partAmountIn +
                ((prevAmountIn -
                    amountsToSyncPrices[index[0]] -
                    amountsToSyncPrices[index[1]] -
                    amountsToSyncPrices[index[2]] -
                    amountsToSyncPrices[index[3]]) *
                    (reserves[index[0]].reserveIn + amountsToSyncPrices[index[0]] + partAmountIn)) /
                cumulativeReserveIn;
            partAmountIn =
                (amountsToSyncPrices[index[1]] * reserves[index[1]].reserveIn) /
                (reserves[index[0]].reserveIn + amountsToSyncPrices[index[0]] + reserves[index[1]].reserveIn);
            partAmountIn =
                partAmountIn +
                (amountsToSyncPrices[index[2]] * (reserves[index[1]].reserveIn + partAmountIn)) /
                (reserves[index[0]].reserveIn +
                    amountsToSyncPrices[index[0]] +
                    reserves[index[1]].reserveIn +
                    amountsToSyncPrices[index[1]] +
                    reserves[index[2]].reserveIn);
            partAmountIn =
                partAmountIn +
                (amountsToSyncPrices[index[1]] * (reserves[index[1]].reserveIn + partAmountIn)) /
                (reserves[index[0]].reserveIn +
                    amountsToSyncPrices[index[0]] +
                    reserves[index[1]].reserveIn +
                    amountsToSyncPrices[index[1]] +
                    reserves[index[2]].reserveIn +
                    amountsToSyncPrices[index[2]] +
                    reserves[index[3]].reserveIn);
            amountsIn[index[1]] =
                partAmountIn +
                ((prevAmountIn -
                    amountsToSyncPrices[index[0]] -
                    amountsToSyncPrices[index[1]] -
                    amountsToSyncPrices[index[2]] -
                    amountsToSyncPrices[index[3]]) * (reserves[index[1]].reserveIn + partAmountIn)) /
                cumulativeReserveIn;
            partAmountIn =
                (amountsToSyncPrices[index[2]] * reserves[index[2]].reserveIn) /
                (reserves[index[0]].reserveIn +
                    amountsToSyncPrices[index[0]] +
                    reserves[index[1]].reserveIn +
                    amountsToSyncPrices[index[1]] +
                    reserves[index[2]].reserveIn);
            partAmountIn =
                partAmountIn +
                (amountsToSyncPrices[index[1]] * (reserves[index[2]].reserveIn + partAmountIn)) /
                (reserves[index[0]].reserveIn +
                    amountsToSyncPrices[index[0]] +
                    reserves[index[1]].reserveIn +
                    amountsToSyncPrices[index[1]] +
                    reserves[index[2]].reserveIn +
                    amountsToSyncPrices[index[2]] +
                    reserves[index[3]].reserveIn);
            amountsIn[index[2]] =
                partAmountIn +
                ((prevAmountIn -
                    amountsToSyncPrices[index[0]] -
                    amountsToSyncPrices[index[1]] -
                    amountsToSyncPrices[index[2]] -
                    amountsToSyncPrices[index[3]]) * (reserves[index[2]].reserveIn + partAmountIn)) /
                cumulativeReserveIn;
            partAmountIn =
                (amountsToSyncPrices[index[1]] * reserves[index[1]].reserveIn) /
                (reserves[index[0]].reserveIn +
                    amountsToSyncPrices[index[0]] +
                    reserves[index[1]].reserveIn +
                    amountsToSyncPrices[index[1]] +
                    reserves[index[2]].reserveIn +
                    amountsToSyncPrices[index[2]] +
                    reserves[index[3]].reserveIn);
            amountsIn[index[3]] =
                partAmountIn +
                ((prevAmountIn -
                    amountsToSyncPrices[index[0]] -
                    amountsToSyncPrices[index[1]] -
                    amountsToSyncPrices[index[2]] -
                    amountsToSyncPrices[index[3]]) * (reserves[index[3]].reserveIn + partAmountIn)) /
                cumulativeReserveIn;

            amountsOut[index[0]] = getAmountOutFee(
                amountsIn[index[0]],
                reserves[index[0]].reserveIn,
                reserves[index[0]].reserveOut,
                getFee(index[0])
            );
            amountsOut[index[1]] = getAmountOutFee(
                amountsIn[index[1]],
                reserves[index[1]].reserveIn,
                reserves[index[1]].reserveOut,
                getFee(index[1])
            );
            amountsOut[index[2]] = getAmountOutFee(
                amountsIn[index[2]],
                reserves[index[2]].reserveIn,
                reserves[index[2]].reserveOut,
                getFee(index[2])
            );
            amountsOut[index[3]] = getAmountOutFee(
                amountsIn[index[3]],
                reserves[index[3]].reserveIn,
                reserves[index[3]].reserveOut,
                getFee(index[3])
            );
            amountsOut[index[4]] =
                amountOut -
                amountsOut[index[3]] -
                amountsOut[index[2]] -
                amountsOut[index[1]] -
                amountsOut[index[0]];
            amountsIn[index[4]] = getAmountInFee(
                amountsOut[index[4]],
                reserves[index[4]].reserveIn,
                reserves[index[4]].reserveOut,
                getFee(index[4])
            );
        }
    }

    /// @dev returns sorted index of amount array (in ascending order)
    function _sortArray(uint256[5] memory arr_) internal pure returns (uint256[5] memory index) {
        uint256[5] memory arr;
        index = [uint256(0), uint256(1), uint256(2), uint256(3), uint256(4)];
        for (uint256 i; i < 5; i++) {
            arr[i] = arr_[i];
        }
        for (uint256 i; i < 5; i++) {
            for (uint256 j = i + 1; j < 5; j++) {
                if (arr[i] > arr[j]) {
                    uint256 temp = arr[j];
                    uint256 tmp2 = index[j];
                    arr[j] = arr[i];
                    arr[i] = temp;
                    index[j] = index[i];
                    index[i] = tmp2;
                }
            }
        }
    }

    /// @dev sorts possible swaps by best price, then assigns optimal split
    function _optimalRouteIn(uint256 amountOut, Reserve[5] memory reserves)
        internal
        pure
        returns (uint256[5] memory amountsIn, uint256[5] memory amountsOut)
    {
        uint256[5] memory amountsInSingleSwap;
        // first 3 pools have fee of 0.3%
        for (uint256 i; i < 3; i = _inc(i)) {
            if (reserves[i].reserveOut > amountOut && reserves[i].reserveIn > MINIMUM_LIQUIDITY) {
                amountsInSingleSwap[i] = getAmountIn(amountOut, reserves[i].reserveIn, reserves[i].reserveOut);
            }
        }
        // next 2 pools have variable rates
        for (uint256 i = 3; i < 5; i = _inc(i)) {
            if (reserves[i].reserveOut > amountOut && reserves[i].reserveIn > MINIMUM_LIQUIDITY) {
                amountsInSingleSwap[i] = getAmountInFee(
                    amountOut,
                    reserves[i].reserveIn,
                    reserves[i].reserveOut,
                    getFee(i)
                );
                if (i == 3 && _isNonZero(amountsInSingleSwap[i])) {
                    // 0.05 % pool potentially crosses more ticks, lowering expected output (add margin of error 0.01% of amountIn)
                    amountsInSingleSwap[i] = amountsInSingleSwap[i] + amountsInSingleSwap[i] / 1000;
                }
            }
        }

        (amountsIn, amountsOut) = _splitSwapIn(amountOut, amountsInSingleSwap, reserves);
    }

    /// @dev returns amount In of pool 1 required to sync prices with pool 2
    /// @param x1 reserveIn pool 1
    /// @param y1 reserveOut pool 1
    /// @param x2 reserveIn pool 2
    /// @param y2 reserveOut pool 2
    /// @param fee pool 1 fee
    function _amountToSyncPricesFee(
        uint256 x1,
        uint256 y1,
        uint256 x2,
        uint256 y2,
        uint256 fee
    ) internal pure returns (uint256) {
        unchecked {
            return
                (x1 *
                    (Babylonian.sqrt((fee * fee + (x2 * y1 * (4000000000000 - 4000000 * fee)) / (x1 * y2))) -
                        (2000000 - fee))) / (2 * (1000000 - fee));
        }
    }

    /// @custom:gas Uint256 zero check gas saver
    /// @dev Uint256 zero check gas saver
    /// @param value Number to check
    function _isZero(uint256 value) internal pure returns (bool boolValue) {
        assembly ("memory-safe") {
            boolValue := iszero(value)
        }
    }

    /// @custom:gas Uint256 not zero check gas saver
    /// @dev Uint256 not zero check gas saver
    /// @param value Number to check
    function _isNonZero(uint256 value) internal pure returns (bool boolValue) {
        assembly ("memory-safe") {
            boolValue := iszero(iszero(value))
        }
    }

    /// @custom:gas Unchecked increment gas saver
    /// @dev Unchecked increment gas saver for loops
    /// @param i Number to increment
    function _inc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    /// @custom:gas Unchecked decrement gas saver
    /// @dev Unchecked decrement gas saver for loops
    /// @param i Number to decrement
    function _dec(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i - 1;
        }
    }
}
