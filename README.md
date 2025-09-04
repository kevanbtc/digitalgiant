# Bradley Kizer Family Wealth System

## TEUCRIUM-Style Tokenized Commodity ETF Infrastructure

This repository contains a complete tokenized commodity fund system modeled after TEUCRIUM's ETF structure, built specifically for the Bradley Kizer family wealth management operation.

## 🎯 System Overview

The system enables the family to:
- Digitize physical asset custody receipts as NFTs
- Issue fungible unit tokens (grams/tons/credits) backed by receipts  
- Create investor fund shares with KYC/AML compliance
- Earn management fees and creation/redemption fees
- Provide transparent NAV and proof-of-reserves

## 🏗️ Architecture

### Core Components

1. **ReceiptNFT** - ERC-721 custody receipts for physical assets
2. **UnitToken** - ERC-20 fungible units (XAUg, CARBt, WTRc) backed by receipts
3. **KYCRegistry** - Investor compliance and partition management
4. **FamilyGovernance** - Multi-sig family roles and voting
5. **FundVault4626Enhanced** - ERC-4626 vaults with fee accrual
6. **FundShare1400Enhanced** - Partitioned fund shares (Reg D/S/Family/Institutional)

### Asset Flow

```
Physical Assets → Custody Receipt → Receipt NFT → Unit Tokens → Fund Vault → Fund Shares → Investors
```

## 💰 Revenue Model

- **Management Fees**: 0.75% annual on AUM
- **Creation Fees**: 0.10% per share creation
- **Redemption Fees**: 0.10% per share redemption
- **Collateral Yield**: Interest on idle cash/tokens

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js and npm (for additional tooling)

### Installation

```bash
git clone <this-repo>
cd bradley-kizer-wealth-system
forge install
```

### Deployment

1. Set up environment variables:
```bash
export PRIVATE_KEY="your_private_key"
export RPC_URL="your_rpc_url"
```

2. Update family addresses in `script/DeployKizerFamily.s.sol`:
```solidity
address constant BRADLEY_KIZER = 0x...;          // Family Head
address constant KIZER_TREASURER = 0x...;        // Treasurer  
address constant KIZER_TREASURY_WALLET = 0x...;  // Treasury
// ... etc
```

3. Deploy the system:
```bash
forge script script/DeployKizerFamily.s.sol --rpc-url $RPC_URL --broadcast
```

### Testing

```bash
forge test -vv
```

## 📊 Fund Types Supported

### Gold Fund (XAUg → KZR-GOLD)
- Unit: Grams of gold (3 decimals for milligrams)
- Custody: Brinks/Prosegur vault receipts
- Shares: KZR-XAU fund shares

### Carbon Fund (CARBt → KZR-CARB)  
- Unit: Tons of carbon credits (0 decimals)
- Custody: Registry transfer certificates
- Shares: KZR-CARB fund shares

### Water Fund (WTRc → KZR-WTR)
- Unit: Water rights credits (2 decimals)
- Custody: Deed/permit recordings
- Shares: KZR-WTR fund shares

## 👥 Investor Partitions

### Reg D (US Accredited)
- US accredited investors only
- Securities exemption under Regulation D
- KYC required with income/net worth verification

### Reg S (Offshore)
- Non-US persons only  
- Securities exemption under Regulation S
- Jurisdiction-based KYC requirements

### Family Partition
- Bradley Kizer family members
- Internal governance voting rights
- Higher investment limits

### Institutional
- Banks, funds, institutions
- Highest investment limits
- Enhanced due diligence

## 🔐 Security Features

- **Role-based access control** via OpenZeppelin AccessControl
- **Pausable emergency stops** on all major functions
- **KYC gating** on all transfers and investments
- **Proof-of-reserves** via IPFS custody documentation
- **Partition isolation** prevents cross-contamination of investor types
- **Family governance** with voting and multi-sig controls

## 🔄 Operational Flow

### 1. Asset Loading
```solidity
// Custodian mints receipt NFT after physical custody
receiptNFT.mintReceipt(
    familyVault,
    "GOLD",
    20000,  // 20kg = 20,000 grams
    "BRINKS_VAULT_NYC_001",
    "serial_12345",
    "ipfs_hash_of_assay_docs"
);
```

### 2. Unit Token Issuance
```solidity
// Vault mints unit tokens against receipt
goldUnitToken.mintFromReceipt(receiptId, familyVault);
// Result: 20,000,000 XAUg tokens (20kg * 1000g/kg * 1000mg/g)
```

### 3. Fund Share Creation
```solidity
// AP deposits unit tokens, gets fund shares
goldVault.deposit(unitTokens, investorAddress);
// Shares are partitioned based on investor KYC status
```

### 4. Fee Collection
```solidity
// Management fees accrue automatically
// Family collects fees to treasury wallet
goldVault.collectFees();
```

## 📈 Scaling Roadmap

### Phase 1: Pilot (0-6 months)
- Deploy 20kg gold fund
- 5-10 family office investors
- $1-5M AUM

### Phase 2: Diversified (6-18 months)  
- Add carbon and water rights
- White-label for allied families
- $25-50M AUM

### Phase 3: Institutional (18-36 months)
- Partner with ATS for liquidity
- Add commodity baskets
- $100-250M AUM

### Phase 4: Public Markets (36+ months)
- Apply for ETF status
- Compete with TEUCRIUM directly
- $500M-1B+ AUM

## 🧪 Testing Coverage

- Unit tests for all contracts
- Integration tests for full flows
- Fuzz testing for edge cases
- Gas optimization analysis

## 📝 License

MIT License - Open source infrastructure for family wealth management

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## 📞 Support

For deployment assistance or customization:
- Documentation: See `docs/` folder
- Examples: See `examples/` folder  
- Issues: GitHub Issues tracker

---

## ⚖️ Legal Disclaimers

This system is designed for compliance with:
- Securities regulations (Reg D/S exemptions)
- KYC/AML requirements
- Commodity trading regulations
- Family office governance standards

**Always consult legal and compliance experts before deployment.**

---

**Built with ❤️ for family wealth preservation and growth**