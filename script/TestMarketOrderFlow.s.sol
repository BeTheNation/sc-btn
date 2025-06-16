// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import "../src/PositionManager.sol";
import "../src/OrderManager.sol";
import "../src/MarketOrderExecutor.sol";
import "../src/LimitOrderManager.sol";
import "../src/LiquidationManager.sol";

contract TestMarketOrderFlow is Script {
    PositionManager positionManager;
    OrderManager orderManager;
    LiquidationManager liquidationManager;
    address trader;
    uint256 positionId;
    
    function run() external {
        deployOrLoadContracts();
        
        console.log("=== Market Order Flow Test (Base Sepolia) ===");
        console.log("Trader:", trader);
        console.log("Initial balance:", formatBalance(trader.balance));
        
        vm.startBroadcast();
        
        // Test flow with 0.00001 ETH
        checkPosition("Initial");
        createMarketPosition();
        checkPosition("After Creation");
        closeMarketPosition();
        checkPosition("Final");
        
        vm.stopBroadcast();
        
        logTestSummary();
    }
    
    function deployOrLoadContracts() internal {
        trader = vm.addr(vm.envUint("PRIVATE_KEY"));
        
        // Always deploy fresh contracts for testing
        console.log("Deploying fresh contracts for testing...");
        deployNewContracts();
    }
    
    function deployNewContracts() internal {
        vm.startBroadcast();
        
        // Deploy core contracts
        positionManager = new PositionManager();
        orderManager = new OrderManager();
        
        // Deploy execution contracts
        MarketOrderExecutor marketExecutor = new MarketOrderExecutor(
            address(orderManager),
            address(positionManager)
        );
        
        LimitOrderManager limitManager = new LimitOrderManager(
            address(orderManager),
            address(positionManager)
        );
        
        liquidationManager = new LiquidationManager(address(positionManager));
        
        // Setup contract connections
        orderManager.setMarketOrderExecutor(address(marketExecutor));
        orderManager.setLimitOrderManager(address(limitManager));
        orderManager.setPositionManager(address(positionManager));
        
        // Authorize executors
        positionManager.setAuthorizedCaller(address(marketExecutor), true);
        positionManager.setAuthorizedCaller(address(limitManager), true);
        positionManager.setAuthorizedCaller(address(orderManager), true);
        positionManager.setAuthorizedCaller(address(liquidationManager), true);
        positionManager.setLiquidationManager(address(liquidationManager));
        
        vm.stopBroadcast();
        
        console.log("=== Deployment Completed ===");
        console.log("PositionManager:", address(positionManager));
        console.log("OrderManager:", address(orderManager));
        console.log("MarketOrderExecutor:", address(marketExecutor));
        console.log("LimitOrderManager:", address(limitManager));
        console.log("LiquidationManager:", address(liquidationManager));
    }
    
    function createMarketPosition() internal {
        console.log("Creating market position with 0.00001 ETH...");
        
        try orderManager.createMarketOrder{value: 0.00001 ether}(
            "USA",
            OrderManager.PositionDirection.LONG,
            2
        ) returns (uint256 id) {
            positionId = id;
            console.log("Position created successfully. ID:", id);
            console.log("Position value:", formatWeiToEth(0.00001 ether));
        } catch Error(string memory reason) {
            console.log("Position creation failed:", reason);
        } catch (bytes memory lowLevelError) {
            console.log("Position creation failed with low-level error");
            console.logBytes(lowLevelError);
        }
    }
    
    function closeMarketPosition() internal {
        if (positionId == 0) {
            console.log("No position to close");
            return;
        }
        
        console.log("=== Closing Position ===");
        console.log("Position ID:", positionId);
        
        try orderManager.closePosition(trader, 75000) {
            console.log("Position closed successfully through OrderManager");
        } catch Error(string memory reason) {
            console.log("OrderManager close failed:", reason);
            console.log("Trying direct close through PositionManager...");
            
            try positionManager.closePosition(positionId, 75000, false) {
                console.log("Position closed successfully through PositionManager");
            } catch Error(string memory reason2) {
                console.log("Direct close also failed:", reason2);
            }
        } catch (bytes memory lowLevelError) {
            console.log("Close failed with low-level error");
            console.logBytes(lowLevelError);
        }
    }
    
    function checkPosition(string memory stage) internal view {
        try positionManager.getPosition(trader) returns (
            uint256 id,
            string memory countryId,
            PositionManager.PositionDirection direction,
            uint256 size,
            uint8 leverage,
            uint256 entryPrice,
            uint256 openTime,
            bool isOpen
        ) {
            console.log("=== Position Status (%s) ===", stage);
            if (isOpen) {
                console.log("ID:", id);
                console.log("Country:", countryId);
                console.log("Direction:", direction == PositionManager.PositionDirection.LONG ? "LONG" : "SHORT");
                console.log("Size (wei):", size);
                console.log("Size (ETH):", formatWeiToEth(size));
                console.log("Leverage:", leverage, "x");
                console.log("Entry Price:", entryPrice);
                console.log("Open Time:", openTime);
                console.log("Status: ACTIVE");
            } else {
                console.log("Status: NO ACTIVE POSITION");
            }
        } catch {
            console.log("=== Position Status (%s) ===", stage);
            console.log("Status: NO POSITION FOUND");
        }
    }

    function logTestSummary() internal view {
        console.log("=== Test Summary ===");
        console.log("Final balance:", formatBalance(trader.balance));
        console.log("System status: Market order flow test completed");
        console.log("Test amount: 0.00001 ETH");
    }

    function formatWeiToEth(uint256 wei_amount) internal pure returns (string memory) {
        uint256 eth_part = wei_amount / 1e18;
        uint256 fraction_part = (wei_amount % 1e18) / 1e13; // 5 decimal places for small amounts
        
        if (eth_part > 0) {
            return string(abi.encodePacked(vm.toString(eth_part), ".", vm.toString(fraction_part)));
        } else {
            return string(abi.encodePacked("0.", vm.toString(fraction_part)));
        }
    }
    
    function formatBalance(uint256 balance) internal pure returns (string memory) {
        return string(abi.encodePacked(vm.toString(balance / 1e18), " ETH"));
    }
}
