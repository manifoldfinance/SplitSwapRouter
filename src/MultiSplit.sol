// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";

/// @title Multi Split - Allows to batch multiple split swap transactions into one.
/// @notice Based on Gnosis MultiSend v1.1.1 (https://etherscan.io/address/0x8d29be29923b68abfdd21e541b9374737b49cdad#code)
/// @author Sandy Bradley - <@sandybradley>
contract MultiSplit {
    using SafeTransferLib for ERC20;

    /// @notice Split Swap Router address
    address public ROUTER;
    /// @dev Governence for sweeping dust
    address internal GOV;
    /// @dev max uint256 for approvals
    uint256 internal constant MAX_UINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    error ExecuteNotAuthorized();

    constructor(address router) {
        ROUTER = router;
        GOV = tx.origin;
    }

    /// @dev Sends multiple transactions, allowing reverts
    /// @param transactions Encoded transactions. Each transaction is encoded as a packed bytes of
    ///                     value as a uint256 (=> 32 bytes),
    ///                     data length as a uint256 (=> 32 bytes),
    ///                     data as bytes.
    ///                     see abi.encodePacked for more information on packed encoding
    /// @notice This method is payable as delegatecalls keep the msg.value from the previous call
    ///         If the calling method (e.g. execTransaction) received ETH this would revert otherwise
    function multiSplit(bytes memory transactions) external payable {
        bytes memory dataToken = new bytes(68); // balanceOf / allowance / approve erc20 token call
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            let length := mload(transactions)
            let i := 0x20
            for {
                // Pre block is not used in "while mode"
            } lt(i, length) {
                // Post block is not used in "while mode"
            } {
                let value := mload(add(transactions, i))
                let dataLength := mload(add(transactions, add(i, 0x20)))
                let data := add(transactions, add(i, 0x40))
                let success := 0
                switch iszero(value)
                case 0 {
                    // ETH -> token
                    // requires eth to have been sent to this contract
                    let bal := balance(address()) // check eth balance
                    if gt(value, bal) {
                        revert(0, 0)
                    } // revert if not enough balance for tx
                    success := call(
                        gas(),
                        and(sload(0), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff), // router
                        value,
                        data,
                        dataLength,
                        0,
                        0
                    ) // swap
                    if gt(balance(address()), sub(bal, value)) {
                        // refund any dust
                        success := call(gas(), caller(), sub(balance(address()), sub(bal, value)), 0, 0, 0, 0)
                    }
                }
                default {
                    // token -> token / ETH
                    // requires token0 to have been sent to this contract
                    // using call as delegatecall fails because of V3 callback and address(this) usage in SplitSwapRouter
                    // success := delegatecall(gas(), router, data, dataLength, 0, 0)
                    let bal := balance(address()) // check eth balance
                    // extract token0 and amountIn from data
                    let amountIn := mload(add(data, 0x04)) // amountIn at slot 1 of data (offset = 0)
                    let token0 := mload(add(data, 0xC4)) // token0 at slot 7 of data (offset = 6 * 32 = 192 = 0xC0)
                    // check token balance
                    mstore(dataToken, shl(224, 0x70a08231)) // store balanceof sig
                    mstore(add(dataToken, 0x04), address()) // store address
                    success := call(gas(), token0, 0, dataToken, 36, dataToken, 0x20) // call balance of token0 at this address
                    let tokenBal := mload(dataToken)
                    if gt(amountIn, tokenBal) {
                        revert(0, 0)
                    } // revert if not enough balance for tx
                    // check router allowance
                    mstore(dataToken, shl(224, 0xdd62ed3e)) // store allowance sig
                    mstore(add(dataToken, 0x04), address()) // store owner address
                    mstore(
                        add(dataToken, 0x24),
                        and(sload(0), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                    ) // store spender address
                    success := call(gas(), token0, 0, dataToken, 68, dataToken, 0x20) // call allowance of token0 for router
                    let tokenAllowance := mload(dataToken)
                    if gt(amountIn, tokenAllowance) {
                        // if allowance greater than 0, be safe and reset to 0 first (for usdt etc)
                        if iszero(iszero(tokenAllowance)) {
                            mstore(dataToken, shl(224, 0x095ea7b3)) // store approve sig
                            mstore(
                                add(dataToken, 0x04),
                                and(sload(0), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                            ) // store spender address
                            mstore(add(dataToken, 0x24), 0) // store amount
                            success := call(gas(), token0, 0, dataToken, 68, 0, 0) // call approve 0 of token0 for router
                        }
                        // set to max
                        mstore(dataToken, shl(224, 0x095ea7b3)) // store approve sig
                        mstore(
                            add(dataToken, 0x04),
                            and(sload(0), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                        ) // store spender address
                        mstore(add(dataToken, 0x24), MAX_UINT) // store amount
                        success := call(gas(), token0, 0, dataToken, 68, 0, 0) // call approve max of token0 to router
                    }
                    success := call(
                        gas(),
                        and(sload(0), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff),  // router
                        0, //value
                        data, // input data
                        dataLength,
                        0,
                        0
                    )
                    if gt(balance(address()), bal) {
                        // send any eth
                        success := call(gas(), caller(), sub(balance(address()), bal), 0, 0, 0, 0)
                    }
                    // refund any dust token0
                    // check token balance
                    mstore(dataToken, shl(224, 0x70a08231)) // store balanceof sig
                    mstore(add(dataToken, 0x04), address()) // store address
                    success := call(gas(), token0, 0, dataToken, 36, dataToken, 0x20) // call balance of token0 at this address
                    value := mload(dataToken) // re-assign value as tokenBal2
                    if gt(value, sub(tokenBal, amountIn)) {
                        // transfer dust
                        mstore(dataToken, shl(224, 0x23b872dd)) // store transfer sig
                        mstore(add(dataToken, 0x04), caller()) // store address
                        mstore(add(dataToken, 0x24), sub(value, sub(tokenBal, amountIn))) // store amount
                        success := call(gas(), token0, 0, dataToken, 68, 0, 0) // call transfer token0 to sender
                    }
                }
                // do not revert on error
                // if eq(success, 0) {
                //     revert(0, 0)
                // }
                // Next entry starts at 0x40 byte + data length
                i := add(i, add(0x40, dataLength))
            }
        }
    }

    /// @notice Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// @notice Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function changeGov(address newGov) external {
        if (msg.sender != GOV) revert ExecuteNotAuthorized();
        GOV = newGov;
    }

    /// @notice Sweep dust tokens and eth to recipient
    /// @param tokens Array of token addresses
    /// @param recipient Address of recipient
    function sweep(address[] calldata tokens, address recipient) external {
        if (msg.sender != GOV) revert ExecuteNotAuthorized();
        for (uint256 i; i < tokens.length; i++) {
            address token = tokens[i];
            ERC20(token).safeTransfer(recipient, ERC20(token).balanceOf(address(this)));
        }
        SafeTransferLib.safeTransferETH(recipient, address(this).balance);
    }
}
