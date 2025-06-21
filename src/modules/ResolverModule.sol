// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {PoolStorage} from "../PoolStorage.sol";

contract ResolverModule {
    function getPosition(bytes32 orderId) public view returns (PoolStorage.Order memory) {
        return PoolStorage.s().orders[orderId];
    }

    function readFromStorage(bytes32 slot) public view returns (bytes32 result) {
        assembly {
            result := sload(slot)
        }
    }
}
