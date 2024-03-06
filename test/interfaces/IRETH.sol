// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 /**
  * @title RETH interface
  */
interface IRETH is IERC20 {
    error ZeroInput();

    error PermissionDenied();
    
    function deposit() payable external;

    function withdraw(uint256 amount) external;

    function mint(address _account, uint256 _amount) external;

    function setOutETHVault(address _outETHVault) external;
    
    event Deposit(address indexed _account, uint256 _amount);

    event Withdraw(address indexed _account, uint256 _amount);

    event SetOutETHVault(address _outETHVault);
}