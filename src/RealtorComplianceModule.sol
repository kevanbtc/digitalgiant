// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Pausable.sol";

/// @title RESPA-Compliant Realtor Module for Territory Franchise System
/// @notice Manages realtor compliance, non-settlement services, and broker-to-broker referrals
/// @dev Designed to avoid RESPA Section 8 violations while enabling compliant revenue sharing
contract RealtorComplianceModule is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant COMPLIANCE_ADMIN_ROLE = keccak256("COMPLIANCE_ADMIN_ROLE");
    bytes32 public constant BROKER_ROLE = keccak256("BROKER_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");
    
    enum ServiceType {
        NON_SETTLEMENT,        // 0 - Memberships, concierge, vouchers (RESPA-safe)
        SETTLEMENT_ADJACENT,   // 1 - Education, community (RESPA-safe)
        BROKER_TO_BROKER      // 2 - Licensed referrals (off-chain settlement)
    }
    
    enum LicenseStatus {
        UNLICENSED,           // 0 - Not licensed
        AGENT_LICENSED,       // 1 - Real estate agent
        BROKER_LICENSED,      // 2 - Real estate broker
        SUSPENDED,            // 3 - License suspended
        EXPIRED              // 4 - License expired
    }
    
    struct RealtorProfile {
        address wallet;
        string name;
        string licenseNumber;
        LicenseStatus licenseStatus;
        string state;
        string brokerage;
        uint256 licenseExpiry;
        bool canReceiveReferrals;
        bool canPayReferrals;
        uint256 createdAt;
        uint256 lastUpdated;
        string ipfsKYC;           // KYC documents hash
        bool isActive;
    }
    
    struct ServiceOffering {
        uint256 id;
        address provider;
        ServiceType serviceType;
        string title;
        string description;
        uint256 price;            // In USD cents (scaled by 1e2)
        bool isRecurring;
        uint256 recurringPeriod;  // In seconds (30 days = 2592000)
        bool requiresLicense;
        address revVault;         // Revenue split contract
        string complianceNotes;
        bool isActive;
        uint256 createdAt;
    }
    
    struct BrokerReferralAgreement {
        uint256 id;
        address referringBroker;
        address receivingBroker;
        string propertyAddress;
        uint256 expectedCommission;  // In USD cents
        uint256 referralFeeBps;      // Basis points (500 = 5%)
        uint256 createdAt;
        uint256 expiresAt;
        bool isExecuted;
        bool isPaid;
        string ipfsAgreement;        // PDF agreement hash
        string notes;
    }
    
    struct ComplianceViolation {
        uint256 id;
        address violator;
        string violationType;
        string description;
        uint256 timestamp;
        bool isResolved;
        address resolver;
        string resolutionNotes;
        uint256 penaltyAmount;
    }
    
    mapping(address => RealtorProfile) public realtorProfiles;
    mapping(uint256 => ServiceOffering) public serviceOfferings;
    mapping(uint256 => BrokerReferralAgreement) public referralAgreements;
    mapping(uint256 => ComplianceViolation) public violations;
    
    mapping(address => uint256[]) public realtorServices;
    mapping(address => uint256[]) public realtorReferrals;
    mapping(address => uint256[]) public complianceHistory;
    
    uint256 public nextServiceId = 1;
    uint256 public nextReferralId = 1;
    uint256 public nextViolationId = 1;
    
    // RESPA compliance parameters
    uint256 public maxSettlementServiceReferralBps = 0; // No settlement service referrals
    uint256 public maxBrokerReferralBps = 5000; // 50% max for broker-to-broker
    uint256 public minimumLicenseValidityDays = 30;
    
    event RealtorRegistered(
        address indexed wallet,
        string name,
        string licenseNumber,
        LicenseStatus status,
        string state
    );
    
    event ServiceCreated(
        uint256 indexed serviceId,
        address indexed provider,
        ServiceType serviceType,
        string title,
        uint256 price
    );
    
    event BrokerReferralCreated(
        uint256 indexed referralId,
        address indexed referringBroker,
        address indexed receivingBroker,
        uint256 expectedCommission,
        uint256 referralFeeBps
    );
    
    event ComplianceViolationRecorded(
        uint256 indexed violationId,
        address indexed violator,
        string violationType,
        uint256 timestamp
    );
    
    event ServicePurchased(
        uint256 indexed serviceId,
        address indexed buyer,
        address indexed provider,
        uint256 amount,
        uint256 timestamp
    );
    
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(COMPLIANCE_ADMIN_ROLE, admin);
    }
    
    /// @notice Register a realtor profile with license verification
    /// @param wallet Realtor's wallet address
    /// @param name Full legal name
    /// @param licenseNumber State license number
    /// @param licenseStatus Current license status
    /// @param state Licensing state
    /// @param brokerage Associated brokerage
    /// @param licenseExpiry License expiration timestamp
    /// @param ipfsKYC IPFS hash of KYC documents
    function registerRealtor(
        address wallet,
        string memory name,
        string memory licenseNumber,
        LicenseStatus licenseStatus,
        string memory state,
        string memory brokerage,
        uint256 licenseExpiry,
        string memory ipfsKYC
    ) external onlyRole(COMPLIANCE_ADMIN_ROLE) {
        require(wallet != address(0), "Invalid wallet");
        require(bytes(name).length > 0, "Name required");
        require(bytes(licenseNumber).length > 0, "License number required");
        require(licenseExpiry > block.timestamp + (minimumLicenseValidityDays * 1 days), "License expires too soon");
        
        realtorProfiles[wallet] = RealtorProfile({
            wallet: wallet,
            name: name,
            licenseNumber: licenseNumber,
            licenseStatus: licenseStatus,
            state: state,
            brokerage: brokerage,
            licenseExpiry: licenseExpiry,
            canReceiveReferrals: licenseStatus == LicenseStatus.BROKER_LICENSED,
            canPayReferrals: licenseStatus == LicenseStatus.BROKER_LICENSED,
            createdAt: block.timestamp,
            lastUpdated: block.timestamp,
            ipfsKYC: ipfsKYC,
            isActive: true
        });
        
        // Grant appropriate role based on license status
        if (licenseStatus == LicenseStatus.BROKER_LICENSED) {
            _grantRole(BROKER_ROLE, wallet);
        } else if (licenseStatus == LicenseStatus.AGENT_LICENSED) {
            _grantRole(AGENT_ROLE, wallet);
        }
        
        emit RealtorRegistered(wallet, name, licenseNumber, licenseStatus, state);
    }
    
    /// @notice Create a non-settlement service offering (RESPA-safe)
    /// @param serviceType Type of service (must be non-settlement)
    /// @param title Service title
    /// @param description Service description
    /// @param price Price in USD cents
    /// @param isRecurring Whether service is subscription-based
    /// @param recurringPeriod Period in seconds (if recurring)
    /// @param revVault Address of revenue split contract
    /// @param complianceNotes Compliance documentation
    function createService(
        ServiceType serviceType,
        string memory title,
        string memory description,
        uint256 price,
        bool isRecurring,
        uint256 recurringPeriod,
        address revVault,
        string memory complianceNotes
    ) external nonReentrant whenNotPaused returns (uint256) {
        require(hasRole(AGENT_ROLE, msg.sender) || hasRole(BROKER_ROLE, msg.sender), "Must be licensed");
        require(realtorProfiles[msg.sender].isActive, "Profile not active");
        require(serviceType != ServiceType.BROKER_TO_BROKER, "Use createBrokerReferral for referrals");
        require(price > 0, "Price must be positive");
        require(revVault != address(0), "Revenue vault required");
        
        // Verify license is still valid
        require(realtorProfiles[msg.sender].licenseExpiry > block.timestamp, "License expired");
        
        uint256 serviceId = nextServiceId++;
        
        serviceOfferings[serviceId] = ServiceOffering({
            id: serviceId,
            provider: msg.sender,
            serviceType: serviceType,
            title: title,
            description: description,
            price: price,
            isRecurring: isRecurring,
            recurringPeriod: recurringPeriod,
            requiresLicense: false, // Non-settlement services don't require license
            revVault: revVault,
            complianceNotes: complianceNotes,
            isActive: true,
            createdAt: block.timestamp
        });
        
        realtorServices[msg.sender].push(serviceId);
        
        emit ServiceCreated(serviceId, msg.sender, serviceType, title, price);
        
        return serviceId;
    }
    
    /// @notice Create broker-to-broker referral agreement (off-chain settlement)
    /// @param receivingBroker Licensed broker receiving referral
    /// @param propertyAddress Property address for referral
    /// @param expectedCommission Expected total commission in USD cents
    /// @param referralFeeBps Referral fee in basis points
    /// @param expiresAt Expiration timestamp
    /// @param ipfsAgreement IPFS hash of signed agreement
    /// @param notes Additional notes
    function createBrokerReferral(
        address receivingBroker,
        string memory propertyAddress,
        uint256 expectedCommission,
        uint256 referralFeeBps,
        uint256 expiresAt,
        string memory ipfsAgreement,
        string memory notes
    ) external nonReentrant whenNotPaused onlyRole(BROKER_ROLE) returns (uint256) {
        require(hasRole(BROKER_ROLE, receivingBroker), "Receiving broker must be licensed");
        require(realtorProfiles[msg.sender].canPayReferrals, "Cannot pay referrals");
        require(realtorProfiles[receivingBroker].canReceiveReferrals, "Receiving broker cannot receive referrals");
        require(referralFeeBps <= maxBrokerReferralBps, "Referral fee too high");
        require(expiresAt > block.timestamp, "Expiration must be in future");
        require(expectedCommission > 0, "Commission must be positive");
        
        uint256 referralId = nextReferralId++;
        
        referralAgreements[referralId] = BrokerReferralAgreement({
            id: referralId,
            referringBroker: msg.sender,
            receivingBroker: receivingBroker,
            propertyAddress: propertyAddress,
            expectedCommission: expectedCommission,
            referralFeeBps: referralFeeBps,
            createdAt: block.timestamp,
            expiresAt: expiresAt,
            isExecuted: false,
            isPaid: false,
            ipfsAgreement: ipfsAgreement,
            notes: notes
        });
        
        realtorReferrals[msg.sender].push(referralId);
        realtorReferrals[receivingBroker].push(referralId);
        
        emit BrokerReferralCreated(
            referralId,
            msg.sender,
            receivingBroker,
            expectedCommission,
            referralFeeBps
        );
        
        return referralId;
    }
    
    /// @notice Record service purchase (called by RevVault or payment processor)
    /// @param serviceId Service being purchased
    /// @param buyer Buyer address
    /// @param amount Amount paid in USD cents
    function recordServicePurchase(
        uint256 serviceId,
        address buyer,
        uint256 amount
    ) external nonReentrant {
        require(serviceId < nextServiceId, "Service does not exist");
        
        ServiceOffering storage service = serviceOfferings[serviceId];
        require(service.isActive, "Service not active");
        require(msg.sender == service.revVault, "Only revenue vault can record");
        
        emit ServicePurchased(serviceId, buyer, service.provider, amount, block.timestamp);
    }
    
    /// @notice Mark broker referral as executed (transaction closed)
    /// @param referralId Referral agreement ID
    function executeReferral(
        uint256 referralId
    ) external nonReentrant {
        require(referralId < nextReferralId, "Referral does not exist");
        
        BrokerReferralAgreement storage referral = referralAgreements[referralId];
        require(msg.sender == referral.receivingBroker, "Only receiving broker can execute");
        require(!referral.isExecuted, "Already executed");
        require(block.timestamp <= referral.expiresAt, "Referral expired");
        
        referral.isExecuted = true;
        
        // Note: Actual payment happens off-chain through escrow/broker disbursement
        // This just records that the transaction closed
    }
    
    /// @notice Record compliance violation
    /// @param violator Address of violator
    /// @param violationType Type of violation
    /// @param description Violation description
    /// @param penaltyAmount Penalty amount in USD cents
    function recordViolation(
        address violator,
        string memory violationType,
        string memory description,
        uint256 penaltyAmount
    ) external onlyRole(COMPLIANCE_ADMIN_ROLE) returns (uint256) {
        uint256 violationId = nextViolationId++;
        
        violations[violationId] = ComplianceViolation({
            id: violationId,
            violator: violator,
            violationType: violationType,
            description: description,
            timestamp: block.timestamp,
            isResolved: false,
            resolver: address(0),
            resolutionNotes: "",
            penaltyAmount: penaltyAmount
        });
        
        complianceHistory[violator].push(violationId);
        
        emit ComplianceViolationRecorded(violationId, violator, violationType, block.timestamp);
        
        return violationId;
    }
    
    /// @notice Check if address can participate in settlement-service referrals
    /// @param addr Address to check
    /// @return canParticipate Always returns false (RESPA compliance)
    function canParticipateInSettlementReferrals(address addr) external pure returns (bool) {
        // Always return false to maintain RESPA compliance
        // Settlement service referrals are prohibited
        addr; // Silence unused parameter warning
        return false;
    }
    
    /// @notice Check if broker can receive referral fees
    /// @param broker Broker address
    /// @return canReceive Whether broker can receive referrals
    function canReceiveReferrals(address broker) external view returns (bool) {
        RealtorProfile memory profile = realtorProfiles[broker];
        return profile.isActive && 
               profile.canReceiveReferrals && 
               profile.licenseExpiry > block.timestamp &&
               profile.licenseStatus == LicenseStatus.BROKER_LICENSED;
    }
    
    /// @notice Get realtor's service offerings
    /// @param realtor Realtor address
    /// @return serviceIds Array of service IDs
    function getRealtorServices(address realtor) external view returns (uint256[] memory) {
        return realtorServices[realtor];
    }
    
    /// @notice Get realtor's referral agreements
    /// @param realtor Realtor address
    /// @return referralIds Array of referral IDs
    function getRealtorReferrals(address realtor) external view returns (uint256[] memory) {
        return realtorReferrals[realtor];
    }
    
    /// @notice Get compliance history for address
    /// @param addr Address to check
    /// @return violationIds Array of violation IDs
    function getComplianceHistory(address addr) external view returns (uint256[] memory) {
        return complianceHistory[addr];
    }
    
    /// @notice Update realtor license status
    /// @param realtor Realtor address
    /// @param newStatus New license status
    /// @param newExpiry New expiry date (if applicable)
    function updateLicenseStatus(
        address realtor,
        LicenseStatus newStatus,
        uint256 newExpiry
    ) external onlyRole(COMPLIANCE_ADMIN_ROLE) {
        RealtorProfile storage profile = realtorProfiles[realtor];
        require(profile.wallet != address(0), "Realtor not registered");
        
        profile.licenseStatus = newStatus;
        profile.lastUpdated = block.timestamp;
        
        if (newExpiry > 0) {
            profile.licenseExpiry = newExpiry;
        }
        
        // Update referral permissions based on new status
        profile.canReceiveReferrals = newStatus == LicenseStatus.BROKER_LICENSED;
        profile.canPayReferrals = newStatus == LicenseStatus.BROKER_LICENSED;
        
        // Update roles
        if (newStatus == LicenseStatus.BROKER_LICENSED) {
            _grantRole(BROKER_ROLE, realtor);
            if (hasRole(AGENT_ROLE, realtor)) {
                _revokeRole(AGENT_ROLE, realtor);
            }
        } else if (newStatus == LicenseStatus.AGENT_LICENSED) {
            _grantRole(AGENT_ROLE, realtor);
            if (hasRole(BROKER_ROLE, realtor)) {
                _revokeRole(BROKER_ROLE, realtor);
            }
        } else {
            // Suspended, expired, or unlicensed
            if (hasRole(BROKER_ROLE, realtor)) {
                _revokeRole(BROKER_ROLE, realtor);
            }
            if (hasRole(AGENT_ROLE, realtor)) {
                _revokeRole(AGENT_ROLE, realtor);
            }
        }
    }
    
    /// @notice Emergency functions
    function pause() external onlyRole(COMPLIANCE_ADMIN_ROLE) {
        _pause();
    }
    
    function unpause() external onlyRole(COMPLIANCE_ADMIN_ROLE) {
        _unpause();
    }
    
    /// @notice Update compliance parameters
    /// @param newMaxBrokerReferralBps New max broker referral basis points
    /// @param newMinValidityDays New minimum license validity days
    function updateComplianceParams(
        uint256 newMaxBrokerReferralBps,
        uint256 newMinValidityDays
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newMaxBrokerReferralBps <= 5000, "Max 50% referral fee");
        maxBrokerReferralBps = newMaxBrokerReferralBps;
        minimumLicenseValidityDays = newMinValidityDays;
    }
}