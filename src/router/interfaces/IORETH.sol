//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

/**
 * @title Outrun ETH interface
 */
interface IORETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function transfer(address to, uint256 value) external returns (bool);
}
