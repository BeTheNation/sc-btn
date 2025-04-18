// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {CounterFactory} from "../src/CounterFactory.sol";

contract CounterFactoryScript is Script {
    CounterFactory public counter;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("https://arb-sepolia.g.alchemy.com/v2/IpWFQVx6ZTeZyG85llRd7h6qRRNMqErS"));
    }

    function run() public {
        uint256 privateKey = vm.envUint("DEPLOYER_WALLET_PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        counter = new CounterFactory(0);

        vm.stopBroadcast();
    }
}
