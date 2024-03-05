// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/IOutUSDBVault.sol";

/**
 * @title Outrun USD Wrapped Token
 */
contract RUSD is ERC20, Ownable {
    error PermissionDenied();
    error ZeroInput();

    event OutETHVaultUpdated(address indexed vault);
    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed receiver, uint256 amount);
    event SetOutUSDBVault(address indexed vault);

    using SafeERC20 for IERC20;

    address public constant USDB = 0x4200000000000000000000000000000000000022;
    address public outUSDBVault;

    modifier onlyOutUSDBVault() {
        if (msg.sender != outUSDBVault) {
            revert PermissionDenied();
        }
        _;
    }

    constructor(address owner) ERC20("Outrun Wrapped USDB", "RUSD") Ownable(owner) {}

    /**
     * @dev Allows user to deposit USDB and mint RUSD
     * @notice User must have approved this contract to spend USDB
     */
    function deposit(uint256 amount) external  {
        if (amount == 0) {
            revert ZeroInput();
        }
        address user = msg.sender;
        IERC20(USDB).safeTransferFrom(user, outUSDBVault, amount);
        _mint(user, amount);

        emit Deposit(user, amount);
    }

        /**
     * @dev Allows user to withdraw USDB by RUSD
     * @param amount - Amount of RUSD for burn
     */
    function withdraw(uint256 amount) external  {
        if (amount == 0) {
            revert ZeroInput();
        }
        address user = msg.sender;
        _burn(user, amount);
        IOutUSDBVault(outUSDBVault).withdraw(user, amount);

        emit Withdraw(user, amount);
    }

    function mint(address _account, uint256 _amount) external  onlyOutUSDBVault {
        _mint(_account, _amount);
    }
    
    function setOutUSDBVault(address _outUSDBVault) external  onlyOwner {
        outUSDBVault = _outUSDBVault;
        emit SetOutUSDBVault(_outUSDBVault);
    }
}