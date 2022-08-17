// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.13 <0.9.0;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function pairCodeHash() external pure returns (bytes32);
}
