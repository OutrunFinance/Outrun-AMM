//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

interface IOutETHVault {
    struct FlashLoanFee {
        uint256 providerFeeRate;
        uint256 protocolFeeRate;
    }

    error ZeroInput();

    error PermissionDenied();

    error FeeRateOverflow();

    error FlashLoanRepayFailed();

    function initialize() external;

    function withdraw(address user, uint256 amount) external;

    function claimETHYield() external;

    function flashLoan(address payable receiver, uint256 amount, bytes calldata data) external;

    function setFeeRate(uint256 _feeRate) external;

    function setFlashLoanFee(uint256 _providerFeeRate, uint256 _protocolFeeRate) external;

    function setRevenuePool(address _pool) external;

    function setRETHStakeManager(address _RETHStakeManager) external;

    event ClaimETHYield(uint256 amount);

    event FlashLoan(address indexed receiver, uint256 amount);

    event SetFeeRate(uint256 _feeRate);

    event SetFlashLoanFee(uint256 _providerFeeRate, uint256 _protocolFeeRate);

    event SetRevenuePool(address _pool);

    event SetRETHStakeManager(address _RETHStakeManager);
}