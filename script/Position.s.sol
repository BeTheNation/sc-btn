// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {PredictionMarket} from "../src/Position.sol";

contract DeployUpgradeablePosition is Script {
    function run() external {
        uint256 privateKey = vm.envUint("DEPLOYER_WALLET_PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        PredictionMarket implementation = new PredictionMarket();
        console.log("Implementation deployed to:", address(implementation));

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(PredictionMarket.initialize.selector)
        );
        console.log("Proxy deployed to:", address(proxy));

        PredictionMarket predictionMarket = PredictionMarket(address(proxy));
        console.log("PredictionMarket proxy address:", address(predictionMarket));

        vm.stopBroadcast();
    }
}