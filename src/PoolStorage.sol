// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library PoolStorage {
    struct Order {
        uint256 collateral;
        uint256 tradingSize;
        bool isLong;
        uint256 createdAt;
    }

    struct PoolDS {
        mapping(bytes32 => Order) orders;
    }

    // keccak256(abi.encode(uint256(keccak256("betezen.pool.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant STORAGE_SLOT = 0x7c0c80bbf357809bb7c9d076beb77e47baabe6051db87d5193a77ab1a5196400;

    function s() internal pure returns (PoolDS storage ds) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            ds.slot := slot
        }
    }
}
