/// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

/**
Optimal MEV library to support OpenMevRouter
Based on UniswapV2Library: https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
*/

import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "./Uint512.sol";

/// @title OpenMevLibrary
/// @author Sandy Bradley <sandy@manifoldx.com>, Sam Bacha <sam@manifoldfinance.com>
/// @notice Optimal MEV library to support OpenMevRouter
library OpenMevLibrary {
    error Overflow();
    error ZeroAmount();
    error InvalidPath();
    error ZeroAddress();
    error IdenticalAddresses();
    error InsufficientLiquidity();

    struct Swap {
        bool isReverse;
        bool isBackrunnable;
        uint112 reserveIn;
        uint112 reserveOut;
        address tokenIn;
        address tokenOut;
        address pair;
        uint256 amountIn;
        uint256 amountOut;
    }

    address internal constant SUSHI_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    bytes32 internal constant SUSHI_FACTORY_HASH = 0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303;
    bytes32 internal constant BACKUP_FACTORY_HASH = 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;
    uint256 internal constant FF_SUSHI_FACTORY = 0xFFC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac0000000000000000000000;
    uint256 internal constant FF_BACKUP_FACTORY = 0xFF5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f0000000000000000000000;
    uint256 internal constant MINIMUM_LIQUIDITY = 1000;

    /// @notice Retreive factoryCodeHash from factory address
    /// @param factory Dex factory
    /// @return initCodeHash factory code hash for pair address calculation
    /// @return ffFactory formatted factory address prefixed with 0xff and shifted for abi encoding
    function factoryHash(address factory) internal pure returns (bytes32 initCodeHash, uint256 ffFactory) {
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
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        if (tokenA == tokenB) revert IdenticalAddresses();
        bool isZeroAddress;
        /// @solidity memory-safe-assembly
        assembly {
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
        assembly {
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
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_asmPairFor(factory, token0, token1)).getReserves();
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
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[_inc(i)]);
            amounts[_inc(i)] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    /// @notice Fetches swap data for each pair and amounts given a desired output and path
    /// @param factory Factory address for dex
    /// @param amountIn Amount in for first token in path
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @return swaps Array Swap data for each user swap in path
    function getSwapsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (Swap[] memory swaps) {
        uint256 length = path.length;
        if (length < 2) revert InvalidPath();
        swaps = new Swap[](_dec(length));
        swaps[0].amountIn = amountIn;
        for (uint256 i; i < _dec(length); i = _inc(i)) {
            (address tokenIn, address tokenOut) = (path[i], path[_inc(i)]);
            (address token0, address token1) = sortTokens(tokenIn, tokenOut);
            bool isReverse = tokenOut == token0;
            address pair = _asmPairFor(factory, token0, token1);
            swaps[i].isReverse = isReverse;
            swaps[i].tokenIn = tokenIn;
            swaps[i].tokenOut = tokenOut;
            swaps[i].pair = pair;
            uint112 reserveIn;
            uint112 reserveOut;
            {
                (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair).getReserves();
                (reserveIn, reserveOut) = isReverse ? (reserve1, reserve0) : (reserve0, reserve1);
            }
            swaps[i].reserveIn = reserveIn;
            swaps[i].reserveOut = reserveOut;
            swaps[i].amountOut = getAmountOut(swaps[i].amountIn, reserveIn, reserveOut);
            unchecked {
                swaps[i].isBackrunnable = _isNonZero((1000 * swaps[i].amountIn) / reserveIn);
            }
            // assign next amount in as last amount out
            if (i < _dec(_dec(length))) swaps[_inc(i)].amountIn = swaps[i].amountOut;
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
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[_dec(i)], path[i]);
            amounts[_dec(i)] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    /// @notice Fetches swap data for each pair and amounts given a desired output and path
    /// @param factory Factory address for dex
    /// @param amountOut Amount out for last token in path
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @return swaps Array Swap data for each user swap in path
    function getSwapsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (Swap[] memory swaps) {
        uint256 length = path.length;
        if (length < 2) revert InvalidPath();
        swaps = new Swap[](_dec(length));
        swaps[_dec(_dec(length))].amountOut = amountOut;
        for (uint256 i = _dec(length); _isNonZero(i); i = _dec(i)) {
            (address tokenIn, address tokenOut) = (path[_dec(i)], path[i]);
            (address token0, address token1) = sortTokens(tokenIn, tokenOut);
            address pair = _asmPairFor(factory, token0, token1);
            bool isReverse = tokenOut == token0;
            swaps[_dec(i)].isReverse = isReverse;
            swaps[_dec(i)].tokenIn = tokenIn;
            swaps[_dec(i)].tokenOut = tokenOut;
            swaps[_dec(i)].pair = pair;
            uint112 reserveIn;
            uint112 reserveOut;
            {
                (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair).getReserves();
                (reserveIn, reserveOut) = isReverse ? (reserve1, reserve0) : (reserve0, reserve1);
            }
            swaps[_dec(i)].amountIn = getAmountIn(swaps[_dec(i)].amountOut, reserveIn, reserveOut);
            unchecked {
                swaps[_dec(i)].isBackrunnable = _isNonZero((1000 * swaps[_dec(i)].amountOut) / reserveOut);
            }
            // assign next amount out as last amount in
            if (i > 1) swaps[i - 2].amountOut = swaps[_dec(i)].amountIn;
        }
    }

    /// @notice Internal call for optimal coefficients
    /// @dev Unchecked used to save gas with internal checks for overflows
    /// @param reserve0Token0 Reserve for first pool for first token
    /// @param reserve0Token1 Reserve for first pool for second token
    /// @param reserve1Token0 Reserve for second pool for first token
    /// @param reserve1Token1 Reserve for second pool for second token
    /// @return Cb Coefficient for Cb
    /// @return Cf Coefficient for Cf
    /// @return Cg Coefficient for Cg
    function calcCoeffs(
        uint112 reserve0Token0,
        uint112 reserve0Token1,
        uint112 reserve1Token0,
        uint112 reserve1Token1
    )
        internal
        pure
        returns (
            uint256 Cb,
            uint256 Cf,
            uint256 Cg
        )
    {
        // save gas with unchecked ... perform internal overflow checks
        unchecked {
            Cb = uint256(reserve1Token1) * uint256(reserve0Token0) * 1000000;
            if ((uint256(reserve0Token0) * 1000000) == Cb / uint256(reserve1Token1)) {
                uint256 Ca = uint256(reserve1Token0) * uint256(reserve0Token1) * 994009;
                if ((uint256(reserve0Token1) * 994009) == Ca / uint256(reserve1Token0)) {
                    if (Ca > Cb) {
                        Cf = Ca - Cb;
                        Cg = (uint256(reserve1Token1) * 997000) + (uint256(reserve0Token1) * 994009);
                    }
                }
            }
        }
    }

    /// @notice Internal call for optimal returns
    /// @dev Unchecked used to save gas. Values already checked.
    /// @param Cb Coefficient for Cb
    /// @param Cf Coefficient for Cf
    /// @param Cg Coefficient for Cg
    /// @param amountIn Optimal amount in
    /// @return optimalReturns Optimal return amount
    function calcReturns(
        uint256 Cb,
        uint256 Cf,
        uint256 Cg,
        uint256 amountIn
    ) internal pure returns (uint256) {
        unchecked {
            return (amountIn * (Cf - (Cg * amountIn))) / (Cb + amountIn * Cg);
        }
    }

    /// @notice Optimal amount in and return for back-run
    /// @param pair0 Pair for first back-run swap
    /// @param pair1 Pair for second back-run swap
    /// @param isReverse True if sorted tokens are opposite to input, output order
    /// @param isAaveAsset True if first token is an Aave asset, otherwise false
    /// @param contractAssetBalance Contract balance for first token
    /// @return optimalAmount Optimal amount for back-run
    /// @return optimalReturns Optimal return for back-run
    function getOptimalAmounts(
        address pair0,
        address pair1,
        bool isReverse,
        bool isAaveAsset,
        uint256 contractAssetBalance,
        uint256 bentoBalance
    ) internal view returns (uint256 optimalAmount, uint256 optimalReturns) {
        uint256 Cb;
        uint256 Cf;
        uint256 Cg;
        {
            (uint112 pair0Reserve0, uint112 pair0Reserve1, ) = IUniswapV2Pair(pair0).getReserves();
            (uint112 pair1Reserve0, uint112 pair1Reserve1, ) = IUniswapV2Pair(pair1).getReserves();
            (Cb, Cf, Cg) = isReverse
                ? calcCoeffs(pair0Reserve0, pair0Reserve1, pair1Reserve0, pair1Reserve1)
                : calcCoeffs(pair0Reserve1, pair0Reserve0, pair1Reserve1, pair1Reserve0);
        }
        if (_isNonZero(Cf) && _isNonZero(Cg)) {
            uint256 numerator0;
            {
                (uint256 _bSquare0, uint256 _bSquare1) = Uint512.mul256x256(Cb, Cb);
                (uint256 _4ac0, uint256 _4ac1) = Uint512.mul256x256(Cb, Cf);
                (uint256 _bsq4ac0, uint256 _bsq4ac1) = Uint512.add512x512(_bSquare0, _bSquare1, _4ac0, _4ac1);
                numerator0 = Uint512.sqrt512(_bsq4ac0, _bsq4ac1);
            }
            if (numerator0 > Cb) {
                // save gas with unchecked. We already know amount is +ve and finite
                unchecked {
                    optimalAmount = (numerator0 - Cb) / Cg;
                }
                // adjust optimal amount for available liquidity if needed
                if (contractAssetBalance < optimalAmount && !isAaveAsset && bentoBalance < optimalAmount) {
                    if (contractAssetBalance > bentoBalance) {
                        optimalAmount = contractAssetBalance;
                    } else {
                        optimalAmount = bentoBalance;
                    }
                }
                optimalReturns = calcReturns(Cb, Cf, Cg, optimalAmount);
            }
        }
    }

    /// @custom:gas Uint256 zero check gas saver
    /// @notice Uint256 zero check gas saver
    /// @param value Number to check
    function _isZero(uint256 value) internal pure returns (bool boolValue) {
        /// @solidity memory-safe-assembly
        assembly {
            boolValue := iszero(value)
        }
    }

    /// @custom:gas Uint256 not zero check gas saver
    /// @notice Uint256 not zero check gas saver
    /// @param value Number to check
    function _isNonZero(uint256 value) internal pure returns (bool boolValue) {
        /// @solidity memory-safe-assembly
        assembly {
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
