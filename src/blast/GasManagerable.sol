//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "./IBlast.sol";

abstract contract GasManagerable {
    IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);

    address public gasManager;

    error ZeroAddress();

    error UnauthorizedAccount(address account);

    event ClaimMaxGas(address indexed recipient, uint256 gasAmount);

    constructor(address initialGasManager) {
        if (initialGasManager == address(0)) {
            revert ZeroAddress();
        }
        gasManager = initialGasManager;
        BLAST.configureClaimableGas();
    }

    modifier onlyGasManager() {
        address msgSender = msg.sender;
        if (gasManager != msgSender) {
            revert UnauthorizedAccount(msgSender);
        }
        _;
    }

    /**
     * @dev Read all gas remaining balance 
     */
    function readGasBalance() external view onlyGasManager returns (uint256 gasBanlance) {
        (, gasBanlance, , ) = BLAST.readGasParams(address(this));
    }

    /**
     * @dev Claim max gas of this contract
     * @param recipient - Address of receive gas
     */
    function claimMaxGas(address recipient) external onlyGasManager returns (uint256 gasAmount) {
        if (recipient == address(0)) {
            revert ZeroAddress();
        }

        gasAmount = BLAST.claimMaxGas(address(this), recipient);
        emit ClaimMaxGas(recipient, gasAmount);
    }

    function transferGasManager(address newGasManager) external onlyGasManager {
        if (newGasManager == address(0)) {
            revert ZeroAddress();
        }
        gasManager = newGasManager;
    }
}