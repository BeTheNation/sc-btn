// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PredictionMarket} from "../src/Position.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PredictionMarketTest is Test {
    PredictionMarket public predictionMarket;
    MockUSDC public mockUSDC;

    address trader = makeAddr("trader");

    function setUp() public {
        mockUSDC = new MockUSDC();
        predictionMarket = new PredictionMarket(address(mockUSDC));

        deal(address(mockUSDC), trader, 100e6);
        deal(address(mockUSDC), address(predictionMarket), 100e6);
    }

    function test_OpenPosition() public {
        vm.startPrank(trader);
        IERC20(mockUSDC).approve(address(predictionMarket), 100e6);
        //PredictionMarket.PositionDirection direction;
        //uint256 positionId = predictionMarket.openPosition{value: 1 ether}("USA", PredictionMarket.PositionDirection.LONG, 2, 1);
        address user = predictionMarket.openPosition("USA", PredictionMarket.PositionDirection.LONG, 2, 1);
        PredictionMarket.Position memory position = predictionMarket.getPosition();
        vm.stopPrank();
        //Position memory position = predictionMarket.getPosition(positionId);

        assertEq(position.countryId, "USA");
        assertEq(position.trader, trader);
        assertEq(uint8(position.direction), uint8(PredictionMarket.PositionDirection.LONG));
        assertEq(position.size, 1);
        assertEq(position.leverage, 2);
        assertEq(position.entryPrice, 100);
    }

    function test_ClosePosition() public {
        vm.startPrank(trader);
        IERC20(mockUSDC).approve(address(predictionMarket), 10e6);
        console.log("balance before open position: ", mockUSDC.balanceOf(trader));
        address user = predictionMarket.openPosition("USA", PredictionMarket.PositionDirection.LONG, 2, 10e6);
        console.log("balance after open position: ", mockUSDC.balanceOf(trader));
        predictionMarket.closePosition(user);
        console.log("balance after close position: ", mockUSDC.balanceOf(trader));
        vm.stopPrank();

        PredictionMarket.Position memory position = predictionMarket.getPosition();

        assertEq(position.isOpen, false);
    }
}
