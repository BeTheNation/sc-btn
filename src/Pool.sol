// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {PoolStorage} from "./PoolStorage.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Modularity} from "./Modularity.sol";
import {InitializeModule} from "./modules/InitializeModule.sol";
import {OrderModule} from "./modules/OrderModule.sol";
import {ResolverModule} from "./modules/ResolverModule.sol";

contract Pool is Initializable, Modularity {
    constructor(Modularity.Modules memory modules) Modularity(modules) {
        _disableInitializers();
    }

    function initialize(string memory name_, string memory symbol_) public useModuleWrite(MODULE_INITIALIZE) {}

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                 Order Module                                              //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    function createOrder(uint256 collateral, uint256 tradingSize, bool isLong)
        external
        useModuleWrite(MODULE_ORDER)
        returns (bytes32)
    {}

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                Resolver Module                                         //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    function getPosition(bytes32 orderId)
        public
        view
        useModuleView(MODULE_RESOLVER)
        returns (PoolStorage.Order memory)
    {}
}
