# BeTheNation Smart Contracts

A modular prediction market system for country-based trading outcomes. Built with Solidity and Foundry.

## Overview

BeTheNation enables users to trade positions on country-based predictions using a modular smart contract architecture. The system supports market orders, limit orders, and automatic position liquidation.

## Deployed Contracts

| Contract | Address | Explorer |
|----------|---------|----------|
| PositionManager | `0xA62F56b0BE223e60457f652f08DdEd7E173c1022` | [View](https://sepolia.basescan.org/address/0xA62F56b0BE223e60457f652f08DdEd7E173c1022) |
| OrderManager | `0x30B9Ff7eC9Ca3d3f85044ae23A8E61cB1FFA32cB` | [View](https://sepolia.basescan.org/address/0x30B9Ff7eC9Ca3d3f85044ae23A8E61cB1FFA32cB) |
| MarketOrderExecutor | `0x20af2912a5203B777fBEc7279F62d8c89b811b63` | [View](https://sepolia.basescan.org/address/0x20af2912a5203B777fBEc7279F62d8c89b811b63) |
| LimitOrderManager | `0xc012801c5CFCD09447310aFA744edB5B570D48cC` | [View](https://sepolia.basescan.org/address/0xc012801c5CFCD09447310aFA744edB5B570D48cC) |
| LiquidationManager | `0x3C75cBDEb7D6088Ab0E1A5BA310a40F67B8fF75C` | [View](https://sepolia.basescan.org/address/0x3C75cBDEb7D6088Ab0E1A5BA310a40F67B8fF75C) |

**Network**: Base Sepolia (Chain ID: 84532)

## Quick Start

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Setup
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone and install dependencies
git clone <repository-url>
cd BeTheNation/sc
forge install
```

### Environment Configuration
Create `.env` file:
```bash
RPC_URL_BASE_SEPOLIA=https://sepolia.base.org
PRIVATE_KEY=your_private_key
BASESCAN_API_KEY=your_api_key
```

## Development

### Build
```bash
forge build
```

### Test
```bash
# Run all tests
forge test

# Run with verbose output
forge test -vvv

# Generate coverage report
forge coverage
```

### Deploy
```bash
# Deploy contracts
forge script script/DeployModular.s.sol:DeployModular \
  --rpc-url $RPC_URL_BASE_SEPOLIA \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

## Architecture

The system uses five specialized contracts:

**PositionManager**
- Core position lifecycle management
- Collateral handling
- Position state tracking

**OrderManager**
- Order routing and validation
- Execution coordination
- Order type management

**MarketOrderExecutor**
- Immediate order execution
- Real-time price handling
- Position opening/closing

**LimitOrderManager**
- Pending order management
- Conditional execution
- Order book functionality

**LiquidationManager**
- Position health monitoring
- Liquidation execution
- Penalty and reward distribution

## Usage Examples

### Market Order (Solidity)
```solidity
// Open a long position on USA with 2x leverage
IOrderManager(orderManager).executeMarketOrder(
    "USA",           // country
    true,            // isLong
    2,              // leverage
    {value: 0.001 ether}
);
```

### TypeScript Integration
```typescript
import { useWriteContract } from 'wagmi';
import { parseEther } from 'viem';

// Execute market order
const { writeContractAsync } = useWriteContract();

await writeContractAsync({
  address: '0x30B9Ff7eC9Ca3d3f85044ae23A8E61cB1FFA32cB',
  abi: orderManagerAbi,
  functionName: 'executeMarketOrder',
  args: ['USA', true, 2],
  value: parseEther('0.001'),
});
```

## Project Structure

```
src/
├── PositionManager.sol       # Position lifecycle
├── OrderManager.sol          # Order routing
├── MarketOrderExecutor.sol   # Market execution
├── LimitOrderManager.sol     # Limit orders
├── LiquidationManager.sol    # Liquidations
└── interfaces/               # Contract interfaces

test/
└── ModularContract.t.sol     # Unit tests

script/
├── DeployModular.s.sol       # Deployment
└── VerifyContracts.s.sol     # Verification
```

## Documentation

- [Foundry Book](https://book.getfoundry.sh/)
- [Base Documentation](https://docs.base.org/)
- [Contract Explorer](https://sepolia.basescan.org/)

