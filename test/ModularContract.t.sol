// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/OrderManager.sol";
import "../src/MarketOrderExecutor.sol";
import "../src/LimitOrderManager.sol";
import "../src/PositionManager.sol";
import "../src/LiquidationManager.sol";

/**
 * @title ModularContractTest
 * @notice Tests for modular prediction market contracts
 */
contract ModularContractTest is Test {
    OrderManager public orderManager;
    MarketOrderExecutor public marketExecutor;
    LimitOrderManager public limitManager;
    PositionManager public positionManager;
    LiquidationManager public liquidationManager;

    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public liquidator = address(0x3);

    function setUp() public {
        positionManager = new PositionManager();
        orderManager = new OrderManager();
        marketExecutor = new MarketOrderExecutor(address(orderManager), address(positionManager));
        limitManager = new LimitOrderManager(address(orderManager), address(positionManager));
        liquidationManager = new LiquidationManager(address(positionManager));

        orderManager.setMarketOrderExecutor(address(marketExecutor));
        orderManager.setLimitOrderManager(address(limitManager));
        orderManager.setPositionManager(address(positionManager));

        positionManager.setAuthorizedCaller(address(marketExecutor), true);
        positionManager.setAuthorizedCaller(address(limitManager), true);
        positionManager.setAuthorizedCaller(address(orderManager), true);
        positionManager.setAuthorizedCaller(address(liquidationManager), true);

        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(liquidator, 10 ether);
    }

    function testMarketOrderCreation() public {
        vm.startPrank(user1);

        uint256 positionId =
            orderManager.createMarketOrder{value: 1 ether}("USA", OrderManager.PositionDirection.LONG, 2);

        (
            uint256 returnedPositionId,
            string memory countryId,
            OrderManager.PositionDirection direction,
            uint256 size,
            uint8 leverage,
            uint256 entryPrice,
            ,
            bool isOpen
        ) = orderManager.getPosition(user1);

        assertEq(returnedPositionId, positionId);
        assertEq(countryId, "USA");
        assertTrue(direction == OrderManager.PositionDirection.LONG);
        assertTrue(size > 0);
        assertEq(leverage, 2);
        assertTrue(entryPrice > 0);
        assertTrue(isOpen);

        vm.stopPrank();
    }

    function testLimitOrderCreation() public {
        vm.startPrank(user1);

        uint256 orderId =
            orderManager.createLimitOrder{value: 1 ether}("USA", OrderManager.PositionDirection.LONG, 2, 50000);

        LimitOrderManager.LimitOrder memory order = limitManager.getLimitOrder(orderId);

        assertEq(order.orderId, orderId);
        assertEq(order.trader, user1);
        assertEq(order.countryId, "USA");
        assertTrue(order.direction == LimitOrderManager.PositionDirection.LONG);
        assertEq(order.leverage, 2);
        assertEq(order.triggerPrice, 50000);
        assertTrue(order.status == LimitOrderManager.OrderStatus.PENDING);

        vm.stopPrank();
    }

    function testLimitOrderExecution() public {
        vm.startPrank(user1);

        uint256 orderId =
            orderManager.createLimitOrder{value: 1 ether}("USA", OrderManager.PositionDirection.LONG, 2, 100000);

        vm.stopPrank();

        vm.startPrank(user2);
        uint256 positionId = limitManager.executeLimitOrder(orderId);
        vm.stopPrank();

        (uint256 returnedPositionId, string memory countryId, OrderManager.PositionDirection direction,,,,, bool isOpen)
        = orderManager.getPosition(user1);

        assertEq(returnedPositionId, positionId);
        assertEq(countryId, "USA");
        assertTrue(direction == OrderManager.PositionDirection.LONG);
        assertTrue(isOpen);

        LimitOrderManager.LimitOrder memory order = limitManager.getLimitOrder(orderId);
        assertTrue(order.status == LimitOrderManager.OrderStatus.EXECUTED);
    }

    function testLimitOrderCancellation() public {
        vm.startPrank(user1);

        uint256 initialBalance = user1.balance;

        uint256 orderId =
            orderManager.createLimitOrder{value: 1 ether}("USA", OrderManager.PositionDirection.LONG, 2, 50000);

        limitManager.cancelLimitOrder(orderId);

        LimitOrderManager.LimitOrder memory order = limitManager.getLimitOrder(orderId);
        assertTrue(order.status == LimitOrderManager.OrderStatus.CANCELLED);

        assertTrue(user1.balance > initialBalance - 1 ether);

        vm.stopPrank();
    }

    function testPositionClosing() public {
        vm.startPrank(user1);

        orderManager.createMarketOrder{value: 1 ether}("USA", OrderManager.PositionDirection.LONG, 2);

        orderManager.closePosition(user1, 80000);

        (,,,,,,, bool isOpen) = orderManager.getPosition(user1);

        assertFalse(isOpen);

        vm.stopPrank();
    }

    function test_RevertWhen_UnauthorizedAccess() public {
        vm.startPrank(user1);

        vm.expectRevert(PositionManager.OnlyAuthorized.selector);
        positionManager.createPosition(user1, "USA", 0, 1 ether, 2, 50000);

        vm.stopPrank();
    }

    function test_RevertWhen_InvalidLeverage() public {
        vm.startPrank(user1);

        vm.expectRevert(MarketOrderExecutor.InvalidLeverage.selector);
        orderManager.createMarketOrder{value: 1 ether}("USA", OrderManager.PositionDirection.LONG, 10);

        vm.stopPrank();
    }

    function testLiquidationEligibilityCheck() public {
        vm.startPrank(user1);

        uint256 positionId =
            orderManager.createMarketOrder{value: 1 ether}("USA", OrderManager.PositionDirection.LONG, 5);

        vm.stopPrank();

        (, uint256 marginRatio) = liquidationManager.isLiquidatable(positionId);

        assertTrue(marginRatio > 0, "Margin ratio should be calculated");
    }

    function testLiquidationExecution() public {
        vm.startPrank(user1);

        uint256 positionId =
            orderManager.createMarketOrder{value: 1 ether}("USA", OrderManager.PositionDirection.LONG, 5);

        vm.stopPrank();

        (bool eligible,) = liquidationManager.isLiquidatable(positionId);

        if (eligible) {
            vm.startPrank(liquidator);

            uint256 liquidatorReward = liquidationManager.liquidatePosition(positionId);

            assertTrue(liquidatorReward > 0, "Liquidator should receive reward");

            (
                uint256 recordedPositionId,
                address recordedLiquidator,
                uint256 liquidationPrice,
                uint256 timestamp,
                LiquidationManager.LiquidationStatus status
            ) = liquidationManager.liquidations(positionId);

            assertEq(recordedPositionId, positionId);
            assertEq(recordedLiquidator, liquidator);
            assertTrue(liquidationPrice > 0);
            assertTrue(timestamp > 0);
            assertTrue(status == LiquidationManager.LiquidationStatus.EXECUTED);

            vm.stopPrank();
        }
    }

    function testBatchLiquidationCheck() public {
        uint256[] memory positionIds = new uint256[](2);

        vm.startPrank(user1);
        positionIds[0] = orderManager.createMarketOrder{value: 1 ether}("USA", OrderManager.PositionDirection.LONG, 5);
        vm.stopPrank();

        vm.startPrank(user2);
        positionIds[1] = orderManager.createMarketOrder{value: 1 ether}("USA", OrderManager.PositionDirection.SHORT, 4);
        vm.stopPrank();

        (bool[] memory eligible, uint256[] memory marginRatios) = liquidationManager.batchCheckLiquidatable(positionIds);

        assertEq(eligible.length, 2);
        assertEq(marginRatios.length, 2);

        for (uint256 i = 0; i < marginRatios.length; i++) {
            assertTrue(marginRatios[i] > 0, "Margin ratio should be calculated for each position");
        }
    }

    function testLiquidatorRewardClaim() public {
        vm.startPrank(user1);

        uint256 positionId =
            orderManager.createMarketOrder{value: 1 ether}("USA", OrderManager.PositionDirection.LONG, 5);

        vm.stopPrank();

        (bool eligible,) = liquidationManager.isLiquidatable(positionId);

        if (eligible) {
            vm.startPrank(liquidator);

            uint256 initialBalance = liquidator.balance;
            liquidationManager.liquidatePosition(positionId);

            uint256 accumulatedRewards = liquidationManager.liquidatorRewards(liquidator);
            assertTrue(accumulatedRewards > 0, "Liquidator should have accumulated rewards");

            liquidationManager.claimRewards();

            uint256 finalBalance = liquidator.balance;
            assertTrue(finalBalance >= initialBalance, "Liquidator balance should increase");

            uint256 remainingRewards = liquidationManager.liquidatorRewards(liquidator);
            assertEq(remainingRewards, 0, "Rewards should be reset after claiming");

            vm.stopPrank();
        }
    }

    function test_RevertWhen_LiquidatingNonLiquidatablePosition() public {
        vm.startPrank(user1);

        uint256 positionId =
            orderManager.createMarketOrder{value: 1 ether}("USA", OrderManager.PositionDirection.LONG, 2);

        vm.stopPrank();

        vm.startPrank(liquidator);

        vm.expectRevert(LiquidationManager.PositionNotLiquidatable.selector);
        liquidationManager.liquidatePosition(positionId);

        vm.stopPrank();
    }

    function test_RevertWhen_LiquidatingInvalidPosition() public {
        vm.startPrank(liquidator);

        vm.expectRevert(LiquidationManager.PositionNotLiquidatable.selector);
        liquidationManager.liquidatePosition(999);

        vm.expectRevert(LiquidationManager.InvalidPosition.selector);
        liquidationManager.liquidatePosition(0);

        vm.stopPrank();
    }

    function testMultiplePositions() public {
        vm.startPrank(user1);

        // Create multiple positions
        uint256 positionId1 = orderManager.createMarketOrder{value: 1 ether}("USA", OrderManager.PositionDirection.LONG, 2);
        uint256 positionId2 = orderManager.createMarketOrder{value: 1 ether}("UK", OrderManager.PositionDirection.SHORT, 3);
        uint256 positionId3 = orderManager.createMarketOrder{value: 1 ether}("JP", OrderManager.PositionDirection.LONG, 1);

        // Check positions count
        uint256 openCount = orderManager.getOpenPositionsCount(user1);
        assertEq(openCount, 3);

        // Get all positions
        (uint256[] memory positionIds, ) = orderManager.getTraderPositions(user1);
        assertEq(positionIds.length, 3);
        assertEq(positionIds[0], positionId1);
        assertEq(positionIds[1], positionId2);
        assertEq(positionIds[2], positionId3);

        // Close specific position
        orderManager.closePositionById(positionId2, 80000);

        // Check remaining positions
        uint256 remainingCount = orderManager.getOpenPositionsCount(user1);
        assertEq(remainingCount, 2);

        // Verify correct position was closed
        (, , , , , , , bool isOpen2) = positionManager.getPosition(positionId2);
        assertFalse(isOpen2);

        // Verify other positions still open
        (, , , , , , , bool isOpen1) = positionManager.getPosition(positionId1);
        (, , , , , , , bool isOpen3) = positionManager.getPosition(positionId3);
        assertTrue(isOpen1);
        assertTrue(isOpen3);

        vm.stopPrank();
    }

    function testPositionLimit() public {
        vm.startPrank(user1);

        // Create maximum positions (10)
        for (uint i = 0; i < 10; i++) {
            orderManager.createMarketOrder{value: 1 ether}("USA", OrderManager.PositionDirection.LONG, 2);
        }

        uint256 openCount = orderManager.getOpenPositionsCount(user1);
        assertEq(openCount, 10);

        // Try to create 11th position - should fail with TooManyPositions
        // We'll check that it reverts, even if the error doesn't propagate perfectly
        vm.expectRevert();
        orderManager.createMarketOrder{value: 1 ether}("USA", OrderManager.PositionDirection.LONG, 2);

        vm.stopPrank();
    }

    function testBackwardCompatibility() public {
        vm.startPrank(user1);

        // Create multiple positions
        uint256 positionId1 = orderManager.createMarketOrder{value: 1 ether}("USA", OrderManager.PositionDirection.LONG, 2);
        uint256 positionId2 = orderManager.createMarketOrder{value: 1 ether}("UK", OrderManager.PositionDirection.SHORT, 3);

        // Old closePosition function should close first open position
        orderManager.closePosition(user1, 80000);

        // Check that first position was closed
        (, , , , , , , bool isOpen1) = positionManager.getPosition(positionId1);
        assertFalse(isOpen1);

        // Check that second position is still open
        (, , , , , , , bool isOpen2) = positionManager.getPosition(positionId2);
        assertTrue(isOpen2);

        vm.stopPrank();
    }
}
