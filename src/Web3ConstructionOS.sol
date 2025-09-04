// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.5/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.5/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.5/contracts/token/ERC20/utils/SafeERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.5/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.5/contracts/access/Ownable2Step.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.5/contracts/security/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.5/contracts/security/Pausable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.5/contracts/utils/cryptography/ECDSA.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.5/contracts/utils/Counters.sol";

// ═══════════════════════════════════════════════════════════════════════════════════════
// WEB3 CONSTRUCTION OS - COMPLETE BUSINESS ENTITY INFRASTRUCTURE
// ═══════════════════════════════════════════════════════════════════════════════════════

/**
 * @title Web3ConstructionOS
 * @dev Complete construction business management system with Web3 infrastructure
 * Features: Multi-state compliance, instant settlements, AI agents, ESG tracking
 */

// ═══════════════════════════════════════════════════════════════════════════════════════
// CORE INFRASTRUCTURE - Identity, Compliance, and State Management
// ═══════════════════════════════════════════════════════════════════════════════════════

/**
 * @title VerifiableCredentialRegistry
 * @dev Manages all contractor licenses, insurance, certifications across states
 */
contract VerifiableCredentialRegistry is AccessControl, Pausable {
    using Counters for Counters.Counter;
    
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    
    struct CredentialType {
        string name;
        bool required;
        uint256 validityPeriod;
        string[] requiredFields;
    }
    
    struct Credential {
        uint256 id;
        string credentialType;
        address holder;
        string issuer;
        uint256 issuedAt;
        uint256 expiresAt;
        string dataHash; // IPFS hash of credential data
        bool revoked;
        string metadata; // JSON metadata
    }
    
    struct StateCompliance {
        string state;
        string[] requiredCredentials;
        mapping(string => string) stateLaws; // law type -> statute reference
        uint256 lastUpdated;
    }
    
    Counters.Counter private _credentialIds;
    
    mapping(uint256 => Credential) public credentials;
    mapping(address => uint256[]) public holderCredentials;
    mapping(string => CredentialType) public credentialTypes;
    mapping(string => StateCompliance) public stateCompliance;
    mapping(address => mapping(string => uint256[])) public holderCredentialsByType;
    
    event CredentialIssued(uint256 indexed id, address indexed holder, string credentialType, address issuer);
    event CredentialRevoked(uint256 indexed id, string reason);
    event CredentialTypeAdded(string credentialType, bool required);
    event StateComplianceUpdated(string state, string[] requiredCredentials);
    
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ISSUER_ROLE, admin);
        _grantRole(VERIFIER_ROLE, admin);
        
        // Initialize common credential types
        _initializeCredentialTypes();
    }
    
    function _initializeCredentialTypes() internal {
        // Contractor Licenses
        credentialTypes["CONTRACTOR_LICENSE"] = CredentialType({
            name: "Contractor License",
            required: true,
            validityPeriod: 365 days,
            requiredFields: ["state", "licenseNumber", "classification", "expiryDate"]
        });
        
        // Insurance
        credentialTypes["GENERAL_LIABILITY"] = CredentialType({
            name: "General Liability Insurance",
            required: true,
            validityPeriod: 365 days,
            requiredFields: ["carrier", "policyNumber", "coverage", "expiryDate"]
        });
        
        credentialTypes["WORKERS_COMP"] = CredentialType({
            name: "Workers Compensation",
            required: true,
            validityPeriod: 365 days,
            requiredFields: ["carrier", "policyNumber", "coverage", "expiryDate"]
        });
        
        // Certifications
        credentialTypes["OSHA_TRAINING"] = CredentialType({
            name: "OSHA Safety Training",
            required: true,
            validityPeriod: 1095 days, // 3 years
            requiredFields: ["certificationLevel", "completionDate", "instructorId"]
        });
        
        // Tax/Business
        credentialTypes["W9_FORM"] = CredentialType({
            name: "W-9 Tax Form",
            required: true,
            validityPeriod: 1095 days,
            requiredFields: ["ein", "businessName", "address", "signatureDate"]
        });
        
        // ESG/Diversity
        credentialTypes["MBE_CERT"] = CredentialType({
            name: "Minority Business Enterprise",
            required: false,
            validityPeriod: 1095 days,
            requiredFields: ["certifyingAgency", "certificationNumber", "minorityType"]
        });
    }
    
    function issueCredential(
        address holder,
        string memory credentialType,
        string memory issuer,
        uint256 validityPeriod,
        string memory dataHash,
        string memory metadata
    ) external onlyRole(ISSUER_ROLE) returns (uint256) {
        require(bytes(credentialTypes[credentialType].name).length > 0, "Invalid credential type");
        
        _credentialIds.increment();
        uint256 credentialId = _credentialIds.current();
        
        uint256 expiresAt = block.timestamp + validityPeriod;
        
        credentials[credentialId] = Credential({
            id: credentialId,
            credentialType: credentialType,
            holder: holder,
            issuer: issuer,
            issuedAt: block.timestamp,
            expiresAt: expiresAt,
            dataHash: dataHash,
            revoked: false,
            metadata: metadata
        });
        
        holderCredentials[holder].push(credentialId);
        holderCredentialsByType[holder][credentialType].push(credentialId);
        
        emit CredentialIssued(credentialId, holder, credentialType, msg.sender);
        return credentialId;
    }
    
    function revokeCredential(uint256 credentialId, string memory reason) external onlyRole(ISSUER_ROLE) {
        require(credentials[credentialId].id != 0, "Credential does not exist");
        credentials[credentialId].revoked = true;
        emit CredentialRevoked(credentialId, reason);
    }
    
    function isCredentialValid(uint256 credentialId) external view returns (bool) {
        Credential memory cred = credentials[credentialId];
        return cred.id != 0 && !cred.revoked && block.timestamp < cred.expiresAt;
    }
    
    function hasValidCredential(address holder, string memory credentialType) external view returns (bool) {
        uint256[] memory holderCreds = holderCredentialsByType[holder][credentialType];
        
        for (uint256 i = 0; i < holderCreds.length; i++) {
            Credential memory cred = credentials[holderCreds[i]];
            if (!cred.revoked && block.timestamp < cred.expiresAt) {
                return true;
            }
        }
        return false;
    }
    
    function getStateComplianceStatus(address holder, string memory state) external view returns (bool compliant, string[] memory missingCredentials) {
        StateCompliance storage compliance = stateCompliance[state];
        string[] memory required = compliance.requiredCredentials;
        
        string[] memory missing = new string[](required.length);
        uint256 missingCount = 0;
        
        for (uint256 i = 0; i < required.length; i++) {
            if (!this.hasValidCredential(holder, required[i])) {
                missing[missingCount] = required[i];
                missingCount++;
            }
        }
        
        // Resize array to actual missing count
        string[] memory result = new string[](missingCount);
        for (uint256 i = 0; i < missingCount; i++) {
            result[i] = missing[i];
        }
        
        return (missingCount == 0, result);
    }
    
    function updateStateCompliance(
        string memory state,
        string[] memory requiredCredentials,
        string[] memory lawTypes,
        string[] memory statutes
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(lawTypes.length == statutes.length, "Law types and statutes length mismatch");
        
        StateCompliance storage compliance = stateCompliance[state];
        compliance.state = state;
        compliance.requiredCredentials = requiredCredentials;
        compliance.lastUpdated = block.timestamp;
        
        // Update state laws
        for (uint256 i = 0; i < lawTypes.length; i++) {
            compliance.stateLaws[lawTypes[i]] = statutes[i];
        }
        
        emit StateComplianceUpdated(state, requiredCredentials);
    }
    
    function addCredentialType(
        string memory typeName,
        string memory displayName,
        bool required,
        uint256 validityPeriod,
        string[] memory requiredFields
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        credentialTypes[typeName] = CredentialType({
            name: displayName,
            required: required,
            validityPeriod: validityPeriod,
            requiredFields: requiredFields
        });
        
        emit CredentialTypeAdded(typeName, required);
    }
}

/**
 * @title SubcontractorRegistry
 * @dev Manages subcontractor profiles, wallets, and business relationships
 */
contract SubcontractorRegistry is AccessControl, Pausable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");
    
    struct SubcontractorProfile {
        uint256 id;
        address wallet;
        string businessName;
        string ein;
        string businessAddress;
        string[] tradeSpecialties;
        string[] operatingStates;
        uint256 registeredAt;
        bool active;
        string profileDataHash; // IPFS hash with full profile
        mapping(string => bool) specialtyMap;
        mapping(string => bool) stateMap;
    }
    
    struct BusinessMetrics {
        uint256 totalJobsCompleted;
        uint256 totalValueCompleted;
        uint256 averageRating; // scaled by 100 (450 = 4.5 stars)
        uint256 onTimeCompletionRate; // percentage * 100
        uint256 safetyScore; // 0-100
        uint256 esgScore; // 0-100
        uint256 lastUpdated;
    }
    
    Counters.Counter private _subIds;
    
    mapping(uint256 => SubcontractorProfile) public subcontractors;
    mapping(address => uint256) public walletToSubId;
    mapping(string => uint256[]) public specialtyToSubs;
    mapping(string => uint256[]) public stateToSubs;
    mapping(uint256 => BusinessMetrics) public businessMetrics;
    
    VerifiableCredentialRegistry public immutable credentialRegistry;
    
    event SubcontractorRegistered(uint256 indexed id, address indexed wallet, string businessName);
    event SubcontractorUpdated(uint256 indexed id, string[] tradeSpecialties, string[] operatingStates);
    event MetricsUpdated(uint256 indexed id, uint256 totalJobs, uint256 totalValue, uint256 rating);
    
    constructor(address admin, VerifiableCredentialRegistry _credentialRegistry) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(REGISTRAR_ROLE, admin);
        credentialRegistry = _credentialRegistry;
    }
    
    function registerSubcontractor(
        address wallet,
        string memory businessName,
        string memory ein,
        string memory businessAddress,
        string[] memory tradeSpecialties,
        string[] memory operatingStates,
        string memory profileDataHash
    ) external onlyRole(REGISTRAR_ROLE) returns (uint256) {
        require(walletToSubId[wallet] == 0, "Wallet already registered");
        
        _subIds.increment();
        uint256 subId = _subIds.current();
        
        SubcontractorProfile storage profile = subcontractors[subId];
        profile.id = subId;
        profile.wallet = wallet;
        profile.businessName = businessName;
        profile.ein = ein;
        profile.businessAddress = businessAddress;
        profile.tradeSpecialties = tradeSpecialties;
        profile.operatingStates = operatingStates;
        profile.registeredAt = block.timestamp;
        profile.active = true;
        profile.profileDataHash = profileDataHash;
        
        // Update mappings
        walletToSubId[wallet] = subId;
        
        for (uint256 i = 0; i < tradeSpecialties.length; i++) {
            profile.specialtyMap[tradeSpecialties[i]] = true;
            specialtyToSubs[tradeSpecialties[i]].push(subId);
        }
        
        for (uint256 i = 0; i < operatingStates.length; i++) {
            profile.stateMap[operatingStates[i]] = true;
            stateToSubs[operatingStates[i]].push(subId);
        }
        
        // Initialize metrics
        businessMetrics[subId] = BusinessMetrics({
            totalJobsCompleted: 0,
            totalValueCompleted: 0,
            averageRating: 0,
            onTimeCompletionRate: 0,
            safetyScore: 0,
            esgScore: 0,
            lastUpdated: block.timestamp
        });
        
        emit SubcontractorRegistered(subId, wallet, businessName);
        return subId;
    }
    
    function updateBusinessMetrics(
        uint256 subId,
        uint256 totalJobs,
        uint256 totalValue,
        uint256 rating,
        uint256 onTimeRate,
        uint256 safetyScore,
        uint256 esgScore
    ) external onlyRole(REGISTRAR_ROLE) {
        require(subcontractors[subId].id != 0, "Subcontractor does not exist");
        
        BusinessMetrics storage metrics = businessMetrics[subId];
        metrics.totalJobsCompleted = totalJobs;
        metrics.totalValueCompleted = totalValue;
        metrics.averageRating = rating;
        metrics.onTimeCompletionRate = onTimeRate;
        metrics.safetyScore = safetyScore;
        metrics.esgScore = esgScore;
        metrics.lastUpdated = block.timestamp;
        
        emit MetricsUpdated(subId, totalJobs, totalValue, rating);
    }
    
    function isEligibleForProject(
        uint256 subId,
        string memory projectState,
        string memory requiredTrade,
        uint256 minimumRating
    ) external view returns (bool eligible, string memory reason) {
        SubcontractorProfile storage profile = subcontractors[subId];
        
        if (!profile.active) {
            return (false, "Subcontractor not active");
        }
        
        if (!profile.stateMap[projectState]) {
            return (false, "Not licensed in project state");
        }
        
        if (!profile.specialtyMap[requiredTrade]) {
            return (false, "Does not have required trade specialty");
        }
        
        // Check credentials
        (bool compliant, string[] memory missing) = credentialRegistry.getStateComplianceStatus(profile.wallet, projectState);
        if (!compliant) {
            return (false, "Missing required credentials");
        }
        
        // Check rating
        if (businessMetrics[subId].averageRating < minimumRating) {
            return (false, "Rating below minimum requirement");
        }
        
        return (true, "");
    }
    
    function findQualifiedSubcontractors(
        string memory state,
        string memory trade,
        uint256 minimumRating,
        uint256 limit
    ) external view returns (uint256[] memory qualifiedSubs, uint256 count) {
        uint256[] memory candidates = specialtyToSubs[trade];
        uint256[] memory qualified = new uint256[](limit > 0 ? limit : candidates.length);
        uint256 qualifiedCount = 0;
        
        for (uint256 i = 0; i < candidates.length && (limit == 0 || qualifiedCount < limit); i++) {
            uint256 subId = candidates[i];
            (bool eligible,) = this.isEligibleForProject(subId, state, trade, minimumRating);
            
            if (eligible) {
                qualified[qualifiedCount] = subId;
                qualifiedCount++;
            }
        }
        
        // Resize array
        uint256[] memory result = new uint256[](qualifiedCount);
        for (uint256 i = 0; i < qualifiedCount; i++) {
            result[i] = qualified[i];
        }
        
        return (result, qualifiedCount);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// PROJECT MANAGEMENT - Jobs, Scopes, and Work Orders
// ═══════════════════════════════════════════════════════════════════════════════════════

/**
 * @title ProjectVault
 * @dev Manages individual construction projects with scope NFTs and milestone tracking
 */
contract ProjectVault is ERC721, AccessControl, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    
    bytes32 public constant PROJECT_MANAGER_ROLE = keccak256("PROJECT_MANAGER_ROLE");
    bytes32 public constant SUPERINTENDENT_ROLE = keccak256("SUPERINTENDENT_ROLE");
    bytes32 public constant INSPECTOR_ROLE = keccak256("INSPECTOR_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    
    enum ProjectStatus { PLANNING, AWARDED, ACTIVE, COMPLETED, DISPUTED, CANCELLED }
    enum MilestoneStatus { PENDING, IN_PROGRESS, COMPLETED, DISPUTED }
    
    struct Project {
        uint256 id;
        string name;
        string projectAddress;
        string state;
        ProjectStatus status;
        uint256 totalValue;
        uint256 startDate;
        uint256 scheduledEndDate;
        uint256 actualEndDate;
        address owner;
        address generalContractor;
        string projectDataHash; // IPFS hash with complete project data
        uint256 createdAt;
    }
    
    struct ScopeNFT {
        uint256 projectId;
        string division; // CSI division (e.g., "07 - Thermal & Moisture Protection")
        string scopeDescription;
        uint256 contractValue;
        address assignedSubcontractor;
        uint256 assignedAt;
        MilestoneStatus status;
        string[] requiredCredentials;
        string scopeDataHash; // IPFS hash with detailed scope
    }
    
    struct Milestone {
        uint256 id;
        uint256 scopeNFTId;
        string description;
        uint256 value;
        uint256 scheduledDate;
        uint256 completedDate;
        MilestoneStatus status;
        address[] requiredApprovals;
        mapping(address => bool) approvals;
        string evidenceHash; // IPFS hash with photos, docs
    }
    
    struct ESGMetrics {
        uint256 energyEfficiencyRating; // 0-100
        uint256 recycledContentPercentage; // 0-100
        uint256 localSourcingPercentage; // 0-100
        uint256 apprenticeshipHours;
        uint256 diversitySpend; // in wei
        bool greenBuildingCertified;
        string[] esgDataHashes; // IPFS hashes for ESG documentation
    }
    
    Counters.Counter private _projectIds;
    Counters.Counter private _scopeIds;
    Counters.Counter private _milestoneIds;
    
    mapping(uint256 => Project) public projects;
    mapping(uint256 => ScopeNFT) public scopes;
    mapping(uint256 => Milestone) public milestones;
    mapping(uint256 => uint256[]) public projectScopes;
    mapping(uint256 => uint256[]) public scopeMilestones;
    mapping(uint256 => ESGMetrics) public projectESGMetrics;
    mapping(address => uint256[]) public contractorProjects;
    
    VerifiableCredentialRegistry public immutable credentialRegistry;
    SubcontractorRegistry public immutable subcontractorRegistry;
    
    event ProjectCreated(uint256 indexed projectId, string name, address owner, address generalContractor);
    event ScopeAssigned(uint256 indexed scopeId, uint256 indexed projectId, address subcontractor, uint256 value);
    event MilestoneCompleted(uint256 indexed milestoneId, uint256 indexed scopeId, uint256 value);
    event ESGMetricsUpdated(uint256 indexed projectId, uint256 energyRating, uint256 diversitySpend);
    
    constructor(
        address admin,
        VerifiableCredentialRegistry _credentialRegistry,
        SubcontractorRegistry _subcontractorRegistry
    ) ERC721("ConstructionScope", "SCOPE") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PROJECT_MANAGER_ROLE, admin);
        _grantRole(SUPERINTENDENT_ROLE, admin);
        _grantRole(INSPECTOR_ROLE, admin);
        _grantRole(ORACLE_ROLE, admin);
        
        credentialRegistry = _credentialRegistry;
        subcontractorRegistry = _subcontractorRegistry;
    }
    
    function createProject(
        string memory name,
        string memory projectAddress,
        string memory state,
        uint256 totalValue,
        uint256 startDate,
        uint256 scheduledEndDate,
        address owner,
        address generalContractor,
        string memory projectDataHash
    ) external onlyRole(PROJECT_MANAGER_ROLE) returns (uint256) {
        _projectIds.increment();
        uint256 projectId = _projectIds.current();
        
        projects[projectId] = Project({
            id: projectId,
            name: name,
            projectAddress: projectAddress,
            state: state,
            status: ProjectStatus.PLANNING,
            totalValue: totalValue,
            startDate: startDate,
            scheduledEndDate: scheduledEndDate,
            actualEndDate: 0,
            owner: owner,
            generalContractor: generalContractor,
            projectDataHash: projectDataHash,
            createdAt: block.timestamp
        });
        
        contractorProjects[generalContractor].push(projectId);
        
        emit ProjectCreated(projectId, name, owner, generalContractor);
        return projectId;
    }
    
    function createScopeNFT(
        uint256 projectId,
        string memory division,
        string memory scopeDescription,
        uint256 contractValue,
        string[] memory requiredCredentials,
        string memory scopeDataHash
    ) external onlyRole(PROJECT_MANAGER_ROLE) returns (uint256) {
        require(projects[projectId].id != 0, "Project does not exist");
        
        _scopeIds.increment();
        uint256 scopeId = _scopeIds.current();
        
        scopes[scopeId] = ScopeNFT({
            projectId: projectId,
            division: division,
            scopeDescription: scopeDescription,
            contractValue: contractValue,
            assignedSubcontractor: address(0),
            assignedAt: 0,
            status: MilestoneStatus.PENDING,
            requiredCredentials: requiredCredentials,
            scopeDataHash: scopeDataHash
        });
        
        projectScopes[projectId].push(scopeId);
        
        // Mint the NFT (initially to the general contractor)
        _mint(projects[projectId].generalContractor, scopeId);
        
        return scopeId;
    }
    
    function assignScope(uint256 scopeId, address subcontractor) external onlyRole(PROJECT_MANAGER_ROLE) {
        require(_exists(scopeId), "Scope NFT does not exist");
        require(scopes[scopeId].assignedSubcontractor == address(0), "Scope already assigned");
        
        ScopeNFT storage scope = scopes[scopeId];
        Project storage project = projects[scope.projectId];
        
        // Verify subcontractor eligibility
        uint256 subId = subcontractorRegistry.walletToSubId(subcontractor);
        require(subId != 0, "Subcontractor not registered");
        
        (bool eligible, string memory reason) = subcontractorRegistry.isEligibleForProject(
            subId,
            project.state,
            scope.division,
            0 // minimum rating
        );
        require(eligible, reason);
        
        // Check required credentials
        for (uint256 i = 0; i < scope.requiredCredentials.length; i++) {
            require(
                credentialRegistry.hasValidCredential(subcontractor, scope.requiredCredentials[i]),
                string(abi.encodePacked("Missing credential: ", scope.requiredCredentials[i]))
            );
        }
        
        scope.assignedSubcontractor = subcontractor;
        scope.assignedAt = block.timestamp;
        scope.status = MilestoneStatus.IN_PROGRESS;
        
        // Transfer NFT to subcontractor
        _transfer(ownerOf(scopeId), subcontractor, scopeId);
        
        emit ScopeAssigned(scopeId, scope.projectId, subcontractor, scope.contractValue);
    }
    
    function createMilestone(
        uint256 scopeId,
        string memory description,
        uint256 value,
        uint256 scheduledDate,
        address[] memory requiredApprovals
    ) external onlyRole(PROJECT_MANAGER_ROLE) returns (uint256) {
        require(_exists(scopeId), "Scope NFT does not exist");
        
        _milestoneIds.increment();
        uint256 milestoneId = _milestoneIds.current();
        
        Milestone storage milestone = milestones[milestoneId];
        milestone.id = milestoneId;
        milestone.scopeNFTId = scopeId;
        milestone.description = description;
        milestone.value = value;
        milestone.scheduledDate = scheduledDate;
        milestone.status = MilestoneStatus.PENDING;
        milestone.requiredApprovals = requiredApprovals;
        
        scopeMilestones[scopeId].push(milestoneId);
        
        return milestoneId;
    }
    
    function approveMilestone(uint256 milestoneId, string memory evidenceHash) external {
        Milestone storage milestone = milestones[milestoneId];
        require(milestone.id != 0, "Milestone does not exist");
        
        bool isApprover = false;
        for (uint256 i = 0; i < milestone.requiredApprovals.length; i++) {
            if (milestone.requiredApprovals[i] == msg.sender) {
                isApprover = true;
                break;
            }
        }
        require(isApprover || hasRole(INSPECTOR_ROLE, msg.sender), "Not authorized to approve");
        
        milestone.approvals[msg.sender] = true;
        
        if (bytes(evidenceHash).length > 0) {
            milestone.evidenceHash = evidenceHash;
        }
        
        // Check if all required approvals are received
        bool allApproved = true;
        for (uint256 i = 0; i < milestone.requiredApprovals.length; i++) {
            if (!milestone.approvals[milestone.requiredApprovals[i]]) {
                allApproved = false;
                break;
            }
        }
        
        if (allApproved) {
            milestone.status = MilestoneStatus.COMPLETED;
            milestone.completedDate = block.timestamp;
            
            emit MilestoneCompleted(milestoneId, milestone.scopeNFTId, milestone.value);
        }
    }
    
    function updateESGMetrics(
        uint256 projectId,
        uint256 energyRating,
        uint256 recycledContent,
        uint256 localSourcing,
        uint256 apprenticeHours,
        uint256 diversitySpend,
        bool greenCertified,
        string[] memory esgDataHashes
    ) external onlyRole(PROJECT_MANAGER_ROLE) {
        require(projects[projectId].id != 0, "Project does not exist");
        
        ESGMetrics storage metrics = projectESGMetrics[projectId];
        metrics.energyEfficiencyRating = energyRating;
        metrics.recycledContentPercentage = recycledContent;
        metrics.localSourcingPercentage = localSourcing;
        metrics.apprenticeshipHours = apprenticeHours;
        metrics.diversitySpend = diversitySpend;
        metrics.greenBuildingCertified = greenCertified;
        metrics.esgDataHashes = esgDataHashes;
        
        emit ESGMetricsUpdated(projectId, energyRating, diversitySpend);
    }
    
    function getProjectProgress(uint256 projectId) external view returns (
        uint256 totalMilestones,
        uint256 completedMilestones,
        uint256 totalValue,
        uint256 completedValue,
        uint256 percentComplete
    ) {
        uint256[] memory scopeIds = projectScopes[projectId];
        
        for (uint256 i = 0; i < scopeIds.length; i++) {
            uint256[] memory milestoneIds = scopeMilestones[scopeIds[i]];
            
            for (uint256 j = 0; j < milestoneIds.length; j++) {
                Milestone storage milestone = milestones[milestoneIds[j]];
                totalMilestones++;
                totalValue += milestone.value;
                
                if (milestone.status == MilestoneStatus.COMPLETED) {
                    completedMilestones++;
                    completedValue += milestone.value;
                }
            }
        }
        
        percentComplete = totalValue > 0 ? (completedValue * 100) / totalValue : 0;
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// PAYMENT AND SETTLEMENT SYSTEM - Instant, Atomic, Multi-State Compliant
// ═══════════════════════════════════════════════════════════════════════════════════════

/**
 * @title PaymentSettlementEngine
 * @dev Handles instant, atomic settlements with tax calculations and multi-party splits
 */
contract PaymentSettlementEngine is AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    
    bytes32 public constant SETTLEMENT_MANAGER_ROLE = keccak256("SETTLEMENT_MANAGER_ROLE");
    bytes32 public constant TAX_ORACLE_ROLE = keccak256("TAX_ORACLE_ROLE");
    
    enum SettlementStatus { PENDING, PROCESSING, COMPLETED, FAILED, DISPUTED }
    
    struct TaxJurisdiction {
        string name;
        uint256 salesTaxRate; // basis points (500 = 5%)
        uint256 useTaxRate;
        uint256 laborTaxRate;
        bool materialTaxable;
        bool laborTaxable;
        bool serviceTaxable;
        string taxIdRequired; // EIN, state tax ID, etc.
        uint256 lastUpdated;
    }
    
    struct PaymentSplit {
        address recipient;
        string role; // "subcontractor", "commission", "retainage", "tax", "insurance"
        uint256 amount;
        string currency; // "USD", "USDC", etc.
        string taxCategory; // "materials", "labor", "services"
        string metadata; // JSON with additional data
    }
    
    struct SettlementInstruction {
        uint256 id;
        uint256 projectId;
        uint256 scopeId;
        address payer;
        uint256 totalAmount;
        PaymentSplit[] splits;
        string jurisdiction; // state-city combination
        SettlementStatus status;
        uint256 createdAt;
        uint256 processedAt;
        string evidenceHash; // IPFS hash with supporting docs
        string calculationHash; // IPFS hash with tax calculations
    }
    
    struct CommissionStructure {
        address salesRep;
        uint256 baseRate; // basis points
        uint256 tierThreshold1;
        uint256 tierRate1;
        uint256 tierThreshold2;
        uint256 tierRate2;
        uint256 maxCommission; // maximum commission amount
        bool active;
    }
    
    struct RetainagePolicy {
        uint256 defaultRate; // basis points (1000 = 10%)
        mapping(string => uint256) divisionRates; // CSI division -> rate
        uint256 releaseThreshold; // percentage of work complete for release
        bool requireLienWaiver;
    }
    
    Counters.Counter private _settlementIds;
    
    mapping(uint256 => SettlementInstruction) public settlements;
    mapping(string => TaxJurisdiction) public taxJurisdictions;
    mapping(address => CommissionStructure) public commissionStructures;
    mapping(uint256 => RetainagePolicy) public retainagePolicies; // projectId -> policy
    mapping(uint256 => uint256) public projectRetainageHeld;
    mapping(string => uint256) public taxRemittanceBalances; // jurisdiction -> amount
    
    // Payment tokens
    IERC20 public immutable USDC;
    IERC20 public immutable USDT;
    mapping(string => IERC20) public acceptedTokens;
    
    event SettlementCreated(uint256 indexed settlementId, uint256 indexed projectId, address payer, uint256 amount);
    event SettlementProcessed(uint256 indexed settlementId, uint256 totalSplits, uint256 taxAmount);
    event TaxRemitted(string jurisdiction, uint256 amount, string period);
    event RetainageReleased(uint256 indexed projectId, address subcontractor, uint256 amount);
    
    constructor(
        address admin,
        IERC20 _usdc,
        IERC20 _usdt
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(SETTLEMENT_MANAGER_ROLE, admin);
        _grantRole(TAX_ORACLE_ROLE, admin);
        
        USDC = _usdc;
        USDT = _usdt;
        acceptedTokens["USDC"] = _usdc;
        acceptedTokens["USDT"] = _usdt;
        
        _initializeTaxJurisdictions();
    }
    
    function _initializeTaxJurisdictions() internal {
        // Florida - Storm restoration heavy state
        taxJurisdictions["FL-MIAMI-DADE"] = TaxJurisdiction({
            name: "Miami-Dade County, FL",
            salesTaxRate: 700, // 7%
            useTaxRate: 700,
            laborTaxRate: 0,
            materialTaxable: true,
            laborTaxable: false,
            serviceTaxable: true,
            taxIdRequired: "FL_TAX_ID",
            lastUpdated: block.timestamp
        });
        
        // Texas
        taxJurisdictions["TX-HARRIS"] = TaxJurisdiction({
            name: "Harris County, TX",
            salesTaxRate: 825, // 8.25%
            useTaxRate: 825,
            laborTaxRate: 0,
            materialTaxable: true,
            laborTaxable: false,
            serviceTaxable: true,
            taxIdRequired: "TX_TAX_ID",
            lastUpdated: block.timestamp
        });
        
        // Louisiana - Hurricane prone
        taxJurisdictions["LA-ORLEANS"] = TaxJurisdiction({
            name: "Orleans Parish, LA",
            salesTaxRate: 995, // 9.95%
            useTaxRate: 995,
            laborTaxRate: 0,
            materialTaxable: true,
            laborTaxable: false,
            serviceTaxable: true,
            taxIdRequired: "LA_TAX_ID",
            lastUpdated: block.timestamp
        });
    }
    
    function createSettlement(
        uint256 projectId,
        uint256 scopeId,
        address payer,
        uint256 totalAmount,
        string memory jurisdiction,
        PaymentSplit[] memory splits,
        string memory evidenceHash
    ) external onlyRole(SETTLEMENT_MANAGER_ROLE) returns (uint256) {
        require(taxJurisdictions[jurisdiction].lastUpdated > 0, "Unknown jurisdiction");
        require(totalAmount > 0, "Invalid amount");
        
        _settlementIds.increment();
        uint256 settlementId = _settlementIds.current();
        
        SettlementInstruction storage settlement = settlements[settlementId];
        settlement.id = settlementId;
        settlement.projectId = projectId;
        settlement.scopeId = scopeId;
        settlement.payer = payer;
        settlement.totalAmount = totalAmount;
        settlement.jurisdiction = jurisdiction;
        settlement.status = SettlementStatus.PENDING;
        settlement.createdAt = block.timestamp;
        settlement.evidenceHash = evidenceHash;
        
        // Copy splits
        for (uint256 i = 0; i < splits.length; i++) {
            settlement.splits.push(splits[i]);
        }
        
        emit SettlementCreated(settlementId, projectId, payer, totalAmount);
        return settlementId;
    }
    
    function processSettlement(
        uint256 settlementId,
        string memory calculationHash
    ) external onlyRole(SETTLEMENT_MANAGER_ROLE) nonReentrant {
        SettlementInstruction storage settlement = settlements[settlementId];
        require(settlement.status == SettlementStatus.PENDING, "Settlement not pending");
        
        settlement.status = SettlementStatus.PROCESSING;
        settlement.calculationHash = calculationHash;
        
        TaxJurisdiction storage jurisdiction = taxJurisdictions[settlement.jurisdiction];
        uint256 totalTaxAmount = 0;
        
        // Process each split
        PaymentSplit[] storage splits = settlement.splits;
        for (uint256 i = 0; i < splits.length; i++) {
            PaymentSplit storage split = splits[i];
            
            if (keccak256(bytes(split.role)) == keccak256(bytes("tax"))) {
                // Tax payment
                taxRemittanceBalances[settlement.jurisdiction] += split.amount;
                totalTaxAmount += split.amount;
            } else if (keccak256(bytes(split.role)) == keccak256(bytes("retainage"))) {
                // Retainage holding
                projectRetainageHeld[settlement.projectId] += split.amount;
            } else {
                // Direct payment to recipient
                IERC20 token = acceptedTokens[split.currency];
                require(address(token) != address(0), "Unsupported currency");
                
                token.safeTransferFrom(settlement.payer, split.recipient, split.amount);
            }
        }
        
        settlement.status = SettlementStatus.COMPLETED;
        settlement.processedAt = block.timestamp;
        
        emit SettlementProcessed(settlementId, splits.length, totalTaxAmount);
    }
    
    function calculateTaxSplits(
        uint256 materialsCost,
        uint256 laborCost,
        uint256 servicesCost,
        string memory jurisdiction
    ) external view returns (PaymentSplit[] memory taxSplits) {
        TaxJurisdiction storage tax = taxJurisdictions[jurisdiction];
        require(tax.lastUpdated > 0, "Unknown jurisdiction");
        
        PaymentSplit[] memory splits = new PaymentSplit[](3);
        uint256 splitCount = 0;
        
        if (tax.materialTaxable && materialsCost > 0) {
            splits[splitCount] = PaymentSplit({
                recipient: address(this), // Tax holding contract
                role: "tax",
                amount: (materialsCost * tax.salesTaxRate) / 10000,
                currency: "USDC",
                taxCategory: "materials",
                metadata: string(abi.encodePacked('{"jurisdiction":"', jurisdiction, '","type":"sales_tax"}'))
            });
            splitCount++;
        }
        
        if (tax.laborTaxable && laborCost > 0) {
            splits[splitCount] = PaymentSplit({
                recipient: address(this),
                role: "tax",
                amount: (laborCost * tax.laborTaxRate) / 10000,
                currency: "USDC",
                taxCategory: "labor",
                metadata: string(abi.encodePacked('{"jurisdiction":"', jurisdiction, '","type":"labor_tax"}'))
            });
            splitCount++;
        }
        
        if (tax.serviceTaxable && servicesCost > 0) {
            splits[splitCount] = PaymentSplit({
                recipient: address(this),
                role: "tax",
                amount: (servicesCost * tax.salesTaxRate) / 10000,
                currency: "USDC",
                taxCategory: "services",
                metadata: string(abi.encodePacked('{"jurisdiction":"', jurisdiction, '","type":"service_tax"}'))
            });
            splitCount++;
        }
        
        // Resize array to actual count
        PaymentSplit[] memory result = new PaymentSplit[](splitCount);
        for (uint256 i = 0; i < splitCount; i++) {
            result[i] = splits[i];
        }
        
        return result;
    }
    
    function calculateCommission(
        address salesRep,
        uint256 contractValue
    ) external view returns (uint256 commission) {
        CommissionStructure storage structure = commissionStructures[salesRep];
        if (!structure.active || contractValue == 0) {
            return 0;
        }
        
        uint256 totalCommission = 0;
        
        // Base rate on entire amount
        totalCommission += (contractValue * structure.baseRate) / 10000;
        
        // Tier 1 bonus
        if (contractValue > structure.tierThreshold1 && structure.tierRate1 > 0) {
            uint256 tier1Amount = contractValue > structure.tierThreshold2 
                ? structure.tierThreshold2 - structure.tierThreshold1
                : contractValue - structure.tierThreshold1;
            totalCommission += (tier1Amount * structure.tierRate1) / 10000;
        }
        
        // Tier 2 bonus
        if (contractValue > structure.tierThreshold2 && structure.tierRate2 > 0) {
            uint256 tier2Amount = contractValue - structure.tierThreshold2;
            totalCommission += (tier2Amount * structure.tierRate2) / 10000;
        }
        
        // Cap at maximum
        if (structure.maxCommission > 0 && totalCommission > structure.maxCommission) {
            totalCommission = structure.maxCommission;
        }
        
        return totalCommission;
    }
    
    function releaseRetainage(
        uint256 projectId,
        address subcontractor,
        uint256 amount,
        string memory lienWaiverHash
    ) external onlyRole(SETTLEMENT_MANAGER_ROLE) {
        require(projectRetainageHeld[projectId] >= amount, "Insufficient retainage held");
        
        RetainagePolicy storage policy = retainagePolicies[projectId];
        if (policy.requireLienWaiver) {
            require(bytes(lienWaiverHash).length > 0, "Lien waiver required");
        }
        
        projectRetainageHeld[projectId] -= amount;
        USDC.safeTransfer(subcontractor, amount);
        
        emit RetainageReleased(projectId, subcontractor, amount);
    }
    
    function setCommissionStructure(
        address salesRep,
        uint256 baseRate,
        uint256 tierThreshold1,
        uint256 tierRate1,
        uint256 tierThreshold2,
        uint256 tierRate2,
        uint256 maxCommission
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        commissionStructures[salesRep] = CommissionStructure({
            salesRep: salesRep,
            baseRate: baseRate,
            tierThreshold1: tierThreshold1,
            tierRate1: tierRate1,
            tierThreshold2: tierThreshold2,
            tierRate2: tierRate2,
            maxCommission: maxCommission,
            active: true
        });
    }
    
    function setRetainagePolicy(
        uint256 projectId,
        uint256 defaultRate,
        string[] memory divisions,
        uint256[] memory rates,
        uint256 releaseThreshold,
        bool requireLienWaiver
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(divisions.length == rates.length, "Array length mismatch");
        
        RetainagePolicy storage policy = retainagePolicies[projectId];
        policy.defaultRate = defaultRate;
        policy.releaseThreshold = releaseThreshold;
        policy.requireLienWaiver = requireLienWaiver;
        
        for (uint256 i = 0; i < divisions.length; i++) {
            policy.divisionRates[divisions[i]] = rates[i];
        }
    }
    
    function updateTaxJurisdiction(
        string memory code,
        string memory name,
        uint256 salesTaxRate,
        uint256 useTaxRate,
        uint256 laborTaxRate,
        bool materialTaxable,
        bool laborTaxable,
        bool serviceTaxable,
        string memory taxIdRequired
    ) external onlyRole(TAX_ORACLE_ROLE) {
        taxJurisdictions[code] = TaxJurisdiction({
            name: name,
            salesTaxRate: salesTaxRate,
            useTaxRate: useTaxRate,
            laborTaxRate: laborTaxRate,
            materialTaxable: materialTaxable,
            laborTaxable: laborTaxable,
            serviceTaxable: serviceTaxable,
            taxIdRequired: taxIdRequired,
            lastUpdated: block.timestamp
        });
    }
    
    function remitTaxes(
        string memory jurisdiction,
        uint256 amount,
        string memory period,
        address taxAuthority
    ) external onlyRole(TAX_ORACLE_ROLE) {
        require(taxRemittanceBalances[jurisdiction] >= amount, "Insufficient tax balance");
        
        taxRemittanceBalances[jurisdiction] -= amount;
        USDC.safeTransfer(taxAuthority, amount);
        
        emit TaxRemitted(jurisdiction, amount, period);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// INCENTIVE AND ESG TRACKING - Federal/State/Local Rebates and Credits
// ═══════════════════════════════════════════════════════════════════════════════════════

/**
 * @title IncentiveTrackingEngine
 * @dev Tracks and calculates energy incentives, tax credits, and ESG metrics
 */
contract IncentiveTrackingEngine is AccessControl, Pausable {
    using Counters for Counters.Counter;
    
    bytes32 public constant INCENTIVE_MANAGER_ROLE = keccak256("INCENTIVE_MANAGER_ROLE");
    bytes32 public constant ENERGY_AUDITOR_ROLE = keccak256("ENERGY_AUDITOR_ROLE");
    
    enum IncentiveType { 
        FEDERAL_TAX_CREDIT,    // ITC, PTC, 45L, 179D
        STATE_REBATE,          // State-specific programs
        LOCAL_INCENTIVE,       // City/county programs
        UTILITY_REBATE,        // Utility company programs
        FINANCING,             // PACE, C-PACE
        OPPORTUNITY_ZONE,      // OZ benefits
        GREEN_BUILDING         // LEED, ENERGY STAR
    }
    
    enum IncentiveStatus {
        ELIGIBLE,
        APPLIED,
        APPROVED,
        RECEIVED,
        DENIED,
        EXPIRED
    }
    
    struct IncentiveProgram {
        uint256 id;
        string name;
        IncentiveType incentiveType;
        string jurisdiction; // Federal, state code, or city code
        uint256 maxIncentive; // Maximum incentive amount
        uint256 percentageRate; // Percentage of qualifying costs (basis points)
        uint256 validFrom;
        uint256 validTo;
        string[] eligibilityCriteria;
        string[] requiredDocuments;
        bool active;
        string programDataHash; // IPFS hash with full program details
    }
    
    struct ProjectIncentive {
        uint256 id;
        uint256 projectId;
        uint256 programId;
        uint256 qualifyingCosts;
        uint256 calculatedIncentive;
        IncentiveStatus status;
        string applicationHash; // IPFS hash of application documents
        string approvalReference; // External approval/tracking number
        uint256 appliedAt;
        uint256 approvedAt;
        uint256 receivedAt;
        address applicant;
    }
    
    struct EnergyMetrics {
        uint256 projectId;
        uint256 baselineEnergyUse; // kWh/year
        uint256 projectedEnergyUse; // kWh/year after improvements
        uint256 energySavings; // kWh/year saved
        uint256 energyEfficiencyRating; // HERS, Energy Star score, etc.
        uint256 renewableEnergyGeneration; // kWh/year generated
        uint256 carbonFootprintReduction; // tons CO2 equivalent
        bool thirdPartyVerified;
        string verificationHash; // IPFS hash of verification docs
        uint256 lastUpdated;
    }
    
    struct ESGScore {
        uint256 projectId;
        uint256 environmentalScore; // 0-100
        uint256 socialScore; // 0-100
        uint256 governanceScore; // 0-100
        uint256 overallScore; // 0-100
        string[] certifications; // LEED, BREEAM, etc.
        uint256 diversitySpendPercentage; // Percentage of spend with diverse suppliers
        uint256 localSpendPercentage; // Percentage of spend with local suppliers
        uint256 apprenticeshipHours; // Total apprenticeship hours on project
        uint256 safetyIncidents; // Number of safety incidents
        string esgReportHash; // IPFS hash of full ESG report
        uint256 lastUpdated;
    }
    
    Counters.Counter private _programIds;
    Counters.Counter private _incentiveIds;
    
    mapping(uint256 => IncentiveProgram) public incentivePrograms;
    mapping(uint256 => ProjectIncentive) public projectIncentives;
    mapping(uint256 => EnergyMetrics) public energyMetrics;
    mapping(uint256 => ESGScore) public esgScores;
    mapping(uint256 => uint256[]) public projectIncentiveIds;
    mapping(string => uint256[]) public jurisdictionPrograms;
    
    event IncentiveProgramAdded(uint256 indexed programId, string name, IncentiveType incentiveType);
    event IncentiveApplicationSubmitted(uint256 indexed incentiveId, uint256 indexed projectId, uint256 amount);
    event IncentiveApproved(uint256 indexed incentiveId, uint256 approvedAmount, string reference);
    event EnergyMetricsUpdated(uint256 indexed projectId, uint256 energySavings, bool verified);
    event ESGScoreCalculated(uint256 indexed projectId, uint256 overallScore, uint256 diversitySpend);
    
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(INCENTIVE_MANAGER_ROLE, admin);
        _grantRole(ENERGY_AUDITOR_ROLE, admin);
        
        _initializeIncentivePrograms();
    }
    
    function _initializeIncentivePrograms() internal {
        // Federal Investment Tax Credit (ITC)
        _addIncentiveProgram(
            "Federal Investment Tax Credit (ITC)",
            IncentiveType.FEDERAL_TAX_CREDIT,
            "FEDERAL",
            0, // No max limit
            3000, // 30% (3000 basis points)
            block.timestamp,
            block.timestamp + (10 * 365 days), // 10 year program
            _createStringArray(["solar_installation", "battery_storage", "geothermal"]),
            _createStringArray(["irs_form_5695", "equipment_certification", "installation_certification"]),
            "QmITCProgramHash"
        );
        
        // Section 179D Commercial Energy Efficiency Deduction
        _addIncentiveProgram(
            "Section 179D Energy Efficient Commercial Building Deduction",
            IncentiveType.FEDERAL_TAX_CREDIT,
            "FEDERAL",
            5 ether * 1000000, // $5 per sq ft maximum
            0, // Fixed amount per sq ft, not percentage
            block.timestamp,
            block.timestamp + (5 * 365 days),
            _createStringArray(["commercial_building", "50_percent_energy_reduction", "ashrae_compliance"]),
            _createStringArray(["energy_model", "ashrae_certification", "tax_form_179D"]),
            "Qm179DProgramHash"
        );
        
        // Section 45L Energy Efficient Homes Credit
        _addIncentiveProgram(
            "Section 45L Energy Efficient Home Credit",
            IncentiveType.FEDERAL_TAX_CREDIT,
            "FEDERAL",
            5000 ether, // $5,000 per unit
            0, // Fixed amount per unit
            block.timestamp,
            block.timestamp + (3 * 365 days),
            _createStringArray(["new_construction", "energy_star", "multifamily_residential"]),
            _createStringArray(["energy_star_certification", "hers_rating", "tax_form_45L"]),
            "Qm45LProgramHash"
        );
        
        // Florida PACE Financing
        _addIncentiveProgram(
            "Florida PACE Financing",
            IncentiveType.FINANCING,
            "FL",
            1000000 ether, // $1M max project
            10000, // 100% financing available
            block.timestamp,
            block.timestamp + (20 * 365 days),
            _createStringArray(["commercial_property", "energy_efficiency", "renewable_energy"]),
            _createStringArray(["property_assessment", "energy_audit", "financing_application"]),
            "QmFLPACEProgramHash"
        );
    }
    
    function _addIncentiveProgram(
        string memory name,
        IncentiveType incentiveType,
        string memory jurisdiction,
        uint256 maxIncentive,
        uint256 percentageRate,
        uint256 validFrom,
        uint256 validTo,
        string[] memory eligibilityCriteria,
        string[] memory requiredDocuments,
        string memory programDataHash
    ) internal returns (uint256) {
        _programIds.increment();
        uint256 programId = _programIds.current();
        
        incentivePrograms[programId] = IncentiveProgram({
            id: programId,
            name: name,
            incentiveType: incentiveType,
            jurisdiction: jurisdiction,
            maxIncentive: maxIncentive,
            percentageRate: percentageRate,
            validFrom: validFrom,
            validTo: validTo,
            eligibilityCriteria: eligibilityCriteria,
            requiredDocuments: requiredDocuments,
            active: true,
            programDataHash: programDataHash
        });
        
        jurisdictionPrograms[jurisdiction].push(programId);
        
        return programId;
    }
    
    function _createStringArray(string[3] memory items) internal pure returns (string[] memory) {
        string[] memory result = new string[](3);
        result[0] = items[0];
        result[1] = items[1];
        result[2] = items[2];
        return result;
    }
    
    function addIncentiveProgram(
        string memory name,
        IncentiveType incentiveType,
        string memory jurisdiction,
        uint256 maxIncentive,
        uint256 percentageRate,
        uint256 validFrom,
        uint256 validTo,
        string[] memory eligibilityCriteria,
        string[] memory requiredDocuments,
        string memory programDataHash
    ) external onlyRole(INCENTIVE_MANAGER_ROLE) returns (uint256) {
        uint256 programId = _addIncentiveProgram(
            name,
            incentiveType,
            jurisdiction,
            maxIncentive,
            percentageRate,
            validFrom,
            validTo,
            eligibilityCriteria,
            requiredDocuments,
            programDataHash
        );
        
        emit IncentiveProgramAdded(programId, name, incentiveType);
        return programId;
    }
    
    function calculateIncentive(
        uint256 programId,
        uint256 qualifyingCosts
    ) external view returns (uint256 incentiveAmount) {
        IncentiveProgram memory program = incentivePrograms[programId];
        require(program.active, "Program not active");
        require(block.timestamp >= program.validFrom && block.timestamp <= program.validTo, "Program not valid");
        
        uint256 calculated = 0;
        
        if (program.percentageRate > 0) {
            calculated = (qualifyingCosts * program.percentageRate) / 10000;
        } else {
            // Fixed amount incentive (like 179D per sq ft)
            calculated = program.maxIncentive;
        }
        
        if (program.maxIncentive > 0 && calculated > program.maxIncentive) {
            calculated = program.maxIncentive;
        }
        
        return calculated;
    }
    
    function applyForIncentive(
        uint256 projectId,
        uint256 programId,
        uint256 qualifyingCosts,
        string memory applicationHash
    ) external onlyRole(INCENTIVE_MANAGER_ROLE) returns (uint256) {
        IncentiveProgram memory program = incentivePrograms[programId];
        require(program.active, "Program not active");
        
        uint256 calculatedIncentive = this.calculateIncentive(programId, qualifyingCosts);
        
        _incentiveIds.increment();
        uint256 incentiveId = _incentiveIds.current();
        
        projectIncentives[incentiveId] = ProjectIncentive({
            id: incentiveId,
            projectId: projectId,
            programId: programId,
            qualifyingCosts: qualifyingCosts,
            calculatedIncentive: calculatedIncentive,
            status: IncentiveStatus.APPLIED,
            applicationHash: applicationHash,
            approvalReference: "",
            appliedAt: block.timestamp,
            approvedAt: 0,
            receivedAt: 0,
            applicant: msg.sender
        });
        
        projectIncentiveIds[projectId].push(incentiveId);
        
        emit IncentiveApplicationSubmitted(incentiveId, projectId, calculatedIncentive);
        return incentiveId;
    }
    
    function updateIncentiveStatus(
        uint256 incentiveId,
        IncentiveStatus status,
        string memory approvalReference
    ) external onlyRole(INCENTIVE_MANAGER_ROLE) {
        ProjectIncentive storage incentive = projectIncentives[incentiveId];
        require(incentive.id != 0, "Incentive does not exist");
        
        incentive.status = status;
        
        if (status == IncentiveStatus.APPROVED) {
            incentive.approvedAt = block.timestamp;
            incentive.approvalReference = approvalReference;
            emit IncentiveApproved(incentiveId, incentive.calculatedIncentive, approvalReference);
        } else if (status == IncentiveStatus.RECEIVED) {
            incentive.receivedAt = block.timestamp;
        }
    }
    
    function updateEnergyMetrics(
        uint256 projectId,
        uint256 baselineEnergyUse,
        uint256 projectedEnergyUse,
        uint256 renewableEnergyGeneration,
        uint256 energyEfficiencyRating,
        bool thirdPartyVerified,
        string memory verificationHash
    ) external onlyRole(ENERGY_AUDITOR_ROLE) {
        uint256 energySavings = baselineEnergyUse > projectedEnergyUse ? 
            baselineEnergyUse - projectedEnergyUse : 0;
        
        // Simple carbon footprint calculation (0.4 kg CO2/kWh average grid)
        uint256 carbonReduction = (energySavings * 4) / 10; // 0.4 kg per kWh
        
        energyMetrics[projectId] = EnergyMetrics({
            projectId: projectId,
            baselineEnergyUse: baselineEnergyUse,
            projectedEnergyUse: projectedEnergyUse,
            energySavings: energySavings,
            energyEfficiencyRating: energyEfficiencyRating,
            renewableEnergyGeneration: renewableEnergyGeneration,
            carbonFootprintReduction: carbonReduction,
            thirdPartyVerified: thirdPartyVerified,
            verificationHash: verificationHash,
            lastUpdated: block.timestamp
        });
        
        emit EnergyMetricsUpdated(projectId, energySavings, thirdPartyVerified);
    }
    
    function calculateESGScore(
        uint256 projectId,
        uint256 diversitySpendPercentage,
        uint256 localSpendPercentage,
        uint256 apprenticeshipHours,
        uint256 safetyIncidents,
        string[] memory certifications,
        string memory esgReportHash
    ) external onlyRole(INCENTIVE_MANAGER_ROLE) returns (uint256 overallScore) {
        // Environmental Score (40% of total)
        uint256 environmentalScore = 0;
        EnergyMetrics memory metrics = energyMetrics[projectId];
        
        if (metrics.energySavings > 0) {
            environmentalScore += 30; // Energy efficiency
        }
        if (metrics.renewableEnergyGeneration > 0) {
            environmentalScore += 25; // Renewable energy
        }
        if (certifications.length > 0) {
            environmentalScore += 25; // Green certifications
        }
        if (metrics.thirdPartyVerified) {
            environmentalScore += 20; // Third party verification
        }
        environmentalScore = environmentalScore > 100 ? 100 : environmentalScore;
        
        // Social Score (35% of total)
        uint256 socialScore = 0;
        socialScore += diversitySpendPercentage > 30 ? 30 : diversitySpendPercentage;
        socialScore += localSpendPercentage > 50 ? 25 : (localSpendPercentage / 2);
        socialScore += apprenticeshipHours > 1000 ? 25 : (apprenticeshipHours / 40);
        socialScore += safetyIncidents == 0 ? 20 : (safetyIncidents > 5 ? 0 : 20 - (safetyIncidents * 4));
        socialScore = socialScore > 100 ? 100 : socialScore;
        
        // Governance Score (25% of total)
        uint256 governanceScore = 80; // Base score for using Web3 transparency
        if (bytes(esgReportHash).length > 0) {
            governanceScore += 20; // ESG reporting
        }
        governanceScore = governanceScore > 100 ? 100 : governanceScore;
        
        // Calculate weighted overall score
        overallScore = (environmentalScore * 40 + socialScore * 35 + governanceScore * 25) / 100;
        
        esgScores[projectId] = ESGScore({
            projectId: projectId,
            environmentalScore: environmentalScore,
            socialScore: socialScore,
            governanceScore: governanceScore,
            overallScore: overallScore,
            certifications: certifications,
            diversitySpendPercentage: diversitySpendPercentage,
            localSpendPercentage: localSpendPercentage,
            apprenticeshipHours: apprenticeshipHours,
            safetyIncidents: safetyIncidents,
            esgReportHash: esgReportHash,
            lastUpdated: block.timestamp
        });
        
        emit ESGScoreCalculated(projectId, overallScore, diversitySpendPercentage);
        return overallScore;
    }
    
    function getProjectIncentiveSummary(uint256 projectId) external view returns (
        uint256 totalAppliedAmount,
        uint256 totalApprovedAmount,
        uint256 totalReceivedAmount,
        uint256[] memory incentiveIds
    ) {
        uint256[] memory ids = projectIncentiveIds[projectId];
        
        for (uint256 i = 0; i < ids.length; i++) {
            ProjectIncentive memory incentive = projectIncentives[ids[i]];
            totalAppliedAmount += incentive.calculatedIncentive;
            
            if (incentive.status == IncentiveStatus.APPROVED || incentive.status == IncentiveStatus.RECEIVED) {
                totalApprovedAmount += incentive.calculatedIncentive;
            }
            
            if (incentive.status == IncentiveStatus.RECEIVED) {
                totalReceivedAmount += incentive.calculatedIncentive;
            }
        }
        
        return (totalAppliedAmount, totalApprovedAmount, totalReceivedAmount, ids);
    }
    
    function getAvailableIncentives(
        string memory jurisdiction,
        IncentiveType incentiveType
    ) external view returns (uint256[] memory availablePrograms) {
        uint256[] memory jurisdictionIds = jurisdictionPrograms[jurisdiction];
        uint256[] memory filtered = new uint256[](jurisdictionIds.length);
        uint256 count = 0;
        
        for (uint256 i = 0; i < jurisdictionIds.length; i++) {
            IncentiveProgram memory program = incentivePrograms[jurisdictionIds[i]];
            if (program.active && 
                program.incentiveType == incentiveType && 
                block.timestamp >= program.validFrom && 
                block.timestamp <= program.validTo) {
                filtered[count] = jurisdictionIds[i];
                count++;
            }
        }
        
        // Resize array
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = filtered[i];
        }
        
        return result;
    }
}