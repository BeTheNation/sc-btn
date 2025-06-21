// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {PoolStorage} from "../PoolStorage.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract InitializeModule is Initializable, ReentrancyGuardUpgradeable, ERC20Upgradeable, OwnableUpgradeable {
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name_, string memory symbol_) public virtual initializer {
        __ERC20_init(name_, symbol_);
        __ReentrancyGuard_init();
        __Ownable_init(msg.sender);
    }
}
