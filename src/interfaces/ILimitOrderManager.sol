// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title ILimitOrderManager
 * @dev Interface for limit order management
 */
interface ILimitOrderManager {
    enum PositionDirection {
        LONG,
        SHORT
    }
    enum OrderStatus {
        PENDING,
        EXECUTED,
        CANCELLED,
        EXPIRED
    }

    struct LimitOrder {
        uint256 orderId;
        address trader;
        string countryId;
        PositionDirection direction;
        uint256 size;
        uint8 leverage;
        uint256 triggerPrice;
        uint256 executionFee;
        uint256 createdAt;
        uint256 expiresAt;
        OrderStatus status;
    }

    function createLimitOrder(
        address trader,
        string calldata countryId,
        uint8 direction,
        uint8 leverage,
        uint256 triggerPrice
    ) external payable returns (uint256);

    function executeLimitOrder(uint256 orderId) external returns (uint256);
    function cancelLimitOrder(uint256 orderId) external;
    function getLimitOrder(uint256 orderId) external view returns (LimitOrder memory);
    function getUserOrders(address trader) external view returns (uint256[] memory);
    function getMarketOrders(string calldata countryId) external view returns (uint256[] memory);
}
