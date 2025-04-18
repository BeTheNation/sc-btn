// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract CounterUpgrade {
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

}
