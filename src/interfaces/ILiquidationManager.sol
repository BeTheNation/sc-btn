// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface ILiquidationManager {
    enum LiquidationStatus {
        PENDING,
        EXECUTED,
        FAILED
    }

    struct LiquidationInfo {
        uint256 positionId;
        address liquidator;
        uint256 liquidationPrice;
        uint256 timestamp;
        LiquidationStatus status;
    }

    function isLiquidatable(uint256 positionId) external view returns (bool eligible, uint256 currentMarginRatio);

    function liquidatePosition(uint256 positionId) external returns (uint256 liquidatorReward);

    function batchLiquidate(uint256[] calldata positionIds) external returns (uint256 totalReward);

    function claimRewards() external;

    function getLiquidationInfo(uint256 positionId) external view returns (LiquidationInfo memory);

    function getLiquidatorRewards(address liquidator) external view returns (uint256);

    function batchCheckLiquidatable(uint256[] calldata positionIds)
        external
        view
        returns (bool[] memory eligible, uint256[] memory marginRatios);
}
