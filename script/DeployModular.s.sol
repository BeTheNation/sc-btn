// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import "../src/OrderManager.sol";
import "../src/MarketOrderExecutor.sol";
import "../src/PositionManager.sol";
import "../src/LiquidationManager.sol";
import "../src/LimitOrderManager.sol";

/**
 * @title DeployModular
 * @notice Deployment script for modular prediction market contracts
 */
contract DeployModular is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy core contracts
        PositionManager positionManager = new PositionManager();
        OrderManager orderManager = new OrderManager();

        // Deploy execution contracts
        MarketOrderExecutor marketExecutor = new MarketOrderExecutor(address(orderManager), address(positionManager));

        LimitOrderManager limitManager = new LimitOrderManager(address(orderManager), address(positionManager));

        LiquidationManager liquidationManager = new LiquidationManager(address(positionManager));

        // Setup contract connections
        orderManager.setMarketOrderExecutor(address(marketExecutor));
        orderManager.setLimitOrderManager(address(limitManager));
        orderManager.setPositionManager(address(positionManager));

        // Authorize executors
        positionManager.setAuthorizedCaller(address(marketExecutor), true);
        positionManager.setAuthorizedCaller(address(limitManager), true);

        vm.stopBroadcast();

        // Output deployed addresses
        console.log("=== Deployment Addresses ===");
        console.log("OrderManager:", address(orderManager));
        console.log("PositionManager:", address(positionManager));
        console.log("MarketOrderExecutor:", address(marketExecutor));
        console.log("LimitOrderManager:", address(limitManager));
        console.log("LiquidationManager:", address(liquidationManager));
    }
}
