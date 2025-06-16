// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title IMarketOrderExecutor
 * @dev Interface for market order execution
 */
interface IMarketOrderExecutor {
    enum PositionDirection {
        LONG,
        SHORT
    }

    function executeMarketOrder(address trader, string calldata countryId, uint8 direction, uint8 leverage)
        external
        payable
        returns (uint256);
}
