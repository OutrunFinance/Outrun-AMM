// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import { IBlast } from "./IBlast.sol";
import { BlastModeEnum } from "./BlastModeEnum.sol";

interface IBlastGovernorable is BlastModeEnum  {
    function readGasBalance() external view returns (uint256);

    function claimMaxGas(address recipient) external returns (uint256 gasAmount);

    function transferGasManager(address newBlastGovernor) external;
}

abstract contract BlastGovernorable is IBlastGovernorable {
    IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);  // TODO mainnet

    address public blastGovernor;

    error BlastZeroAddress();

    error UnauthorizedAccount(address account);

    event ClaimMaxGas(address indexed recipient, uint256 gasAmount);

    event BlastGovernorTransferred(address indexed previousBlastGovernor, address indexed newBlastGovernor);

    constructor(address initialBlastGovernor) {
        require(initialBlastGovernor != address(0), BlastZeroAddress());
        
        _transferBlastGovernor(initialBlastGovernor);
    }

    modifier onlyBlastGovernor() {
        address msgSender = msg.sender;
        require(blastGovernor == msgSender, UnauthorizedAccount(msgSender));
        _;
    }

    /**
     * @dev Read all gas remaining balance 
     */
    function readGasBalance() external view override onlyBlastGovernor returns (uint256) {
        (, uint256 gasBanlance, , ) = BLAST.readGasParams(address(this));
        return gasBanlance;
    }

    /**
     * @dev Claim max gas of this contract
     * @param recipient - Address of receive gas
     */
    function claimMaxGas(address recipient) external override onlyBlastGovernor returns (uint256 gasAmount) {
        require(recipient != address(0), BlastZeroAddress());

        gasAmount = BLAST.claimMaxGas(address(this), recipient);
        emit ClaimMaxGas(recipient, gasAmount);
    }

    function transferGasManager(address newBlastGovernor) external override onlyBlastGovernor {
        require(newBlastGovernor != address(0), BlastZeroAddress());

        _transferBlastGovernor(newBlastGovernor);
    }

    function _transferBlastGovernor(address newBlastGovernor) internal {
        address oldBlastGovernor = blastGovernor;
        blastGovernor = newBlastGovernor;
        BLAST.configure(YieldMode.CLAIMABLE, GasMode.CLAIMABLE, newBlastGovernor);

        emit BlastGovernorTransferred(oldBlastGovernor, newBlastGovernor);
    }
}