#!/bin/bash

# 🦄 UNYKORN ECOSYSTEM DEPLOYMENT SCRIPT
# Complete 7-layer Web3 participation engine deployment

echo "🦄 =============================================="
echo "   UNYKORN ECOSYSTEM DEPLOYMENT STARTING"
echo "   Complete Web3 Participation Engine"
echo "============================================== 🦄"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if required environment variables are set
echo "🔧 Checking environment configuration..."

if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}❌ PRIVATE_KEY not set. Please export your deployer private key.${NC}"
    exit 1
fi

if [ -z "$RPC_URL" ]; then
    echo -e "${YELLOW}⚠️  RPC_URL not set. Using default localhost.${NC}"
    export RPC_URL="http://localhost:8545"
fi

echo -e "${GREEN}✅ Environment configuration OK${NC}"
echo "   Private Key: [HIDDEN]"
echo "   RPC URL: $RPC_URL"
echo ""

# Build the project
echo "🔨 Building Unykorn Ecosystem..."
forge build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed. Please check your contracts for compilation errors.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful${NC}"
echo ""

# Run deployment script
echo "🚀 Deploying Unykorn Ecosystem..."
echo "   This will deploy all 7 system contracts:"
echo "   1. UnykornToken (1T supply, POC/POI tracking)"
echo "   2. AssetVault (Multi-asset backing, leverage)"
echo "   3. RevVault (Revenue splitting, commerce)"
echo "   4. POCBeacons (Physical engagement network)"
echo "   5. SalesForceManager (MLM structure, packs)"
echo "   6. UnykornGovernance (DAO, multi-sig)"
echo "   7. LiquidityHelper (DEX integration, vesting)"
echo ""

forge script script/DeployUnykornEcosystem.s.sol \
    --rpc-url $RPC_URL \
    --broadcast \
    --verify \
    -vvvv

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 =============================================="
    echo "   UNYKORN ECOSYSTEM DEPLOYED SUCCESSFULLY!"
    echo "============================================== 🎉"
    echo ""
    echo -e "${GREEN}✅ All 7 system contracts deployed and configured${NC}"
    echo -e "${GREEN}✅ Inter-contract integrations established${NC}"
    echo -e "${GREEN}✅ Token allocations distributed${NC}"
    echo -e "${GREEN}✅ MLM commission structure activated${NC}"
    echo -e "${GREEN}✅ POC beacon network initialized${NC}"
    echo -e "${GREEN}✅ Governance multi-sig configured${NC}"
    echo -e "${GREEN}✅ Liquidity framework ready${NC}"
    echo ""
    echo -e "${BLUE}📊 IMMEDIATE CAPABILITIES:${NC}"
    echo "   💰 Pack Sales: $25/$50/$100 with instant token allocation"
    echo "   🎯 Commission System: 12-50% rates with MLM structure"
    echo "   📱 POC Check-ins: Daily rewards with streak bonuses"
    echo "   🏪 Commerce Integration: Revenue-sharing merchant partnerships"
    echo "   🔥 Token Burns: 2-5% deflationary pressure on all usage"
    echo "   🗳️  DAO Governance: Community parameter control"
    echo "   💧 DEX Liquidity: Automated market making ready"
    echo ""
    echo -e "${PURPLE}🚀 NEXT STEPS TO LAUNCH:${NC}"
    echo ""
    echo -e "${CYAN}1. LIQUIDITY LAUNCH${NC}"
    echo "   • Seed DEX liquidity pool (recommended: 10 ETH + 50M UNY)"
    echo "   • Activate team vesting schedules"
    echo "   • Enable auto-liquidity from pack sales"
    echo ""
    echo -e "${CYAN}2. POC BEACON DEPLOYMENT${NC}" 
    echo "   • Deploy beacons in 5-10 major cities"
    echo "   • Generate QR codes for easy scanning"
    echo "   • Set up GPS verification zones"
    echo ""
    echo -e "${CYAN}3. FOUNDING BROKER RECRUITMENT${NC}"
    echo "   • Target 25-50 founding brokers initially"
    echo "   • Each must recruit 10+ people for qualification"
    echo "   • Provide training materials and support"
    echo ""
    echo -e "${CYAN}4. MERCHANT PARTNERSHIPS${NC}"
    echo "   • Onboard 10-20 initial merchants"
    echo "   • Configure UNY payment options"
    echo "   • Set up revenue sharing agreements"
    echo ""
    echo -e "${CYAN}5. MARKETING CAMPAIGN${NC}"
    echo "   • Launch pack sales across all tiers"
    echo "   • Demonstrate POC system functionality"
    echo "   • Showcase asset vault backing"
    echo ""
    echo -e "${YELLOW}⚡ REVENUE PROJECTIONS:${NC}"
    echo "   Month 1: $25K pack sales (1000 members)"
    echo "   Month 3: $75K pack sales (3000 members)" 
    echo "   Month 6: $250K pack sales (10K members)"
    echo "   Year 1: $1M+ total ecosystem value"
    echo ""
    echo -e "${GREEN}📚 DOCUMENTATION:${NC}"
    echo "   • Complete system docs: UNYKORN_SYSTEM_DOCUMENTATION.md"
    echo "   • Contract addresses saved in deployment artifacts"
    echo "   • Integration guides available in /docs folder"
    echo ""
    echo -e "${PURPLE}🦄 Your Global Participation Engine is LIVE!${NC}"
    echo -e "${PURPLE}   Welcome to the future of tokenized engagement!${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}❌ Deployment failed. Check the error messages above.${NC}"
    echo ""
    echo -e "${YELLOW}Common issues and solutions:${NC}"
    echo "• Insufficient gas: Increase gas limit in forge.toml"  
    echo "• Network issues: Check RPC_URL connectivity"
    echo "• Permission denied: Verify PRIVATE_KEY has funds"
    echo "• Contract size: Enable via-ir in foundry.toml"
    echo ""
    echo "For support, check the documentation or create an issue."
    exit 1
fi

echo ""
echo "🦄 Unykorn Ecosystem - Built with ❤️ for global prosperity 🌍"
echo "   Repository: https://github.com/kevanbtc/bradleykizer"
echo "   Join the revolution: Your participation creates the future!"
echo ""