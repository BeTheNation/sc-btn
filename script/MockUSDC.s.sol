// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";

contract MockUSDCScript is Script {
    MockUSDC public usdc;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("https://devnet.dplabs-internal.com"));
        //https://base-sepolia.g.alchemy.com/v2/IpWFQVx6ZTeZyG85llRd7h6qRRNMqErS
        //https://arb-sepolia.g.alchemy.com/v2/IpWFQVx6ZTeZyG85llRd7h6qRRNMqErS
    }

    function run() public {
        uint256 privateKey = vm.envUint("DEPLOYER_WALLET_PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        new MockUSDC();

        vm.stopBroadcast();
    }
}
