// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockUSDC} from "./mocks/MockUSDC.sol";

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
    }

    enum PositionDirection {
        LONG,
        SHORT
    }

    address usdc;
    uint256 private nextPositionId;
    uint256 public CURRENT_PRICE = 120;
    uint256 public TRANSACTION_FEE = 30;
    mapping(address => Position) public positions;

    event PositionOpened(
        uint256 indexed positionId,
        string countryId,
        address indexed trader,
        PositionDirection direction,
        uint256 size,
        uint8 leverage,
        uint256 entryPrice
    );

    event PositionClosed(uint256 indexed positionId);
    event TPSLSet(uint256 indexed positionId, uint256 takeProfit, uint256 stopLoss);
    event LimitPositionOpened(
        uint256 indexed positionId,
        string countryId,
        address indexed trader,
        PositionDirection direction,
        uint256 size,
        uint8 leverage,
        uint256 entryPrice
    );

    error SizeShouldBeGreaterThanZero();
    error LeverageShouldBeBetweenOneAndFive();
    error PositionDoesNotExist();
    error NotTheOwner();
    error Liquidated();
    error PositionAlreadyExist();

    constructor(address _usdc) {
        usdc = _usdc;
    }

    function openPosition(
        string calldata countryId,
        PositionDirection direction,
        uint8 leverage,
        uint256 size
    ) external payable {
        if (size == 0) revert SizeShouldBeGreaterThanZero();
        if (leverage < 1 || leverage > 5) revert LeverageShouldBeBetweenOneAndFive();

        IERC20(usdc).transferFrom(msg.sender, address(this), size);

        // Transfer fee
        uint256 fee = (size * TRANSACTION_FEE) / 10000;
        
        //uint256 positionId = nextPositionId++;
        positions[msg.sender] = Position({
            positionId: positionId,
            countryId: countryId,
            trader: msg.sender,
            direction: direction,
            size: size - fee,
            leverage: leverage,
            entryPrice: 100,
            openTime: block.number,
            takeProfit: 0,
            stopLoss: 0,
            isOpen: true
        });

        emit PositionOpened(
            positionId,
            countryId,
            msg.sender,
            direction,
            size,
            leverage,
            100
        );
    }

    function limitOrder(uint256 size, uint256 leverage, uint256 _entryPrice) external {
        if (size == 0) revert SizeShouldBeGreaterThanZero();
        if (leverage < 1 || leverage > 5) revert LeverageShouldBeBetweenOneAndFive();
        IERC20(usdc).transferFrom(msg.sender, address(this), size);

        // Transfer fee
        uint256 fee = (size * TRANSACTION_FEE) / 10000;
        
        //uint256 positionId = nextPositionId++;
        positions[msg.sender] = Position({
            positionId: positionId,
            countryId: countryId,
            trader: msg.sender,
            direction: direction,
            size: size - fee,
            leverage: leverage,
            entryPrice: _entryPrice,
            openTime: block.number,
            takeProfit: 0,
            stopLoss: 0,
            isOpen: false
        });

        emit LimitPositionOpened(
            positionId,
            countryId,
            msg.sender,
            direction,
            size,
            leverage,
            entryPrice
        );
    }

    function executeLimitOrder(address _sender) external {
        Position storage position = positions[_sender];
        if (position.isOpen == false) revert PositionAlreadyExist();
        if (position.trader != msg.sender) revert NotTheOwner();

        // Logic to check if the limit order can be executed
        if (CURRENT_PRICE >= position.entryPrice) {
            position.isOpen = true;
            emit PositionOpened(
                positionId,
                position.countryId,
                msg.sender,
                position.direction,
                position.size,
                position.leverage,
                position.entryPrice
            );
        }
    }

    function closePosition() external {
        Position storage position = positions[msg.sender];
        if (position.isOpen == false) revert PositionDoesNotExist();
        if (position.trader != msg.sender) revert NotTheOwner();

        position.isOpen = false;
        if (position.direction == PositionDirection.LONG) {
            // Logic for closing a long position
            // For simplicity, we assume the price is 100 when closing
            if (CURRENT_PRICE > position.entryPrice) {
                uint256 profit = (CURRENT_PRICE - position.entryPrice) * position.size * position.leverage / position.entryPrice;
                //payable(msg.sender).transfer(profit + position.size);
                IERC20(usdc).transfer(msg.sender, profit + position.size);
            } else {
                uint256 loss = (position.entryPrice - CURRENT_PRICE) * position.size * position.leverage / position.entryPrice;
                if (position.size  >= loss) revert Liquidated();
                //payable(msg.sender).transfer(position.size - loss);
                IERC20(usdc).transfer(msg.sender, position.size - loss);
            }
        } else {
            // Logic for closing a short position
            // For simplicity, we assume the price is 100 when closing
            if (CURRENT_PRICE > position.entryPrice) {
                uint256 loss = (CURRENT_PRICE - position.entryPrice) * position.size * position.leverage / position.entryPrice;
                if (position.size >= loss) revert Liquidated();
                IERC20(usdc).transfer(msg.sender, position.size - loss);
            } else {
                uint256 profit = (position.entryPrice - CURRENT_PRICE) * position.size * position.leverage / position.entryPrice;
                IERC20(usdc).transfer(msg.sender, profit + position.size);
            }
        }
        
        emit PositionClosed(positionId);
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
        emit TPSLSet(positionId, takeProfit, stopLoss);
    }

    function getPosition(uint256 positionId) external view returns (Position memory) {
        return positions[positionId];
    }

    function calculateLiquidation() external view returns (uint256) {
        // Logic to calculate liquidation price based on position details
        return 0; // Placeholder
    }
}
