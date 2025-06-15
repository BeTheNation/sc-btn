// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PredictionMarket {
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

    enum PositionDirection {
        LONG,
        SHORT
    }

    uint256 private nextPositionId;
    uint256 public CURRENT_PRICE = 120;
    uint256 public TRANSACTION_FEE = 30;
    mapping(address => Position) public positions;
    mapping(address => uint256) public positionIdToPosition;

    // Reentrancy guard
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

    error SizeShouldBeGreaterThanZero();
    error LeverageShouldBeBetweenOneAndFive();
    error PositionDoesNotExist();
    error NotTheOwner();
    error PositionAlreadyExist();
    error InsufficientETH();

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    function openPosition(string calldata countryId, PositionDirection direction, uint8 leverage)
        external
        payable
        returns (address)
    {
        if (msg.value == 0) revert SizeShouldBeGreaterThanZero();
        if (leverage < 1 || leverage > 5) revert LeverageShouldBeBetweenOneAndFive();

        uint256 positionId = positionIdToPosition[msg.sender];
        positionIdToPosition[msg.sender] = positionId++;
        positionId = positionIdToPosition[msg.sender];

        uint256 fee = (msg.value * TRANSACTION_FEE) / 10000;
        uint256 size = msg.value - fee;

        // Create new position
        positions[msg.sender] = Position({
            positionId: positionId,
            countryId: countryId,
            trader: msg.sender,
            direction: direction,
            size: size,
            leverage: leverage,
            entryPrice: 100,
            openTime: block.number,
            isOpen: true
        });

        emit PositionOpened(positionId, countryId, msg.sender, direction, msg.value, 100);

        return msg.sender;
    }

    function closePosition(address sender) external nonReentrant {
        Position storage position = positions[sender];
        if (position.isOpen == false) revert PositionDoesNotExist();
        if (position.trader != msg.sender) revert NotTheOwner();

        uint256 positionId = position.positionId;
        string memory countryId = position.countryId;
        uint256 size = position.size;
        uint256 exitPrice = CURRENT_PRICE;
        int256 pnl = 0;
        uint256 payout = 0;

        position.isOpen = false;

        // Calculate PnL and payout
        if (position.direction == PositionDirection.LONG) {
            // Long position logic
            if (CURRENT_PRICE > position.entryPrice) {
                // Profit for long
                uint256 percentageGain = ((CURRENT_PRICE - position.entryPrice) * 10000) / position.entryPrice;
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
                // Loss for long
                uint256 percentageLoss = ((position.entryPrice - CURRENT_PRICE) * 10000) / position.entryPrice;
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
            // Short position logic
            if (CURRENT_PRICE > position.entryPrice) {
                // Loss for short
                uint256 percentageLoss = ((CURRENT_PRICE - position.entryPrice) * 10000) / position.entryPrice;
                uint256 loss = (position.size * percentageLoss * position.leverage) / 10000;

                if (loss >= position.size) {
                    pnl = -int256(position.size);
                    payout = 0;
                } else {
                    pnl = -int256(loss);
                    payout = position.size - loss;
                }
            } else {
                // Profit for short
                uint256 percentageGain = ((position.entryPrice - CURRENT_PRICE) * 10000) / position.entryPrice;
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

        emit PositionClosed(positionId, countryId, msg.sender, size, pnl, exitPrice);

        // Transfer payout
        if (payout > 0) {
            (bool success,) = payable(msg.sender).call{value: payout}("");
            require(success, "Transfer failed");
        }
    }

    function getPosition() external view returns (Position memory) {
        return positions[msg.sender];
    }
}