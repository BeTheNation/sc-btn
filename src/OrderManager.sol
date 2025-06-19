// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title OrderManager
 * @notice Main router for prediction market orders
 */
contract OrderManager {
    enum OrderType {
        MARKET,
        LIMIT
    }
    enum PositionDirection {
        LONG,
        SHORT
    }

    address public owner;
    address public marketOrderExecutor;
    address public limitOrderManager;
    address public positionManager;
    address public priceOracle;

    uint256 public constant TRANSACTION_FEE = 30;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    event OrderRouted(address indexed trader, OrderType indexed orderType, string countryId, uint256 amount);

    event ContractUpdated(string indexed contractType, address indexed newAddress);

    error InvalidAmount();
    error InvalidContract();
    error ContractNotSet();
    error OnlyOwner();
    error ReentrantCall();

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier nonReentrant() {
        if (_status == _ENTERED) revert ReentrantCall();
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    constructor() {
        owner = msg.sender;
        _status = _NOT_ENTERED;
    }

    function setMarketOrderExecutor(address _marketOrderExecutor) external onlyOwner {
        if (_marketOrderExecutor == address(0)) revert InvalidContract();
        marketOrderExecutor = _marketOrderExecutor;
        emit ContractUpdated("MarketOrderExecutor", _marketOrderExecutor);
    }

    function setLimitOrderManager(address _limitOrderManager) external onlyOwner {
        if (_limitOrderManager == address(0)) revert InvalidContract();
        limitOrderManager = _limitOrderManager;
        emit ContractUpdated("LimitOrderManager", _limitOrderManager);
    }

    function setPositionManager(address _positionManager) external onlyOwner {
        if (_positionManager == address(0)) revert InvalidContract();
        positionManager = _positionManager;
        emit ContractUpdated("PositionManager", _positionManager);
    }

    function createMarketOrder(string calldata countryId, PositionDirection direction, uint8 leverage)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        if (msg.value == 0) revert InvalidAmount();
        if (marketOrderExecutor == address(0)) revert ContractNotSet();

        emit OrderRouted(msg.sender, OrderType.MARKET, countryId, msg.value);

        (bool success, bytes memory data) = marketOrderExecutor.call{value: msg.value}(
            abi.encodeWithSignature(
                "executeMarketOrder(address,string,uint8,uint8)", msg.sender, countryId, uint8(direction), leverage
            )
        );

        if (!success) {
            assembly {
                revert(add(data, 0x20), mload(data))
            }
        }
        return abi.decode(data, (uint256));
    }

    function createLimitOrder(
        string calldata countryId,
        PositionDirection direction,
        uint8 leverage,
        uint256 triggerPrice
    ) external payable nonReentrant returns (uint256) {
        if (msg.value == 0) revert InvalidAmount();
        if (limitOrderManager == address(0)) revert ContractNotSet();

        emit OrderRouted(msg.sender, OrderType.LIMIT, countryId, msg.value);

        (bool success, bytes memory data) = limitOrderManager.call{value: msg.value}(
            abi.encodeWithSignature(
                "createLimitOrder(address,string,uint8,uint8,uint256)",
                msg.sender,
                countryId,
                uint8(direction),
                leverage,
                triggerPrice
            )
        );

        require(success, "Limit order creation failed");
        return abi.decode(data, (uint256));
    }

    function closePosition(address trader, uint256 exitPrice) external nonReentrant {
        if (positionManager == address(0)) revert ContractNotSet();

        (bool success, bytes memory data) = positionManager.call(
            abi.encodeWithSignature("closePosition(address,uint256,address)", trader, exitPrice, msg.sender)
        );

        if (!success) {
            assembly {
                revert(add(data, 0x20), mload(data))
            }
        }
    }

    function closePositionById(uint256 positionId, uint256 exitPrice) external nonReentrant {
        if (positionManager == address(0)) revert ContractNotSet();

        (bool success, bytes memory data) = positionManager.call(
            abi.encodeWithSignature("closePositionById(uint256,uint256,bool)", positionId, exitPrice, false)
        );

        if (!success) {
            assembly {
                revert(add(data, 0x20), mload(data))
            }
        }
    }

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
        )
    {
        if (positionManager == address(0)) revert ContractNotSet();

        (bool success, bytes memory data) =
            positionManager.staticcall(abi.encodeWithSignature("getPosition(address)", trader));

        require(success, "Failed to get position");
        return abi.decode(data, (uint256, string, PositionDirection, uint256, uint8, uint256, uint256, bool));
    }

    function getTraderPositions(address trader)
        external
        view
        returns (uint256[] memory positionIds, bytes memory positionsData)
    {
        if (positionManager == address(0)) revert ContractNotSet();

        (bool success, bytes memory data) =
            positionManager.staticcall(abi.encodeWithSignature("getTraderPositions(address)", trader));

        require(success, "Failed to get trader positions");
        (uint256[] memory ids,) = abi.decode(data, (uint256[], bytes));
        return (ids, data);
    }

    function getOpenPositionsCount(address trader) external view returns (uint256) {
        if (positionManager == address(0)) revert ContractNotSet();

        (bool success, bytes memory data) =
            positionManager.staticcall(abi.encodeWithSignature("getOpenPositionsCount(address)", trader));

        require(success, "Failed to get open positions count");
        return abi.decode(data, (uint256));
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        owner = newOwner;
    }

    receive() external payable {}
}
