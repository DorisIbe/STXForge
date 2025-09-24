# STXForge - Stacks of Fortune

> A revolutionary proof-of-use STX mining game where players burn STX tokens to forge valuable artifacts and participate in an engaging on-chain economy.

[![Clarity](https://img.shields.io/badge/Clarity-Contract-purple)](https://clarity-lang.org/)
[![Stacks](https://img.shields.io/badge/Stacks-Blockchain-orange)](https://stacks.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## 🎯 Overview

STXForge is a fully on-chain strategy game that pioneers the "Proof-of-Use" model for cryptocurrency tokens. Players acquire virtual mining rigs as NFTs, mine for resources, and burn STX tokens to forge powerful artifacts. This creates a deflationary utility for STX while providing an engaging gaming experience.

### 🌟 Key Features

- **Proof-of-Use Mechanics**: STX burning is integral to gameplay, not just an economic afterthought
- **NFT Mining Rigs**: Unique mining equipment with different efficiency levels
- **Daily Mining**: Free resource gathering with 24-hour cooldowns
- **Artifact Forging**: Burn 5 STX + resources to create randomized artifact NFTs
- **Deep-Core Mining**: High-risk, high-reward mining for 50 STX with 80% success rate
- **Player Marketplace**: Trade artifacts directly with other players
- **Leaderboards**: Compete based on total STX burned (contribution to the ecosystem)
- **Rarity System**: Common, Rare, Epic, and Legendary artifacts with varying power levels

## 🎮 Game Mechanics

### Mining System

#### Basic Mining (Free)
- Perform once every 24 hours per mining rig
- Chance to find resources: Iron, Crystal, or Energy
- Success rate depends on rig efficiency
- No STX cost - purely time-gated

#### Deep-Core Mining (50 STX)
- High-stakes mining that burns 50 STX
- 80% success rate for rare artifacts
- Guaranteed rare, epic, or legendary rarity
- Higher artifact power levels (5-20)
- Bypasses resource requirement

### Forging System

#### Standard Forging (5 STX)
- Requires resources + 5 STX burn
- Creates randomized artifacts with varying rarities:
  - Common: 50% chance
  - Rare: 30% chance  
  - Epic: 15% chance
  - Legendary: 5% chance
- Artifact power: 1-10

#### Artifact Types
- **Weapons** (from Iron): Combat-focused artifacts
- **Magic** (from Crystal): Mystical artifacts with special properties
- **Tech** (from Energy): Technological artifacts

### Marketplace

- List artifacts for sale in STX
- Direct player-to-player trading
- Automatic ownership transfer on purchase
- Price discovery through free market

## 🏗️ Technical Architecture

### Smart Contract (`stx_forge.clar`)

The contract is built with Clarity and implements:

- **NFT-like functionality** for mining rigs and artifacts
- **STX burn mechanism** using provably unspendable address
- **Randomization system** using block height for fairness
- **Access controls** and admin functions
- **Event logging** for all major actions

### Key Functions

#### Public Functions
- `mint-basic-rig()` - Get your first mining rig (free)
- `mine(rig-id)` - Perform daily mining action
- `forge(resource-type, quantity)` - Burn STX to create artifacts
- `deep-core-mine(rig-id)` - High-stakes mining with STX burn
- `list-artifact-for-sale(artifact-id, price)` - List on marketplace
- `buy-artifact(listing-id)` - Purchase from marketplace

#### Read-Only Functions
- `get-player-stats(player)` - View player's game statistics
- `get-total-stx-burned()` - Total STX burned by all players
- `get-rig-data(rig-id)` / `get-artifact-data(artifact-id)` - NFT data
- `can-mine-now(rig-id)` - Check if mining cooldown is complete

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) for development
- [Node.js](https://nodejs.org/) for testing
- [Hiro Wallet](https://wallet.hiro.so/) for interaction

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd stx_forge
```

2. Install dependencies:
```bash
npm install
```

3. Check contract syntax:
```bash
clarinet check
```

4. Run tests:
```bash
npm test
```

### Deployment

#### Testnet Deployment
```bash
clarinet deploy --testnet
```

#### Mainnet Deployment
```bash
clarinet deploy --mainnet
```

## 🎯 Gameplay Guide

### For New Players

1. **Get Your First Rig**: Call `mint-basic-rig()` to receive a free basic mining rig
2. **Start Mining**: Use `mine(rig-id)` daily to collect resources
3. **Gather Resources**: Accumulate Iron, Crystal, and Energy over time
4. **Forge Your First Artifact**: Use `forge()` with 5 STX + resources

### Advanced Strategies

1. **Deep-Core Mining**: For players with more STX, deep-core mining offers better odds
2. **Marketplace Trading**: Buy low, sell high - create your artifact trading empire
3. **Leaderboard Climbing**: Burn more STX to climb the contribution leaderboards
4. **Resource Optimization**: Different resource types create different artifact categories

## 📊 Economics & Tokenomics

### STX Burn Mechanism

All burned STX is sent to: `SP000000000000000000002Q6VF78`

This is a provably unspendable address, meaning burned tokens are permanently removed from circulation.

#### Burn Amounts
- **Forging**: 5 STX per artifact
- **Deep-Core Mining**: 50 STX per attempt

#### Deflationary Impact
- Every game action requiring STX reduces total supply
- Creates utility-driven demand for STX tokens
- Aligns player enjoyment with ecosystem health

## 🔧 Development

### Contract Structure

```
contracts/
├── stx_forge.clar          # Main game contract
tests/
├── stx_forge.test.ts       # Contract tests
settings/
├── Devnet.toml            # Local development settings
├── Testnet.toml           # Testnet configuration  
└── Mainnet.toml           # Production settings
```

### Running Tests

```bash
npm test                    # Run all tests
npm run test:watch         # Watch mode
clarinet test              # Clarinet native tests
```

### Code Quality

The contract passes `clarinet check` with only minor warnings and implements:

- Proper error handling with descriptive error codes
- Access controls and authorization checks  
- Input validation and overflow protection
- Event logging for transparency
- Gas optimization techniques

## 🏆 Game Statistics

Track your progress with comprehensive statistics:

- **Total STX Burned**: Your contribution to the deflationary mechanism
- **Artifacts Forged**: Number of artifacts created
- **Mining Operations**: Successful mining attempts
- **Marketplace Activity**: Trading volume and transactions

## 🔒 Security Features

- **Access Controls**: Only rig/artifact owners can perform actions
- **Burn Address Verification**: Uses well-known unspendable address
- **Input Validation**: Prevents invalid operations and overflow attacks
- **Emergency Controls**: Admin pause functionality for critical issues
- **No Private Key Requirements**: Fully on-chain, trustless operation

## 🌐 Community & Ecosystem

### Contribution Opportunities

- **Game Balance**: Suggest improvements to probability tables
- **New Features**: Propose additional gameplay mechanics
- **UI/UX**: Build frontend interfaces for the game
- **Analytics**: Create dashboards for game statistics

### Governance (Future)

Plans for decentralized governance include:
- Community voting on game parameters
- Decentralized feature development funding
- Player-driven seasonal events and competitions

## 📈 Roadmap

### Phase 1: MVP ✅
- [x] Core mining and forging mechanics
- [x] Basic marketplace functionality
- [x] Player statistics tracking
- [x] STX burn implementation

### Phase 2: Enhancement (Planned)
- [ ] Advanced mining rig types
- [ ] Seasonal events and competitions
- [ ] Guild/team functionality
- [ ] Enhanced artifact utility

### Phase 3: Ecosystem (Future)
- [ ] Cross-game artifact usage
- [ ] DAO governance implementation
- [ ] Mobile app development
- [ ] Institutional partnerships

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Stacks Foundation** for the blockchain infrastructure
- **Hiro Systems** for development tools
- **Clarity Language** for smart contract capabilities
- **Community** for feedback and support

## 📞 Support & Contact

- **Issues**: [GitHub Issues](https://github.com/your-repo/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-repo/discussions)
- **Discord**: [Community Discord](#)
- **Twitter**: [@STXForge](#)

---

**⚡ Start your mining adventure today and help build the future of utility-driven cryptocurrency gaming! ⚡**

*Built with ❤️ on the Stacks blockchain*