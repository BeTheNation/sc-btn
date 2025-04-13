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
        uint256 positionId = predictionMarket.openPosition{value: 1 ether}("USA", true, 2);
        //Position memory position = predictionMarket.getPosition(positionId);
        PredictionMarket.Position memory position = predictionMarket.getPosition(positionId);

        assertEq(position.countryId, "USA");
        assertEq(position.trader, address(this));
        assertEq(position.direction, true);
        assertEq(position.size, 1 ether);
        assertEq(position.leverage, 2);
        assertEq(position.entryPrice, 100);
    }
}
