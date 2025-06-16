// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";

/**
 * @title VerifyContracts
 * @notice Script to verify all deployed BeTheNation contracts on Base Sepolia
 * @dev Generates verification commands for all modular contracts
 */
contract VerifyContracts is Script {
    // Contract addresses from latest deployment
    address constant POSITION_MANAGER = 0xA62F56b0BE223e60457f652f08DdEd7E173c1022;
    address constant ORDER_MANAGER = 0x30B9Ff7eC9Ca3d3f85044ae23A8E61cB1FFA32cB;
    address constant MARKET_ORDER_EXECUTOR = 0x20af2912a5203B777fBEc7279F62d8c89b811b63;
    address constant LIMIT_ORDER_MANAGER = 0xc012801c5CFCD09447310aFA744edB5B570D48cC;
    address constant LIQUIDATION_MANAGER = 0x3C75cBDEb7D6088Ab0E1A5BA310a40F67B8fF75C;

    function run() external view {
        console.log("BeTheNation Contract Verification");
        console.log("Network: Base Sepolia");
        console.log("");

        console.log("Execute these commands to verify all contracts:");
        console.log("");

        // Core contracts
        console.log("# PositionManager");
        console.log(
            "forge verify-contract --chain base-sepolia --constructor-args $(cast abi-encode \"constructor()\") %s src/PositionManager.sol:PositionManager",
            POSITION_MANAGER
        );
        console.log("");

        console.log("# OrderManager");
        console.log(
            "forge verify-contract --chain base-sepolia --constructor-args $(cast abi-encode \"constructor()\") %s src/OrderManager.sol:OrderManager",
            ORDER_MANAGER
        );
        console.log("");

        // Execution contracts
        console.log("# MarketOrderExecutor");
        console.log(
            "forge verify-contract --chain base-sepolia --constructor-args $(cast abi-encode \"constructor(address,address)\" %s %s) %s src/MarketOrderExecutor.sol:MarketOrderExecutor",
            ORDER_MANAGER,
            POSITION_MANAGER,
            MARKET_ORDER_EXECUTOR
        );
        console.log("");

        console.log("# LimitOrderManager");
        console.log(
            "forge verify-contract --chain base-sepolia --constructor-args $(cast abi-encode \"constructor(address,address)\" %s %s) %s src/LimitOrderManager.sol:LimitOrderManager",
            ORDER_MANAGER,
            POSITION_MANAGER,
            LIMIT_ORDER_MANAGER
        );
        console.log("");

        console.log("# LiquidationManager");
        console.log(
            "forge verify-contract --chain base-sepolia --constructor-args $(cast abi-encode \"constructor(address)\" %s) %s src/LiquidationManager.sol:LiquidationManager",
            POSITION_MANAGER,
            LIQUIDATION_MANAGER
        );
        console.log("");

        console.log("Verification complete.");
    }
}
