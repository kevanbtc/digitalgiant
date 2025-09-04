// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./RevVault.sol";
import "./TerritoryNFT.sol";
import "./RealtorComplianceModule.sol";

/**
 * @title Realtor Membership System - RESPA Compliant
 * @dev Manages realtor memberships, voucher systems, and non-settlement benefits
 * Compliant with RESPA by avoiding settlement service referrals
 */
contract RealtorMembershipSystem is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant TERRITORY_MANAGER_ROLE = keccak256("TERRITORY_MANAGER_ROLE");
    
    RealtorComplianceModule public complianceModule;
    TerritoryNFT public territoryNFT;
    RevVault public revVault;
    
    enum MembershipTier {
        BASIC,      // $50/month - Basic directory listing, community access
        PRO,        // $150/month - Enhanced profile, voucher credits
        ELITE       // $300/month - Premium branding, max benefits
    }
    
    struct Membership {
        MembershipTier tier;
        uint256 monthlyFee;
        uint256 lastPayment;
        uint256 paidUntil;
        bool active;
        uint256 voucherCredits;
        uint256 totalSpent;
        uint256 joinDate;
    }
    
    struct VoucherProgram {
        string name;
        string description;
        uint256 creditCost;      // Credits required to purchase
        uint256 dollarValue;     // Face value of voucher
        string merchantCategory; // "home_improvement", "moving", "insurance"
        bool active;
        uint256 totalIssued;
    }
    
    struct TerritoryMembership {
        uint256 territoryId;
        uint256 memberCount;
        uint256 monthlyRevenue;
        mapping(address => bool) members;
        address[] memberList;
    }
    
    // State variables
    mapping(address => Membership) public memberships;
    mapping(uint256 => VoucherProgram) public voucherPrograms;
    mapping(uint256 => TerritoryMembership) public territoryMemberships;
    mapping(address => mapping(uint256 => uint256)) public voucherBalances; // user -> programId -> balance
    
    uint256 public voucherProgramCount;
    uint256 public totalMembers;
    uint256 public totalMonthlyRevenue;
    
    // Membership pricing
    uint256 public constant BASIC_FEE = 50 * 10**18;   // $50 in wei
    uint256 public constant PRO_FEE = 150 * 10**18;    // $150 in wei  
    uint256 public constant ELITE_FEE = 300 * 10**18;  // $300 in wei
    
    // Events
    event MembershipCreated(address indexed member, MembershipTier tier, uint256 territoryId);
    event MembershipUpgraded(address indexed member, MembershipTier oldTier, MembershipTier newTier);
    event PaymentProcessed(address indexed member, uint256 amount, uint256 paidUntil);
    event VoucherProgramCreated(uint256 indexed programId, string name, uint256 creditCost);
    event VoucherPurchased(address indexed member, uint256 programId, uint256 quantity);
    event VoucherRedeemed(address indexed member, uint256 programId, uint256 quantity, string merchantId);
    
    constructor(
        address _complianceModule,
        address _territoryNFT,
        address _revVault
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        
        complianceModule = RealtorComplianceModule(_complianceModule);
        territoryNFT = TerritoryNFT(_territoryNFT);
        revVault = RevVault(_revVault);
    }
    
    /**
     * @dev Join membership program - RESPA compliant (no settlement services)
     */
    function joinMembership(
        MembershipTier tier,
        uint256 territoryId,
        string calldata licenseNumber
    ) external payable nonReentrant whenNotPaused {
        require(!memberships[msg.sender].active, "Already a member");
        require(complianceModule.isLicensedRealtor(msg.sender), "Must be licensed realtor");
        require(territoryNFT.exists(territoryId), "Territory does not exist");
        
        uint256 fee = getMembershipFee(tier);
        require(msg.value >= fee, "Insufficient payment");
        
        // Create membership
        memberships[msg.sender] = Membership({
            tier: tier,
            monthlyFee: fee,
            lastPayment: block.timestamp,
            paidUntil: block.timestamp + 30 days,
            active: true,
            voucherCredits: getInitialCredits(tier),
            totalSpent: fee,
            joinDate: block.timestamp
        });
        
        // Add to territory
        if (!territoryMemberships[territoryId].members[msg.sender]) {
            territoryMemberships[territoryId].members[msg.sender] = true;
            territoryMemberships[territoryId].memberList.push(msg.sender);
            territoryMemberships[territoryId].memberCount++;
        }
        territoryMemberships[territoryId].monthlyRevenue += fee;
        
        // Update totals
        totalMembers++;
        totalMonthlyRevenue += fee;
        
        // Process revenue split through RevVault
        _processRevenueShare(fee, territoryId);
        
        emit MembershipCreated(msg.sender, tier, territoryId);
        emit PaymentProcessed(msg.sender, fee, memberships[msg.sender].paidUntil);
    }
    
    /**
     * @dev Renew membership - auto-debits monthly fee
     */
    function renewMembership() external payable nonReentrant {
        Membership storage membership = memberships[msg.sender];
        require(membership.active, "No active membership");
        require(msg.value >= membership.monthlyFee, "Insufficient payment");
        
        // Extend membership
        membership.lastPayment = block.timestamp;
        membership.paidUntil = membership.paidUntil + 30 days;
        membership.totalSpent += membership.monthlyFee;
        
        // Add monthly voucher credits
        membership.voucherCredits += getMonthlyCredits(membership.tier);
        
        emit PaymentProcessed(msg.sender, membership.monthlyFee, membership.paidUntil);
    }
    
    /**
     * @dev Upgrade membership tier
     */
    function upgradeMembership(MembershipTier newTier) external payable nonReentrant {
        Membership storage membership = memberships[msg.sender];
        require(membership.active, "No active membership");
        require(newTier > membership.tier, "Can only upgrade");
        
        uint256 newFee = getMembershipFee(newTier);
        uint256 proRatedDiff = newFee - membership.monthlyFee;
        require(msg.value >= proRatedDiff, "Insufficient payment for upgrade");
        
        MembershipTier oldTier = membership.tier;
        membership.tier = newTier;
        membership.monthlyFee = newFee;
        membership.totalSpent += proRatedDiff;
        
        // Add upgrade bonus credits
        membership.voucherCredits += getUpgradeBonus(newTier);
        
        emit MembershipUpgraded(msg.sender, oldTier, newTier);
    }
    
    /**
     * @dev Create voucher program (RESPA compliant - no settlement services)
     */
    function createVoucherProgram(
        string memory name,
        string memory description,
        uint256 creditCost,
        uint256 dollarValue,
        string memory merchantCategory
    ) external onlyRole(ADMIN_ROLE) returns (uint256) {
        // Validate RESPA compliance
        require(!_isSettlementService(merchantCategory), "Settlement services prohibited");
        
        uint256 programId = voucherProgramCount++;
        voucherPrograms[programId] = VoucherProgram({
            name: name,
            description: description,
            creditCost: creditCost,
            dollarValue: dollarValue,
            merchantCategory: merchantCategory,
            active: true,
            totalIssued: 0
        });
        
        emit VoucherProgramCreated(programId, name, creditCost);
        return programId;
    }
    
    /**
     * @dev Purchase vouchers with credits (RESPA safe)
     */
    function purchaseVouchers(uint256 programId, uint256 quantity) external nonReentrant {
        Membership storage membership = memberships[msg.sender];
        require(membership.active, "No active membership");
        require(voucherPrograms[programId].active, "Program not active");
        
        uint256 totalCredits = voucherPrograms[programId].creditCost * quantity;
        require(membership.voucherCredits >= totalCredits, "Insufficient credits");
        
        // Deduct credits and issue vouchers
        membership.voucherCredits -= totalCredits;
        voucherBalances[msg.sender][programId] += quantity;
        voucherPrograms[programId].totalIssued += quantity;
        
        emit VoucherPurchased(msg.sender, programId, quantity);
    }
    
    /**
     * @dev Redeem vouchers with merchants
     */
    function redeemVoucher(
        uint256 programId,
        uint256 quantity,
        string calldata merchantId
    ) external nonReentrant {
        require(voucherBalances[msg.sender][programId] >= quantity, "Insufficient vouchers");
        require(voucherPrograms[programId].active, "Program not active");
        
        voucherBalances[msg.sender][programId] -= quantity;
        
        emit VoucherRedeemed(msg.sender, programId, quantity, merchantId);
    }
    
    /**
     * @dev Get member directory for territory (networking benefit)
     */
    function getTerritoryMembers(uint256 territoryId) 
        external 
        view 
        returns (address[] memory) 
    {
        require(
            memberships[msg.sender].active || 
            hasRole(TERRITORY_MANAGER_ROLE, msg.sender),
            "Not authorized"
        );
        return territoryMemberships[territoryId].memberList;
    }
    
    /**
     * @dev Get member profile (public directory)
     */
    function getMemberProfile(address member) 
        external 
        view 
        returns (
            MembershipTier tier,
            bool active,
            uint256 joinDate,
            string memory licenseNumber
        ) 
    {
        Membership memory membership = memberships[member];
        (, licenseNumber,,,) = complianceModule.realtorProfiles(member);
        
        return (
            membership.tier,
            membership.active && membership.paidUntil > block.timestamp,
            membership.joinDate,
            licenseNumber
        );
    }
    
    // Internal functions
    function getMembershipFee(MembershipTier tier) public pure returns (uint256) {
        if (tier == MembershipTier.BASIC) return BASIC_FEE;
        if (tier == MembershipTier.PRO) return PRO_FEE;
        if (tier == MembershipTier.ELITE) return ELITE_FEE;
        revert("Invalid tier");
    }
    
    function getInitialCredits(MembershipTier tier) internal pure returns (uint256) {
        if (tier == MembershipTier.BASIC) return 10;
        if (tier == MembershipTier.PRO) return 25;
        if (tier == MembershipTier.ELITE) return 50;
        return 0;
    }
    
    function getMonthlyCredits(MembershipTier tier) internal pure returns (uint256) {
        if (tier == MembershipTier.BASIC) return 5;
        if (tier == MembershipTier.PRO) return 15;
        if (tier == MembershipTier.ELITE) return 30;
        return 0;
    }
    
    function getUpgradeBonus(MembershipTier tier) internal pure returns (uint256) {
        if (tier == MembershipTier.PRO) return 10;
        if (tier == MembershipTier.ELITE) return 25;
        return 0;
    }
    
    function _isSettlementService(string memory category) internal pure returns (bool) {
        // RESPA prohibited categories
        bytes32 categoryHash = keccak256(abi.encodePacked(category));
        
        return (
            categoryHash == keccak256("title_insurance") ||
            categoryHash == keccak256("mortgage_lending") ||
            categoryHash == keccak256("home_inspection") ||
            categoryHash == keccak256("appraisal") ||
            categoryHash == keccak256("settlement_attorney") ||
            categoryHash == keccak256("escrow_service")
        );
    }
    
    function _processRevenueShare(uint256 amount, uint256 territoryId) internal {
        // 70% to territory holder, 30% to system
        uint256 territoryShare = (amount * 70) / 100;
        uint256 systemShare = amount - territoryShare;
        
        address territoryOwner = territoryNFT.ownerOf(territoryId);
        
        // Send to RevVault for distribution
        (bool success,) = address(revVault).call{value: territoryShare}(
            abi.encodeWithSignature("deposit(address)", territoryOwner)
        );
        require(success, "Revenue share failed");
    }
    
    // Admin functions
    function deactivateExpiredMemberships(address[] calldata members) external onlyRole(ADMIN_ROLE) {
        for (uint i = 0; i < members.length; i++) {
            if (memberships[members[i]].paidUntil < block.timestamp) {
                memberships[members[i]].active = false;
                totalMembers--;
            }
        }
    }
    
    function updateVoucherProgram(
        uint256 programId,
        uint256 newCreditCost,
        uint256 newDollarValue,
        bool active
    ) external onlyRole(ADMIN_ROLE) {
        VoucherProgram storage program = voucherPrograms[programId];
        program.creditCost = newCreditCost;
        program.dollarValue = newDollarValue;
        program.active = active;
    }
    
    function emergencyPause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }
    
    function emergencyUnpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }
    
    // View functions
    function getMembershipStatus(address member) external view returns (bool active, uint256 paidUntil) {
        Membership memory membership = memberships[member];
        return (membership.active && membership.paidUntil > block.timestamp, membership.paidUntil);
    }
    
    function getVoucherBalance(address member, uint256 programId) external view returns (uint256) {
        return voucherBalances[member][programId];
    }
    
    function getTerritoryRevenue(uint256 territoryId) external view returns (uint256) {
        return territoryMemberships[territoryId].monthlyRevenue;
    }
    
    receive() external payable {
        // Accept direct payments for membership fees
        revert("Use joinMembership() or renewMembership()");
    }
}