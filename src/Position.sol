// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PredictionMarket {
    struct Position {
        uint256 positionId;
        string countryId;
        address trader;
        bool direction;
        uint256 size;
        uint8 leverage;
        uint256 entryPrice;
        uint256 openTime;
        uint256 takeProfit;
        uint256 stopLoss;
        bool isOpen;
    }

    uint256 private nextPositionId;
    mapping(uint256 => Position) public positions;

    event PositionOpened(
        uint256 indexed positionId,
        string countryId,
        address indexed trader,
        bool direction,
        uint256 size,
        uint8 leverage,
        uint256 entryPrice
    );

    event PositionClosed(uint256 indexed positionId);
    event TPSLSet(uint256 indexed positionId, uint256 takeProfit, uint256 stopLoss);

    function openPosition(
        string calldata countryId,
        bool direction,
        uint8 leverage
    ) external payable returns (uint256) {
        require(msg.value > 0, "Margin amount must be greater than 0");
        require(leverage >= 1 && leverage <= 5, "Leverage must be between 1-5x");

        
        uint256 positionId = nextPositionId++;
        positions[positionId] = Position({
            positionId: positionId,
            countryId: countryId,
            trader: msg.sender,
            direction: direction,
            size: msg.value,
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
            msg.value,
            leverage,
            100
        );

        return positionId;
    }

    function closePosition(uint256 positionId) external {
        Position storage position = positions[positionId];
        require(position.isOpen, "Position already closed");
        require(position.trader == msg.sender, "Not the position owner");

        position.isOpen = false;
        payable(msg.sender).transfer(position.size);
        
        emit PositionClosed(positionId);
    }

    function setTPSL(
        uint256 positionId,
        uint256 takeProfit,
        uint256 stopLoss
    ) external {
        Position storage position = positions[positionId];
        require(position.isOpen, "Position closed");
        require(position.trader == msg.sender, "Not position owner");

        position.takeProfit = takeProfit;
        position.stopLoss = stopLoss;
        emit TPSLSet(positionId, takeProfit, stopLoss);
    }

    function getPosition(uint256 positionId) external view returns (Position memory) {
        return positions[positionId];
    }
}
