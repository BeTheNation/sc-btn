// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PredictionMarket} from "../src/Position.sol";

contract PredictionMarketTest is Test {
    PredictionMarket public predictionMarket;

    address trader = makeAddr("trader");

    function setUp() public {
        predictionMarket = new PredictionMarket();
        // Give trader some ETH for testing
        vm.deal(trader, 100 ether);
        // Give contract some ETH for payouts
        vm.deal(address(predictionMarket), 10 ether);
    }

    function test_OpenPosition() public {
        vm.startPrank(trader);
        
        // Send ETH with the transaction
        address user = predictionMarket.openPosition{value: 0.01 ether}("USA", PredictionMarket.PositionDirection.LONG, 2);

        PredictionMarket.Position memory position = predictionMarket.getPosition();

        assertEq(position.trader, trader);
        assertEq(position.countryId, "USA");
        assertEq(uint256(position.direction), uint256(PredictionMarket.PositionDirection.LONG));
        assertEq(position.leverage, 2);
        // Size should be original amount minus fee (0.01 ETH - 0.3% fee)
        uint256 expectedSize = 0.01 ether - (0.01 ether * 30 / 10000);
        assertEq(position.size, expectedSize);
        assertEq(position.isOpen, true);

        vm.stopPrank();
    }

    function test_ClosePosition() public {
        vm.startPrank(trader);
        
        console.log("ETH balance before open position: ", trader.balance);
        address user = predictionMarket.openPosition{value: 0.01 ether}("USA", PredictionMarket.PositionDirection.LONG, 2);
        console.log("ETH balance after open position: ", trader.balance);
        
        predictionMarket.closePosition(user);
        console.log("ETH balance after close position: ", trader.balance);
        
        vm.stopPrank();

        PredictionMarket.Position memory position = predictionMarket.getPosition();

        assertEq(position.isOpen, false);
    }
}
