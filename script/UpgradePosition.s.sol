// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {PredictionMarket} from "../src/Position.sol";

contract UpgradePosition is Script {
    address constant EXISTING_PROXY = 0xd321D80155A27A1344ab5703cDDefD2b0fAF92e5;
    
    function run() external {
        uint256 privateKey = vm.envUint("DEPLOYER_WALLET_PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        PredictionMarket newImplementation = new PredictionMarket();
        PredictionMarket proxy = PredictionMarket(EXISTING_PROXY);
        proxy.upgradeToAndCall(address(newImplementation), "");

        vm.stopBroadcast();
    }
}
