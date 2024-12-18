// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}
