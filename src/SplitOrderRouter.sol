// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

/**
Optimal split order router for single swaps with identical markets on uniV2 forks
*/

/// ============ Internal Imports ============
import "./ERC20.sol";
import "./interfaces/IWETH.sol";
import "./libraries/OpenMevLibrary.sol";
import "./libraries/Babylonian.sol";
import { SafeTransferLib } from "./libraries/SafeTransferLib.sol";

/// @title SplitOrderRouter
/// @author Sandy Bradley <sandy@manifoldx.com>
/// @notice Splits single swap order optimally across 2 uniV2 Dexes
contract SplitOrderRouter {
    using SafeTransferLib for ERC20;

    // Custom errors save gas, encoding to 4 bytes
    error Expired();
    error NoTokens();
    error NotPercent();
    error NoReceivers();
    error InvalidPath();
    error TransferFailed();
    error InsufficientBAmount();
    error InsufficientAAmount();
    error TokenIsFeeOnTransfer();
    error ExcessiveInputAmount();
    error ExecuteNotAuthorized();
    error InsufficientAllowance();
    error InsufficientLiquidity();
    error InsufficientOutputAmount();
    error NotYetImplemented();


    bytes4 internal constant SWAP_SELECTOR = bytes4(keccak256("swap(uint256,uint256,address,bytes)"));
    uint256 internal constant EST_SWAP_GAS_USED = 100000;
    address internal constant WETH09 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant BACKUP_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // uniswap v2 factory

    function WETH() external pure returns (address) {
        return WETH09;
    }

    /// @notice Ensures deadline is not passed, otherwise revert. (0 = no deadline)
    /// @dev Modifier has been replaced with a function for gas efficiency
    /// @param deadline Unix timestamp in seconds for transaction to execute before
    function ensure(uint256 deadline) internal view {
        if (deadline < block.timestamp) revert Expired();
    }
    
    function _swap(bool isReverse, address to, address pair, uint256 amountOut)
        internal
        virtual
    {
        (uint256 amount0Out, uint256 amount1Out) = isReverse
            ? (amountOut, uint256(0))
            : (uint256(0), amountOut);
        _asmSwap(pair, amount0Out, amount1Out, to);
    }

    /// @notice Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined by the path. The first element of path is the input token, the last is the output token, and any intermediate elements represent intermediate pairs to trade through. msg.sender should have already given the router an allowance of at least amountIn on the input token.
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountIn Amount of input tokens to send.
    /// @param amountOutMin Minimum amount of output tokens that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        OpenMevLibrary.Swap[] memory sushiSwaps = OpenMevLibrary.getSwapsOut(OpenMevLibrary.SUSHI_FACTORY, amountIn, path);
        OpenMevLibrary.Swap[] memory uniSwaps = OpenMevLibrary.getSwapsOut(BACKUP_FACTORY, amountIn, path);
        uint256 length = sushiSwaps.length;
        if (uniSwaps[_dec(length)].amountOut < sushiSwaps[_dec(length)].amountOut) {
            //  sushi better price
            if (sushiSwaps[_dec(length)].amountOut < amountOutMin) revert InsufficientOutputAmount();
            amounts = _splitRoute(to, sushiSwaps, uniSwaps);
        } else {
            //  uni better price
            if (uniSwaps[_dec(length)].amountOut < amountOutMin) revert InsufficientOutputAmount();
            amounts = _splitRoute(to, uniSwaps, sushiSwaps);
        }
    }

    function _amountToSyncPrices(uint256 x1, uint256 y1, uint256 x2, uint256 y2) internal pure returns(uint256) {
        unchecked{
            return x1 * (Babylonian.sqrt(9 + (3988000 * x2 * y1 / (y2 * x1))) - 1997) / 1994;
        }        
    }
    
    function _getRoutingRatio(uint256 x1, uint256 x2) internal pure returns(uint256) {
        uint256 reserveRatio = 10000 * x1 / x2;
        return 10000 * reserveRatio / (10000 + reserveRatio);
    }

    /// @notice Calculate eth value of a token amount
    /// @param token Address of token
    /// @param amount Amount of token
    /// @return eth value
    function _wethAmount(address token, uint256 amount) internal view returns (uint256) {
        if (token == WETH09) return amount;
        address pair;
        bool isReverse;
        {
            (address token0, address token1) = OpenMevLibrary.sortTokens(token, WETH09);
            pair = OpenMevLibrary._asmPairFor(OpenMevLibrary.SUSHI_FACTORY, token0, token1);
            isReverse = WETH09 == token0;
        }
        {
            (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair).getReserves();
            (uint112 reserveIn, uint112 reserveOut) = isReverse ? (reserve1, reserve0) : (reserve0, reserve1);
            return OpenMevLibrary.getAmountOut(amount, reserveIn, reserveOut);
        }
    }

    function _splitRoute(address to, OpenMevLibrary.Swap[] memory dex0Swaps, OpenMevLibrary.Swap[] memory dex1Swaps) internal returns(uint256[] memory amounts) {
        uint256 length = dex0Swaps.length;
        amounts = new uint256[](_inc(length));
        amounts[0] = dex0Swaps[0].amountIn;
        for (uint256 i; i < length; i = _inc(i)) {
            uint256 amountIn = amounts[i];
            uint256 amountOutOnePair = _isZero(i) ? dex0Swaps[0].amountOut : OpenMevLibrary.getAmountOut(amountIn, uint256(dex0Swaps[i].reserveIn), uint256(dex0Swaps[i].reserveOut));
            address _to = i < _dec(length) ? address(this) : to;
            uint256 amount0 = _amountToSyncPrices(uint256(dex0Swaps[i].reserveIn), uint256(dex0Swaps[i].reserveOut), uint256(dex1Swaps[i].reserveIn), uint256(dex1Swaps[i].reserveOut));
            if (amount0 < amountIn){
                uint256 amountInFirstPair = amount0 + (amountIn - amount0 * _getRoutingRatio(uint256(dex0Swaps[i].reserveIn), uint256(dex1Swaps[i].reserveIn)) / 10000);
                uint256 amountOutFirstPair = OpenMevLibrary.getAmountOut(amountInFirstPair, uint256(dex0Swaps[i].reserveIn), uint256(dex0Swaps[i].reserveOut));
                uint256 amountOutSecondPair = OpenMevLibrary.getAmountOut(amountIn - amountInFirstPair, uint256(dex1Swaps[i].reserveIn), uint256(dex1Swaps[i].reserveOut));
                // uint256 amountOutGain = amountOutFirstPair + amountOutSecondPair - amountOutOnePair;
                if (_isNonZero(amountOutFirstPair + amountOutSecondPair - amountOutOnePair) && _wethAmount(dex0Swaps[i].tokenOut, amountOutFirstPair + amountOutSecondPair - amountOutOnePair) > block.basefee * EST_SWAP_GAS_USED){
                    // amountOutGain is greater than extra swap fee
                    // split the route
                    if (_isZero(i))
                        ERC20(dex0Swaps[0].tokenIn).safeTransferFrom(msg.sender, dex0Swaps[0].pair, amountInFirstPair);
                    else
                        ERC20(dex0Swaps[i].tokenIn).safeTransfer(dex0Swaps[i].pair, amountInFirstPair);
                    _swap(dex0Swaps[i].isReverse, _to, dex0Swaps[i].pair, amountOutFirstPair);
                    if (_isZero(i))
                        ERC20(dex1Swaps[0].tokenIn).safeTransferFrom(msg.sender, dex1Swaps[0].pair, amountIn - amountInFirstPair);
                    else
                        ERC20(dex1Swaps[i].tokenIn).safeTransfer(dex1Swaps[i].pair, amountIn - amountInFirstPair);
                    _swap(dex1Swaps[i].isReverse, _to, dex1Swaps[i].pair, amountOutSecondPair);
                    amounts[i+1] = amountOutFirstPair + amountOutSecondPair;
                    continue;
                } 
            }
            // extra gas not worth it
            // single swap on best rate dex
            if (_isZero(i))
                ERC20(dex0Swaps[0].tokenIn).safeTransferFrom(msg.sender, dex0Swaps[0].pair, amountIn);
            else
                ERC20(dex0Swaps[i].tokenIn).safeTransfer(dex0Swaps[i].pair, amountIn);
            _swap(dex0Swaps[i].isReverse, _to, dex0Swaps[i].pair, amountOutOnePair);
            amounts[i+1] = amountOutOnePair;
        }
    }

    /// @custom:assembly Efficient single swap call
    /// @notice Internal call to perform single swap
    /// @param pair Address of pair to swap in
    /// @param amount0Out AmountOut for token0 of pair
    /// @param amount1Out AmountOut for token1 of pair
    /// @param to Address of receiver
    function _asmSwap(
        address pair,
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) internal {
        bytes4 selector = SWAP_SELECTOR;
        assembly {
            let ptr := mload(0x40) // get free memory pointer
            mstore(ptr, selector) // append 4 byte selector
            mstore(add(ptr, 0x04), amount0Out) // append amount0Out
            mstore(add(ptr, 0x24), amount1Out) // append amount1Out
            mstore(add(ptr, 0x44), to) // append to
            mstore(add(ptr, 0x64), 0x80) // append location of byte list
            mstore(add(ptr, 0x84), 0) // append 0 bytes data
            let success := call(
                gas(), // gas remaining
                pair, // destination address
                0, // 0 value
                ptr, // input buffer
                0xA4, // input length
                0, // output buffer
                0 // output length
            )
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

    /// @notice Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// @notice Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
