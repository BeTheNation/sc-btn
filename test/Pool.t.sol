// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import {Pool} from "../src/Pool.sol";
import {InitializeModule} from "../src/modules/InitializeModule.sol";
import {OrderModule} from "../src/modules/OrderModule.sol";
import {ResolverModule} from "../src/modules/ResolverModule.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Modularity} from "../src/Modularity.sol";
import {PoolStorage} from "../src/PoolStorage.sol";
import {PoolFactory} from "../src/PoolFactory.sol";

contract PoolTest is Test {
    Pool public pool;
    PoolFactory public poolFactory;

    function setUp() public {
        // deploy modules and pool implementation
        address initializeModule = address(new InitializeModule());
        address orderModule = address(new OrderModule());
        address resolverModule = address(new ResolverModule());
        Modularity.Modules memory modules =
            Modularity.Modules({initialize: initializeModule, order: orderModule, resolver: resolverModule});
        address poolImplementation = address(new Pool(modules));

        // deploy pool factory
        address poolFactoryImplementation = address(new PoolFactory());
        poolFactory = PoolFactory(
            address(
                new TransparentUpgradeableProxy(
                    poolFactoryImplementation,
                    msg.sender,
                    abi.encodeWithSelector(PoolFactory.initialize.selector, address(poolImplementation))
                )
            )
        );

        // deploy pool
        pool = Pool(poolFactory.createPool("Test Pool", "TP"));
    }

    function testCreateOrder() public {
        bytes32 orderId = pool.createOrder(100, 100, true);

        PoolStorage.Order memory order = pool.getPosition(orderId);

        assertEq(order.createdAt, block.timestamp);
        assertEq(order.collateral, 100);
        assertEq(order.tradingSize, 100);
        assertEq(order.isLong, true);
    }
}
