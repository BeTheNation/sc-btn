// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract PredictionMarket is Initializable, ReentrancyGuardUpgradeable, UUPSUpgradeable, OwnableUpgradeable {
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
    uint256 public CURRENT_PRICE;
    uint256 public TRANSACTION_FEE;
    uint256 public constant LIQUIDATION_THRESHOLD = 8000;
    mapping(address => Position) public positions;
    mapping(address => uint256) public positionIdToPosition;

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
    error PositionNotLiquidatable();
    error InvalidPositionId();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        __Ownable_init(msg.sender);
        CURRENT_PRICE = 120;
        TRANSACTION_FEE = 30;
    }

    function setCurrentPrice(uint256 newPrice) external {
        CURRENT_PRICE = newPrice;
    }

    function openPosition(
        string calldata countryId,
        PositionDirection direction,
        uint8 leverage,
        uint256 positionId,
        uint256 entryPrice
    ) external payable returns (address) {
        if (msg.value == 0) revert SizeShouldBeGreaterThanZero();
        if (leverage < 1 || leverage > 5) revert LeverageShouldBeBetweenOneAndFive();
        if (positions[msg.sender].isOpen) revert PositionAlreadyExist();

        positionIdToPosition[msg.sender] = positionId;

        uint256 fee = (msg.value * TRANSACTION_FEE) / 10000;
        uint256 size = msg.value - fee;

        positions[msg.sender] = Position({
            positionId: positionId,
            countryId: countryId,
            trader: msg.sender,
            direction: direction,
            size: size,
            leverage: leverage,
            entryPrice: entryPrice,
            openTime: block.number,
            isOpen: true
        });

        emit PositionOpened(positionId, countryId, msg.sender, direction, msg.value, entryPrice);

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

        if (position.direction == PositionDirection.LONG) {
            if (CURRENT_PRICE > position.entryPrice) {
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
            if (CURRENT_PRICE > position.entryPrice) {
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

        if (payout > 0) {
            (bool success,) = payable(msg.sender).call{value: payout}("");
            require(success, "Transfer failed");
        }
    }

    function getPosition() external view returns (Position memory) {
        return positions[msg.sender];
    }

    function checkLiquidation(address user) external view returns (bool) {
        Position memory position = positions[user];
        if (!position.isOpen) return false;

        uint256 percentageLoss;

        if (position.direction == PositionDirection.LONG) {
            if (CURRENT_PRICE >= position.entryPrice) return false;
            percentageLoss = ((position.entryPrice - CURRENT_PRICE) * 10000) / position.entryPrice;
        } else {
            if (CURRENT_PRICE <= position.entryPrice) return false;
            percentageLoss = ((CURRENT_PRICE - position.entryPrice) * 10000) / position.entryPrice;
        }

        uint256 leveragedLoss = percentageLoss * position.leverage;
        return leveragedLoss >= LIQUIDATION_THRESHOLD;
    }

    function liquidate(address user) external nonReentrant {
        Position storage position = positions[user];
        if (!position.isOpen) revert PositionDoesNotExist();
        if (!this.checkLiquidation(user)) revert PositionNotLiquidatable();

        uint256 positionId = position.positionId;
        string memory countryId = position.countryId;
        uint256 size = position.size;
        uint256 exitPrice = CURRENT_PRICE;

        position.isOpen = false;

        int256 pnl = -int256(position.size);

        emit PositionClosed(positionId, countryId, user, size, pnl, exitPrice);
    }

    // Required by UUPSUpgradeable - only owner can authorize upgrades
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
