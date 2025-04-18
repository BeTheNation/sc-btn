// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {CounterUpgrade} from "./CounterUpgrade.sol";

contract CounterFactory {
    CounterUpgrade public counterUpgrade;
    uint256 public number;
    uint256 public id;

    constructor(uint256 _id) {
        id = _id;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }

    function newCounter(uint256 _id) public returns (address){
        counterUpgrade = new CounterUpgrade(_id);
        return address(counterUpgrade);
    }
}
