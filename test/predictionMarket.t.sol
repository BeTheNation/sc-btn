// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PredictionMarket} from "../src/predictionMarket.sol";

contract SimplifiedPositionTest is Test {
    PredictionMarket public predictionMarket;

    address trader1 = makeAddr("trader1");
    address trader2 = makeAddr("trader2");

    function setUp() public {
        predictionMarket = new PredictionMarket();
        vm.deal(trader1, 100 ether);
        vm.deal(trader2, 100 ether);
        vm.deal(address(predictionMarket), 50 ether);
    }

    function test_OpenAndClosePositions() public {
        // Test LONG position
        vm.startPrank(trader1);
        predictionMarket.openPosition{value: 1 ether}("USA", PredictionMarket.PositionDirection.LONG, 3);

        PredictionMarket.Position memory pos1 = predictionMarket.getPosition();
        assertEq(pos1.trader, trader1);
        assertEq(pos1.countryId, "USA");
        assertEq(uint256(pos1.direction), uint256(PredictionMarket.PositionDirection.LONG));
        assertEq(pos1.leverage, 3);
        assertEq(pos1.isOpen, true);

        predictionMarket.closePosition(trader1);

        PredictionMarket.Position memory closedPos1 = predictionMarket.getPosition();
        assertEq(closedPos1.isOpen, false);
        vm.stopPrank();

        // Test SHORT position
        vm.startPrank(trader2);
        predictionMarket.openPosition{value: 0.5 ether}("GERMANY", PredictionMarket.PositionDirection.SHORT, 2);

        PredictionMarket.Position memory pos2 = predictionMarket.getPosition();
        assertEq(pos2.trader, trader2);
        assertEq(pos2.countryId, "GERMANY");
        assertEq(uint256(pos2.direction), uint256(PredictionMarket.PositionDirection.SHORT));
        assertEq(pos2.leverage, 2);

        predictionMarket.closePosition(trader2);
        vm.stopPrank();
    }

    function test_ErrorCases() public {
        vm.startPrank(trader1);

        vm.expectRevert(PredictionMarket.SizeShouldBeGreaterThanZero.selector);
        predictionMarket.openPosition{value: 0}("USA", PredictionMarket.PositionDirection.LONG, 1);

        vm.expectRevert(PredictionMarket.LeverageShouldBeBetweenOneAndFive.selector);
        predictionMarket.openPosition{value: 1 ether}("USA", PredictionMarket.PositionDirection.LONG, 0);

        vm.expectRevert(PredictionMarket.LeverageShouldBeBetweenOneAndFive.selector);
        predictionMarket.openPosition{value: 1 ether}("USA", PredictionMarket.PositionDirection.LONG, 6);

        vm.expectRevert(PredictionMarket.PositionDoesNotExist.selector);
        predictionMarket.closePosition(trader1);

        vm.stopPrank();
    }
}