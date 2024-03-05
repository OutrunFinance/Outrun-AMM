//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

interface IOutUSDBVault {
    function withdraw(address user, uint256 amount) external;
}