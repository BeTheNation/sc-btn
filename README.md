## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

# Smart Contract - Prediction Market

A decentralized prediction trading platform built with Solidity and Foundry, deployed on Base Sepolia testnet. Users can open leveraged positions on country-based predictions using native ETH.

## 🏗️ Architecture

- **Smart Contract**: `PredictionMarket.sol` - Core trading logic with ETH-native operations
- **Framework**: Foundry for development, testing, and deployment
- **Network**: Base Sepolia (Chain ID: 84532)
- **Token**: Native ETH (no USDC/token dependencies)

## 📋 Prerequisites

Ensure you have the following installed:

```bash
# Foundry toolkit
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Verify installation
forge --version
cast --version
anvil --version
```

## 🚀 Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd sc-btn

# Install dependencies (OpenZeppelin contracts)
forge install
```

### 2. Environment Configuration

```bash
cp .env.example .env
```

Edit `.env` with your configuration:
```bash
# Base Sepolia RPC (get from Alchemy/Infura)
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
# or use public RPC: https://sepolia.base.org

# Your private key (for deployment)
PRIVATE_KEY=your_private_key_here

# Optional: Etherscan API key for verification
ETHERSCAN_API_KEY=your_etherscan_api_key
```

### 3. Build & Test

```bash
# Compile contracts
forge build

# Run tests
forge test

# Run tests with verbose output
forge test -vvv

# Generate gas report
forge test --gas-report
```

## 📄 Smart Contract Details

### PredictionMarket Contract

**Deployed Address**: `0x34662e1BE68A95141550c69c4aD7844EA2314b0D` (Base Sepolia)

**Key Features**:
- ✅ ETH-native operations (no token approvals needed)
- ✅ Leveraged position trading (1x to 10x)
- ✅ Automatic liquidation system
- ✅ Gas-optimized with custom errors
- ✅ OpenZeppelin security standards

**Main Functions**:
```solidity
// Open a leveraged position with ETH
function openPosition(string countryId, PositionDirection direction, uint8 leverage) 
    external payable returns (uint256 positionId)

// Close user's position
function closePosition(address sender) external

// Create limit order
function limitOrder(string countryId, uint8 leverage, uint256 entryPrice, PositionDirection direction) 
    external payable returns (address)

// View functions
function getPosition(string countryId, address trader) external view returns (Position memory)
function calculateLiquidation(address sender) external view returns (uint256)
```

## 🔧 Development Commands

### Building & Testing
```bash
# Clean build artifacts
forge clean

# Compile with optimization
forge build --optimize

# Run specific test file
forge test --match-path test/Position.t.sol

# Run tests with coverage
forge coverage

# Generate documentation
forge doc --build
```

### Local Development
```bash
# Start local Anvil node
anvil

# Deploy to local network
forge script script/Position.s.sol --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

# Interact with local contract
cast call <CONTRACT_ADDRESS> "CURRENT_PRICE()" --rpc-url http://localhost:8545
```

### Deployment

#### Deploy to Base Sepolia
```bash
# Deploy contract
forge script script/Position.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify

# Verify contract manually (if auto-verify fails)
forge verify-contract <CONTRACT_ADDRESS> src/Position.sol:PredictionMarket --chain-id 84532 --etherscan-api-key $ETHERSCAN_API_KEY
```

#### Deploy to Other Networks
```bash
# Deploy to Ethereum Mainnet
forge script script/Position.s.sol --rpc-url $MAINNET_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify

# Deploy to Polygon
forge script script/Position.s.sol --rpc-url $POLYGON_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

## 🧪 Testing

### Test Structure
```
test/
├── Position.t.sol          # Main contract tests
├── mocks/                  # Mock contracts for testing
└── utils/                  # Test utilities
```

### Test Commands
```bash
# Run all tests
forge test

# Run with different verbosity levels
forge test -v    # Show test results
forge test -vv   # Show test results + logs
forge test -vvv  # Show test results + logs + traces
forge test -vvvv # Show test results + logs + traces + debug info

# Test specific function
forge test --match-test testOpenPosition

# Test with gas reporting
forge test --gas-report

# Generate coverage report
forge coverage --report lcov
```

## 📊 Contract Interactions

### Using Cast (Command Line)
```bash
# Get current price
cast call $CONTRACT_ADDRESS "CURRENT_PRICE()" --rpc-url $BASE_SEPOLIA_RPC_URL

# Get user position
cast call $CONTRACT_ADDRESS "getPosition(string,address)" "USA" "0x742d35Cc6634C0532925a3b8D1e4d6f2c1c89c7B" --rpc-url $BASE_SEPOLIA_RPC_URL

# Open position (send 0.01 ETH)
cast send $CONTRACT_ADDRESS "openPosition(string,uint8,uint8)" "USA" 1 2 --value 0.01ether --private-key $PRIVATE_KEY --rpc-url $BASE_SEPOLIA_RPC_URL
```

### Using Forge Script
```solidity
// scripts/Interact.s.sol
contract InteractScript is Script {
    function run() external {
        vm.startBroadcast();
        
        PredictionMarket market = PredictionMarket(CONTRACT_ADDRESS);
        
        // Open position with 0.01 ETH, 2x leverage, LONG direction
        market.openPosition{value: 0.01 ether}("USA", PredictionMarket.PositionDirection.LONG, 2);
        
        vm.stopBroadcast();
    }
}
```

## 🔍 Verification & Debugging

### Contract Verification
```bash
# Verify on Base Sepolia
forge verify-contract 0x34662e1BE68A95141550c69c4aD7844EA2314b0D src/Position.sol:PredictionMarket --chain-id 84532 --etherscan-api-key $ETHERSCAN_API_KEY

# Check verification status
cast etherscan-source $CONTRACT_ADDRESS --chain base-sepolia
```

### Debugging
```bash
# Debug failed transaction
forge debug $TRANSACTION_HASH --rpc-url $BASE_SEPOLIA_RPC_URL

# Trace transaction
cast run $TRANSACTION_HASH --rpc-url $BASE_SEPOLIA_RPC_URL --debug
```

## 📁 Project Structure

```
sc-btn/
├── src/
│   └── Position.sol            # Main contract
├── test/
│   └── Position.t.sol          # Contract tests
├── script/
│   └── Position.s.sol          # Deployment script
├── lib/
│   ├── forge-std/              # Foundry standard library
│   └── openzeppelin-contracts/ # OpenZeppelin contracts
├── broadcast/                  # Deployment artifacts
├── cache/                      # Compiler cache
├── out/                        # Compiled contracts
├── .env                        # Environment variables
├── .env.example               # Environment template
├── foundry.toml               # Foundry configuration
└── README.md                  # This file
```

## 🔒 Security Considerations

- ✅ Uses OpenZeppelin 5.0+ security standards
- ✅ Implements ReentrancyGuard for state-changing functions
- ✅ Custom errors for gas efficiency
- ✅ Proper access controls and validation
- ✅ CEI (Checks-Effects-Interactions) pattern
- ✅ Integer overflow protection with Solidity 0.8.26+

## 🚨 Important Notes

1. **Testnet Only**: Currently deployed on Base Sepolia for testing
2. **ETH Native**: No token approvals needed - send ETH directly
3. **Gas Optimization**: Uses custom errors and packed structs
4. **Liquidation Risk**: Monitor positions to avoid liquidation
5. **Network Switching**: Ensure your wallet is on Base Sepolia

## 🔗 Useful Links

- [Foundry Documentation](https://book.getfoundry.sh/)
- [Base Sepolia Faucet](https://faucet.quicknode.com/base/sepolia)
- [Base Sepolia Explorer](https://sepolia.basescan.org/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/5.x/)
- [Solidity Documentation](https://docs.soliditylang.org/)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Run tests (`forge test`)
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Contract Address**: `0x34662e1BE68A95141550c69c4aD7844EA2314b0D`  
**Network**: Base Sepolia (84532)  
**Frontend**: [../Frontend-btn](../Frontend-btn)
