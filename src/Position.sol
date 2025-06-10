// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import {console} from "forge-std/console.sol";

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
        uint256 takeProfit;
        uint256 stopLoss;
        bool isOpen;
        uint256 liquidationPrice;
    }

    enum PositionDirection {
        LONG,
        SHORT
    }

    uint256 private nextPositionId;
    uint256 public CURRENT_PRICE = 120;
    uint256 public TRANSACTION_FEE = 30;
    uint256 public MAINTENANCE_MARGIN = 10; // 10% maintenance margin
    mapping(address => Position) public positions;
    mapping(address => uint256) public positionIdToPosition;

    event PositionOpened(
        uint256 indexed positionId,
        string countryId,
        address indexed trader,
        PositionDirection direction,
        uint256 size,
        uint256 entryPrice,
        uint256 liquidationPrice
    );

    event PositionClosed(
        uint256 indexed positionId,
        string countryId,
        address indexed trader,
        uint256 size,
        int256 pnl,
        bool liquidated,
        uint256 exitPrice
    );

    event TPSLSet(address sender, uint256 takeProfit, uint256 stopLoss);
    
    event LimitPositionOpened(
        uint256 indexed positionId,
        string countryId,
        address indexed trader,
        PositionDirection direction,
        uint256 size,
        uint8 leverage,
        uint256 entryPrice,
        uint256 liquidationPrice
    );

    error SizeShouldBeGreaterThanZero();
    error LeverageShouldBeBetweenOneAndFive();
    error PositionDoesNotExist();
    error NotTheOwner();
    error Liquidated();
    error PositionAlreadyExist();
    error InsufficientETH();

    function openPosition(
        string calldata countryId,
        PositionDirection direction,
        uint8 leverage
    ) external payable returns (address){
        if (msg.value == 0) revert SizeShouldBeGreaterThanZero();
        if (leverage < 1 || leverage > 5) revert LeverageShouldBeBetweenOneAndFive();

        uint256 positionId = positionIdToPosition[msg.sender];
        positionIdToPosition[msg.sender] = positionId++;
        positionId = positionIdToPosition[msg.sender];

        // Calculate fee from ETH sent
        uint256 fee = (msg.value * TRANSACTION_FEE) / 10000;
        uint256 size = msg.value - fee;
        
        positions[msg.sender] = Position({
            positionId: positionId,
            countryId: countryId,
            trader: msg.sender,
            direction: direction,
            size: size,
            leverage: leverage,
            entryPrice: 100,
            openTime: block.number,
            takeProfit: 0,
            stopLoss: 0,
            isOpen: true,
            liquidationPrice: 0
        });

        uint256 liquidation = calculateLiquidation(msg.sender);

        emit PositionOpened(
            positionId,
            countryId,
            msg.sender,
            direction,
            msg.value,
            100,
            liquidation
        );

        return msg.sender;
    }

    function limitOrder(string calldata countryId, uint8 leverage, uint256 _entryPrice, PositionDirection _direction) external payable {
        if (msg.value == 0) revert SizeShouldBeGreaterThanZero();
        if (leverage < 1 || leverage > 5) revert LeverageShouldBeBetweenOneAndFive();
        
        // Calculate fee from ETH sent
        uint256 fee = (msg.value * TRANSACTION_FEE) / 10000;
        uint256 size = msg.value - fee;

        uint256 positionId = positionIdToPosition[msg.sender];
        positionIdToPosition[msg.sender] = positionId++;
        positionId = positionIdToPosition[msg.sender];
        
        positions[msg.sender] = Position({
            positionId: positionId,
            countryId: countryId,
            trader: msg.sender,
            direction: _direction,
            size: size,
            leverage: leverage,
            entryPrice: _entryPrice,
            openTime: block.number,
            takeProfit: 0,
            stopLoss: 0,
            isOpen: false,
            liquidationPrice: 0
        });

        uint256 liquidation = calculateLiquidation(msg.sender);

        emit LimitPositionOpened(
            positionId,
            countryId,
            msg.sender,
            _direction,
            msg.value,
            leverage,
            _entryPrice,
            liquidation
        );
    }

    function executeLimitOrder(address _sender, uint256 positionId) external {
        Position storage position = positions[_sender];
        if (position.isOpen == true) revert PositionAlreadyExist();
        if (position.trader != _sender) revert NotTheOwner();

        // Logic to check if the limit order can be executed
        if (CURRENT_PRICE >= position.entryPrice) {
            position.isOpen = true;
            emit PositionOpened(
                positionId,
                position.countryId,
                _sender,
                position.direction,
                position.size,
                position.entryPrice,
                position.liquidationPrice
            );
        }
    }

    function closePosition(address sender) external {
        Position storage position = positions[sender];
        if (position.isOpen == false) revert PositionDoesNotExist();
        if (position.trader != msg.sender) revert NotTheOwner();

        // Store position data before closing for event emission
        uint256 positionId = position.positionId;
        uint256 size = position.size;
        uint256 exitPrice = CURRENT_PRICE;
        int256 pnl = 0;
        bool liquidated = false;

        // Close position first to prevent reentrancy
        position.isOpen = false;
        
        if (position.direction == PositionDirection.LONG) {
            // Logic for closing a long position
            if (CURRENT_PRICE > position.entryPrice) {
                // Calculate profit as percentage gain * position size * leverage
                uint256 percentageGain = ((CURRENT_PRICE - position.entryPrice) * 10000) / position.entryPrice; // in basis points
                uint256 profit = (position.size * percentageGain * position.leverage) / 10000;
                pnl = int256(profit); // Positive PnL for profit
                uint256 payout = position.size + profit;
                
                // Ensure contract has enough ETH to pay, fallback to original size if not
                if (address(this).balance >= payout) {
                    (bool success, ) = payable(msg.sender).call{value: payout}("");
                    require(success, "Transfer failed");
                } else {
                    // Fallback: return original position size if insufficient balance for profit
                    (bool success, ) = payable(msg.sender).call{value: position.size}("");
                    require(success, "Transfer failed");
                    pnl = 0; // No profit due to insufficient contract balance
                }
            } else {
                // Calculate loss as percentage loss * position size * leverage
                uint256 percentageLoss = ((position.entryPrice - CURRENT_PRICE) * 10000) / position.entryPrice; // in basis points
                uint256 loss = (position.size * percentageLoss * position.leverage) / 10000;
                
                if (loss >= position.size) {
                    liquidated = true;
                    pnl = -int256(position.size); // Total loss
                    // Don't transfer anything - total liquidation
                } else {
                    pnl = -int256(loss); // Negative PnL for loss
                    uint256 payout = position.size - loss;
                    (bool success, ) = payable(msg.sender).call{value: payout}("");
                    require(success, "Transfer failed");
                }
            }
        } else {
            // Logic for closing a short position
            if (CURRENT_PRICE > position.entryPrice) {
                // Calculate loss for short position when price goes up
                uint256 percentageLoss = ((CURRENT_PRICE - position.entryPrice) * 10000) / position.entryPrice; // in basis points
                uint256 loss = (position.size * percentageLoss * position.leverage) / 10000;
                
                if (loss >= position.size) {
                    liquidated = true;
                    pnl = -int256(position.size); // Total loss
                    // Don't transfer anything - total liquidation
                } else {
                    pnl = -int256(loss); // Negative PnL for loss
                    uint256 payout = position.size - loss;
                    (bool success, ) = payable(msg.sender).call{value: payout}("");
                    require(success, "Transfer failed");
                }
            } else {
                // Calculate profit for short position when price goes down
                uint256 percentageGain = ((position.entryPrice - CURRENT_PRICE) * 10000) / position.entryPrice; // in basis points
                uint256 profit = (position.size * percentageGain * position.leverage) / 10000;
                pnl = int256(profit); // Positive PnL for profit
                uint256 payout = position.size + profit;
                
                // Ensure contract has enough ETH to pay, fallback to original size if not
                if (address(this).balance >= payout) {
                    (bool success, ) = payable(msg.sender).call{value: payout}("");
                    require(success, "Transfer failed");
                } else {
                    // Fallback: return original position size if insufficient balance for profit
                    (bool success, ) = payable(msg.sender).call{value: position.size}("");
                    require(success, "Transfer failed");
                    pnl = 0; // No profit due to insufficient contract balance
                }
            }
        }
        
        emit PositionClosed(
            positionId,
            position.countryId,
            msg.sender,
            size,
            pnl,
            liquidated,
            exitPrice
        );
    }

    function setTPSL(
        uint256 takeProfit,
        uint256 stopLoss
    ) external {
        Position storage position = positions[msg.sender];
        require(position.isOpen, "Position closed");
        require(position.trader == msg.sender, "Not position owner");

        position.takeProfit = takeProfit;
        position.stopLoss = stopLoss;
        emit TPSLSet(msg.sender, takeProfit, stopLoss);
    }

    function getPosition() external view returns (Position memory) {
        return positions[msg.sender];
    }

    function calculateLiquidation(address _sender) public view returns (uint256) {
        // Logic to calculate liquidation price based on position details
        Position memory position = positions[_sender];
        if (position.isOpen == false) revert PositionDoesNotExist();
        if (position.trader != _sender) revert NotTheOwner();
        
        uint256 liquidationPrice;
        uint256 marginPercentage = (100 - MAINTENANCE_MARGIN); // 90% for 10% maintenance margin

        if(position.direction == PositionDirection.LONG) {
            // For long: liquidation when price drops by margin percentage / leverage
            liquidationPrice = (position.entryPrice * marginPercentage) / (100 * position.leverage);
        } else {
            // For short: liquidation when price rises by margin percentage / leverage  
            liquidationPrice = position.entryPrice + ((position.entryPrice * marginPercentage) / (100 * position.leverage));
        }
        return liquidationPrice;
    }
}
