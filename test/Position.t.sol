// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PredictionMarket} from "../src/Position.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract SimplifiedPositionTest is Test {
    PredictionMarket public predictionMarket;

    address trader1 = makeAddr("trader1");
    address trader2 = makeAddr("trader2");

    function setUp() public {
        PredictionMarket implementation = new PredictionMarket();

        ERC1967Proxy proxy =
            new ERC1967Proxy(address(implementation), abi.encodeWithSelector(PredictionMarket.initialize.selector));

        predictionMarket = PredictionMarket(address(proxy));

        vm.deal(trader1, 100 ether);
        vm.deal(trader2, 100 ether);
        vm.deal(address(predictionMarket), 50 ether);
    }

    function test_OpenAndClosePositions() public {
        vm.startPrank(trader1);
        uint256 positionId1 = uint256(keccak256(abi.encodePacked(trader1, block.timestamp, "LONG")));
        predictionMarket.openPosition{value: 1 ether}(
            "USA", PredictionMarket.PositionDirection.LONG, 3, positionId1, 100
        );

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

        vm.startPrank(trader2);
        uint256 positionId2 = uint256(keccak256(abi.encodePacked(trader2, block.timestamp, "SHORT")));
        predictionMarket.openPosition{value: 0.5 ether}(
            "GERMANY", PredictionMarket.PositionDirection.SHORT, 2, positionId2, 110
        );

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

        uint256 positionId = uint256(keccak256(abi.encodePacked(trader1, block.timestamp, "TEST")));

        vm.expectRevert(PredictionMarket.SizeShouldBeGreaterThanZero.selector);
        predictionMarket.openPosition{value: 0}("USA", PredictionMarket.PositionDirection.LONG, 1, positionId, 100);

        vm.expectRevert(PredictionMarket.LeverageShouldBeBetweenOneAndFive.selector);
        predictionMarket.openPosition{value: 1 ether}(
            "USA", PredictionMarket.PositionDirection.LONG, 0, positionId, 100
        );

        vm.expectRevert(PredictionMarket.LeverageShouldBeBetweenOneAndFive.selector);
        predictionMarket.openPosition{value: 1 ether}(
            "USA", PredictionMarket.PositionDirection.LONG, 6, positionId, 100
        );

        vm.expectRevert(PredictionMarket.PositionDoesNotExist.selector);
        predictionMarket.closePosition(trader1);

        vm.stopPrank();
    }

    function test_LiquidationAndPriceUpdate() public {
        predictionMarket.setCurrentPrice(150);
        assertEq(predictionMarket.CURRENT_PRICE(), 150);

        vm.startPrank(trader1);
        uint256 positionId = uint256(keccak256(abi.encodePacked(trader1, block.timestamp, "LIQUIDATION")));
        predictionMarket.openPosition{value: 1 ether}(
            "USA", PredictionMarket.PositionDirection.LONG, 5, positionId, 100
        );
        vm.stopPrank();

        assertEq(predictionMarket.checkLiquidation(trader1), false);

        predictionMarket.setCurrentPrice(84);

        assertEq(predictionMarket.checkLiquidation(trader1), true);

        predictionMarket.liquidate(trader1);

        vm.startPrank(trader1);
        PredictionMarket.Position memory liquidatedPos = predictionMarket.getPosition();
        assertEq(liquidatedPos.isOpen, false);
        vm.stopPrank();
    }
}
