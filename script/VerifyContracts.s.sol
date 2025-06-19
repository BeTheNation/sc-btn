// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";

/**
 * @title VerifyContracts
 * @notice Script to verify all deployed BeTheNation contracts on Base Sepolia
 * @dev Generates verification commands for all modular contracts
 */
contract VerifyContracts is Script {
    // Current deployed addresses - Multiple Positions Support
    address constant POSITION_MANAGER = 0x9fead44f799927BaBc81598fF6134543A2240173;
    address constant ORDER_MANAGER = 0x369327Cb1f9E164A20215Bb12024108BdbE1c8E1;
    address constant MARKET_ORDER_EXECUTOR = 0x682aaED27CD2991f8864062eb9aB5bf58010341F;
    address constant LIMIT_ORDER_MANAGER = 0x6e7F0a5c8a671E5BC316029cCbcfA27A094073aE;
    address constant LIQUIDATION_MANAGER = 0xB17D986306401cbd34E25ecC38c7ec8e094B520c;

    function run() external view {
        console.log("BeTheNation Contract Verification - Multiple Positions Support");
        console.log("Network: Base Sepolia");
        console.log("");

        console.log("Execute these commands to verify all contracts:");
        console.log("");

        // Core contracts
        console.log("# PositionManager");
        console.log(
            "forge verify-contract --chain base-sepolia --constructor-args $(cast abi-encode \"constructor()\") --etherscan-api-key $BASESCAN_API_KEY %s src/PositionManager.sol:PositionManager",
            POSITION_MANAGER
        );
        console.log("");

        console.log("# OrderManager");
        console.log(
            "forge verify-contract --chain base-sepolia --constructor-args $(cast abi-encode \"constructor()\") --etherscan-api-key $BASESCAN_API_KEY %s src/OrderManager.sol:OrderManager",
            ORDER_MANAGER
        );
        console.log("");

        // Execution contracts
        console.log("# MarketOrderExecutor");
        console.log(
            "forge verify-contract --chain base-sepolia --constructor-args $(cast abi-encode \"constructor(address,address)\" %s %s) --etherscan-api-key $BASESCAN_API_KEY %s src/MarketOrderExecutor.sol:MarketOrderExecutor",
            ORDER_MANAGER,
            POSITION_MANAGER,
            MARKET_ORDER_EXECUTOR
        );
        console.log("");

        console.log("# LimitOrderManager");
        console.log(
            "forge verify-contract --chain base-sepolia --constructor-args $(cast abi-encode \"constructor(address,address)\" %s %s) --etherscan-api-key $BASESCAN_API_KEY %s src/LimitOrderManager.sol:LimitOrderManager",
            ORDER_MANAGER,
            POSITION_MANAGER,
            LIMIT_ORDER_MANAGER
        );
        console.log("");

        console.log("# LiquidationManager");
        console.log(
            "forge verify-contract --chain base-sepolia --constructor-args $(cast abi-encode \"constructor(address)\" %s) --etherscan-api-key $BASESCAN_API_KEY %s src/LiquidationManager.sol:LiquidationManager",
            POSITION_MANAGER,
            LIQUIDATION_MANAGER
        );
        console.log("");

        console.log("Verification complete - Multiple Positions Support Ready!");
    }
}
