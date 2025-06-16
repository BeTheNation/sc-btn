// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title LimitOrderManager
 * @notice Manages conditional limit orders and execution
 */
contract LimitOrderManager {
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

    address public immutable orderManager;
    address public immutable positionManager;

    mapping(uint256 => LimitOrder) public orders;
    mapping(string => uint256[]) public marketOrders;
    mapping(address => uint256[]) public userOrders;
    uint256 public nextOrderId;

    uint256 public constant TRANSACTION_FEE = 30;
    uint256 public constant DEFAULT_EXPIRY = 7 days;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    event LimitOrderCreated(
        uint256 indexed orderId,
        address indexed trader,
        string countryId,
        PositionDirection direction,
        uint256 triggerPrice
    );

    event LimitOrderExecuted(
        uint256 indexed orderId, address indexed trader, uint256 executionPrice, uint256 positionId
    );

    event LimitOrderCancelled(uint256 indexed orderId, address indexed trader);

    error OnlyOrderManager();
    error OnlyOrderOwner();
    error OrderNotActive();
    error OrderNotFound();
    error TriggerConditionsNotMet();
    error OrderExpired();
    error InvalidLeverage();
    error InvalidTriggerPrice();
    error ReentrantCall();

    modifier onlyOrderManager() {
        if (msg.sender != orderManager) revert OnlyOrderManager();
        _;
    }

    modifier nonReentrant() {
        if (_status == _ENTERED) revert ReentrantCall();
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    constructor(address _orderManager, address _positionManager) {
        orderManager = _orderManager;
        positionManager = _positionManager;
        _status = _NOT_ENTERED;
        nextOrderId = 1; // Start from 1 instead of 0
    }

    function createLimitOrder(
        address trader,
        string calldata countryId,
        uint8 direction,
        uint8 leverage,
        uint256 triggerPrice
    ) external payable onlyOrderManager returns (uint256) {
        // Input validation for order parameters
        if (leverage < 1 || leverage > 5) revert InvalidLeverage();
        if (triggerPrice == 0) revert InvalidTriggerPrice();

        // Calculate transaction fee and effective order size
        uint256 fee = (msg.value * TRANSACTION_FEE) / 10000;
        uint256 size = msg.value - fee;

        uint256 orderId = nextOrderId++;

        // Create and store the limit order
        orders[orderId] = LimitOrder({
            orderId: orderId,
            trader: trader,
            countryId: countryId,
            direction: PositionDirection(direction),
            size: size,
            leverage: leverage,
            triggerPrice: triggerPrice,
            executionFee: fee,
            createdAt: block.timestamp,
            expiresAt: block.timestamp + DEFAULT_EXPIRY,
            status: OrderStatus.PENDING
        });

        // Add order to indexing mappings for efficient queries
        marketOrders[countryId].push(orderId);
        userOrders[trader].push(orderId);

        emit LimitOrderCreated(orderId, trader, countryId, PositionDirection(direction), triggerPrice);

        return orderId;
    }

    function executeLimitOrder(uint256 orderId) external nonReentrant returns (uint256) {
        LimitOrder storage order = orders[orderId];

        // Validate order exists and is executable
        if (order.trader == address(0)) revert OrderNotFound();
        if (order.status != OrderStatus.PENDING) revert OrderNotActive();
        if (block.timestamp > order.expiresAt) revert OrderExpired();

        // Get current market price for trigger evaluation
        uint256 currentPrice = _getCurrentPrice(order.countryId);

        // Check if trigger conditions are satisfied
        if (!_shouldExecute(order, currentPrice)) {
            revert TriggerConditionsNotMet();
        }

        // Mark order as executed
        order.status = OrderStatus.EXECUTED;

        // Create trading position through PositionManager
        (bool success, bytes memory data) = positionManager.call{value: order.size}(
            abi.encodeWithSignature(
                "createPosition(address,string,uint8,uint256,uint8,uint256)",
                order.trader,
                order.countryId,
                uint8(order.direction),
                order.size,
                order.leverage,
                currentPrice
            )
        );

        require(success, "Position creation failed");
        uint256 positionId = abi.decode(data, (uint256));

        emit LimitOrderExecuted(orderId, order.trader, currentPrice, positionId);

        // Transfer execution fee to the order executor as incentive
        if (order.executionFee > 0) {
            (bool feeSuccess,) = payable(msg.sender).call{value: order.executionFee}("");
            require(feeSuccess, "Fee transfer failed");
        }

        return positionId;
    }

    function cancelLimitOrder(uint256 orderId) external nonReentrant {
        LimitOrder storage order = orders[orderId];

        if (order.trader == address(0)) revert OrderNotFound(); // Check trader instead of orderId
        if (order.trader != msg.sender) revert OnlyOrderOwner();
        if (order.status != OrderStatus.PENDING) revert OrderNotActive();

        order.status = OrderStatus.CANCELLED;

        // Refund full amount including fees to the trader
        uint256 refundAmount = order.size + order.executionFee;
        (bool success,) = payable(order.trader).call{value: refundAmount}("");
        require(success, "Refund failed");

        emit LimitOrderCancelled(orderId, order.trader);
    }

    function _shouldExecute(LimitOrder memory order, uint256 currentPrice) internal pure returns (bool) {
        if (order.direction == PositionDirection.LONG) {
            // Long: Execute when price drops to or below trigger (buy low)
            return currentPrice <= order.triggerPrice;
        } else {
            // Short: Execute when price rises to or above trigger (sell high)
            return currentPrice >= order.triggerPrice;
        }
    }

    function _getCurrentPrice(string memory countryId) internal pure returns (uint256) {
        // Placeholder implementation - should be replaced with oracle integration
        return uint256(keccak256(abi.encodePacked(countryId))) % 100000 + 50000;
    }

    function getLimitOrder(uint256 orderId) external view returns (LimitOrder memory) {
        return orders[orderId];
    }

    function getUserOrders(address trader) external view returns (uint256[] memory) {
        return userOrders[trader];
    }

    function getMarketOrders(string calldata countryId) external view returns (uint256[] memory) {
        return marketOrders[countryId];
    }
}
