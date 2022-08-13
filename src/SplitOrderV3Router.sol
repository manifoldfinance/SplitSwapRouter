// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

/**
Optimal split order router for single swaps with identical markets on uniV2 forks
*/

/// ============ Internal Imports ============
import "./ERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapV3SwapCallback.sol";
import "./libraries/SplitOrderV3Library.sol";
import { SafeTransferLib } from "./libraries/SafeTransferLib.sol";

/// @title SplitOrderV3Router
/// @author Sandy Bradley <sandy@manifoldx.com>
/// @notice Splits single swap order optimally across 2 uniV2 Dexes
contract SplitOrderV3Router is IUniswapV3SwapCallback {
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
    address internal constant WETH09 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant BACKUP_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // uniswap v2 factory
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    uint256 internal constant EST_SWAP_GAS_USED = 100000;
    uint256 internal constant MIN_LIQUIDITY = 1000;

    function factory() external pure returns (address) {
        return SplitOrderV3Library.SUSHI_FACTORY;
    }

    function WETH() external pure returns (address) {
        return WETH09;
    }

    /// @dev Callback for Uniswap V3 pool.
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        address pool;
        address tokenIn;
        {
            uint24 fee;
            address tokenOut;
            (tokenIn, tokenOut, fee) = abi.decode(data, (address, address, uint24));
            (address token0, address token1) = SplitOrderV3Library.sortTokens(tokenIn, tokenOut);
            pool = SplitOrderV3Library.uniswapV3PoolAddress(token0, token1, fee);
        }
        if (msg.sender != pool) revert ExecuteNotAuthorized();
        if (amount0Delta > 0) ERC20(tokenIn).safeTransfer(msg.sender, uint256(amount0Delta));
        if (amount1Delta > 0) ERC20(tokenIn).safeTransfer(msg.sender, uint256(amount1Delta));
    }

    /// @notice Ensures deadline is not passed, otherwise revert. (0 = no deadline)
    /// @dev Modifier has been replaced with a function for gas efficiency
    /// @param deadline Unix timestamp in seconds for transaction to execute before
    function ensure(uint256 deadline) internal view {
        if (deadline < block.timestamp) revert Expired();
    }

    /// @notice Checks amounts for token A and token B are balanced for pool. Creates a pair if none exists
    /// @dev Reverts with custom errors replace requires
    /// @param tokenA Token in pool
    /// @param tokenB Token in pool
    /// @param amountADesired Amount of token A desired to add to pool
    /// @param amountBDesired Amount of token B desired to add to pool
    /// @param amountAMin Minimum amount of token A, can be 0
    /// @param amountBMin Minimum amount of token B, can be 0
    /// @return amountA exact amount of token A to be added
    /// @return amountB exact amount of token B to be added
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        address factory0 = SplitOrderV3Library.SUSHI_FACTORY;
        if (IUniswapV2Factory(factory0).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory0).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = SplitOrderV3Library.getReserves(factory0, tokenA, tokenB);
        if (_isZero(reserveA) && _isZero(reserveB)) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = SplitOrderV3Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal > amountBDesired) {
                uint256 amountAOptimal = SplitOrderV3Library.quote(amountBDesired, reserveB, reserveA);
                if (amountAOptimal > amountADesired) revert InsufficientAAmount();
                if (amountAOptimal < amountAMin) revert InsufficientAAmount();
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            } else {
                if (amountBOptimal < amountBMin) revert InsufficientBAmount();
                (amountA, amountB) = (amountADesired, amountBOptimal);
            }
        }
    }

    /// @notice Adds liquidity to an ERC-20⇄ERC-20 pool. msg.sender should have already given the router an allowance of at least amountADesired/amountBDesired on tokenA/tokenB
    /// @param tokenA Token in pool
    /// @param tokenB Token in pool
    /// @param amountADesired Amount of token A desired to add to pool
    /// @param amountBDesired Amount of token B desired to add to pool
    /// @param amountAMin Minimum amount of token A, can be 0
    /// @param amountBMin Minimum amount of token B, can be 0
    /// @param to Address to receive liquidity token
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amountA exact amount of token A added to pool
    /// @return amountB exact amount of token B added to pool
    /// @return liquidity amount of liquidity token received
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        virtual
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        ensure(deadline);
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = SplitOrderV3Library.pairFor(SplitOrderV3Library.SUSHI_FACTORY, tokenA, tokenB);
        ERC20(tokenA).safeTransferFrom(msg.sender, pair, amountA);
        ERC20(tokenB).safeTransferFrom(msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    /// @notice Adds liquidity to an ERC-20⇄WETH pool with ETH. msg.sender should have already given the router an allowance of at least amountTokenDesired on token. msg.value is treated as a amountETHDesired. Leftover ETH, if any, is returned to msg.sender
    /// @param token Token in pool
    /// @param amountTokenDesired Amount of token desired to add to pool
    /// @param amountTokenMin Minimum amount of token, can be 0
    /// @param amountETHMin Minimum amount of ETH, can be 0
    /// @param to Address to receive liquidity token
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amountToken exact amount of token added to pool
    /// @return amountETH exact amount of ETH added to pool
    /// @return liquidity amount of liquidity token received
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        ensure(deadline);
        address weth = WETH09;
        (amountToken, amountETH) = _addLiquidity(
            token,
            weth,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = SplitOrderV3Library.pairFor(SplitOrderV3Library.SUSHI_FACTORY, token, weth);
        ERC20(token).safeTransferFrom(msg.sender, pair, amountToken);
        IWETH(weth).deposit{ value: amountETH }();
        ERC20(weth).safeTransfer(pair, amountETH);
        liquidity = IUniswapV2Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) SafeTransferLib.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    /// @notice Removes liquidity from an ERC-20⇄ERC-20 pool. msg.sender should have already given the router an allowance of at least liquidity on the pool.
    /// @param tokenA Token in pool
    /// @param tokenB Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountAMin Minimum amount of token A, can be 0
    /// @param amountBMin Minimum amount of token B, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amountA Amount of token A received
    /// @return amountB Amount of token B received
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual returns (uint256 amountA, uint256 amountB) {
        ensure(deadline);
        address pair = SplitOrderV3Library.pairFor(SplitOrderV3Library.SUSHI_FACTORY, tokenA, tokenB);
        ERC20(pair).safeTransferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0, ) = SplitOrderV3Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        if (amountA < amountAMin) revert InsufficientAAmount();
        if (amountB < amountBMin) revert InsufficientBAmount();
    }

    /// @notice Removes liquidity from an ERC-20⇄WETH pool and receive ETH. msg.sender should have already given the router an allowance of at least liquidity on the pool.
    /// @param token Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountTokenMin Minimum amount of token, can be 0
    /// @param amountETHMin Minimum amount of ETH, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amountToken Amount of token received
    /// @return amountETH Amount of ETH received
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual returns (uint256 amountToken, uint256 amountETH) {
        address weth = WETH09;
        uint256 balanceBefore = ERC20(token).balanceOf(address(this));
        (amountToken, amountETH) = removeLiquidity(
            token,
            weth,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        // exploit check from fee-on-transfer tokens
        if (amountToken != ERC20(token).balanceOf(address(this)) - balanceBefore) revert TokenIsFeeOnTransfer();
        ERC20(token).safeTransfer(to, amountToken);
        IWETH(weth).withdraw(amountETH);
        SafeTransferLib.safeTransferETH(to, amountETH);
    }

    /// @notice Removes liquidity from an ERC-20⇄ERC-20 pool without pre-approval, thanks to permit.
    /// @param tokenA Token in pool
    /// @param tokenB Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountAMin Minimum amount of token A, can be 0
    /// @param amountBMin Minimum amount of token B, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @param approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1)
    /// @param v The v component of the permit signature
    /// @param r The r component of the permit signature
    /// @param s The s component of the permit signature
    /// @return amountA Amount of token A received
    /// @return amountB Amount of token B received
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (uint256 amountA, uint256 amountB) {
        IUniswapV2Pair(SplitOrderV3Library.pairFor(SplitOrderV3Library.SUSHI_FACTORY, tokenA, tokenB)).permit(
            msg.sender,
            address(this),
            approveMax ? type(uint256).max : liquidity,
            deadline,
            v,
            r,
            s
        );
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    /// @notice Removes liquidity from an ERC-20⇄WETTH pool and receive ETH without pre-approval, thanks to permit
    /// @param token Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountTokenMin Minimum amount of token, can be 0
    /// @param amountETHMin Minimum amount of ETH, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @param approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1)
    /// @param v The v component of the permit signature
    /// @param r The r component of the permit signature
    /// @param s The s component of the permit signature
    /// @return amountToken Amount of token received
    /// @return amountETH Amount of ETH received
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (uint256 amountToken, uint256 amountETH) {
        IUniswapV2Pair(SplitOrderV3Library.pairFor(SplitOrderV3Library.SUSHI_FACTORY, token, WETH09)).permit(
            msg.sender,
            address(this),
            approveMax ? type(uint256).max : liquidity,
            deadline,
            v,
            r,
            s
        );
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    /// @notice Identical to removeLiquidityETH, but succeeds for tokens that take a fee on transfer. msg.sender should have already given the router an allowance of at least liquidity on the pool.
    /// @param token Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountTokenMin Minimum amount of token, can be 0
    /// @param amountETHMin Minimum amount of ETH, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amountETH Amount of ETH received
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual returns (uint256 amountETH) {
        address weth = WETH09;
        uint256 balanceBefore = ERC20(token).balanceOf(address(this));
        (, amountETH) = removeLiquidity(token, weth, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        ERC20(token).safeTransfer(to, ERC20(token).balanceOf(address(this)) - balanceBefore);
        IWETH(weth).withdraw(amountETH);
        SafeTransferLib.safeTransferETH(to, amountETH);
    }

    /// @notice Identical to removeLiquidityETHWithPermit, but succeeds for tokens that take a fee on transfer.
    /// @param token Token in pool
    /// @param liquidity Amount of liquidity tokens to remove
    /// @param amountTokenMin Minimum amount of token, can be 0
    /// @param amountETHMin Minimum amount of ETH, can be 0
    /// @param to Address to receive pool tokens
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @param approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1)
    /// @param v The v component of the permit signature
    /// @param r The r component of the permit signature
    /// @param s The s component of the permit signature
    /// @return amountETH Amount of ETH received
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (uint256 amountETH) {
        IUniswapV2Pair(SplitOrderV3Library.pairFor(SplitOrderV3Library.SUSHI_FACTORY, token, WETH09)).permit(
            msg.sender,
            address(this),
            approveMax ? type(uint256).max : liquidity,
            deadline,
            v,
            r,
            s
        );
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    function _swapSingle(
        bool isReverse,
        address to,
        address pair,
        uint256 amountOut
    ) internal virtual {
        (uint256 amount0Out, uint256 amount1Out) = isReverse ? (amountOut, uint256(0)) : (uint256(0), amountOut);
        _asmSwap(pair, amount0Out, amount1Out, to);
    }

    function _swapUniV3(
        bool isReverse,
        uint24 fee,
        address to,
        address tokenIn,
        address tokenOut,
        address pair,
        uint256 amountIn
    ) internal virtual returns (uint256 amountOut) {
        // bytes memory data = abi.encodePacked(tokenIn, tokenOut, fee);
        bytes memory data = abi.encode(tokenIn, tokenOut, fee);
        uint160 sqrtPriceLimitX96 = isReverse ? MAX_SQRT_RATIO - 1 : MIN_SQRT_RATIO + 1;
        (int256 amount0, int256 amount1) = IUniswapV3Pool(pair).swap(
            to,
            !isReverse,
            int256(amountIn),
            sqrtPriceLimitX96,
            data
        );
        amountOut = isReverse ? uint256(-(amount0)) : uint256(-(amount1));
    }

    /// @notice Internal core swap. Requires the initial amount to have already been sent to the first pair.
    /// @param _to Address of receiver
    /// @param swaps Array of user swap data
    function _swap(address _to, SplitOrderV3Library.Swap[] memory swaps)
        internal
        virtual
        returns (uint256[] memory amounts)
    {
        uint256 length = swaps.length;
        amounts = new uint256[](_inc(length));
        amounts[0] =
            swaps[0].pools[0].amountIn +
            swaps[0].pools[1].amountIn +
            swaps[0].pools[2].amountIn +
            swaps[0].pools[3].amountIn +
            swaps[0].pools[4].amountIn +
            swaps[0].pools[5].amountIn;
        for (uint256 i; i < length; i = _inc(i)) {
            address to = i < _dec(length) ? address(this) : _to; // split route requires intermediate swaps route to this address
            // V2 swaps
            for (uint256 j; j < 2; j = _inc(j)) {
                if (_isNonZero(swaps[i].pools[j].amountIn)) {
                    if (_isNonZero(i))
                        ERC20(swaps[i].tokenIn).safeTransfer(swaps[i].pools[j].pair, swaps[i].pools[j].amountIn);
                    _swapSingle(swaps[i].isReverse, to, swaps[i].pools[j].pair, swaps[i].pools[j].amountOut);
                    amounts[_inc(i)] = amounts[_inc(i)] + swaps[i].pools[j].amountOut;
                }
            }
            // V3 swaps
            for (uint256 j = 2; j < 6; j = _inc(j)) {
                uint24 fee = uint24(SplitOrderV3Library.getFee(j));
                if (_isNonZero(swaps[i].pools[j].amountIn)) {
                    uint256 amountOut = _swapUniV3(
                        swaps[i].isReverse,
                        fee,
                        to,
                        swaps[i].tokenIn,
                        swaps[i].tokenOut,
                        swaps[i].pools[j].pair,
                        swaps[i].pools[j].amountIn
                    );
                    amounts[_inc(i)] = amounts[_inc(i)] + amountOut;
                }
            }
        }
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
        SplitOrderV3Library.Swap[] memory swaps = SplitOrderV3Library.getSwapsOut(BACKUP_FACTORY, amountIn, path);
        {
            uint256 amountOut;
            for (uint256 i; i < 6; i = _inc(i)) {
                amountOut = amountOut + swaps[_dec(swaps.length)].pools[i].amountOut;
            }
            if (amountOutMin > amountOut) revert InsufficientOutputAmount();
        }
        for (uint256 i; i < 2; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pools[i].pair, swaps[0].pools[i].amountIn);
        }
        for (uint256 i = 2; i < 6; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(path[0]).safeTransferFrom(msg.sender, address(this), swaps[0].pools[i].amountIn);
        }
        amounts = _swap(to, swaps);
    }

    /// @notice Receive an exact amount of output tokens for as few input tokens as possible, along the route determined by the path. msg.sender should have already given the router an allowance of at least amountInMax on the input token.
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountOut Amount of output tokens to receive
    /// @param amountInMax Maximum amount of input tokens
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory amounts) {
        ensure(deadline);

        SplitOrderV3Library.Swap[] memory swaps = SplitOrderV3Library.getSwapsIn(BACKUP_FACTORY, amountOut, path);
        {
            uint256 amountIn;
            for (uint256 i; i < 6; i = _inc(i)) {
                amountIn = amountIn + swaps[0].pools[i].amountIn;
            }
            if (amountInMax < amountIn) revert ExcessiveInputAmount();
        }
        for (uint256 i; i < 2; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pools[i].pair, swaps[0].pools[i].amountIn);
        }
        for (uint256 i = 2; i < 6; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(path[0]).safeTransferFrom(msg.sender, address(this), swaps[0].pools[i].amountIn);
        }
        amounts = _swap(to, swaps);
    }

    /// @notice Swaps an exact amount of ETH for as many output tokens as possible, along the route determined by the path. The first element of path must be WETH, the last is the output token. amountIn = msg.value
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountOutMin Minimum amount of output tokens that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        address weth = WETH09;
        if (path[0] != weth) revert InvalidPath();
        SplitOrderV3Library.Swap[] memory swaps = SplitOrderV3Library.getSwapsOut(BACKUP_FACTORY, msg.value, path);
        {
            uint256 amountOut;
            for (uint256 i; i < 6; i = _inc(i)) {
                amountOut = amountOut + swaps[_dec(swaps.length)].pools[i].amountOut;
            }
            if (amountOutMin > amountOut) revert InsufficientOutputAmount();
        }
        IWETH(weth).deposit{ value: msg.value }();
        for (uint256 i; i < 2; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(weth).safeTransfer(swaps[0].pools[i].pair, swaps[0].pools[i].amountIn);
        }
        amounts = _swap(to, swaps);
    }

    /// @notice Receive an exact amount of ETH for as few input tokens as possible, along the route determined by the path. The first element of path is the input token, the last must be WETH. msg.sender should have already given the router an allowance of at least amountInMax on the input token.
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountOut Amount of ETH to receive
    /// @param amountInMax Maximum amount of input tokens
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        address weth = WETH09;
        if (path[_dec(path.length)] != weth) revert InvalidPath();
        SplitOrderV3Library.Swap[] memory swaps = SplitOrderV3Library.getSwapsIn(BACKUP_FACTORY, amountOut, path);
        {
            uint256 amountIn;
            for (uint256 i; i < 6; i = _inc(i)) {
                amountIn = amountIn + swaps[0].pools[i].amountIn;
            }
            if (amountInMax < amountIn) revert ExcessiveInputAmount();
        }
        for (uint256 i; i < 2; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pools[i].pair, swaps[0].pools[i].amountIn);
        }
        for (uint256 i = 2; i < 6; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(path[0]).safeTransferFrom(msg.sender, address(this), swaps[0].pools[i].amountIn);
        }
        amounts = _swap(address(this), swaps);
        IWETH(weth).withdraw(amounts[_dec(path.length)]);
        SafeTransferLib.safeTransferETH(to, amounts[_dec(path.length)]);
    }

    /// @notice Swaps an exact amount of tokens for as much ETH as possible, along the route determined by the path. The first element of path is the input token, the last must be WETH.
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountIn Amount of input tokens to send.
    /// @param amountOutMin Minimum amount of ETH that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        address weth = WETH09;
        if (path[_dec(path.length)] != weth) revert InvalidPath();
        SplitOrderV3Library.Swap[] memory swaps = SplitOrderV3Library.getSwapsOut(BACKUP_FACTORY, amountIn, path);
        uint256 amountOut;
        for (uint256 i; i < 6; i = _inc(i)) {
            amountOut = amountOut + swaps[_dec(swaps.length)].pools[i].amountOut;
        }
        if (amountOutMin > amountOut) revert InsufficientOutputAmount();
        for (uint256 i; i < 2; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(path[0]).safeTransferFrom(msg.sender, swaps[0].pools[i].pair, swaps[0].pools[i].amountIn);
        }
        for (uint256 i = 2; i < 6; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(path[0]).safeTransferFrom(msg.sender, address(this), swaps[0].pools[i].amountIn);
        }
        amounts = _swap(address(this), swaps);
        amountOut = amounts[_dec(path.length)];
        IWETH(weth).withdraw(amountOut);
        SafeTransferLib.safeTransferETH(to, amountOut);
    }

    /// @notice Receive an exact amount of tokens for as little ETH as possible, along the route determined by the path. The first element of path must be WETH. Leftover ETH, if any, is returned to msg.sender. amountInMax = msg.value
    /// @dev Require has been replaced with revert for gas optimization. Fallback alternate router check for insufficient output amount. Attempt to back-run swaps.
    /// @param amountOut Amount of output tokens that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    /// @return amounts Array of input token amount and all subsequent output token amounts
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual returns (uint256[] memory amounts) {
        ensure(deadline);
        address weth = WETH09;
        if (path[0] != weth) revert InvalidPath();
        SplitOrderV3Library.Swap[] memory swaps = SplitOrderV3Library.getSwapsIn(BACKUP_FACTORY, amountOut, path);
        uint256 amountIn;
        for (uint256 i; i < 6; i = _inc(i)) {
            amountIn = amountIn + swaps[0].pools[i].amountIn;
        }
        if (msg.value < amountIn) revert ExcessiveInputAmount();
        IWETH(weth).deposit{ value: amountIn }();
        for (uint256 i; i < 2; i = _inc(i)) {
            if (_isNonZero(swaps[0].pools[i].amountIn))
                ERC20(weth).safeTransfer(swaps[0].pools[i].pair, swaps[0].pools[i].amountIn);
        }
        amounts = _swap(to, swaps);

        // refund dust eth, if any
        if (msg.value > amountIn) SafeTransferLib.safeTransferETH(msg.sender, msg.value - amountIn);
    }

    //requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokensExecute(
        address pair,
        uint256 amountOutput,
        bool isReverse,
        address to
    ) internal virtual {
        (uint256 amount0Out, uint256 amount1Out) = isReverse ? (amountOutput, uint256(0)) : (uint256(0), amountOutput);
        _asmSwap(pair, amount0Out, amount1Out, to);
    }

    function _swapSupportingFeeOnTransferTokens(
        address[] memory path,
        address _to,
        address factory0
    ) internal virtual {
        uint256 length = path.length;
        for (uint256 i; i < _dec(length); i = _inc(i)) {
            (address tokenIn, address tokenOut) = (path[i], path[_inc(i)]);
            bool isReverse;
            address pair;
            {
                (address token0, address token1) = SplitOrderV3Library.sortTokens(tokenIn, tokenOut);
                isReverse = tokenOut == token0;
                pair = SplitOrderV3Library._asmPairFor(factory0, token0, token1);
            }
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                uint256 amountInput;
                (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair).getReserves();
                (uint112 reserveInput, uint112 reserveOutput) = isReverse ? (reserve1, reserve0) : (reserve0, reserve1);
                amountInput = ERC20(tokenIn).balanceOf(pair) - reserveInput;
                amountOutput = SplitOrderV3Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }

            address to = i < length - 2 ? SplitOrderV3Library.pairFor(factory0, tokenOut, path[i + 2]) : _to;
            _swapSupportingFeeOnTransferTokensExecute(pair, amountOutput, isReverse, to);
        }
    }

    /// @notice Identical to swapExactTokensForTokens, but succeeds for tokens that take a fee on transfer. msg.sender should have already given the router an allowance of at least amountIn on the input token.
    /// @dev Require has been replaced with revert for gas optimization. Attempt to back-run swaps.
    /// @param amountIn Amount of input tokens to send.
    /// @param amountOutMin Minimum amount of output tokens that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual {
        ensure(deadline);
        address factory0 = SplitOrderV3Library.SUSHI_FACTORY;
        ERC20(path[0]).safeTransferFrom(msg.sender, SplitOrderV3Library.pairFor(factory0, path[0], path[1]), amountIn);
        uint256 balanceBefore = ERC20(path[_dec(path.length)]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to, factory0);
        if (ERC20(path[_dec(path.length)]).balanceOf(to) - balanceBefore < amountOutMin)
            revert InsufficientOutputAmount();
    }

    /// @notice Identical to swapExactETHForTokens, but succeeds for tokens that take a fee on transfer. amountIn = msg.value
    /// @dev Require has been replaced with revert for gas optimization. Attempt to back-run swaps.
    /// @param amountOutMin Minimum amount of output tokens that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual {
        ensure(deadline);
        address weth = WETH09;
        if (path[0] != weth) revert InvalidPath();
        address factory0 = SplitOrderV3Library.SUSHI_FACTORY;
        uint256 amountIn = msg.value;
        IWETH(weth).deposit{ value: amountIn }();
        ERC20(weth).safeTransfer(SplitOrderV3Library.pairFor(factory0, path[0], path[1]), amountIn);
        uint256 balanceBefore = ERC20(path[_dec(path.length)]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to, factory0);
        if (ERC20(path[_dec(path.length)]).balanceOf(to) - balanceBefore < amountOutMin)
            revert InsufficientOutputAmount();
    }

    /// @notice Identical to swapExactTokensForETH, but succeeds for tokens that take a fee on transfer.
    /// @dev Require has been replaced with revert for gas optimization. Attempt to back-run swaps.
    /// @param amountIn Amount of input tokens to send.
    /// @param amountOutMin Minimum amount of ETH that must be received
    /// @param path Array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
    /// @param to Address of receiver
    /// @param deadline Unix timestamp in seconds after which the transaction will revert
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual {
        ensure(deadline);
        address weth = WETH09;
        if (path[_dec(path.length)] != weth) revert InvalidPath();
        address factory0 = SplitOrderV3Library.SUSHI_FACTORY;
        ERC20(path[0]).safeTransferFrom(msg.sender, SplitOrderV3Library.pairFor(factory0, path[0], path[1]), amountIn);
        uint256 balanceBefore = ERC20(weth).balanceOf(address(this));
        _swapSupportingFeeOnTransferTokens(path, address(this), factory0);
        uint256 amountOut = ERC20(weth).balanceOf(address(this)) - balanceBefore;
        if (amountOut < amountOutMin) revert InsufficientOutputAmount();
        IWETH(weth).withdraw(amountOut);
        SafeTransferLib.safeTransferETH(to, amountOut);
    }

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure virtual returns (uint256 amountB) {
        return SplitOrderV3Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure virtual returns (uint256 amountOut) {
        return SplitOrderV3Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure virtual returns (uint256 amountIn) {
        return SplitOrderV3Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        virtual
        returns (uint256[] memory amounts)
    {
        return SplitOrderV3Library.getAmountsOut(SplitOrderV3Library.SUSHI_FACTORY, amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        virtual
        returns (uint256[] memory amounts)
    {
        return SplitOrderV3Library.getAmountsIn(SplitOrderV3Library.SUSHI_FACTORY, amountOut, path);
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
        assembly ("memory-safe") {
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

            if iszero(success) {
                // 0 size error is the cheapest, but mstore an error enum if you wish
                revert(0x0, 0x0)
            }
        }
    }

    /// @custom:gas Uint256 zero check gas saver
    /// @notice Uint256 zero check gas saver
    /// @param value Number to check
    function _isZero(uint256 value) internal pure returns (bool boolValue) {
        // Stack Only Safety
        assembly ("memory-safe") {
            boolValue := iszero(value)
        }
    }

    /// @custom:gas Uint256 not zero check gas saver
    /// @notice Uint256 not zero check gas saver
    /// @param value Number to check
    function _isNonZero(uint256 value) internal pure returns (bool boolValue) {
        // Stack Only Safety
        assembly ("memory-safe") {
            boolValue := iszero(iszero(value))
        }
    }

    /// @custom:gas Unchecked increment gas saver
    /// @notice Unchecked increment gas saver for loops
    /// @param i Number to increment
    function _inc(uint256 i) internal pure returns (uint256 result) {
        // Stack only safety
        assembly ("memory-safe") {
            result := add(i, 1)
        }
    }

    /// @custom:gas Unchecked decrement gas saver
    /// @notice Unchecked decrement gas saver for loops
    /// @param i Number to decrement
    function _dec(uint256 i) internal pure returns (uint256 result) {
        // Stack Only Safety
        assembly ("memory-safe") {
            result := sub(i, 1)
        }
    }

    /// @notice Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// @notice Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
