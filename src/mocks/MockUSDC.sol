// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("USDC", "USDC") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 6; // USDC has 6 decimals
    }
}
