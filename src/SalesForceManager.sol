// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./UnykornToken.sol";
import "./AssetVault.sol";

/**
 * @title Sales Force Manager - MLM-like Hierarchical Recruitment and Commission System
 * @dev Manages Founding Brokers, Hustlers, Advocates with progressive token allocations and vesting
 */
contract SalesForceManager is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FOUNDING_BROKER_ROLE = keccak256("FOUNDING_BROKER_ROLE");
    bytes32 public constant HUSTLER_ROLE = keccak256("HUSTLER_ROLE");
    bytes32 public constant ADVOCATE_ROLE = keccak256("ADVOCATE_ROLE");
    
    UnykornToken public unykornToken;
    AssetVault public assetVault;
    
    // Pack tiers and pricing
    enum PackTier {
        STARTER,    // $25 - Basic entry level
        GROWTH,     // $50 - Enhanced allocation  
        PRO         // $100 - Maximum benefits
    }
    
    // Role hierarchy
    enum SalesRole {
        ADVOCATE,       // Entry level - 10-12% commissions
        HUSTLER,        // Mid level - 50% token commissions (vested)
        FOUNDING_BROKER // Top level - Must bring 10 people each
    }
    
    // Pack configuration
    struct PackConfig {
        PackTier tier;
        uint256 price;              // Price in wei
        uint256 tokenAllocation;    // Tokens allocated
        uint256 lockPeriod;         // Vesting/lock period in seconds
        uint256 assetVaultShare;    // Percentage going to asset vault
        uint256 liquidityShare;     // Percentage for liquidity
        uint256 commissionPool;     // Percentage for commissions
        bool active;
    }
    
    // Member information
    struct Member {
        address wallet;
        SalesRole role;
        address upline;             // Direct upline
        address[] downline;         // Direct downline
        PackTier currentPack;
        uint256 joinDate;
        uint256 totalInvested;
        uint256 totalTokensEarned;
        uint256 totalCommissionsEarned;
        uint256 teamSize;           // Total downline size
        uint256 teamVolume;         // Total team investment volume
        uint256 personalVolume;     // Personal investment volume
        bool foundingBrokerQualified; // Brought 10+ people
        uint256 lockReleaseDate;    // When tokens unlock
        uint256 vestedTokens;       // Tokens available for claim
    }
    
    // Commission structure
    struct CommissionRates {
        uint256 advocateDirectRate;     // 10-12% for advocates
        uint256 hustlerDirectRate;      // 50% for hustlers (vested)
        uint256 teamOverrideRate;       // 2% team override
        uint256 foundingBrokerBonus;    // Bonus for founding brokers
        uint256 vestingPeriod;          // Vesting period for commissions
    }
    
    // Purchase record
    struct Purchase {
        uint256 purchaseId;
        address buyer;
        PackTier tier;
        uint256 amount;
        uint256 tokensAllocated;
        uint256 timestamp;
        bool processed;
        address referrer;
    }
    
    // State variables
    mapping(PackTier => PackConfig) public packConfigs;
    mapping(address => Member) public members;
    mapping(uint256 => Purchase) public purchases;
    mapping(address => uint256[]) public memberPurchases;
    mapping(address => uint256) public pendingCommissions;
    mapping(address => uint256) public claimableTokens;
    
    uint256 public purchaseCount;
    uint256 public totalMembers;
    uint256 public totalSalesVolume;
    uint256 public totalCommissionsPaid;
    
    CommissionRates public commissionRates;
    
    // Founding broker requirements
    uint256 public foundingBrokerMinRecruits = 10;
    uint256 public foundingBrokerMinVolume = 1000 * 10**18; // $1000 equivalent
    
    // Events
    event PackPurchased(
        uint256 indexed purchaseId,
        address indexed buyer,
        PackTier tier,
        uint256 amount,
        address referrer
    );
    event MemberJoined(address indexed member, SalesRole role, address upline);
    event CommissionPaid(address indexed recipient, uint256 amount, string commissionType);
    event RoleUpgraded(address indexed member, SalesRole oldRole, SalesRole newRole);
    event TokensVested(address indexed member, uint256 amount);
    event FoundingBrokerQualified(address indexed broker, uint256 teamSize);
    
    constructor(address _unykornToken, address _assetVault) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        
        unykornToken = UnykornToken(_unykornToken);
        assetVault = AssetVault(_assetVault);
        
        // Initialize pack configurations
        _initializePackConfigs();
        
        // Initialize commission rates
        commissionRates = CommissionRates({
            advocateDirectRate: 1200,       // 12%
            hustlerDirectRate: 5000,        // 50%
            teamOverrideRate: 200,          // 2%
            foundingBrokerBonus: 500,       // 5%
            vestingPeriod: 90 days          // 90 day vesting
        });
    }
    
    /**
     * @dev Initialize pack configurations
     */
    function _initializePackConfigs() internal {
        // Starter Pack - $25
        packConfigs[PackTier.STARTER] = PackConfig({
            tier: PackTier.STARTER,
            price: 25 * 10**18,             // $25
            tokenAllocation: 10000 * 10**18, // 10,000 tokens
            lockPeriod: 60 days,            // 60 day lock
            assetVaultShare: 4000,          // 40% to vault
            liquidityShare: 3000,           // 30% to liquidity
            commissionPool: 2500,           // 25% for commissions
            active: true
        });
        
        // Growth Pack - $50  
        packConfigs[PackTier.GROWTH] = PackConfig({
            tier: PackTier.GROWTH,
            price: 50 * 10**18,             // $50
            tokenAllocation: 25000 * 10**18, // 25,000 tokens
            lockPeriod: 75 days,            // 75 day lock
            assetVaultShare: 4500,          // 45% to vault
            liquidityShare: 2500,           // 25% to liquidity  
            commissionPool: 2500,           // 25% for commissions
            active: true
        });
        
        // Pro Pack - $100
        packConfigs[PackTier.PRO] = PackConfig({
            tier: PackTier.PRO,
            price: 100 * 10**18,            // $100
            tokenAllocation: 60000 * 10**18, // 60,000 tokens
            lockPeriod: 90 days,            // 90 day lock
            assetVaultShare: 5000,          // 50% to vault
            liquidityShare: 2000,           // 20% to liquidity
            commissionPool: 2500,           // 25% for commissions
            active: true
        });
    }
    
    /**
     * @dev Purchase pack and join sales force
     */
    function purchasePack(
        PackTier tier,
        address referrer
    ) external payable nonReentrant whenNotPaused {
        PackConfig memory pack = packConfigs[tier];
        require(pack.active, "Pack not available");
        require(msg.value >= pack.price, "Insufficient payment");
        
        // Validate referrer
        if (referrer != address(0)) {
            require(members[referrer].wallet != address(0), "Invalid referrer");
        }
        
        uint256 purchaseId = purchaseCount++;
        
        // Create purchase record
        purchases[purchaseId] = Purchase({
            purchaseId: purchaseId,
            buyer: msg.sender,
            tier: tier,
            amount: msg.value,
            tokensAllocated: pack.tokenAllocation,
            timestamp: block.timestamp,
            processed: false,
            referrer: referrer
        });
        
        memberPurchases[msg.sender].push(purchaseId);
        
        // Initialize or update member
        _initializeOrUpdateMember(msg.sender, tier, referrer, pack);
        
        // Process purchase distribution
        _processPurchaseDistribution(purchaseId, pack);
        
        // Process commissions
        _processCommissions(purchaseId, msg.value, referrer);
        
        purchases[purchaseId].processed = true;
        totalSalesVolume += msg.value;
        
        // Refund excess payment
        if (msg.value > pack.price) {
            payable(msg.sender).transfer(msg.value - pack.price);
        }
        
        emit PackPurchased(purchaseId, msg.sender, tier, msg.value, referrer);
    }
    
    /**
     * @dev Initialize or update member information
     */
    function _initializeOrUpdateMember(
        address memberAddress,
        PackTier tier,
        address referrer,
        PackConfig memory pack
    ) internal {
        Member storage member = members[memberAddress];
        
        if (member.wallet == address(0)) {
            // New member
            member.wallet = memberAddress;
            member.role = SalesRole.ADVOCATE; // Start as advocate
            member.upline = referrer;
            member.currentPack = tier;
            member.joinDate = block.timestamp;
            member.lockReleaseDate = block.timestamp + pack.lockPeriod;
            
            totalMembers++;
            
            // Add to upline's downline
            if (referrer != address(0)) {
                members[referrer].downline.push(memberAddress);
                _updateTeamSizes(referrer);
            }
            
            // Set up token contract relationships
            if (referrer != address(0)) {
                unykornToken.setUpline(memberAddress, referrer);
            }
            
            // Grant appropriate role
            _grantRole(ADVOCATE_ROLE, memberAddress);
            
            emit MemberJoined(memberAddress, SalesRole.ADVOCATE, referrer);
        } else {
            // Existing member - upgrade pack
            if (tier > member.currentPack) {
                member.currentPack = tier;
                // Extend lock period if new pack has longer lock
                uint256 newLockDate = block.timestamp + pack.lockPeriod;
                if (newLockDate > member.lockReleaseDate) {
                    member.lockReleaseDate = newLockDate;
                }
            }
        }
        
        // Update investment tracking
        member.totalInvested += pack.price;
        member.personalVolume += pack.price;
        
        // Add vested tokens (will be claimable after lock period)
        member.vestedTokens += pack.tokenAllocation;
        claimableTokens[memberAddress] += pack.tokenAllocation;
        
        // Check for role upgrades
        _checkRoleUpgrade(memberAddress);
    }
    
    /**
     * @dev Process purchase distribution to vault and liquidity
     */
    function _processPurchaseDistribution(
        uint256 purchaseId,
        PackConfig memory pack
    ) internal {
        uint256 totalAmount = purchases[purchaseId].amount;
        
        // Asset vault allocation
        uint256 vaultAmount = (totalAmount * pack.assetVaultShare) / 10000;
        if (vaultAmount > 0) {
            // In production, would call assetVault.depositAsset()
            // For now, send ETH to vault contract
            payable(address(assetVault)).transfer(vaultAmount);
        }
        
        // Liquidity allocation - keep in contract for DEX seeding
        uint256 liquidityAmount = (totalAmount * pack.liquidityShare) / 10000;
        // Liquidity funds stay in contract for DEX operations
        
        // Remaining goes to commission pool and operations
    }
    
    /**
     * @dev Process commission payments
     */
    function _processCommissions(
        uint256 purchaseId,
        uint256 amount,
        address referrer
    ) internal {
        Purchase memory purchase = purchases[purchaseId];
        PackConfig memory pack = packConfigs[purchase.tier];
        
        uint256 commissionPool = (amount * pack.commissionPool) / 10000;
        uint256 remainingPool = commissionPool;
        
        // Direct commission to referrer
        if (referrer != address(0)) {
            Member memory referrerMember = members[referrer];
            uint256 directRate = referrerMember.role == SalesRole.HUSTLER 
                ? commissionRates.hustlerDirectRate 
                : commissionRates.advocateDirectRate;
            
            uint256 directCommission = (amount * directRate) / 10000;
            if (directCommission <= remainingPool) {
                if (referrerMember.role == SalesRole.HUSTLER) {
                    // Hustler commissions are vested
                    pendingCommissions[referrer] += directCommission;
                } else {
                    // Advocate commissions are immediate
                    payable(referrer).transfer(directCommission);
                    members[referrer].totalCommissionsEarned += directCommission;
                }
                
                remainingPool -= directCommission;
                totalCommissionsPaid += directCommission;
                
                emit CommissionPaid(referrer, directCommission, "Direct Commission");
            }
        }
        
        // Team override commissions (2% up the chain)
        address current = referrer;
        uint256 level = 1;
        
        while (current != address(0) && level <= 5 && remainingPool > 0) {
            address upline = members[current].upline;
            if (upline != address(0)) {
                uint256 overrideCommission = (amount * commissionRates.teamOverrideRate) / 10000;
                if (overrideCommission <= remainingPool) {
                    payable(upline).transfer(overrideCommission);
                    members[upline].totalCommissionsEarned += overrideCommission;
                    remainingPool -= overrideCommission;
                    totalCommissionsPaid += overrideCommission;
                    
                    emit CommissionPaid(upline, overrideCommission, "Team Override");
                }
            }
            current = upline;
            level++;
        }
        
        // Add to team volume up the chain
        unykornToken.addTeamVolume(purchase.buyer, amount);
    }
    
    /**
     * @dev Update team sizes up the chain
     */
    function _updateTeamSizes(address upline) internal {
        address current = upline;
        while (current != address(0)) {
            members[current].teamSize++;
            current = members[current].upline;
        }
    }
    
    /**
     * @dev Check and process role upgrades
     */
    function _checkRoleUpgrade(address memberAddress) internal {
        Member storage member = members[memberAddress];
        
        // Check for Hustler upgrade (specific criteria)
        if (member.role == SalesRole.ADVOCATE) {
            if (member.downline.length >= 5 && member.personalVolume >= 100 * 10**18) {
                member.role = SalesRole.HUSTLER;
                _revokeRole(ADVOCATE_ROLE, memberAddress);
                _grantRole(HUSTLER_ROLE, memberAddress);
                
                emit RoleUpgraded(memberAddress, SalesRole.ADVOCATE, SalesRole.HUSTLER);
            }
        }
        
        // Check for Founding Broker qualification
        if (member.role == SalesRole.HUSTLER && !member.foundingBrokerQualified) {
            if (member.teamSize >= foundingBrokerMinRecruits && 
                member.teamVolume >= foundingBrokerMinVolume) {
                member.foundingBrokerQualified = true;
                member.role = SalesRole.FOUNDING_BROKER;
                _grantRole(FOUNDING_BROKER_ROLE, memberAddress);
                
                // Founding broker bonus
                uint256 bonus = (member.totalInvested * commissionRates.foundingBrokerBonus) / 10000;
                if (bonus > 0) {
                    payable(memberAddress).transfer(bonus);
                    member.totalCommissionsEarned += bonus;
                    emit CommissionPaid(memberAddress, bonus, "Founding Broker Bonus");
                }
                
                emit FoundingBrokerQualified(memberAddress, member.teamSize);
                emit RoleUpgraded(memberAddress, SalesRole.HUSTLER, SalesRole.FOUNDING_BROKER);
            }
        }
    }
    
    /**
     * @dev Claim vested tokens
     */
    function claimVestedTokens() external nonReentrant {
        Member storage member = members[msg.sender];
        require(member.wallet != address(0), "Not a member");
        require(block.timestamp >= member.lockReleaseDate, "Tokens still locked");
        require(claimableTokens[msg.sender] > 0, "No tokens to claim");
        
        uint256 tokensToTransfer = claimableTokens[msg.sender];
        claimableTokens[msg.sender] = 0;
        member.vestedTokens = 0;
        
        // Transfer tokens
        unykornToken.transfer(msg.sender, tokensToTransfer);
        member.totalTokensEarned += tokensToTransfer;
        
        emit TokensVested(msg.sender, tokensToTransfer);
    }
    
    /**
     * @dev Claim pending commissions (for hustlers after vesting)
     */
    function claimPendingCommissions() external nonReentrant {
        Member storage member = members[msg.sender];
        require(member.role == SalesRole.HUSTLER || member.role == SalesRole.FOUNDING_BROKER, "Not eligible");
        require(pendingCommissions[msg.sender] > 0, "No pending commissions");
        
        uint256 commissionAmount = pendingCommissions[msg.sender];
        pendingCommissions[msg.sender] = 0;
        
        payable(msg.sender).transfer(commissionAmount);
        member.totalCommissionsEarned += commissionAmount;
        
        emit CommissionPaid(msg.sender, commissionAmount, "Vested Commission");
    }
    
    /**
     * @dev Get member's complete information
     */
    function getMemberInfo(address memberAddress) 
        external 
        view 
        returns (
            Member memory member,
            uint256 pendingCommission,
            uint256 claimableTokenAmount,
            bool canClaimTokens,
            bool canClaimCommissions
        ) 
    {
        member = members[memberAddress];
        pendingCommission = pendingCommissions[memberAddress];
        claimableTokenAmount = claimableTokens[memberAddress];
        canClaimTokens = block.timestamp >= member.lockReleaseDate && claimableTokenAmount > 0;
        canClaimCommissions = pendingCommission > 0 && 
            (member.role == SalesRole.HUSTLER || member.role == SalesRole.FOUNDING_BROKER);
        
        return (member, pendingCommission, claimableTokenAmount, canClaimTokens, canClaimCommissions);
    }
    
    /**
     * @dev Get member's downline tree
     */
    function getMemberDownline(address memberAddress) 
        external 
        view 
        returns (address[] memory) 
    {
        return members[memberAddress].downline;
    }
    
    /**
     * @dev Get member's purchase history
     */
    function getMemberPurchases(address memberAddress) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return memberPurchases[memberAddress];
    }
    
    /**
     * @dev Calculate potential earnings for pack tier
     */
    function calculatePotentialEarnings(PackTier tier, uint256 teamSize) 
        external 
        view 
        returns (
            uint256 directCommissionPotential,
            uint256 teamOverridePotential,
            uint256 tokenAllocation
        ) 
    {
        PackConfig memory pack = packConfigs[tier];
        
        directCommissionPotential = (pack.price * commissionRates.advocateDirectRate) / 10000;
        teamOverridePotential = (pack.price * teamSize * commissionRates.teamOverrideRate) / 10000;
        tokenAllocation = pack.tokenAllocation;
        
        return (directCommissionPotential, teamOverridePotential, tokenAllocation);
    }
    
    // Admin functions
    function updatePackConfig(
        PackTier tier,
        uint256 price,
        uint256 tokenAllocation,
        uint256 lockPeriod,
        bool active
    ) external onlyRole(ADMIN_ROLE) {
        PackConfig storage pack = packConfigs[tier];
        pack.price = price;
        pack.tokenAllocation = tokenAllocation;
        pack.lockPeriod = lockPeriod;
        pack.active = active;
    }
    
    function updateCommissionRates(
        uint256 advocateRate,
        uint256 hustlerRate,
        uint256 overrideRate,
        uint256 foundingBrokerBonus
    ) external onlyRole(ADMIN_ROLE) {
        commissionRates.advocateDirectRate = advocateRate;
        commissionRates.hustlerDirectRate = hustlerRate;
        commissionRates.teamOverrideRate = overrideRate;
        commissionRates.foundingBrokerBonus = foundingBrokerBonus;
    }
    
    function updateFoundingBrokerRequirements(
        uint256 minRecruits,
        uint256 minVolume
    ) external onlyRole(ADMIN_ROLE) {
        foundingBrokerMinRecruits = minRecruits;
        foundingBrokerMinVolume = minVolume;
    }
    
    function emergencyPause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }
    
    function emergencyUnpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }
    
    function emergencyWithdraw(uint256 amount) external onlyRole(ADMIN_ROLE) {
        payable(msg.sender).transfer(amount);
    }
    
    // View functions for analytics
    function getSystemStats() 
        external 
        view 
        returns (
            uint256 _totalMembers,
            uint256 _totalSalesVolume,
            uint256 _totalCommissionsPaid,
            uint256 advocateCount,
            uint256 hustlerCount,
            uint256 foundingBrokerCount
        ) 
    {
        // Would need to implement counters for role counts
        return (
            totalMembers,
            totalSalesVolume,
            totalCommissionsPaid,
            0, // Placeholder - would need role counters
            0, // Placeholder
            0  // Placeholder
        );
    }
    
    receive() external payable {
        // Accept ETH for liquidity and operations
    }
}