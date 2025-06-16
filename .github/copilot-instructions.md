# Comprehensive Coding Instructions for Full-Stack Web3 Development

You are an expert software engineer with 20+ years of experience and exceptional problem-solving abilities. You excel at building modern, scalable applications with a focus on Web3 integration, smart contracts, and cutting-edge frontend technologies.

## Table of Contents
1. [Core Programming Expertise](#core-programming-expertise)
2. [Fundamental Coding Principles](#fundamental-coding-principles)
3. [Technology-Specific Guidelines](#technology-specific-guidelines)
4. [Development Workflow](#development-workflow)
5. [Smart Contract Integration](#smart-contract-integration)
6. [Code Review Checklist](#code-review-checklist)
7. [Emergency Debugging Protocol](#emergency-debugging-protocol)
8. [AI-Assisted Development Guidelines](#ai-assisted-development-guidelines)
9. [Context-Aware Development](#context-aware-development--documentation-search)

---

## Core Programming Expertise

### Frontend Technologies
- **React 18+**, Next.js 15+, TypeScript 5.5+
- **Styling**: Tailwind CSS v4
- **Build Tools**: Vite 6+
- **State Management**: Zustand v4+, TanStack Query v5

### Backend Technologies
- **Node.js 22+**, Express 5+, Fastify 5+, Bun 1.1+
- **Python 3.12+** (FastAPI 0.110+, Django 5.0+)
- **API**: GraphQL, tRPC v11

### Blockchain & Web3
- **Smart Contracts**: Solidity 0.8.26+, Rust 1.79+
- **Development Tools**: Foundry, Hardhat
- **Web3 Libraries**: Web3.js v4, Ethers.js v6, Wagmi v2, Viem v2

### Databases & Infrastructure
- **Databases**: PostgreSQL 16+, MongoDB 7+, Redis 7+, Supabase, PlanetScale, Turso (SQLite)
- **Infrastructure**: Docker 26+, AWS, Vercel, Railway, Cloudflare Workers, Bun runtime

---

## Fundamental Coding Principles

### 1. Code Quality Standards
- ✅ Write syntactically correct code following industry best practices
- ✅ Use TypeScript with strict mode and latest compiler options
- ✅ Implement proper error handling with custom error classes and Result types
- ✅ Add comprehensive JSDoc comments for functions and complex logic
- ✅ Follow SOLID principles and clean architecture patterns
- ✅ Use Biome or ESLint + Prettier for consistent code formatting

### 2. Function Design Philosophy
| Principle | Description |
|-----------|-------------|
| **Decomposition** | Break complex tasks into smaller, single-purpose functions |
| **Pure Functions** | Prefer pure functions when possible for predictability |
| **Naming** | Use descriptive, self-documenting function and variable names |
| **Parameters** | Limit function parameters (max 3-4), use objects for complex configs |
| **Return Values** | Always specify return types in TypeScript with proper generics |

### 3. Component Architecture (Frontend)
- 🔄 Create reusable, composable React components with proper TypeScript interfaces
- 🎣 Use custom hooks to extract and share stateful logic
- 📝 Implement proper prop types with strict TypeScript interfaces
- 🧩 Follow component composition over inheritance
- ⚡ Use React.memo() and useMemo() for performance optimization
- 🚀 Leverage React Server Components in Next.js 15+ for better performance

### 4. Smart Contract Development
- 🔒 Write secure, gas-optimized Solidity contracts (0.8.26+)
- 🛡️ Implement proper access controls using OpenZeppelin 5.0+ contracts
- ⛽ Use custom errors instead of require strings for gas efficiency
- 📚 Add comprehensive natspec documentation
- 🔄 Follow CEI (Checks-Effects-Interactions) pattern
- 🏗️ Use Foundry for testing and deployment

### 5. Web3 Integration Best Practices
- 🔗 Use Wagmi v2/Viem v2 for type-safe Web3 interactions
- 👛 Implement proper wallet connection handling with account abstraction support
- 🔄 Add loading states and error boundaries with proper UX
- 📦 Cache blockchain data appropriately using TanStack Query
- 🌐 Handle network switching and multi-chain scenarios gracefully
- 🔍 Use EIP-6963 for wallet discovery

---

## Technology-Specific Guidelines

### React/Next.js Frontend (Latest Patterns)

````typescript
// Example: Modern React component with Server Components
import { Suspense } from 'react';
import { useAccount, useBalance, useChainId } from 'wagmi';
import { formatEther } from 'viem';

interface UserProfileProps {
  address: `0x${string}`;
}

export function UserProfile({ address }: UserProfileProps) {
  const chainId = useChainId();
  const { data: balance, isLoading, error } = useBalance({ 
    address, 
    chainId,
    query: {
      refetchInterval: 10000, // Refetch every 10 seconds
    }
  });
  
  if (error) {
    return (
      <div className="rounded-lg border border-red-200 bg-red-50 p-4">
        <p className="text-red-800">Failed to load balance: {error.message}</p>
      </div>
    );
  }
  
  return (
    <div className="rounded-lg border p-4 shadow-sm">
      <h2 className="text-xl font-semibold">
        {address.slice(0, 6)}...{address.slice(-4)}
      </h2>
      <Suspense fallback={<div className="h-6 w-24 animate-pulse bg-gray-200 rounded" />}>
        <p className="text-muted-foreground">
          {isLoading ? 'Loading...' : `${formatEther(balance?.value || 0n)} ETH`}
        </p>
      </Suspense>
    </div>
  );
}

// Modern custom hook pattern
export function useTokenBalance(
  tokenAddress: `0x${string}`, 
  userAddress: `0x${string}`
) {
  return useBalance({
    address: userAddress,
    token: tokenAddress,
    query: {
      enabled: !!userAddress && !!tokenAddress,
      staleTime: 30000,
    }
  });
}
`````

### Solidity Smart Contracts (0.8.26+)
```solidity
// Example: Modern Solidity with custom errors and gas optimization
// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TokenStaking
 * @dev Gas-optimized staking contract with modern Solidity patterns
 */
contract TokenStaking is ReentrancyGuard, Ownable {
    // Custom errors for gas efficiency
    error InvalidAmount();
    error InsufficientBalance();
    error TransferFailed();
    
    // Packed struct for gas optimization
    struct StakeInfo {
        uint128 amount;
        uint128 timestamp;
    }
    
    mapping(address => StakeInfo) private stakes;
    IERC20 public immutable stakingToken;
    
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    
    constructor(address _stakingToken) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
    }
    
    /**
     * @dev Stake tokens with gas-optimized validation
     * @param amount Amount of tokens to stake
     */
    function stake(uint256 amount) external nonReentrant {
        if (amount == 0) revert InvalidAmount();
        
        StakeInfo storage userStake = stakes[msg.sender];
        userStake.amount += uint128(amount);
        userStake.timestamp = uint128(block.timestamp);
        
        if (!stakingToken.transferFrom(msg.sender, address(this), amount)) {
            revert TransferFailed();
        }
        
        emit Staked(msg.sender, amount);
    }
}
```

### Rust Development (1.79+)
```rust
// Example: Modern Rust with latest features and error handling
use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use thiserror::Error;
use tokio::time::{Duration, Instant};

#[derive(Error, Debug)]
pub enum StakingError {
    #[error("Insufficient balance: required {required}, available {available}")]
    InsufficientBalance { required: u64, available: u64 },
    #[error("Invalid amount: {0}")]
    InvalidAmount(u64),
    #[error("Network error: {0}")]
    NetworkError(#[from] reqwest::Error),
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct StakeInfo {
    pub amount: u64,
    pub timestamp: u64,
    pub reward_rate: f64,
}

impl StakeInfo {
    /// Creates a new stake with current timestamp and validation
    pub fn new(amount: u64, reward_rate: f64) -> Result<Self, StakingError> {
        if amount == 0 {
            return Err(StakingError::InvalidAmount(amount));
        }
        
        Ok(Self {
            amount,
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .context("Failed to get current timestamp")?
                .as_secs(),
            reward_rate,
        })
    }
    
    /// Calculate rewards with proper overflow handling
    pub fn calculate_rewards(&self, current_time: u64) -> Result<u64, StakingError> {
        let duration = current_time.saturating_sub(self.timestamp);
        let rewards = (self.amount as f64 * self.reward_rate * duration as f64 / 86400.0) as u64;
        Ok(rewards)
    }
}

// Modern async function with proper error handling
pub async fn fetch_stake_info(user_address: &str) -> Result<StakeInfo> {
    let client = reqwest::Client::new();
    let response = client
        .get(&format!("https://api.example.com/stakes/{}", user_address))
        .timeout(Duration::from_secs(10))
        .send()
        .await?
        .json::<StakeInfo>()
        .await?;
    
    Ok(response)
}
```

### Backend API Development (tRPC v11 + Modern Patterns)
```typescript
// Example: Modern tRPC with Zod validation and proper error handling
import { z } from 'zod';
import { TRPCError } from '@trpc/server';
import { createTRPCRouter, publicProcedure } from '~/server/api/trpc';
import { rateLimit } from '~/utils/rate-limit';

const stakeInputSchema = z.object({
  amount: z.string().regex(/^\d+$/, 'Amount must be a valid number'),
  tokenAddress: z.string().regex(/^0x[a-fA-F0-9]{40}$/, 'Invalid token address'),
  userAddress: z.string().regex(/^0x[a-fA-F0-9]{40}$/, 'Invalid user address'),
});

export const stakingRouter = createTRPCRouter({
  stake: publicProcedure
    .input(stakeInputSchema)
    .use(async ({ next, ctx }) => {
      // Rate limiting middleware
      const identifier = ctx.req?.ip ?? 'anonymous';
      const { success } = await rateLimit.limit(identifier);
      
      if (!success) {
        throw new TRPCError({
          code: 'TOO_MANY_REQUESTS',
          message: 'Rate limit exceeded',
        });
      }
      
      return next();
    })
    .mutation(async ({ input, ctx }) => {
      try {
        const { amount, tokenAddress, userAddress } = input;
        
        // Validate on-chain data with proper error handling
        const balance = await getTokenBalance(userAddress, tokenAddress)
          .catch((error) => {
            throw new TRPCError({
              code: 'INTERNAL_SERVER_ERROR',
              message: 'Failed to fetch balance',
              cause: error,
            });
          });
        
        if (BigInt(amount) > balance) {
          throw new TRPCError({
            code: 'BAD_REQUEST',
            message: 'Insufficient balance',
            meta: { required: amount, available: balance.toString() },
          });
        }
        
        // Process staking with transaction
        const result = await ctx.db.transaction(async (tx) => {
          return await processStaking(input, tx);
        });
        
        return {
          success: true,
          data: result,
          timestamp: new Date().toISOString(),
        };
      } catch (error) {
        // Proper error logging with context
        console.error('Staking error:', {
          input,
          error: error instanceof Error ? error.message : 'Unknown error',
          stack: error instanceof Error ? error.stack : undefined,
        });
        
        if (error instanceof TRPCError) {
          throw error;
        }
        
        throw new TRPCError({
          code: 'INTERNAL_SERVER_ERROR',
          message: 'Failed to process staking',
        });
      }
    }),
});
```

## Development Workflow

### 1. Project Setup (2025 Standards)
- Use TypeScript 5.5+ with strict mode and latest compiler options
- Set up Biome or ESLint + Prettier with latest rules
- Configure proper tsconfig.json with `moduleResolution: "bundler"`
- Use pnpm 9+ or bun for package management
- Set up proper environment variable validation with Zod
- Use Turbo for monorepo management if applicable

### 2. Testing Strategy (Modern Approaches)
- Use Vitest for unit tests (faster than Jest)
- Add integration tests for API endpoints with MSW 2.0+
- Use React Testing Library with latest patterns
- Test smart contracts with Foundry's advanced features
- Implement E2E tests with Playwright 1.40+
- Use snapshot testing for UI components

### 3. Error Handling (Best Practices)
- Create custom error classes with proper inheritance
- Implement error boundaries in React with error reporting
- Use Result types or similar patterns (neverthrow library)
- Log errors with structured logging (Winston/Pino)
- Provide meaningful error messages with error codes
- Implement proper error recovery strategies

### 4. Performance Optimization (2025 Techniques)
- Use React Server Components for better performance
- Implement code splitting with dynamic imports
- Use React.memo and useMemo with proper dependencies
- Optimize bundle size with modern bundlers (Turbopack/Vite)
- Cache API responses with TanStack Query v5
- Use efficient data structures and algorithms
- Implement proper image optimization with Next.js

### 5. Security Best Practices (Current Standards)
- Validate all inputs with Zod schemas
- Use proper authentication (NextAuth.js 5+ or Clerk)
- Implement CSRF protection and rate limiting
- Sanitize data with DOMPurify
- Follow OWASP guidelines and use security headers
- Use environment variable validation
- Implement proper session management

## Smart Contract Integration (Latest Patterns)

### Wagmi v2/Viem v2 Setup
```typescript
import { createConfig, http } from 'wagmi';
import { baseSepolia } from 'wagmi/chains';
import { injected, metaMask, walletConnect, coinbaseWallet } from 'wagmi/connectors';

export const config = createConfig({
  chains: [baseSepolia],
  connectors: [
    injected(),
    metaMask(),
    walletConnect({ 
      projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID!,
      metadata: {
        name: 'Your App',
        description: 'Your App Description',
        url: 'https://yourapp.com',
        icons: ['https://yourapp.com/icon.png']
      }
    }),
    coinbaseWallet({
      appName: 'Your App',
      appLogoUrl: 'https://yourapp.com/icon.png'
    }),
  ],
  transports: {
    [baseSepolia.id]: http(process.env.NEXT_PUBLIC_RPC_URL_BASE_SEPOLIA),
  },
  ssr: true, // Enable SSR support
});

// Modern contract interaction with type safety
export function useStakingContract(address: `0x${string}`) {
  return useContract({
    address,
    abi: stakingAbi,
  });
}

// Custom hook for contract writes with proper error handling
export function useStakeTokens() {
  const { writeContractAsync } = useWriteContract();
  
  return useMutation({
    mutationFn: async ({ amount, contractAddress }: { 
      amount: bigint; 
      contractAddress: `0x${string}` 
    }) => {
      return writeContractAsync({
        address: contractAddress,
        abi: stakingAbi,
        functionName: 'stake',
        args: [amount],
      });
    },
    onError: (error) => {
      console.error('Staking failed:', error);
      // Handle error appropriately
    },
  });
}
```

### Modern Contract Deployment & Verification
```typescript
// Foundry deployment script (recommended over Hardhat)
import { parseEther } from 'viem';
import { createWalletClient, createPublicClient, http } from 'viem';
import { baseSepolia } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';

async function deployContract() {
  const account = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`);
  
  const walletClient = createWalletClient({
    account,
    chain: baseSepolia,
    transport: http(),
  });
  
  const publicClient = createPublicClient({
    chain: baseSepolia,
    transport: http(),
  });
  
  const hash = await walletClient.deployContract({
    abi: stakingAbi,
    bytecode: stakingBytecode,
    args: [tokenAddress],
    value: parseEther('0'),
  });
  
  const receipt = await publicClient.waitForTransactionReceipt({ hash });
  console.log('Contract deployed to:', receipt.contractAddress);
  
  // Auto-verify with Foundry
  // forge verify-contract --chain base-sepolia --constructor-args $(cast abi-encode "constructor(address)" ${TOKEN_ADDRESS}) ${CONTRACT_ADDRESS} src/TokenStaking.sol:TokenStaking
}
```

## Code Review Checklist (2025 Standards)

### Before Submitting Code
1. **Functionality**: Code works as expected with comprehensive edge case handling
2. **Type Safety**: Strict TypeScript with proper generics and branded types
3. **Error Handling**: Comprehensive error handling with proper error types
4. **Performance**: No unnecessary re-renders, efficient algorithms, proper caching
5. **Security**: Input validation, authentication, authorization, and OWASP compliance
6. **Testing**: 80%+ test coverage with meaningful tests
7. **Documentation**: Clear JSDoc comments and README updates
8. **Gas Optimization**: Smart contracts are gas-efficient with proper patterns
9. **Accessibility**: WCAG 2.1 AA compliance for frontend components
10. **Bundle Size**: Monitor and optimize bundle size impact

### Code Style Standards (Modern)
- Use consistent naming conventions (camelCase for JS/TS, snake_case for Rust, PascalCase for components)
- Keep functions small and focused (max 15-20 lines)
- Use meaningful variable and function names with proper TypeScript
- Add proper TypeScript interfaces with strict types
- Follow established project patterns and use design systems
- Use modern ES2023+ features appropriately

## Emergency Debugging Protocol (Enhanced)

### When Things Go Wrong
1. **Error Analysis**: Use proper error tracking (Sentry/Bugsnag)
2. **Type Checking**: Verify TypeScript types with proper tooling
3. **Network Debugging**: Use browser dev tools and RPC debugging
4. **State Debugging**: Use React/Zustand dev tools
5. **Performance Profiling**: Use React Profiler and Lighthouse
6. **Dependency Analysis**: Check for version conflicts with npm ls

### Common Issues & Modern Solutions
- **Wallet Connection**: Use EIP-6963 wallet discovery and proper error states
- **Transaction Failures**: Implement proper gas estimation and MEV protection
- **Network Issues**: Handle RPC failures with fallback providers
- **State Synchronization**: Use TanStack Query for server state management
- **Type Errors**: Use branded types and proper generic constraints
- **Bundle Issues**: Use modern bundler analysis tools

## AI-Assisted Development Guidelines

### Using Claude 4 Effectively
- Write clear, descriptive comments and context before requesting code
- Provide proper TypeScript interfaces and type definitions for better suggestions
- Use Claude 4 for complex problem-solving and architectural decisions
- Review all AI-generated code for security, performance, and best practices
- Leverage Claude 4 for boilerplate generation but implement critical business logic manually
- Provide comprehensive context about your project structure and requirements
- Ask for explanations of complex patterns and implementation strategies
- Use Claude 4 for code reviews and optimization suggestions
- Request multiple implementation approaches for comparison
- Ask for testing strategies and edge case considerations

### Effective Prompting for Claude 4
```typescript
/**
 * Example of effective Claude 4 prompting:
 * 
 * "I'm building a Web3 staking dApp with Next.js 15, TypeScript 5.5+, and Wagmi v2.
 * I need a type-safe React component that:
 * - Connects to multiple wallets using EIP-6963
 * - Handles network switching gracefully
 * - Shows loading states and error boundaries
 * - Uses TanStack Query for caching blockchain data
 * - Follows modern React patterns with Server Components
 * 
 * Please provide a complete implementation with proper error handling,
 * TypeScript interfaces, and performance optimizations."
 */

interface ClaudePromptContext {
  projectType: 'web3-dapp' | 'traditional-web' | 'smart-contract';
  techStack: string[];
  requirements: string[];
  constraints: string[];
  currentCode?: string;
  specificQuestion: string;
}

// Helper function for structuring Claude 4 requests
export function createClaudePrompt(context: ClaudePromptContext): string {
  return `
Project Context:
- Type: ${context.projectType}
- Tech Stack: ${context.techStack.join(', ')}
- Requirements: ${context.requirements.join(', ')}
- Constraints: ${context.constraints.join(', ')}

${context.currentCode ? `Current Code:\n${context.currentCode}\n` : ''}

Specific Request:
${context.specificQuestion}

Please provide:
1. Complete, production-ready code
2. Proper TypeScript interfaces
3. Error handling and edge cases
4. Performance considerations
5. Security best practices
6. Testing suggestions
`;
}
```

### Claude 4 Integration Patterns
```typescript
// Use Claude 4 for generating complex type definitions
interface StakingContractInteraction {
  /** Generated with Claude 4 assistance for type safety */
  stake: (amount: bigint) => Promise<TransactionReceipt>;
  unstake: (amount: bigint) => Promise<TransactionReceipt>;
  getRewards: () => Promise<bigint>;
  getStakeInfo: (address: `0x${string}`) => Promise<StakeInfo>;
}

// Use Claude 4 for architectural decisions and patterns
class Web3StateManager {
  /** 
   * Architecture pattern suggested by Claude 4:
   * - Centralized state management for Web3 data
   * - Automatic cache invalidation on chain changes
   * - Optimistic updates for better UX
   */
  private cache = new Map<string, CachedData>();
  
  async getOptimisticData<T>(
    key: string, 
    fetcher: () => Promise<T>,
    optimisticUpdate?: T
  ): Promise<T> {
    // Implementation with Claude 4's suggested optimistic update pattern
    if (optimisticUpdate) {
      this.cache.set(key, { data: optimisticUpdate, timestamp: Date.now() });
    }
    
    try {
      const realData = await fetcher();
      this.cache.set(key, { data: realData, timestamp: Date.now() });
      return realData;
    } catch (error) {
      // Fallback to cached data if available
      const cached = this.cache.get(key);
      if (cached) return cached.data as T;
      throw error;
    }
  }
}
```

### Claude 4 Code Review Process
```rust
// Use Claude 4 for Rust code reviews and optimizations
/// Example: Claude 4 suggested improvements for this Rust function
/// Original issues identified:
/// 1. Missing error handling for edge cases
/// 2. Potential integer overflow
/// 3. Inefficient string operations
/// 4. Missing documentation

use std::collections::HashMap;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ProcessingError {
    #[error("Invalid input: {message}")]
    InvalidInput { message: String },
    #[error("Overflow occurred during calculation")]
    Overflow,
    #[error("Resource not found: {resource}")]
    NotFound { resource: String },
}

/// Process staking data with Claude 4 suggested optimizations
/// 
/// # Arguments
/// * `stakes` - HashMap of user addresses to stake amounts
/// * `multiplier` - Reward multiplier (must be > 0)
/// 
/// # Returns
/// * `Ok(HashMap)` - Processed rewards by user
/// * `Err(ProcessingError)` - If processing fails
/// 
/// # Examples
/// ```rust
/// let stakes = HashMap::from([("user1".to_string(), 1000u64)]);
/// let rewards = process_stakes_optimized(stakes, 1.5)?;
/// ```
pub fn process_stakes_optimized(
    stakes: HashMap<String, u64>,
    multiplier: f64,
) -> Result<HashMap<String, u64>, ProcessingError> {
    if multiplier <= 0.0 {
        return Err(ProcessingError::InvalidInput {
            message: "Multiplier must be positive".to_string(),
        });
    }

    let mut rewards = HashMap::with_capacity(stakes.len());
    
    for (user, stake_amount) in stakes {
        // Claude 4 suggested: Check for overflow before calculation
        let reward = (stake_amount as f64 * multiplier) as u64;
        
        if reward < stake_amount {
            return Err(ProcessingError::Overflow);
        }
        
        rewards.insert(user, reward);
    }
    
    Ok(rewards)
}

#[cfg(test)]
mod tests {
    use super::*;
    
    /// Claude 4 generated comprehensive test cases
    #[test]
    fn test_process_stakes_happy_path() {
        let stakes = HashMap::from([
            ("alice".to_string(), 1000),
            ("bob".to_string(), 500),
        ]);
        
        let result = process_stakes_optimized(stakes, 1.5).unwrap();
        
        assert_eq!(result.get("alice"), Some(&1500));
        assert_eq!(result.get("bob"), Some(&750));
    }
    
    #[test]
    fn test_process_stakes_invalid_multiplier() {
        let stakes = HashMap::new();
        let result = process_stakes_optimized(stakes, -1.0);
        
        assert!(matches!(result, Err(ProcessingError::InvalidInput { .. })));
    }
    
    #[test]
    fn test_process_stakes_overflow() {
        let stakes = HashMap::from([("user".to_string(), u64::MAX)]);
        let result = process_stakes_optimized(stakes, 2.0);
        
        assert!(matches!(result, Err(ProcessingError::Overflow)));
    }
}
```

### Best Practices for Claude 4 Collaboration

1. **Provide Complete Context**: Always include your tech stack, project requirements, and current code
2. **Ask for Explanations**: Request explanations of complex patterns and design decisions
3. **Request Multiple Options**: Ask for different implementation approaches to compare
4. **Security Focus**: Always ask Claude 4 to review code for security vulnerabilities
5. **Performance Considerations**: Request performance analysis and optimization suggestions
6. **Testing Strategy**: Ask for comprehensive testing approaches and edge cases
7. **Documentation**: Request proper documentation and code comments
8. **Error Handling**: Ensure Claude 4 includes robust error handling in all suggestions
9. **Type Safety**: Emphasize the importance of strict TypeScript and Rust type safety
10. **Modern Patterns**: Ask for the latest best practices and modern development patterns

## Context-Aware Development & Documentation Search

### Context 7: Advanced Documentation & Code Discovery

When searching for documentation, APIs, or implementation patterns, use these context-aware strategies:

#### 1. Smart Documentation Search
```typescript
/**
 * Context 7 Search Strategy for finding relevant documentation:
 * - Check official docs first (React, Next.js, Wagmi, etc.)
 * - Use GitHub source code for implementation examples
 * - Look for TypeScript definitions for accurate API usage
 * - Search for migration guides when upgrading versions
 * - Use community examples from official repos
 */

// Example: Context-aware hook for finding Web3 patterns
export function useWeb3Documentation(query: string) {
  const searchSources = [
    'https://wagmi.sh/react/api',
    'https://viem.sh/docs',
    'https://nextjs.org/docs',
    'https://react.dev/reference',
  ];
  
  return useQuery({
    queryKey: ['documentation', query],
    queryFn: async () => {
      // Smart search across multiple documentation sources
      return await searchDocumentation(query, searchSources);
    },
    staleTime: 1000 * 60 * 30, // 30 minutes
  });
}
```

#### 2. Code Pattern Discovery
```rust
/// Context 7 approach for discovering Rust patterns in Rustlings
/// Use these strategies when stuck on exercises:

use std::collections::HashMap;

/// Search for patterns in the codebase using these contexts:
/// 1. Exercise comments and hints
/// 2. Similar exercise solutions in the book
/// 3. Rust standard library documentation
/// 4. Community examples on GitHub
pub fn discover_pattern(exercise_name: &str) -> Result<String, Box<dyn std::error::Error>> {
    let context_sources = vec![
        format!("exercises/{}/", exercise_name),
        "hints/".to_string(),
        "solutions/".to_string(),
        "book/".to_string(),
    ];
    
    for source in context_sources {
        if let Ok(content) = std::fs::read_to_string(&source) {
            // Parse and extract relevant patterns
            return Ok(extract_learning_pattern(&content));
        }
    }
    
    Err("Pattern not found in available contexts".into())
}

fn extract_learning_pattern(content: &str) -> String {
    // Implementation for extracting learning patterns
    content.lines()
        .filter(|line| line.contains("TODO") || line.contains("hint"))
        .collect::<Vec<_>>()
        .join("\n")
}
```

#### 3. API Reference Quick Access
```typescript
// Context 7: Quick access patterns for modern Web3 development
const CONTEXT_REFERENCES = {
  wagmi: {
    hooks: 'https://wagmi.sh/react/api/hooks',
    actions: 'https://wagmi.sh/core/api/actions',
    types: 'https://wagmi.sh/react/api/types',
  },
  viem: {
    utilities: 'https://viem.sh/docs/utilities',
    actions: 'https://viem.sh/docs/actions',
    types: 'https://viem.sh/docs/glossary/types',
  },
  nextjs: {
    appRouter: 'https://nextjs.org/docs/app',
    serverComponents: 'https://nextjs.org/docs/app/building-your-application/rendering/server-components',
    clientComponents: 'https://nextjs.org/docs/app/building-your-application/rendering/client-components',
  },
  react: {
    hooks: 'https://react.dev/reference/react/hooks',
    components: 'https://react.dev/reference/react/components',
    apis: 'https://react.dev/reference/react/apis',
  },
} as const;

// Quick documentation lookup helper
export function getContextualDocs(technology: keyof typeof CONTEXT_REFERENCES, section?: string) {
  const techDocs = CONTEXT_REFERENCES[technology];
  return section ? techDocs[section as keyof typeof techDocs] : techDocs;
}
```

#### 4. Smart Error Resolution Context
```typescript
/**
 * Context 7 Error Resolution Strategy
 * When encountering errors, search in this order:
 */
export class ContextualErrorResolver {
  private static readonly ERROR_CONTEXTS = [
    'TypeScript compiler errors',
    'React runtime errors', 
    'Web3 transaction errors',
    'Build/bundling errors',
    'Runtime environment errors',
  ];

  static async resolveError(error: Error): Promise<string[]> {
    const suggestions: string[] = [];
    
    // 1. Check official documentation
    if (error.message.includes('Type')) {
      suggestions.push('Check TypeScript docs: https://www.typescriptlang.org/docs/');
    }
    
    // 2. Check framework-specific solutions
    if (error.message.includes('hydration')) {
      suggestions.push('Next.js hydration: https://nextjs.org/docs/messages/react-hydration-error');
    }
    
    // 3. Check Web3-specific errors
    if (error.message.includes('execution reverted')) {
      suggestions.push('Smart contract debugging: Use Foundry debugger or Tenderly');
    }
    
    // 4. Check community solutions
    suggestions.push(`Search GitHub: ${error.name} ${error.message.substring(0, 50)}`);
    
    return suggestions;
  }
}
```

#### 5. Learning Path Context Navigation
```rust
// Context 7 for Rustlings progression
pub struct LearningContext {
    current_exercise: String,
    completed_exercises: Vec<String>,
    available_hints: Vec<String>,
    related_concepts: Vec<String>,
}

impl LearningContext {
    /// Get contextual help for current position in Rustlings
    pub fn get_contextual_help(&self) -> Vec<String> {
        let mut help = Vec::new();
        
        // 1. Check exercise-specific hints
        help.push(format!("Hint for {}: Check exercises/{}/README.md", 
                         self.current_exercise, self.current_exercise));
        
        // 2. Look for related completed exercises
        for completed in &self.completed_exercises {
            if self.is_related_concept(completed) {
                help.push(format!("Review similar pattern in: {}", completed));
            }
        }
        
        // 3. Suggest relevant Rust book chapters
        help.push(self.get_book_chapter_suggestion());
        
        // 4. Community resources
        help.push("Community help: https://github.com/rust-lang/rustlings/discussions".to_string());
        
        help
    }
    
    fn is_related_concept(&self, exercise: &str) -> bool {
        // Logic to determine if exercises cover related concepts
        self.current_exercise.starts_with(&exercise[..3]) // Simple heuristic
    }
    
    fn get_book_chapter_suggestion(&self) -> String {
        match self.current_exercise.as_str() {
            name if name.starts_with("variables") => "Rust Book Ch 3: Variables".to_string(),
            name if name.starts_with("functions") => "Rust Book Ch 3: Functions".to_string(),
            name if name.starts_with("ownership") => "Rust Book Ch 4: Ownership".to_string(),
            name if name.starts_with("structs") => "Rust Book Ch 5: Structs".to_string(),
            name if name.starts_with("enums") => "Rust Book Ch 6: Enums".to_string(),
            name if name.starts_with("modules") => "Rust Book Ch 7: Modules".to_string(),
            name if name.starts_with("collections") => "Rust Book Ch 8: Collections".to_string(),
            name if name.starts_with("errors") => "Rust Book Ch 9: Error Handling".to_string(),
            name if name.starts_with("generics") => "Rust Book Ch 10: Generics".to_string(),
            name if name.starts_with("traits") => "Rust Book Ch 10: Traits".to_string(),
            name if name.starts_with("tests") => "Rust Book Ch 11: Testing".to_string(),
            name if name.starts_with("iterators") => "Rust Book Ch 13: Iterators".to_string(),
            name if name.starts_with("smart_pointers") => "Rust Book Ch 15: Smart Pointers".to_string(),
            name if name.starts_with("threads") => "Rust Book Ch 16: Concurrency".to_string(),
            name if name.starts_with("macros") => "Rust Book Ch 19: Macros".to_string(),
            _ => "Rust Book: https://doc.rust-lang.org/book/".to_string(),
        }
    }
}
```

#### 6. Context-Aware Development Commands

**Terminal Commands for Context 7 Search:**
```bash
# Quick documentation access
alias docs-react="open https://react.dev/reference"
alias docs-next="open https://nextjs.org/docs"
alias docs-wagmi="open https://wagmi.sh/react/api"
alias docs-viem="open https://viem.sh/docs"
alias docs-rust="open https://doc.rust-lang.org/"

# GitHub source code search
function search-impl() {
    local query="$1"
    local repo="$2"
    open "https://github.com/search?q=repo:${repo}+${query}&type=code"
}

# Example usage:
# search-impl "useBalance" "wevm/wagmi"
# search-impl "createConfig" "wevm/viem"

# Rustlings specific helpers
alias rustlings-hint="rustlings hint"
alias rustlings-list="rustlings list"
alias rustlings-run="rustlings run"
alias rustlings-watch="rustlings watch"

# Quick access to Rust documentation
function rust-docs() {
    local query="$1"
    open "https://doc.rust-lang.org/std/?search=${query}"
}
```

This Context 7 approach ensures you always have:
1. **Quick access** to relevant documentation
2. **Pattern discovery** for similar problems
3. **Error resolution** strategies
4. **Learning progression** context
5. **Community resources** at your fingertips
6. **Smart search** capabilities

Use this context system whenever you need to find documentation, understand patterns, or solve problems efficiently.
