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
/// @author Sandy Bradley <@sandybradley>, ControlCplusControlV <@ControlCplusControlV>
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
        address pair; // pair (sushi, univ2, univ3 (4 pools))
        uint256 amountIn; // amount In for each pair
        uint256 amountOut; // amount Out for each pair
    }

    struct Swap {
        bool isReverse;
        address tokenIn;
        address tokenOut;
        Pool[5] pools; // 5 pools (sushi, univ2, univ3 (3 pools))
    }

    address internal constant UNIV3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984; // Ethereum mainnet, Optimism, Arbitrum, Polygon address
    // bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54; // V3 init code hash
    uint256 internal constant MINIMUM_LIQUIDITY = 1000;
    uint256 internal constant EST_SWAP_GAS_USED = 100000;

    /// @notice calculate uinswap v3 pool address
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

    /// @notice get fee for pool as a fraction of 1000000 (i.e. 0.3% -> 3000)
    /// Reference order is hard coded as sushi, univ2, univ3 (0.3%), univ3 (0.05%), univ3 (1%)
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

    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

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
            uint160 sqrtPriceX96 = (uint160(IUniswapV3Pool(pools[i].pair).slot0()) / uint160(2**96)) + uint160(1); // account for rounding error
            uint256 liquidity = uint256(IUniswapV3Pool(pools[i].pair).liquidity());
            if (_isNonZero(liquidity) && _isNonZero(sqrtPriceX96)) {
                (uint256 reserve0, uint256 reserve1) = (liquidity / sqrtPriceX96, liquidity * sqrtPriceX96);
                (reserves[i].reserveIn, reserves[i].reserveOut) = isReverse
                    ? (reserve1, reserve0)
                    : (reserve0, reserve1);
            }
        }
    }

    /// @notice calculate pool addresses for tokenIn/Out & factory/fee
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
                if (i == 3) {
                    // 0.05 % pool potentially crosses more ticks, lowering expected output (add margin of error 0.01% of amountIn)
                    amountsOutSingleSwap[i] = amountsOutSingleSwap[i] - amountsOutSingleSwap[i] / 1000;
                }
            }
        }
        (amountsIn, amountsOut) = _splitSwapOut(amountIn, amountsOutSingleSwap, reserves);
    }

    /// @notice optimal split for given number of pools
    function _splitRouteOut(
        uint256 i,
        uint256 amountIn,
        uint256 cumulativeAmount,
        uint256[5] memory index,
        uint256[5] memory amountsToSyncPrices,
        Reserve[5] memory reserves
    )
        internal
        pure
        returns (
            uint256 cumAmountOut,
            uint256[5] memory amountsInTmp,
            uint256[5] memory amountsOutTmp
        )
    {
        uint256 cumAmountIn;
        // loop through active pools (indexed 5 (best price) to j (current pool))
        for (uint256 j = 4; j > i; j = _dec(j)) {
            uint256 reserveIn = reserves[index[j]].reserveIn;
            uint256 cumReserveIn = reserveIn;
            // assign ratio from each amounts to sync
            for (uint256 k = 4; k > i; k = _dec(k)) {
                amountsInTmp[index[j]] =
                    amountsInTmp[index[j]] +
                    (amountsToSyncPrices[index[k]] * reserveIn) /
                    cumReserveIn;
                reserveIn = reserveIn + amountsInTmp[index[j]];
                cumReserveIn = cumReserveIn + reserves[index[_dec(k)]].reserveIn + amountsInTmp[index[j]];
            }
            // assign remainder amount to active pools in reserve ratio
            amountsInTmp[index[j]] =
                amountsInTmp[index[j]] +
                ((amountIn - cumulativeAmount) * reserveIn) /
                cumReserveIn;
            amountsOutTmp[index[j]] = getAmountOutFee(
                amountsInTmp[index[j]],
                reserves[index[j]].reserveIn,
                reserves[index[j]].reserveOut,
                getFee(index[j])
            );
            cumAmountIn = cumAmountIn + amountsInTmp[index[j]];
            cumAmountOut = cumAmountOut + amountsOutTmp[index[j]];
        }
        // last one can be calculated as ratio but better to account for rounding errors like this
        amountsInTmp[index[i]] = amountIn - cumAmountIn;
        amountsOutTmp[index[i]] = getAmountOutFee(
            amountsInTmp[index[i]],
            reserves[index[i]].reserveIn,
            reserves[index[i]].reserveOut,
            getFee(index[i])
        );
        cumAmountOut = cumAmountOut + amountsOutTmp[index[i]];
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
            uint256 prevAmountOut = amountsOutSingleSwap[index[4]];
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
                // At this point, We know it is optimal to split by amount out
                // But we dont know if the amount gained is worth the extra gas cost
                // TODO: make space for amount gain vs gas cost
                (prevAmountOut, amountsIn, amountsOut) = _splitRouteOut(
                    i,
                    amountIn,
                    cumulativeAmount,
                    index,
                    amountsToSyncPrices,
                    reserves
                );
                cumulativeReserveOut =
                    cumulativeReserveOut +
                    reserves[index[_dec(i)]].reserveOut -
                    getAmountOut(amountsToSyncPrices[index[i]], cumulativeReserveIn, cumulativeReserveOut);
                cumulativeReserveIn =
                    cumulativeReserveIn +
                    reserves[index[_dec(i)]].reserveIn +
                    amountsToSyncPrices[index[i]];
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

    function _splitRouteIn(
        uint256 prevAmountIn,
        uint256 i,
        uint256 amountOut,
        uint256 cumulativeAmount,
        uint256[5] memory index,
        uint256[5] memory amountsToSyncPrices,
        Reserve[5] memory reserves
    )
        internal
        pure
        returns (
            uint256 cumAmountIn,
            uint256[5] memory amountsInTmp,
            uint256[5] memory amountsOutTmp
        )
    {
        uint256 cumAmountOut;
        // loop through active pools (indexed 5 (best price) to j (current pool))
        for (uint256 j; j < i; j = _inc(j)) {
            if (_isZero(amountsToSyncPrices[index[j]])) continue;
            uint256 reserveIn = reserves[index[j]].reserveIn;
            uint256 cumReserveIn = reserveIn;
            // assign ratio from each amounts to sync
            for (uint256 k; k < i; k = _inc(k)) {
                if (_isZero(amountsToSyncPrices[index[k]])) continue;
                amountsInTmp[index[j]] =
                    amountsInTmp[index[j]] +
                    (amountsToSyncPrices[index[k]] * reserveIn) /
                    cumReserveIn;
                reserveIn = reserveIn + amountsInTmp[index[j]];
                cumReserveIn = cumReserveIn + reserves[index[_inc(k)]].reserveIn + amountsInTmp[index[j]];
            }
            // assign remainder amount to active pools in reserve ratio
            // TODO: make this ratio exact by using the more complex dy equation
            amountsInTmp[index[j]] =
                amountsInTmp[index[j]] +
                ((prevAmountIn - cumulativeAmount) * reserveIn) /
                cumReserveIn;
            amountsOutTmp[index[j]] = getAmountOutFee(
                amountsInTmp[index[j]],
                reserves[index[j]].reserveIn,
                reserves[index[j]].reserveOut,
                getFee(index[j])
            );
            cumAmountIn = cumAmountIn + amountsInTmp[index[j]];
            cumAmountOut = cumAmountOut + amountsOutTmp[index[j]];
        }
        // last one can be calculated as ratio but better to account for rounding errors like this
        amountsOutTmp[index[i]] = amountOut - cumAmountOut;
        if (_isNonZero(amountsOutTmp[index[i]])) {
            amountsInTmp[index[i]] = getAmountInFee(
                amountsOutTmp[index[i]],
                reserves[index[i]].reserveIn,
                reserves[index[i]].reserveOut,
                getFee(index[i])
            );
            cumAmountIn = cumAmountIn + amountsInTmp[index[i]];
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
            // At this point, We know it is optimal to split by amount out
            // But we dont know if the amount gained is worth the extra gas cost
            // TODO: make space for amount gain vs gas cost
            (prevAmountIn, amountsIn, amountsOut) = _splitRouteIn(
                prevAmountIn,
                i,
                amountOut,
                cumulativeAmount,
                index,
                amountsToSyncPrices,
                reserves
            );
            cumulativeReserveOut =
                cumulativeReserveOut +
                reserves[index[_inc(i)]].reserveOut -
                getAmountOut(amountsToSyncPrices[index[i]], cumulativeReserveIn, cumulativeReserveOut);
            cumulativeReserveIn =
                cumulativeReserveIn +
                reserves[index[_inc(i)]].reserveIn +
                amountsToSyncPrices[index[i]];
        }
    }

    /// @notice returns sorted index of amount array (in ascending order)
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

    /// @notice sorts possible swaps by best price, then assigns optimal split
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
                if (i == 3) {
                    // 0.05 % pool potentially crosses more ticks, lowering expected output (add margin of error 0.01% of amountIn)
                    amountsInSingleSwap[i] = amountsInSingleSwap[i] + amountsInSingleSwap[i] / 1000;
                }
            }
        }

        (amountsIn, amountsOut) = _splitSwapIn(amountOut, amountsInSingleSwap, reserves);
    }

    /// @notice returns amount In of pool 1 required to sync prices with pool 2
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
