// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 *
 * In order to transfer ownership, a recipient must be specified, at which point
 * the specified recipient can call `acceptOwnership` and take ownership.
 */

abstract contract TwoStepOwnable {
    error Unauthorized();
    error ZeroAddress();

    address private _owner;

    address private _newPotentialOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initialize contract by setting transaction submitter as initial owner.
     */
    constructor() {
        _owner = tx.origin;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    function _onlyOwner() private view {
        if (!isOwner()) revert Unauthorized();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        // require(isOwner(), "TwoStepOwnable: caller is not the owner.");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows a new account (`newOwner`) to accept ownership.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external payable onlyOwner {
        // require(
        //   newOwner != address(0),
        //   "TwoStepOwnable: new potential owner is the zero address."
        // );
        if (newOwner == address(0)) revert ZeroAddress();

        _newPotentialOwner = newOwner;
    }

    /**
     * @dev Cancel a transfer of ownership to a new account.
     * Can only be called by the current owner.
     */
    function cancelOwnershipTransfer() external payable onlyOwner {
        delete _newPotentialOwner;
    }

    /**
     * @dev Transfers ownership of the contract to the caller.
     * Can only be called by a new potential owner set by the current owner.
     */
    function acceptOwnership() external {
        // require(
        //   msg.sender == _newPotentialOwner,
        //   "TwoStepOwnable: current owner must set caller as new potential owner."
        // );
        if (msg.sender != _newPotentialOwner) revert Unauthorized();

        delete _newPotentialOwner;

        emit OwnershipTransferred(_owner, msg.sender);

        _owner = msg.sender;
    }
}
