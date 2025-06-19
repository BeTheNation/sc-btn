// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title IOrderManager
 * @dev Interface for the main order management contract
 */
interface IOrderManager {
    enum OrderType {
        MARKET,
        LIMIT
    }
    enum PositionDirection {
        LONG,
        SHORT
    }

    function createMarketOrder(string calldata countryId, PositionDirection direction, uint8 leverage)
        external
        payable
        returns (uint256);

    function createLimitOrder(
        string calldata countryId,
        PositionDirection direction,
        uint8 leverage,
        uint256 triggerPrice
    ) external payable returns (uint256);

    function closePosition(address trader, uint256 exitPrice) external;

    function closePositionById(uint256 positionId, uint256 exitPrice) external;

    function getPosition(address trader)
        external
        view
        returns (
            uint256 positionId,
            string memory countryId,
            PositionDirection direction,
            uint256 size,
            uint8 leverage,
            uint256 entryPrice,
            uint256 openTime,
            bool isOpen
        );

    function getTraderPositions(address trader)
        external
        view
        returns (uint256[] memory positionIds, bytes memory positionsData);

    function getOpenPositionsCount(address trader) external view returns (uint256);
}
