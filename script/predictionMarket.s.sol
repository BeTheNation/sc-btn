// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PredictionMarket} from "../src/predictionMarket.sol";

contract PositionScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        PredictionMarket position = new PredictionMarket();

        console.log("PredictionMarket contract deployed to:", address(position));

        vm.stopBroadcast();
    }
}