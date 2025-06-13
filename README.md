# PredictionMarket Contract

Simple leveraged trading on country predictions using ETH.

## Quick Start

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone and setup
git clone <repo>
cd sc-btn
forge install

# Test
forge test

# Build
forge build
```

## Contract

**Deployed on Base Sepolia**: `0xd321D80155A27A1344ab5703cDDefD2b0fAF92e5` (Upgradeable Proxy)  
**Implementation**: `0x53ec36A1Ab0027dCF6d9442aF42Fa43De6dAE702` ([View Code](https://sepolia.basescan.org/address/0x53ec36A1Ab0027dCF6d9442aF42Fa43De6dAE702#code))

> **Note**: Always use the proxy address above for interactions. The implementation address contains your actual contract code.

### Features
- Open LONG/SHORT positions with ETH
- 1x to 5x leverage
- Country-based predictions
- 0.3% transaction fee

### Functions
```solidity
// Open position with ETH
openPosition(countryId, direction, leverage) payable

// Close position
closePosition(sender)

// View position
getPosition()
```

## Usage

```bash
# Deploy
forge script script/Position.s.sol --rpc-url base_sepolia --broadcast

# Test locally
forge test -vv
```

## Example

```solidity
// Open LONG position on USA with 2x leverage
market.openPosition{value: 0.01 ether}("USA", PositionDirection.LONG, 2);

// Close position
market.closePosition(msg.sender);
```

**Entry Price**: 100 (fixed)  
**Current Price**: 120  
**Fee**: 30 basis points (0.3%)