# BeTheNation Smart Contracts

Modular prediction market smart contract system built with Foundry and deployed on Base Sepolia.

## 🚀 Live Contracts (Modular Architecture)

### Core System (Latest Deployment)
- **PositionManager**: [`0xA62F56b0BE223e60457f652f08DdEd7E173c1022`](https://sepolia.basescan.org/address/0xA62F56b0BE223e60457f652f08DdEd7E173c1022)
- **OrderManager**: [`0x30B9Ff7eC9Ca3d3f85044ae23A8E61cB1FFA32cB`](https://sepolia.basescan.org/address/0x30B9Ff7eC9Ca3d3f85044ae23A8E61cB1FFA32cB)
- **MarketOrderExecutor**: [`0x20af2912a5203B777fBEc7279F62d8c89b811b63`](https://sepolia.basescan.org/address/0x20af2912a5203B777fBEc7279F62d8c89b811b63)
- **LimitOrderManager**: [`0xc012801c5CFCD09447310aFA744edB5B570D48cC`](https://sepolia.basescan.org/address/0xc012801c5CFCD09447310aFA744edB5B570D48cC)
- **LiquidationManager**: [`0x3C75cBDEb7D6088Ab0E1A5BA310a40F67B8fF75C`](https://sepolia.basescan.org/address/0x3C75cBDEb7D6088Ab0E1A5BA310a40F67B8fF75C)

### Legacy Contract
- **PredictionMarket** (v1): [`0x4d1059715a072C21E5D56e881f6A9E1b9582F8d0`](https://sepolia.basescan.org/address/0x4d1059715a072c21e5d56e881f6a9e1b9582f8d0)

**Network**: Base Sepolia (Chain ID: 84532)  
**Status**: ✅ All contracts verified on BaseScan

## 🛠️ Development

### Setup
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install dependencies
forge install
```

### Commands
```bash
# Build contracts
forge build

# Run tests
forge test

# Format code
forge fmt

# Deploy modular system
forge script script/DeployModular.s.sol:DeployModular \
  --rpc-url $RPC_URL_BASE_SEPOLIA \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify

# Test market order flow
forge script script/TestMarketOrderFlow.s.sol:TestMarketOrderFlow \
  --rpc-url $RPC_URL_BASE_SEPOLIA \
  --private-key $PRIVATE_KEY \
  --broadcast

# Test complete flow
forge script script/TestCompleteFlow.s.sol:TestCompleteFlow \
  --rpc-url $RPC_URL_BASE_SEPOLIA \
  --private-key $PRIVATE_KEY \
  --broadcast
```

### Environment
Create `.env`:
```bash
RPC_URL_BASE_SEPOLIA=https://sepolia.base.org
PRIVATE_KEY=0x...
BASESCAN_API_KEY=...
```

## 📁 Structure
```
src/                          # Smart contracts
├── PositionManager.sol       # Core position management
├── OrderManager.sol          # Order routing and management
├── MarketOrderExecutor.sol   # Market order execution
├── LimitOrderManager.sol     # Limit order management
├── LiquidationManager.sol    # Position liquidation
└── interfaces/               # Contract interfaces
    ├── IPositionManager.sol
    ├── IOrderManager.sol
    ├── IMarketOrderExecutor.sol
    ├── ILimitOrderManager.sol
    └── ILiquidationManager.sol

test/                         # Test files  
├── ModularContract.t.sol     # Unit tests

script/                       # Deployment scripts
├── DeployModular.s.sol       # Deploy modular system
├── TestMarketOrderFlow.s.sol # Test market orders
└── TestCompleteFlow.s.sol    # Test complete flow

lib/                          # Dependencies
└── forge-std/                # Foundry standard library
```

## 🏗️ Architecture

The system uses a modular architecture for better maintainability and gas optimization:

### Core Components
1. **PositionManager**: Manages position lifecycle, collateral, and state
2. **OrderManager**: Routes orders to appropriate executors
3. **MarketOrderExecutor**: Handles immediate market order execution
4. **LimitOrderManager**: Manages pending limit orders
5. **LiquidationManager**: Handles position liquidations

### Features
- ✅ Market orders with instant execution
- ✅ Limit orders with automated execution
- ✅ Position liquidation system
- ✅ Modular, upgradeable architecture
- ✅ Gas-optimized operations
- ✅ Comprehensive testing suite

## 🔗 Links
- [Foundry Docs](https://book.getfoundry.sh/)
- [Base Docs](https://docs.base.org/)
- [PositionManager on BaseScan](https://sepolia.basescan.org/address/0xA62F56b0BE223e60457f652f08DdEd7E173c1022)
- [OrderManager on BaseScan](https://sepolia.basescan.org/address/0x30B9Ff7eC9Ca3d3f85044ae23A8E61cB1FFA32cB)
- [Legacy Contract on BaseScan](https://sepolia.basescan.org/address/0x4d1059715a072c21e5d56e881f6a9e1b9582f8d0)

## 🧪 Testing

The system includes comprehensive testing:

```bash
# Run all tests
forge test

# Run specific test
forge test --match-contract ModularContract

# Run with verbosity
forge test -vvv

# Test coverage
forge coverage
```

### Test Scripts
- `TestMarketOrderFlow.s.sol`: Tests market order execution (✅ Verified on testnet)
- `TestCompleteFlow.s.sol`: Tests complete system functionality
- `ModularContract.t.sol`: Unit tests for all components

## 📊 Recent Activity

**Latest Deployment (Base Sepolia)**:
- Successfully deployed modular system with 5 contracts
- Executed market order flow with 0.00001 ETH
- All transactions verified on-chain
- Total gas cost: ~0.0000002 ETH for complete test flow
