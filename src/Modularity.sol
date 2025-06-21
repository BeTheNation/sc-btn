// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

abstract contract Modularity {
    error MODULARITY_NotSelf();

    struct Modules {
        address initialize;
        address order;
        address resolver;
    }

    address public immutable MODULE_INITIALIZE;
    address public immutable MODULE_ORDER;
    address public immutable MODULE_RESOLVER;

    /**
     * @notice Initializes the Modularity contract with module addresses and native wrapper
     */
    constructor(Modules memory modules) {
        MODULE_INITIALIZE = modules.initialize;
        MODULE_ORDER = modules.order;
        MODULE_RESOLVER = modules.resolver;
    }

    /**
     * @notice Modifier to execute a function and then delegate to a module
     * @dev This modifier is used to execute a function and then delegate the result to a specific module.
     * @param module The address of the module to delegate to.
     */
    modifier useModuleWrite(address module) {
        _;
        delegateToModule(module);
    }

    /**
     * @notice Modifier to execute a view function and then delegate to a module
     */
    modifier useModuleView(address module) {
        _;
        delegateToModuleView(module);
    }

    /**
     * @notice Delegates a view call to the contract itself
     * @dev This function works as follows:
     * 1. It checks if the caller is the contract itself
     * 2. If not, it reverts with a MODULARITY_NotSelf error
     * 3. If the caller is the contract, it executes a delegatecall with the provided calldata
     * 4. The result of the delegatecall is then returned or reverted based on its success
     */
    function delegateView() external payable {
        if (msg.sender != address(this)) revert MODULARITY_NotSelf();

        assembly {
            let size := sub(calldatasize(), 36)
            calldatacopy(0, 36, size)
            let result := delegatecall(gas(), calldataload(4), 0, size, 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @notice Delegates a view call to a specific module
     * @dev because no delegatecall view so we need to use staticcall
     */
    function delegateToModuleView(address module) private view {
        // [signature of viewDelegate 4B] + [module address 32B] + [original calldata]
        // 0-4 bytes = viewDelegate() signature -> 0x535c370c
        // 4-36 bytes = module address
        // > 36 = original calldata
        assembly {
            mstore(0, 0x535c370c00000000000000000000000000000000000000000000000000000000)

            mstore(4, module)
            calldatacopy(36, 0, calldatasize())
            // Calldatasize + 36 (signature and module address)
            let result := staticcall(gas(), address(), 0, add(calldatasize(), 36), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @notice Delegates a call to a specific module
     */
    function delegateToModule(address module) private {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), module, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
