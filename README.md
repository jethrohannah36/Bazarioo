# 🏪 Bazario - Token-Gated Local Marketplace DAO

A decentralized marketplace smart contract built on Stacks that enables token-gated communities to buy and sell goods locally with built-in DAO governance.

## ✨ Features

- 🔐 **Token-Gated Access**: Members must pay to join the marketplace
- 🛍️ **Local Marketplace**: Create and manage product listings
- 💰 **Secure Transactions**: Built-in escrow and fee system
- 🗳️ **DAO Governance**: Community voting on proposals
- ⭐ **Reputation System**: Build trust through successful transactions
- 📊 **Analytics**: Track member activity and marketplace metrics

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Stacks CLI](https://docs.stacks.co/docs/write-smart-contracts/clarinet) configured

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install
   ```
3. Run tests:
   ```bash
   clarinet test
   ```

## 📋 Usage

### 🎯 Joining the Marketplace

To become a member and access the marketplace:

```clarity
(contract-call? .Bazario join-marketplace)
```

**Cost**: 1 STX (default membership fee)

### 🏷️ Creating Listings

Create a new product listing:

```clarity
(contract-call? .Bazario create-listing 
  "Vintage Bike" 
  "Great condition vintage bike for sale" 
  u5000000 
  "vehicles")
```

**Parameters**:
- `title`: Product name (max 100 chars)
- `description`: Product details (max 500 chars)  
- `price`: Price in microSTX
- `category`: Product category (max 50 chars)

**Cost**: 0.1 STX listing fee

### 🛒 Purchasing Items

Buy a listed item:

```clarity
(contract-call? .Bazario purchase-item u1)
```

**Parameters**:
- `listing-id`: ID of the listing to purchase

**Fees**: 2.5% platform fee deducted from payment

### 🗳️ DAO Governance

#### Create Proposals

```clarity
(contract-call? .Bazario create-proposal 
  "Reduce Platform Fee" 
  "Proposal to reduce platform fee from 2.5% to 2%" 
  "fee-change")
```

#### Vote on Proposals

```clarity
(contract-call? .Bazario vote-proposal u1 true)
```

**Parameters**:
- `proposal-id`: ID of the proposal
- `vote-for`: `true` for yes, `false` for no

**Voting Power**: Based on member reputation points

### 📊 Managing Listings

Toggle listing availability:

```clarity
(contract-call? .Bazario update-listing-availability u1 false)
```

## 🔍 Read-Only Functions

### Get Listing Details
```clarity
(contract-call? .Bazario get-listing u1)
```

### Check Membership Status
```clarity
(contract-call? .Bazario get-member-status 'SP1ABC...)
```

### View Member Reputation
```clarity
(contract-call? .Bazario get-member-reputation 'SP1ABC...)
```

### Get Proposal Details
```clarity
(contract-call? .Bazario get-proposal u1)
```

### View Marketplace Stats
```clarity
(contract-call? .Bazario get-total-members)
(contract-call? .Bazario get-contract-balance)
```

## ⚙️ Admin Functions

### Update Fees (Owner Only)

```clarity
(contract-call? .Bazario set-membership-fee u2000000)
(contract-call? .Bazario set-listing-fee u200000)
(contract-call? .Bazario set-platform-fee u300)
```

### Withdraw Funds (Owner Only)

```clarity
(contract-call? .Bazario withdraw-funds u1000000)
```

## 🏗️ Contract Architecture

### 💾 Data Storage

- **Members**: Mapping of principals to membership status
- **Listings**: Product listings with metadata and availability
- **Purchases**: Transaction history and buyer information
- **Proposals**: DAO governance proposals and voting data
- **Reputation**: Member reputation scores and activity tracking

### 🔒 Security Features

- Membership verification for all marketplace actions
- Owner-only admin functions
- Escrow system for secure transactions
- Reputation-based voting power
- Anti-double-voting protection

## 📈 Economic Model

### 💰 Fee Structure

- **Membership Fee**: 1 STX (configurable)
- **Listing Fee**: 0.1 STX (configurable)
- **Platform Fee**: 2.5% of transaction (configurable, max 10%)

### 🎯 Reputation System

- New members start with 100 reputation points
- Sellers gain 10 points per successful sale
- Reputation determines voting power in DAO proposals

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Submit a pull request

## 📄 License

MIT License

## 🛠️ Development

### Testing

```bash
clarinet test
```

### Local Development

```bash
clarinet console
```

### Deployment

```bash
clarinet deploy
```

---

