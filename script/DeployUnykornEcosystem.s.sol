// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/UnykornToken.sol";
import "../src/AssetVault.sol";
import "../src/RevVault.sol";
import "../src/POCBeacons.sol";
import "../src/SalesForceManager.sol";
import "../src/UnykornGovernance.sol";
import "../src/LiquidityHelper.sol";

/**
 * @title Deploy Unykorn Ecosystem - Complete System Deployment
 * @dev Deploys and configures the complete 7-layer Unykorn participation engine
 */
contract DeployUnykornEcosystem is Script {
    // Deployment addresses
    address public unykornToken;
    address public assetVault;
    address public revVault;
    address public pocBeacons;
    address public salesForceManager;
    address public unykornGovernance;
    address public liquidityHelper;
    
    // Configuration
    address public constant DEPLOYER = 0x742d35Cc6634C0532925a3b8D4F5F5A85fC56c5a;
    address public constant TREASURY = 0x742d35Cc6634C0532925a3b8D4F5F5A85fC56c5a;
    
    // Multi-sig signers for governance
    address[] public multiSigSigners = [
        0x742d35Cc6634C0532925a3b8D4F5F5A85fC56c5a,  // Bradley
        0x1234567890123456789012345678901234567890,  // Technical Lead
        0x0987654321098765432109876543210987654321   // Community Rep
    ];
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== UNYKORN ECOSYSTEM DEPLOYMENT ===");
        console.log("Deployer:", msg.sender);
        console.log("Chain ID:", block.chainid);
        console.log("Block Number:", block.number);
        console.log("");
        
        // 1. Deploy core token
        _deployUnykornToken();
        
        // 2. Deploy asset vault
        _deployAssetVault();
        
        // 3. Deploy revenue vault
        _deployRevVault();
        
        // 4. Deploy POC beacon network
        _deployPOCBeacons();
        
        // 5. Deploy sales force manager
        _deploySalesForceManager();
        
        // 6. Deploy governance system
        _deployGovernance();
        
        // 7. Deploy liquidity helper
        _deployLiquidityHelper();
        
        // 8. Configure system integration
        _configureSystemIntegration();
        
        // 9. Initialize launch parameters
        _initializeLaunchParameters();
        
        vm.stopBroadcast();
        
        // 10. Print deployment summary
        _printDeploymentSummary();
    }
    
    function _deployUnykornToken() internal {
        console.log("1. Deploying Unykorn Token...");
        
        unykornToken = address(new UnykornToken());
        console.log("   UnykornToken deployed at:", unykornToken);
        
        // Configure initial token parameters
        UnykornToken token = UnykornToken(unykornToken);
        token.setBurnRate(300); // 3% initial burn rate
        token.setDailyPOCReward(100 * 10**18); // 100 tokens per day
        
        console.log("   Initial supply:", token.totalSupply() / 10**18, "UNY");
        console.log("   Burn rate: 3%");
        console.log("   Daily POC reward: 100 UNY");
        console.log("");
    }
    
    function _deployAssetVault() internal {
        console.log("2. Deploying Asset Vault...");
        
        assetVault = address(new AssetVault());
        console.log("   AssetVault deployed at:", assetVault);
        
        // Configure vault parameters
        AssetVault vault = AssetVault(assetVault);
        
        // Set allocation targets: 40% stable, 20% BTC, 20% gold, 10% ETH, 10% RWA
        vault.updateAllocationTargets(4000, 2000, 2000, 1000, 1000, 500);
        
        console.log("   Target allocation: 40% Stable, 20% BTC, 20% Gold, 10% ETH, 10% RWA");
        console.log("   Rebalancing tolerance: 5%");
        console.log("");
    }
    
    function _deployRevVault() internal {
        console.log("3. Deploying Revenue Vault...");
        
        revVault = address(new RevVault(unykornToken));
        console.log("   RevVault deployed at:", revVault);
        
        // Configure revenue splitting
        RevVault vault = RevVault(revVault);
        vault.approveMerchant(DEPLOYER); // Approve deployer as first merchant
        
        console.log("   Default revenue split: 92% merchant, 8% commissions");
        console.log("   First merchant approved:", DEPLOYER);
        console.log("");
    }
    
    function _deployPOCBeacons() internal {
        console.log("4. Deploying POC Beacon Network...");
        
        pocBeacons = address(new POCBeacons(unykornToken));
        console.log("   POCBeacons deployed at:", pocBeacons);
        
        // Create initial beacon in major city
        POCBeacons beacons = POCBeacons(pocBeacons);
        
        // Create sample beacon in Times Square, NYC
        POCBeacons.InteractionMethod[] memory methods = new POCBeacons.InteractionMethod[](3);
        methods[0] = POCBeacons.InteractionMethod.QR_CODE;
        methods[1] = POCBeacons.InteractionMethod.NFC;
        methods[2] = POCBeacons.InteractionMethod.GPS;
        
        POCBeacons.BeaconLimits memory limits = POCBeacons.BeaconLimits({
            maxDailyInteractions: 5,
            cooldownPeriod: 300, // 5 minutes
            maxRadiusMeters: 100,
            requiresGPS: true,
            requiresSecondary: false
        });
        
        beacons.createBeacon(
            "Times Square Unykorn Hub",
            "Times Square, New York, NY",
            40758896,  // Latitude * 10^6
            -73985130, // Longitude * 10^6
            100,       // 100 meter radius
            25 * 10**18, // 25 UNY reward
            methods,
            "ipfs://QmTimesSquareBeacon",
            limits
        );
        
        console.log("   Sample beacon created: Times Square Hub");
        console.log("   Reward per interaction: 25 UNY");
        console.log("");
    }
    
    function _deploySalesForceManager() internal {
        console.log("5. Deploying Sales Force Manager...");
        
        salesForceManager = address(new SalesForceManager(unykornToken, assetVault));
        console.log("   SalesForceManager deployed at:", salesForceManager);
        
        // Configure pack pricing and commission rates
        SalesForceManager sfm = SalesForceManager(salesForceManager);
        
        // Update commission rates: 12% advocate, 50% hustler, 2% override, 5% founding bonus
        sfm.updateCommissionRates(1200, 5000, 200, 500);
        
        console.log("   Pack pricing: $25/$50/$100 (Starter/Growth/Pro)");
        console.log("   Commission rates: 12% Advocate, 50% Hustler, 2% Override");
        console.log("");
    }
    
    function _deployGovernance() internal {
        console.log("6. Deploying Governance System...");
        
        unykornGovernance = address(new UnykornGovernance(
            unykornToken,
            assetVault,
            revVault,
            salesForceManager,
            multiSigSigners,
            2 // Require 2 of 3 signatures
        ));
        console.log("   UnykornGovernance deployed at:", unykornGovernance);
        
        console.log("   Multi-sig signers: 3 total, 2 required");
        console.log("   Voting period: 7 days");
        console.log("   Timelock delay: 2 days");
        console.log("");
    }
    
    function _deployLiquidityHelper() internal {
        console.log("7. Deploying Liquidity Helper...");
        
        liquidityHelper = address(new LiquidityHelper(unykornToken));
        console.log("   LiquidityHelper deployed at:", liquidityHelper);
        
        // Add team members with allocations
        LiquidityHelper helper = LiquidityHelper(liquidityHelper);
        
        // Example team allocation (10% total, distributed among team)
        helper.addTeamMember(DEPLOYER, 5000, 365 days);  // 50% of team allocation
        helper.addTeamMember(multiSigSigners[1], 3000, 365 days); // 30% of team allocation  
        helper.addTeamMember(multiSigSigners[2], 2000, 365 days); // 20% of team allocation
        
        console.log("   Team allocation: 10% (90% to community)");
        console.log("   Vesting period: 365 days");
        console.log("");
    }
    
    function _configureSystemIntegration() internal {
        console.log("8. Configuring system integration...");
        
        // Grant roles for inter-contract communication
        UnykornToken token = UnykornToken(unykornToken);
        SalesForceManager sfm = SalesForceManager(salesForceManager);
        POCBeacons beacons = POCBeacons(pocBeacons);
        RevVault vault = RevVault(revVault);
        
        // Grant POC manager role to beacon contract
        token.grantRole(keccak256("POC_MANAGER_ROLE"), pocBeacons);
        
        // Grant sales force role to sales manager
        token.grantRole(keccak256("SALES_FORCE_ROLE"), salesForceManager);
        
        // Grant commission manager role to revenue vault
        vault.grantRole(keccak256("COMMISSION_MANAGER_ROLE"), salesForceManager);
        
        console.log("   Inter-contract roles configured");
        console.log("   Cross-system communication enabled");
        console.log("");
    }
    
    function _initializeLaunchParameters() internal {
        console.log("9. Initializing launch parameters...");
        
        UnykornToken token = UnykornToken(unykornToken);
        
        // Transfer tokens to various contracts for operations
        uint256 totalSupply = token.totalSupply();
        
        // Allocate tokens:
        // 40% to asset vault operations
        // 30% to sales force manager for pack rewards
        // 20% to POC beacon rewards
        // 10% to liquidity operations
        
        token.transfer(assetVault, totalSupply * 40 / 100);
        token.transfer(salesForceManager, totalSupply * 30 / 100);
        token.transfer(pocBeacons, totalSupply * 20 / 100);
        token.transfer(liquidityHelper, totalSupply * 10 / 100);
        
        console.log("   Token distribution completed:");
        console.log("   - Asset Vault: 40% (400B UNY)");
        console.log("   - Sales Force: 30% (300B UNY)");
        console.log("   - POC Rewards: 20% (200B UNY)");
        console.log("   - Liquidity Ops: 10% (100B UNY)");
        console.log("");
    }
    
    function _printDeploymentSummary() internal view {
        console.log("=== DEPLOYMENT SUMMARY ===");
        console.log("");
        console.log("🦄 UNYKORN ECOSYSTEM CONTRACTS:");
        console.log("UnykornToken:        ", unykornToken);
        console.log("AssetVault:          ", assetVault);
        console.log("RevVault:            ", revVault);
        console.log("POCBeacons:          ", pocBeacons);
        console.log("SalesForceManager:   ", salesForceManager);
        console.log("UnykornGovernance:   ", unykornGovernance);
        console.log("LiquidityHelper:     ", liquidityHelper);
        console.log("");
        
        console.log("📊 SYSTEM STATUS:");
        console.log("✅ Token Layer:       1T UNY supply, 3% burn rate, POC/POI tracking");
        console.log("✅ Asset Vault:       Multi-asset backing, 80% max LTV leverage");
        console.log("✅ Revenue Engine:    Auto-splitting, merchant integration ready");
        console.log("✅ POC Network:       Beacon network deployed, GPS verification");
        console.log("✅ Sales Force:       MLM structure, $25/$50/$100 packs, vesting");
        console.log("✅ Governance:        Multi-sig DAO, 7-day voting, 2-day timelock");
        console.log("✅ Liquidity:         DEX integration, team vesting, auto-seeding");
        console.log("");
        
        console.log("💰 IMMEDIATE REVENUE OPPORTUNITIES:");
        console.log("Pack Sales:           $25-$100 per entry (instant revenue)");
        console.log("Commission Structure: 12-50% direct + 2% overrides");
        console.log("Asset Vault:          Multi-asset appreciation + management fees");
        console.log("Token Burns:          Deflationary pressure from all utility usage");
        console.log("Commerce Revenue:     1-3% platform fees on merchant transactions");
        console.log("");
        
        console.log("🚀 NEXT STEPS:");
        console.log("1. Launch liquidity on DEX with initial token allocation");
        console.log("2. Deploy POC beacons in target cities (QR codes, NFC)");
        console.log("3. Recruit founding brokers (10 people each requirement)");
        console.log("4. Partner with merchants for UNY-powered commerce");
        console.log("5. Begin pack sales campaign across all tiers");
        console.log("6. Monitor burn rate and adjust based on usage patterns");
        console.log("");
        
        console.log("🏆 SUCCESS METRICS TO TRACK:");
        console.log("- Pack sales volume and tier distribution");
        console.log("- Daily POC check-ins and streak maintenance");
        console.log("- Token burn rate and circulating supply reduction");
        console.log("- Asset vault growth and diversification");
        console.log("- Commission distribution and member satisfaction");
        console.log("- Governance participation and proposal activity");
        console.log("");
        
        console.log("🦄 UNYKORN ECOSYSTEM DEPLOYED SUCCESSFULLY!");
        console.log("🌍 Ready for global participation engine launch!");
        console.log("💎 Your tokenized wealth revolution begins now!");
        console.log("");
        
        console.log("Repository: https://github.com/kevanbtc/bradleykizer");
        console.log("Documentation: UNYKORN_SYSTEM_DOCUMENTATION.md");
        console.log("Built with ❤️ for the Global Unykorn Community 🦄");
    }
}