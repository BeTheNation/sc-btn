// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title IPositionManager
 * @dev Interface for position management
 */
interface IPositionManager {
    enum PositionDirection {
        LONG,
        SHORT
    }

    struct Position {
        uint256 positionId;
        string countryId;
        address trader;
        PositionDirection direction;
        uint256 size;
        uint8 leverage;
        uint256 entryPrice;
        uint256 openTime;
        bool isOpen;
    }

    function createPosition(
        address trader,
        string calldata countryId,
        uint8 direction,
        uint256 size,
        uint8 leverage,
        uint256 entryPrice
    ) external payable returns (uint256);

    function closePosition(address trader, uint256 exitPrice, address caller) external;

    function closePositionById(uint256 positionId, uint256 exitPrice, bool isLiquidation) external;

    function getTraderPositions(address trader)
        external
        view
        returns (uint256[] memory positionIds, Position[] memory positions);

    function getOpenPositionsCount(address trader) external view returns (uint256);

    function getPosition(uint256 positionId)
        external
        view
        returns (
            address trader,
            string memory countryId,
            uint8 direction,
            uint256 size,
            uint8 leverage,
            uint256 entryPrice,
            uint256 timestamp,
            bool isActive
        );

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

    function setAuthorizedCaller(address caller, bool authorized) external;
}
