// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import {PoolStorage} from "../PoolStorage.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OrderModule is ReentrancyGuardUpgradeable {
    function createOrder(uint256 collateral, uint256 tradingSize, bool isLong) public returns (bytes32) {
        PoolStorage.PoolDS storage $ = PoolStorage.s();

        bytes32 orderId = keccak256(abi.encode(collateral, tradingSize, block.timestamp));

        $.orders[orderId] = PoolStorage.Order({
            collateral: collateral,
            tradingSize: tradingSize,
            isLong: isLong,
            createdAt: block.timestamp
        });

        return orderId;
    }
}
