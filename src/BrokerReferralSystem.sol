// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./RealtorComplianceModule.sol";
import "./TerritoryNFT.sol";

/**
 * @title Broker-to-Broker Referral System - RESPA Compliant
 * @dev Manages inter-broker referral agreements and off-chain settlement coordination
 * Compliant with RESPA Section 8 by tracking agreements but not processing payments
 */
contract BrokerReferralSystem is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant BROKER_ROLE = keccak256("BROKER_ROLE");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");
    
    RealtorComplianceModule public complianceModule;
    TerritoryNFT public territoryNFT;
    
    enum ReferralStatus {
        PENDING,        // Agreement created, awaiting acceptance
        ACTIVE,         // Both parties agreed, can make referrals
        COMPLETED,      // Referral completed, awaiting settlement
        SETTLED,        // Payment processed off-chain
        DISPUTED,       // Dispute raised
        CANCELLED       // Agreement cancelled
    }
    
    enum ReferralType {
        BUYER_REFERRAL,     // Referring buyer to another broker
        SELLER_REFERRAL,    // Referring seller to another broker
        DUAL_REFERRAL,      // Referring both buyer and seller
        RENTAL_REFERRAL     // Rental transaction referral
    }
    
    struct ReferralAgreement {
        uint256 agreementId;
        address referringBroker;
        address receivingBroker;
        uint256 referringTerritory;
        uint256 receivingTerritory;
        ReferralType referralType;
        uint256 referralFeePercent;     // Basis points (e.g., 2500 = 25%)
        uint256 createdDate;
        uint256 expirationDate;
        ReferralStatus status;
        string terms;                   // IPFS hash of detailed terms
        bool requiresMutualConsent;
    }
    
    struct ReferralTransaction {
        uint256 transactionId;
        uint256 agreementId;
        address client;
        string propertyAddress;
        uint256 transactionValue;
        uint256 expectedCommission;
        uint256 referralFee;
        uint256 createdDate;
        uint256 closingDate;
        ReferralStatus status;
        string documentHash;            // IPFS hash of transaction docs
        address settlementAgent;        // Third party handling payment
    }
    
    struct BrokerProfile {
        address broker;
        string businessName;
        string licenseNumber;
        uint256[] territoryIds;
        uint256 referralsMade;
        uint256 referralsReceived;
        uint256 totalFeesEarned;
        uint256 totalFeesPaid;
        bool acceptingReferrals;
        mapping(address => bool) trustedBrokers;
        mapping(uint256 => bool) activeAgreements;
    }
    
    // State variables
    mapping(uint256 => ReferralAgreement) public agreements;
    mapping(uint256 => ReferralTransaction) public transactions;
    mapping(address => BrokerProfile) public brokerProfiles;
    mapping(address => uint256[]) public brokerAgreements;
    mapping(address => uint256[]) public brokerTransactions;
    mapping(uint256 => uint256[]) public territoryAgreements; // territory -> agreement IDs
    
    uint256 public agreementCount;
    uint256 public transactionCount;
    uint256 public totalReferralVolume;
    uint256 public disputeCount;
    
    // Constants
    uint256 public constant MAX_REFERRAL_FEE = 5000; // 50% max
    uint256 public constant AGREEMENT_DURATION = 365 days;
    
    // Events
    event ReferralAgreementCreated(
        uint256 indexed agreementId,
        address indexed referringBroker,
        address indexed receivingBroker,
        uint256 referralFeePercent
    );
    event ReferralAgreementAccepted(uint256 indexed agreementId);
    event ReferralTransactionCreated(
        uint256 indexed transactionId,
        uint256 indexed agreementId,
        address client,
        uint256 transactionValue
    );
    event ReferralCompleted(uint256 indexed transactionId, uint256 referralFee);
    event ReferralSettled(uint256 indexed transactionId, address settlementAgent);
    event DisputeRaised(uint256 indexed transactionId, string reason);
    event BrokerProfileUpdated(address indexed broker);
    
    constructor(address _complianceModule, address _territoryNFT) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(COMPLIANCE_ROLE, msg.sender);
        
        complianceModule = RealtorComplianceModule(_complianceModule);
        territoryNFT = TerritoryNFT(_territoryNFT);
    }
    
    /**
     * @dev Register broker profile - must be licensed
     */
    function registerBroker(
        string calldata businessName,
        string calldata licenseNumber,
        uint256[] calldata territoryIds,
        bool acceptingReferrals
    ) external {
        require(complianceModule.isLicensedRealtor(msg.sender), "Must be licensed");
        require(complianceModule.canReceiveReferrals(msg.sender), "Not authorized for referrals");
        
        BrokerProfile storage profile = brokerProfiles[msg.sender];
        profile.broker = msg.sender;
        profile.businessName = businessName;
        profile.licenseNumber = licenseNumber;
        profile.territoryIds = territoryIds;
        profile.acceptingReferrals = acceptingReferrals;
        
        _grantRole(BROKER_ROLE, msg.sender);
        emit BrokerProfileUpdated(msg.sender);
    }
    
    /**
     * @dev Create referral agreement between brokers
     */
    function createReferralAgreement(
        address receivingBroker,
        uint256 receivingTerritory,
        ReferralType referralType,
        uint256 referralFeePercent,
        uint256 expirationDays,
        string calldata terms,
        bool requiresMutualConsent
    ) external onlyRole(BROKER_ROLE) whenNotPaused returns (uint256) {
        require(hasRole(BROKER_ROLE, receivingBroker), "Receiver not registered broker");
        require(brokerProfiles[receivingBroker].acceptingReferrals, "Receiver not accepting referrals");
        require(referralFeePercent <= MAX_REFERRAL_FEE, "Fee too high");
        require(expirationDays > 0 && expirationDays <= 365, "Invalid expiration");
        
        // Get referring broker's primary territory
        uint256 referringTerritory = brokerProfiles[msg.sender].territoryIds.length > 0 
            ? brokerProfiles[msg.sender].territoryIds[0] 
            : 0;
        
        uint256 agreementId = agreementCount++;
        agreements[agreementId] = ReferralAgreement({
            agreementId: agreementId,
            referringBroker: msg.sender,
            receivingBroker: receivingBroker,
            referringTerritory: referringTerritory,
            receivingTerritory: receivingTerritory,
            referralType: referralType,
            referralFeePercent: referralFeePercent,
            createdDate: block.timestamp,
            expirationDate: block.timestamp + (expirationDays * 1 days),
            status: requiresMutualConsent ? ReferralStatus.PENDING : ReferralStatus.ACTIVE,
            terms: terms,
            requiresMutualConsent: requiresMutualConsent
        });
        
        // Track agreement for both brokers
        brokerAgreements[msg.sender].push(agreementId);
        brokerAgreements[receivingBroker].push(agreementId);
        territoryAgreements[receivingTerritory].push(agreementId);
        
        // Mark as active in broker profiles
        brokerProfiles[msg.sender].activeAgreements[agreementId] = true;
        brokerProfiles[receivingBroker].activeAgreements[agreementId] = true;
        
        emit ReferralAgreementCreated(agreementId, msg.sender, receivingBroker, referralFeePercent);
        
        if (!requiresMutualConsent) {
            emit ReferralAgreementAccepted(agreementId);
        }
        
        return agreementId;
    }
    
    /**
     * @dev Accept pending referral agreement
     */
    function acceptReferralAgreement(uint256 agreementId) external onlyRole(BROKER_ROLE) {
        ReferralAgreement storage agreement = agreements[agreementId];
        require(agreement.receivingBroker == msg.sender, "Not authorized");
        require(agreement.status == ReferralStatus.PENDING, "Agreement not pending");
        require(block.timestamp <= agreement.expirationDate, "Agreement expired");
        
        agreement.status = ReferralStatus.ACTIVE;
        emit ReferralAgreementAccepted(agreementId);
    }
    
    /**
     * @dev Create referral transaction (RESPA compliant - tracking only)
     */
    function createReferralTransaction(
        uint256 agreementId,
        address client,
        string calldata propertyAddress,
        uint256 transactionValue,
        uint256 expectedCommission,
        string calldata documentHash
    ) external onlyRole(BROKER_ROLE) whenNotPaused returns (uint256) {
        ReferralAgreement storage agreement = agreements[agreementId];
        require(agreement.status == ReferralStatus.ACTIVE, "Agreement not active");
        require(agreement.referringBroker == msg.sender, "Not referring broker");
        require(block.timestamp <= agreement.expirationDate, "Agreement expired");
        
        uint256 referralFee = (expectedCommission * agreement.referralFeePercent) / 10000;
        uint256 transactionId = transactionCount++;
        
        transactions[transactionId] = ReferralTransaction({
            transactionId: transactionId,
            agreementId: agreementId,
            client: client,
            propertyAddress: propertyAddress,
            transactionValue: transactionValue,
            expectedCommission: expectedCommission,
            referralFee: referralFee,
            createdDate: block.timestamp,
            closingDate: 0,
            status: ReferralStatus.ACTIVE,
            documentHash: documentHash,
            settlementAgent: address(0)
        });
        
        brokerTransactions[msg.sender].push(transactionId);
        brokerTransactions[agreement.receivingBroker].push(transactionId);
        
        // Update broker stats
        brokerProfiles[msg.sender].referralsMade++;
        brokerProfiles[agreement.receivingBroker].referralsReceived++;
        
        totalReferralVolume += transactionValue;
        
        emit ReferralTransactionCreated(transactionId, agreementId, client, transactionValue);
        return transactionId;
    }
    
    /**
     * @dev Mark referral as completed (closing occurred)
     */
    function completeReferralTransaction(
        uint256 transactionId,
        uint256 actualCommission,
        address settlementAgent
    ) external onlyRole(BROKER_ROLE) {
        ReferralTransaction storage transaction = transactions[transactionId];
        ReferralAgreement storage agreement = agreements[transaction.agreementId];
        
        require(
            transaction.status == ReferralStatus.ACTIVE &&
            (agreement.referringBroker == msg.sender || agreement.receivingBroker == msg.sender),
            "Not authorized or invalid status"
        );
        
        // Recalculate referral fee based on actual commission
        uint256 actualReferralFee = (actualCommission * agreement.referralFeePercent) / 10000;
        
        transaction.referralFee = actualReferralFee;
        transaction.closingDate = block.timestamp;
        transaction.status = ReferralStatus.COMPLETED;
        transaction.settlementAgent = settlementAgent;
        
        // Update broker earnings (tracking only, no payment)
        brokerProfiles[agreement.referringBroker].totalFeesEarned += actualReferralFee;
        brokerProfiles[agreement.receivingBroker].totalFeesPaid += actualReferralFee;
        
        emit ReferralCompleted(transactionId, actualReferralFee);
    }
    
    /**
     * @dev Mark referral as settled (payment processed off-chain)
     */
    function settleReferralTransaction(uint256 transactionId) external {
        ReferralTransaction storage transaction = transactions[transactionId];
        ReferralAgreement storage agreement = agreements[transaction.agreementId];
        
        require(
            transaction.status == ReferralStatus.COMPLETED &&
            (msg.sender == transaction.settlementAgent ||
             msg.sender == agreement.referringBroker ||
             msg.sender == agreement.receivingBroker),
            "Not authorized"
        );
        
        transaction.status = ReferralStatus.SETTLED;
        emit ReferralSettled(transactionId, transaction.settlementAgent);
    }
    
    /**
     * @dev Raise dispute on referral transaction
     */
    function raiseDispute(uint256 transactionId, string calldata reason) external onlyRole(BROKER_ROLE) {
        ReferralTransaction storage transaction = transactions[transactionId];
        ReferralAgreement storage agreement = agreements[transaction.agreementId];
        
        require(
            agreement.referringBroker == msg.sender || agreement.receivingBroker == msg.sender,
            "Not party to agreement"
        );
        require(
            transaction.status == ReferralStatus.COMPLETED || 
            transaction.status == ReferralStatus.ACTIVE,
            "Cannot dispute this status"
        );
        
        transaction.status = ReferralStatus.DISPUTED;
        disputeCount++;
        
        emit DisputeRaised(transactionId, reason);
    }
    
    /**
     * @dev Get broker referral statistics
     */
    function getBrokerStats(address broker) 
        external 
        view 
        returns (
            uint256 referralsMade,
            uint256 referralsReceived,
            uint256 totalFeesEarned,
            uint256 totalFeesPaid,
            uint256 activeAgreementCount
        ) 
    {
        BrokerProfile storage profile = brokerProfiles[broker];
        uint256 activeCount = 0;
        
        uint256[] memory agreements = brokerAgreements[broker];
        for (uint i = 0; i < agreements.length; i++) {
            if (agreements[agreements[i]].status == ReferralStatus.ACTIVE) {
                activeCount++;
            }
        }
        
        return (
            profile.referralsMade,
            profile.referralsReceived,
            profile.totalFeesEarned,
            profile.totalFeesPaid,
            activeCount
        );
    }
    
    /**
     * @dev Get territory referral opportunities
     */
    function getTerritoryReferralOpportunities(uint256 territoryId) 
        external 
        view 
        returns (uint256[] memory activeAgreements) 
    {
        uint256[] memory territoryAgreementIds = territoryAgreements[territoryId];
        uint256 activeCount = 0;
        
        // Count active agreements
        for (uint i = 0; i < territoryAgreementIds.length; i++) {
            if (agreements[territoryAgreementIds[i]].status == ReferralStatus.ACTIVE) {
                activeCount++;
            }
        }
        
        // Build active agreements array
        activeAgreements = new uint256[](activeCount);
        uint256 index = 0;
        for (uint i = 0; i < territoryAgreementIds.length; i++) {
            if (agreements[territoryAgreementIds[i]].status == ReferralStatus.ACTIVE) {
                activeAgreements[index] = territoryAgreementIds[i];
                index++;
            }
        }
    }
    
    /**
     * @dev Check if brokers can create referral agreement
     */
    function canCreateReferral(address referringBroker, address receivingBroker) 
        external 
        view 
        returns (bool) 
    {
        return (
            hasRole(BROKER_ROLE, referringBroker) &&
            hasRole(BROKER_ROLE, receivingBroker) &&
            complianceModule.canPayReferrals(referringBroker) &&
            complianceModule.canReceiveReferrals(receivingBroker) &&
            brokerProfiles[receivingBroker].acceptingReferrals
        );
    }
    
    // Admin functions
    function resolveDispute(
        uint256 transactionId,
        ReferralStatus newStatus
    ) external onlyRole(COMPLIANCE_ROLE) {
        require(
            newStatus == ReferralStatus.SETTLED || 
            newStatus == ReferralStatus.CANCELLED,
            "Invalid resolution status"
        );
        
        ReferralTransaction storage transaction = transactions[transactionId];
        require(transaction.status == ReferralStatus.DISPUTED, "Not disputed");
        
        transaction.status = newStatus;
        disputeCount--;
    }
    
    function updateBrokerStatus(address broker, bool acceptingReferrals) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        brokerProfiles[broker].acceptingReferrals = acceptingReferrals;
        emit BrokerProfileUpdated(broker);
    }
    
    function emergencyPause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }
    
    function emergencyUnpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }
    
    // View functions for compliance reporting
    function getAgreementDetails(uint256 agreementId) 
        external 
        view 
        returns (ReferralAgreement memory) 
    {
        return agreements[agreementId];
    }
    
    function getTransactionDetails(uint256 transactionId) 
        external 
        view 
        returns (ReferralTransaction memory) 
    {
        return transactions[transactionId];
    }
    
    function getBrokerAgreements(address broker) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return brokerAgreements[broker];
    }
    
    function getBrokerTransactions(address broker) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return brokerTransactions[broker];
    }
}