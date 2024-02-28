//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

/**
 * @title Outrun Wrapped USDB interface
 */
interface IRUSD {
    function deposit(uint256 amount) external payable;

    function withdraw(uint256 amount) external;

    function transfer(address to, uint256 value) external returns (bool);
}
