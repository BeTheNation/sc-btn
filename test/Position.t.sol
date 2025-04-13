// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PredictionMarket} from "../src/Position.sol";

contract PredictionMarketTest is Test {
    PredictionMarket public predictionMarket;

    function setUp() public {
        predictionMarket = new PredictionMarket();
    }

    function test_OpenPosition() public {
        //PredictionMarket.PositionDirection direction;
        uint256 positionId = predictionMarket.openPosition{value: 1 ether}("USA", PredictionMarket.PositionDirection.LONG, 2, 1);
        //Position memory position = predictionMarket.getPosition(positionId);
        PredictionMarket.Position memory position = predictionMarket.getPosition(positionId);

        assertEq(position.countryId, "USA");
        assertEq(position.trader, address(this));
        assertEq(uint8(position.direction), uint8(PredictionMarket.PositionDirection.LONG));
        assertEq(position.size, 1);
        assertEq(position.leverage, 2);
        assertEq(position.entryPrice, 100);
    }
}
