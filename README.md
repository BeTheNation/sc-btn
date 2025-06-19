# BeTheNation Smart Contracts

A modular prediction market system for country-based trading outcomes. Built with Solidity and Foundry.

## Overview

BeTheNation enables users to trade positions on country-based predictions using a modular smart contract architecture. The system supports market orders, limit orders, automatic position liquidation, and **multiple positions per trader**.

## Deployed Contracts

| Contract | Address | Explorer |
|----------|---------|----------|
| PositionManager | `0x9fead44f799927BaBc81598fF6134543A2240173` | [View](https://sepolia.basescan.org/address/0x9fead44f799927BaBc81598fF6134543A2240173) |
| OrderManager | `0x369327Cb1f9E164A20215Bb12024108BdbE1c8E1` | [View](https://sepolia.basescan.org/address/0x369327Cb1f9E164A20215Bb12024108BdbE1c8E1) |
| MarketOrderExecutor | `0x682aaED27CD2991f8864062eb9aB5bf58010341F` | [View](https://sepolia.basescan.org/address/0x682aaED27CD2991f8864062eb9aB5bf58010341F) |
| LimitOrderManager | `0x6e7F0a5c8a671E5BC316029cCbcfA27A094073aE` | [View](https://sepolia.basescan.org/address/0x6e7F0a5c8a671E5BC316029cCbcfA27A094073aE) |
| LiquidationManager | `0xB17D986306401cbd34E25ecC38c7ec8e094B520c` | [View](https://sepolia.basescan.org/address/0xB17D986306401cbd34E25ecC38c7ec8e094B520c) |

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
- **Multiple positions per trader support**
- **Position ID-based management**

**OrderManager**
- Order routing and validation
- Execution coordination
- Order type management
- **Multiple position creation**

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
IOrderManager(orderManager).createMarketOrder(
    "USA",           // country
    0,               // direction (0=LONG, 1=SHORT)
    2               // leverage
    {value: 0.001 ether}
);
```

### Multiple Positions Management
```solidity
// Create multiple positions for the same trader
uint256 positionId1 = orderManager.createMarketOrder{value: 0.001 ether}("USA", 0, 2);
uint256 positionId2 = orderManager.createMarketOrder{value: 0.001 ether}("UK", 1, 3);
uint256 positionId3 = orderManager.createMarketOrder{value: 0.001 ether}("JP", 0, 1);

// Get all positions for a trader
(uint256[] memory positionIds, IPositionManager.Position[] memory positions) = 
    positionManager.getTraderPositions(trader);

// Get open positions count
uint256 openCount = positionManager.getOpenPositionsCount(trader);

// Close specific position by ID
positionManager.closePositionById(positionId2, exitPrice, false);
```

### TypeScript Integration
```typescript
import { useWriteContract } from 'wagmi';
import { parseEther } from 'viem';

// Execute market order
const { writeContractAsync } = useWriteContract();

await writeContractAsync({
  address: '0x369327Cb1f9E164A20215Bb12024108BdbE1c8E1',
  abi: orderManagerAbi,
  functionName: 'createMarketOrder',
  args: ['USA', 0, 2], // country, direction (0=LONG, 1=SHORT), leverage
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

