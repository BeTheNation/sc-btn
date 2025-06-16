// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title PositionManager
 * @notice Manages trading positions and PnL calculations
 */
contract PositionManager {
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

    mapping(address => Position) public positions;
    mapping(uint256 => Position) public positionsById;
    uint256 public nextPositionId;
    mapping(address => bool) public authorizedCallers;
    address public owner;
    address public liquidationManager;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    event PositionOpened(
        uint256 indexed positionId,
        string countryId,
        address indexed trader,
        PositionDirection direction,
        uint256 size,
        uint256 entryPrice
    );

    event PositionClosed(
        uint256 indexed positionId,
        string countryId,
        address indexed trader,
        uint256 size,
        int256 pnl,
        uint256 exitPrice
    );

    error OnlyAuthorized();
    error OnlyOwner();
    error PositionAlreadyExist();
    error PositionDoesNotExist();
    error NotTheOwner();
    error InvalidPrice();
    error ReentrantCall();

    modifier onlyAuthorized() {
        if (!authorizedCallers[msg.sender]) revert OnlyAuthorized();
        _;
    }

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

    modifier onlyLiquidationManager() {
        require(msg.sender == liquidationManager, "Only liquidation manager");
        _;
    }

    constructor() {
        owner = msg.sender;
        authorizedCallers[msg.sender] = true;
        _status = _NOT_ENTERED;
        nextPositionId = 1;
    }

    function setAuthorizedCaller(address caller, bool authorized) external onlyOwner {
        authorizedCallers[caller] = authorized;
    }

    function setLiquidationManager(address _liquidationManager) external onlyOwner {
        liquidationManager = _liquidationManager;
    }

    function createPosition(
        address trader,
        string calldata countryId,
        uint8 direction,
        uint256 size,
        uint8 leverage,
        uint256 entryPrice
    ) external payable onlyAuthorized nonReentrant returns (uint256) {
        if (positions[trader].isOpen) revert PositionAlreadyExist();
        if (entryPrice == 0) revert InvalidPrice();

        uint256 positionId = nextPositionId++;

        positions[trader] = Position({
            positionId: positionId,
            countryId: countryId,
            trader: trader,
            direction: PositionDirection(direction),
            size: size,
            leverage: leverage,
            entryPrice: entryPrice,
            openTime: block.timestamp,
            isOpen: true
        });

        // Store in both mappings for easy access
        positionsById[positionId] = positions[trader];

        emit PositionOpened(positionId, countryId, trader, PositionDirection(direction), size, entryPrice);

        return positionId;
    }

    function closePosition(address trader, uint256 exitPrice, address /* caller */ )
        external
        onlyAuthorized
        nonReentrant
    {
        Position storage position = positions[trader];

        if (!position.isOpen) revert PositionDoesNotExist();
        if (exitPrice == 0) revert InvalidPrice();

        (int256 pnl, uint256 payout) = _calculatePnL(position, exitPrice);

        position.isOpen = false;

        emit PositionClosed(position.positionId, position.countryId, trader, position.size, pnl, exitPrice);

        if (payout > 0) {
            (bool success,) = payable(trader).call{value: payout}("");
            require(success, "Transfer failed");
        }
    }

    function closePosition(uint256 positionId, uint256 closingPrice, bool isLiquidation) external {
        Position storage position = positionsById[positionId];

        if (!position.isOpen) revert PositionDoesNotExist();

        if (isLiquidation) {
            require(msg.sender == liquidationManager, "Only liquidation manager for liquidations");
        } else {
            require(msg.sender == position.trader, "Only position owner");
        }

        if (closingPrice == 0) revert InvalidPrice();

        (int256 pnl, uint256 payout) = _calculatePnL(position, closingPrice);

        position.isOpen = false;
        positions[position.trader].isOpen = false; // Update both mappings

        emit PositionClosed(position.positionId, position.countryId, position.trader, position.size, pnl, closingPrice);

        if (payout > 0) {
            (bool success,) = payable(position.trader).call{value: payout}("");
            require(success, "Transfer failed");
        }
    }

    function _calculatePnL(Position memory position, uint256 exitPrice)
        internal
        view
        returns (int256 pnl, uint256 payout)
    {
        if (position.direction == PositionDirection.LONG) {
            if (exitPrice > position.entryPrice) {
                uint256 percentageGain = ((exitPrice - position.entryPrice) * 10000) / position.entryPrice;
                uint256 profit = (position.size * percentageGain * position.leverage) / 10000;
                pnl = int256(profit);
                uint256 totalPayout = position.size + profit;

                if (address(this).balance >= totalPayout) {
                    payout = totalPayout;
                } else {
                    payout = position.size;
                    pnl = 0;
                }
            } else {
                uint256 percentageLoss = ((position.entryPrice - exitPrice) * 10000) / position.entryPrice;
                uint256 loss = (position.size * percentageLoss * position.leverage) / 10000;

                if (loss >= position.size) {
                    pnl = -int256(position.size);
                    payout = 0;
                } else {
                    pnl = -int256(loss);
                    payout = position.size - loss;
                }
            }
        } else {
            if (exitPrice > position.entryPrice) {
                uint256 percentageLoss = ((exitPrice - position.entryPrice) * 10000) / position.entryPrice;
                uint256 loss = (position.size * percentageLoss * position.leverage) / 10000;

                if (loss >= position.size) {
                    pnl = -int256(position.size);
                    payout = 0;
                } else {
                    pnl = -int256(loss);
                    payout = position.size - loss;
                }
            } else {
                uint256 percentageGain = ((position.entryPrice - exitPrice) * 10000) / position.entryPrice;
                uint256 profit = (position.size * percentageGain * position.leverage) / 10000;
                pnl = int256(profit);
                uint256 totalPayout = position.size + profit;

                if (address(this).balance >= totalPayout) {
                    payout = totalPayout;
                } else {
                    payout = position.size;
                    pnl = 0;
                }
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
        Position memory position = positions[trader];
        return (
            position.positionId,
            position.countryId,
            position.direction,
            position.size,
            position.leverage,
            position.entryPrice,
            position.openTime,
            position.isOpen
        );
    }

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
        )
    {
        Position memory position = positionsById[positionId];
        return (
            position.trader,
            position.countryId,
            uint8(position.direction),
            position.size,
            position.leverage,
            position.entryPrice,
            position.openTime,
            position.isOpen
        );
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        owner = newOwner;
    }

    receive() external payable {}
}
