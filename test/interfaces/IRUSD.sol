// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 /**
  * @title RUSD interface
  */
interface IRUSD is IERC20 {
    error ZeroInput();

    error PermissionDenied();

    function outUSDBVault() external view returns (address);

    function initialize(address _vault) external;

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function mint(address _account, uint256 _amount) external;

    function setOutUSDBVault(address _vault) external;
    
    event Deposit(address indexed _account, uint256 _amount);

    event Withdraw(address indexed _account, uint256 _amount);

    event SetOutUSDBVault(address _vault);
}