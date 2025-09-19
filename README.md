# DualFlow Treasury Management

**Automated cash flow optimization for business accounts**

DualFlow is a treasury management application that automatically optimizes fund positioning between business checking and investment accounts to maximize returns while ensuring operational liquidity.

## Overview

Most businesses keep excess cash in low-yield checking accounts to maintain liquidity for daily operations. DualFlow analyzes spending patterns, predicts upcoming bills, and automatically transfers funds between checking (2.5% APY) and investment accounts (5.0% APY) to optimize interest earnings without compromising cash flow needs.

## Core Features

### Automated Fund Positioning
- **Daily optimization decisions** at 7 PM analyzing next-day cash requirements
- **Bidirectional transfers** between checking and investment accounts based on predicted needs
- **Conservative approach** prioritizing operational liquidity over maximum returns

### Bill Prediction & Cash Flow Planning
- **Recurring bill detection** from transaction history using merchant identifiers
- **Monthly payment predictions** based on historical amounts and patterns
- **Safety buffers** to handle unexpected expenses and timing variations

### Interest Optimization
- **Daily compound interest calculations** on both account types
- **Monthly interest payouts** with complete audit trails
- **Performance tracking** comparing automated vs manual management

### Account Management
- **Target balance controls** for operational liquidity preferences
- **Manual override capabilities** for business changes and unexpected needs
- **Transfer decision explanations** with transparent reasoning for each optimization

### Credit Card Integration
- **Balance tracking** and payment scheduling
- **Spending categorization** and transaction history
- **Automated payment planning** integrated with cash flow predictions

## How It Works

### Daily Automation Schedule
- **7:00 PM** - Transfer decision algorithm runs
- **10:00 PM** - Same-day transfers complete (checking → investment)
- **7:00 AM** - Next-day transfers complete (investment → checking)
- **12:00 AM** - Daily compound interest calculations

### Transfer Logic
```
Required Tomorrow = Predicted Bills + User Target Balance + Safety Buffer

If Current Checking < Required Tomorrow:
    Transfer from Investment → Checking

If Current Checking > Required Tomorrow:
    Transfer from Checking → Investment
```

### Settlement Timing
- **Checking → Investment**: Same-day settlement (available 10 PM)
- **Investment → Checking**: Next-day settlement (available 7 AM following day)

## Technical Stack

- **Backend**: Elixir/Phoenix with PostgreSQL
- **Frontend**: React with TypeScript
- **Scheduling**: Oban for automated jobs
- **Containerization**: Docker
- **Database**: 11-table schema with complete audit trails

## Database Architecture

The application maintains comprehensive financial records including:
- Customer accounts and settings
- Daily account balance snapshots
- Transaction history with recurring bill detection
- Transfer decision audit trails
- Interest calculation and payment history
- Credit card balances and transactions

## Getting Started

### Prerequisites
- Elixir 1.14+
- Node.js 18+
- PostgreSQL 14+
- Docker (optional)

### Installation
```bash
# Clone repository
git clone https://github.com/your-org/dualflow-treasury.git
cd dualflow-treasury

# Backend setup
cd backend
mix deps.get
mix ecto.setup

# Frontend setup
cd ../frontend
npm install

# Start development servers
mix phx.server  # Backend on :4000
npm start       # Frontend on :3000
```

### Demo Data
The application includes pre-seeded demo accounts with 2-3 months of realistic business transaction history showcasing optimization opportunities.

## Key Benefits

- **Automated optimization** eliminates manual fund management decisions
- **Transparent decision-making** with clear explanations for every transfer
- **Risk mitigation** through conservative prediction algorithms and safety buffers
- **Compound interest maximization** through daily calculations and optimal fund positioning
- **Operational flexibility** with user-controlled target balances and manual overrides

## Security & Compliance

- Encrypted password storage with bcrypt
- Complete audit trails for all financial decisions
- Transaction-level logging with merchant identification
- User-controlled automation settings with manual override capabilities

---

**Note**: This is a demonstration application showcasing modern treasury management concepts and automated cash flow optimization algorithms.
