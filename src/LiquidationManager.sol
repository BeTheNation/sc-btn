// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title LiquidationManager
 * @notice Handles position liquidations when margin falls below threshold
 */
contract LiquidationManager {
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

    address public immutable positionManager;
    uint256 public constant LIQUIDATION_THRESHOLD = 8000; // 80% margin ratio
    uint256 public constant LIQUIDATION_BONUS = 500; // 5% bonus for liquidators

    mapping(uint256 => LiquidationInfo) public liquidations;
    mapping(address => uint256) public liquidatorRewards;

    error PositionNotLiquidatable();
    error LiquidationFailed();
    error InvalidPosition();
    error InsufficientRewards();

    event LiquidationExecuted(
        uint256 indexed positionId,
        address indexed liquidator,
        uint256 liquidationPrice,
        int256 pnl,
        uint256 liquidatorReward
    );

    constructor(address _positionManager) {
        positionManager = _positionManager;
    }

    function isLiquidatable(uint256 positionId) external view returns (bool eligible, uint256 currentMarginRatio) {
        if (positionId == 0) return (false, 0);

        (bool success, bytes memory data) =
            positionManager.staticcall(abi.encodeWithSignature("getPosition(uint256)", positionId));

        if (!success) return (false, 0);

        (, string memory countryId, uint8 direction, uint256 size, uint8 leverage, uint256 entryPrice,, bool isActive) =
            abi.decode(data, (address, string, uint8, uint256, uint8, uint256, uint256, bool));

        if (!isActive) return (false, 0);

        uint256 currentPrice = _getCurrentPrice(countryId);
        int256 pnl = _calculatePnL(direction, size, leverage, entryPrice, currentPrice);

        uint256 initialMargin = size / leverage;
        uint256 currentMargin;

        if (pnl >= 0) {
            currentMargin = initialMargin + uint256(pnl);
        } else {
            uint256 loss = uint256(-pnl);
            currentMargin = loss >= initialMargin ? 0 : initialMargin - loss;
        }

        currentMarginRatio = (currentMargin * 10000) / initialMargin;
        eligible = currentMarginRatio <= LIQUIDATION_THRESHOLD;
    }

    function liquidatePosition(uint256 positionId) external returns (uint256 liquidatorReward) {
        if (positionId == 0) revert InvalidPosition();

        (bool eligible,) = this.isLiquidatable(positionId);
        if (!eligible) revert PositionNotLiquidatable();

        liquidatorReward = _executeLiquidation(positionId);
    }

    function _executeLiquidation(uint256 positionId) internal returns (uint256 liquidatorReward) {
        (bool success, bytes memory data) =
            positionManager.call(abi.encodeWithSignature("getPosition(uint256)", positionId));

        if (!success) revert InvalidPosition();

        (, string memory countryId,, uint256 size, uint8 leverage,,,) =
            abi.decode(data, (address, string, uint8, uint256, uint8, uint256, uint256, bool));

        uint256 currentPrice = _getCurrentPrice(countryId);
        liquidatorReward = ((size / leverage) * LIQUIDATION_BONUS) / 10000;

        (bool closeSuccess,) = positionManager.call(
            abi.encodeWithSignature("closePosition(uint256,uint256,bool)", positionId, currentPrice, true)
        );

        if (!closeSuccess) revert LiquidationFailed();

        _recordLiquidation(positionId, currentPrice, liquidatorReward);
    }

    function _recordLiquidation(uint256 positionId, uint256 currentPrice, uint256 liquidatorReward) internal {
        liquidations[positionId] = LiquidationInfo({
            positionId: positionId,
            liquidator: msg.sender,
            liquidationPrice: currentPrice,
            timestamp: block.timestamp,
            status: LiquidationStatus.EXECUTED
        });

        liquidatorRewards[msg.sender] += liquidatorReward;

        int256 pnl = _getPnLForEvent(positionId);

        emit LiquidationExecuted(positionId, msg.sender, currentPrice, pnl, liquidatorReward);
    }

    function _getPnLForEvent(uint256 positionId) internal view returns (int256 pnl) {
        (bool success, bytes memory data) =
            positionManager.staticcall(abi.encodeWithSignature("getPosition(uint256)", positionId));

        if (success) {
            (, string memory countryId, uint8 direction, uint256 size, uint8 leverage, uint256 entryPrice,,) =
                abi.decode(data, (address, string, uint8, uint256, uint8, uint256, uint256, bool));

            uint256 currentPrice = _getCurrentPrice(countryId);
            pnl = _calculatePnL(direction, size, leverage, entryPrice, currentPrice);
        }
    }

    function batchLiquidate(uint256[] calldata positionIds) external returns (uint256 totalReward) {
        for (uint256 i = 0; i < positionIds.length; i++) {
            try this.liquidatePosition(positionIds[i]) returns (uint256 reward) {
                totalReward += reward;
            } catch {
                continue;
            }
        }
    }

    function claimRewards() external {
        uint256 reward = liquidatorRewards[msg.sender];
        if (reward == 0) revert InsufficientRewards();

        liquidatorRewards[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: reward}("");
        if (!success) revert LiquidationFailed();
    }

    function _calculatePnL(uint8 direction, uint256 size, uint8 leverage, uint256 entryPrice, uint256 currentPrice)
        internal
        pure
        returns (int256 pnl)
    {
        uint256 leveragedSize = size * leverage;

        if (direction == 0) {
            // LONG
            if (currentPrice > entryPrice) {
                pnl = int256((leveragedSize * (currentPrice - entryPrice)) / entryPrice);
            } else {
                pnl = -int256((leveragedSize * (entryPrice - currentPrice)) / entryPrice);
            }
        } else {
            // SHORT
            if (entryPrice > currentPrice) {
                pnl = int256((leveragedSize * (entryPrice - currentPrice)) / entryPrice);
            } else {
                pnl = -int256((leveragedSize * (currentPrice - entryPrice)) / entryPrice);
            }
        }
    }

    function _getCurrentPrice(string memory countryId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(countryId))) % 100000 + 50000;
    }

    function getLiquidationInfo(uint256 positionId) external view returns (LiquidationInfo memory) {
        return liquidations[positionId];
    }

    function getLiquidatorRewards(address liquidator) external view returns (uint256) {
        return liquidatorRewards[liquidator];
    }

    function batchCheckLiquidatable(uint256[] calldata positionIds)
        external
        view
        returns (bool[] memory eligible, uint256[] memory marginRatios)
    {
        eligible = new bool[](positionIds.length);
        marginRatios = new uint256[](positionIds.length);

        for (uint256 i = 0; i < positionIds.length; i++) {
            (eligible[i], marginRatios[i]) = this.isLiquidatable(positionIds[i]);
        }
    }
}
