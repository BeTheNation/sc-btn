// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title MarketOrderExecutor
 * @notice Executes market orders with immediate execution
 */
contract MarketOrderExecutor {
    enum PositionDirection {
        LONG,
        SHORT
    }

    address public immutable orderManager;
    address public immutable positionManager;

    uint256 public constant TRANSACTION_FEE = 30;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    error OnlyOrderManager();
    error InvalidLeverage();
    error InvalidPrice();
    error ReentrantCall();

    event MarketOrderExecuted(
        address indexed trader,
        uint256 indexed positionId,
        string countryId,
        PositionDirection direction,
        uint256 size,
        uint256 executionPrice
    );

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
    }

    function executeMarketOrder(address trader, string calldata countryId, uint8 direction, uint8 leverage)
        external
        payable
        onlyOrderManager
        nonReentrant
        returns (uint256)
    {
        if (leverage < 1 || leverage > 5) revert InvalidLeverage();

        uint256 currentPrice = _getCurrentPrice(countryId);
        if (currentPrice == 0) revert InvalidPrice();

        uint256 fee = (msg.value * TRANSACTION_FEE) / 10000;
        uint256 size = msg.value - fee;

        (bool success, bytes memory data) = positionManager.call{value: size}(
            abi.encodeWithSignature(
                "createPosition(address,string,uint8,uint256,uint8,uint256)",
                trader,
                countryId,
                direction,
                size,
                leverage,
                currentPrice
            )
        );

        if (!success) {
            assembly {
                revert(add(data, 0x20), mload(data))
            }
        }
        uint256 positionId = abi.decode(data, (uint256));

        emit MarketOrderExecuted(trader, positionId, countryId, PositionDirection(direction), size, currentPrice);

        return positionId;
    }

    function _getCurrentPrice(string calldata countryId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(countryId))) % 100000 + 50000;
    }
}
