// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/IOutETHVault.sol";

/**
 * @title Outrun ETH Wrapped Token
 */
contract RETH is ERC20, Ownable {
    error PermissionDenied();
    error ZeroInput();

    event OutETHVaultUpdated(address indexed vault);
    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed receiver, uint256 amount);
    event SetOutETHVault(address indexed vault);

    address public outETHVault;

    modifier onlyOutETHVault() {
        if (msg.sender != outETHVault) {
            revert PermissionDenied();
        }
        _;
    }

    constructor(address owner) ERC20("Outrun Wrapped ETH", "RETH") Ownable(owner) {}

    /**
     * @dev Allows user to deposit ETH and mint RETH
     */
    function deposit() public payable  {
        uint256 amount = msg.value;
        if (amount == 0) {
            revert ZeroInput();
        }

        address user = msg.sender;
        Address.sendValue(payable(outETHVault), amount);
        _mint(user, amount);

        emit Deposit(user, amount);
    }

    /**
     * @dev Allows user to withdraw ETH by RETH
     * @param amount - Amount of RETH for burn
     */
    function withdraw(uint256 amount) external  {
        if (amount == 0) {
            revert ZeroInput();
        }
        address user = msg.sender;
        _burn(user, amount);
        IOutETHVault(outETHVault).withdraw(user, amount);

        emit Withdraw(user, amount);
    }

    function mint(address _account, uint256 _amount) external  onlyOutETHVault {
        _mint(_account, _amount);
    }

    function setOutETHVault(address _outETHVault) external  onlyOwner {
        outETHVault = _outETHVault;
        emit SetOutETHVault(_outETHVault);
    }

    receive() external payable {
        deposit();
    }
}