// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PrepetualPredictionMarket} from "../src/Position.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PrepetualPredictionMarketTest is Test {
    PrepetualPredictionMarket public prepetualPredictionMarket;
    MockUSDC public mockUSDC;

    address trader = makeAddr("trader");

    function setUp() public {
        mockUSDC = new MockUSDC();
        prepetualPredictionMarket = new PrepetualPredictionMarket(
            address(mockUSDC)
        );

        deal(address(mockUSDC), trader, 100e6);
        deal(address(mockUSDC), address(prepetualPredictionMarket), 100e6);
    }

    function test_OpenPosition() public {
        vm.startPrank(trader);
        IERC20(mockUSDC).approve(address(prepetualPredictionMarket), 1e6);

        prepetualPredictionMarket.openPosition(
            "USA",
            PrepetualPredictionMarket.PositionDirection.LONG,
            2,
            1e6
        );
        PrepetualPredictionMarket.Position
            memory position = prepetualPredictionMarket.getPosition();
        vm.stopPrank();

        assertEq(position.countryId, "USA");
        assertEq(position.trader, trader);
        assertEq(
            uint8(position.direction),
            uint8(PrepetualPredictionMarket.PositionDirection.LONG)
        );
        uint256 expectedSize = 1e6 - ((1e6 * 1) / 10000);
        assertEq(position.size, expectedSize);
        assertEq(position.leverage, 2);
        assertEq(position.entryPrice, 120);
        assertEq(position.isOpen, true);
        assertTrue(position.liquidationPrice > 0);
    }

    function test_ClosePosition() public {
        vm.startPrank(trader);

        // Approve USDC untuk open position
        IERC20(mockUSDC).approve(address(prepetualPredictionMarket), 10e6);

        // Record balance sebelum open position
        uint256 balanceBefore = mockUSDC.balanceOf(trader);
        console.log("Balance before open position: ", balanceBefore);

        // Open position
        address userAddress = prepetualPredictionMarket.openPosition(
            "USA",
            PrepetualPredictionMarket.PositionDirection.LONG,
            2,
            10e6
        );

        // Record balance setelah open position
        uint256 balanceAfterOpen = mockUSDC.balanceOf(trader);
        console.log("Balance after open position: ", balanceAfterOpen);

        // Verify position is open
        PrepetualPredictionMarket.Position
            memory positionBeforeClose = prepetualPredictionMarket
                .getPosition();
        assertEq(positionBeforeClose.isOpen, true);
        assertEq(userAddress, trader); // openPosition returns msg.sender

        // Close position - gunakan trader sebagai parameter, bukan userAddress
        prepetualPredictionMarket.closePosition(trader);

        // Record balance setelah close position
        uint256 balanceAfterClose = mockUSDC.balanceOf(trader);
        console.log("Balance after close position: ", balanceAfterClose);

        vm.stopPrank();

        // Verify position is closed
        PrepetualPredictionMarket.Position
            memory positionAfterClose = prepetualPredictionMarket.getPosition();
        assertEq(positionAfterClose.isOpen, false);

        // Calculate expected balance
        uint256 fee = (10e6 * 1) / 10000; // 1% transaction fee

        // Since CURRENT_PRICE = entryPrice (120), no profit/loss
        // Should get back the position size (after fee)
        uint256 expectedBalance = balanceBefore - fee;
        assertEq(balanceAfterClose, expectedBalance);
    }

    function test_ClosePosition_WithProfit() public {
        vm.startPrank(trader);

        IERC20(mockUSDC).approve(address(prepetualPredictionMarket), 10e6);

        // Open LONG position
        prepetualPredictionMarket.openPosition(
            "USA",
            PrepetualPredictionMarket.PositionDirection.LONG,
            2, // leverage 2x
            10e6
        );

        // Simulate price increase (profit for LONG)
        prepetualPredictionMarket.updatePrice(150); // Price goes from 120 to 150

        uint256 balanceBeforeClose = mockUSDC.balanceOf(trader);

        // Close position
        prepetualPredictionMarket.closePosition(trader);

        uint256 balanceAfterClose = mockUSDC.balanceOf(trader);

        vm.stopPrank();

        // Calculate expected profit
        uint256 fee = (10e6 * 1) / 10000;
        uint256 positionSize = 10e6 - fee;
        uint256 profit = ((150 - 120) * positionSize * 2) / 120; // 2x leverage
        uint256 expectedBalance = balanceBeforeClose + positionSize + profit;

        assertEq(balanceAfterClose, expectedBalance);

        // Verify position is closed
        PrepetualPredictionMarket.Position
            memory position = prepetualPredictionMarket.getPosition();
        assertEq(position.isOpen, false);
    }

    function test_ClosePosition_WithLoss() public {
        vm.startPrank(trader);

        IERC20(mockUSDC).approve(address(prepetualPredictionMarket), 10e6);

        // Open LONG position
        prepetualPredictionMarket.openPosition(
            "USA",
            PrepetualPredictionMarket.PositionDirection.LONG,
            2, // leverage 2x
            10e6
        );

        // Simulate price decrease (loss for LONG)
        prepetualPredictionMarket.updatePrice(100); // Price goes from 120 to 100

        uint256 balanceBeforeClose = mockUSDC.balanceOf(trader);

        // Close position
        prepetualPredictionMarket.closePosition(trader);

        uint256 balanceAfterClose = mockUSDC.balanceOf(trader);

        vm.stopPrank();

        // Calculate expected loss
        uint256 fee = (10e6 * 1) / 10000;
        uint256 positionSize = 10e6 - fee;
        uint256 loss = ((120 - 100) * positionSize * 2) / 120; // 2x leverage
        uint256 expectedBalance = balanceBeforeClose + positionSize - loss;

        assertEq(balanceAfterClose, expectedBalance);

        // Verify position is closed
        PrepetualPredictionMarket.Position
            memory position = prepetualPredictionMarket.getPosition();
        assertEq(position.isOpen, false);
    }

    function test_ClosePosition_Liquidated() public {
        vm.startPrank(trader);

        IERC20(mockUSDC).approve(address(prepetualPredictionMarket), 10e6);

        // Open LONG position with high leverage
        prepetualPredictionMarket.openPosition(
            "USA",
            PrepetualPredictionMarket.PositionDirection.LONG,
            5, // leverage 5x
            10e6
        );

        // Simulate massive price drop (liquidation scenario)
        prepetualPredictionMarket.updatePrice(90); // Price drops significantly

        // Expect liquidation revert
        vm.expectRevert(PrepetualPredictionMarket.Liquidated.selector);
        prepetualPredictionMarket.closePosition(trader);

        vm.stopPrank();
    }

    function test_ClosePosition_NotTheOwner() public {
        address otherUser = makeAddr("otherUser");

        vm.startPrank(trader);
        IERC20(mockUSDC).approve(address(prepetualPredictionMarket), 10e6);

        prepetualPredictionMarket.openPosition(
            "USA",
            PrepetualPredictionMarket.PositionDirection.LONG,
            2,
            10e6
        );
        vm.stopPrank();

        // Try to close position from different user
        vm.startPrank(otherUser);
        vm.expectRevert(PrepetualPredictionMarket.NotTheOwner.selector);
        prepetualPredictionMarket.closePosition(trader);
        vm.stopPrank();
    }

    function test_ClosePosition_PositionDoesNotExist() public {
        vm.startPrank(trader);

        // Try to close position that doesn't exist
        vm.expectRevert(
            PrepetualPredictionMarket.PositionDoesNotExist.selector
        );
        prepetualPredictionMarket.closePosition(trader);

        vm.stopPrank();
    }
}
