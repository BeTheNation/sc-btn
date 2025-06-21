// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {Pool} from "./Pool.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract PoolFactory is Initializable, OwnableUpgradeable {
    address public poolImplementation;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _poolImplementation) external initializer {
        poolImplementation = _poolImplementation;
        __Ownable_init(msg.sender);
    }

    function createPool(string memory name, string memory symbol) external returns (address) {
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(poolImplementation, msg.sender, "");
        Pool(address(proxy)).initialize(name, symbol);
        return address(proxy);
    }

    function setPoolImplementation(address _poolImplementation) external onlyOwner {
        poolImplementation = _poolImplementation;
    }
}
