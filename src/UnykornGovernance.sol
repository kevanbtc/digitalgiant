// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./UnykornToken.sol";
import "./AssetVault.sol";
import "./RevVault.sol";
import "./SalesForceManager.sol";

/**
 * @title Unykorn DAO Governance - Decentralized Parameter Control
 * @dev Token-weighted voting with multi-sig security and time delays
 */
contract UnykornGovernance is AccessControl, ReentrancyGuard {
    using ECDSA for bytes32;
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    
    UnykornToken public unykornToken;
    AssetVault public assetVault;
    RevVault public revVault;
    SalesForceManager public salesForceManager;
    
    // Proposal types
    enum ProposalType {
        BURN_RATE,          // Change token burn rate
        COMMISSION_STRUCTURE, // Modify commission rates
        VAULT_ALLOCATION,   // Update vault asset allocation
        GENERAL            // General governance proposal
    }
    
    // Proposal status
    enum ProposalStatus {
        PENDING,           // Proposal created, voting not started
        ACTIVE,            // Voting in progress
        SUCCEEDED,         // Proposal passed
        FAILED,            // Proposal failed
        QUEUED,            // Passed, waiting for timelock
        EXECUTED,          // Proposal executed
        CANCELLED          // Proposal cancelled
    }
    
    // Proposal structure
    struct Proposal {
        uint256 id;
        address proposer;
        ProposalType proposalType;
        string title;
        string description;
        bytes executionData;        // Encoded function calls
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        uint256 startTime;
        uint256 endTime;
        uint256 executionTime;      // When proposal can be executed (after timelock)
        ProposalStatus status;
        bool executed;
        mapping(address => bool) hasVoted;
        mapping(address => uint256) voteWeight;
    }
    
    // Multi-sig configuration
    struct MultiSigConfig {
        address[] signers;
        uint256 requiredSignatures;
        mapping(address => bool) isSigner;
        mapping(bytes32 => mapping(address => bool)) signatures;
        mapping(bytes32 => uint256) signatureCount;
    }
    
    // Governance parameters
    struct GovernanceParams {
        uint256 votingDelay;        // Delay before voting starts
        uint256 votingPeriod;       // How long voting lasts
        uint256 timelockDelay;      // Delay before execution
        uint256 proposalThreshold;  // Minimum tokens to create proposal
        uint256 quorumVotes;        // Minimum votes needed for quorum
        uint256 maxBurnRate;        // Maximum allowed burn rate
        uint256 maxCommissionRate;  // Maximum commission rate
    }
    
    // State variables
    mapping(uint256 => Proposal) public proposals;
    MultiSigConfig private multiSig;
    GovernanceParams public govParams;
    
    uint256 public proposalCount;
    uint256 public lastProposalId;
    
    // Events
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        ProposalType proposalType,
        string title
    );
    event VoteCast(
        address indexed voter,
        uint256 indexed proposalId,
        uint8 support,
        uint256 weight,
        string reason
    );
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event ProposalQueued(uint256 indexed proposalId, uint256 executionTime);
    event ProposalCancelled(uint256 indexed proposalId);
    event MultiSigSignature(bytes32 indexed hash, address indexed signer);
    event GovernanceParamsUpdated(string parameter, uint256 oldValue, uint256 newValue);
    
    constructor(
        address _unykornToken,
        address _assetVault,
        address _revVault,
        address _salesForceManager,
        address[] memory _multiSigSigners,
        uint256 _requiredSignatures
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(EXECUTOR_ROLE, msg.sender);
        _grantRole(GUARDIAN_ROLE, msg.sender);
        
        unykornToken = UnykornToken(_unykornToken);
        assetVault = AssetVault(_assetVault);
        revVault = RevVault(_revVault);
        salesForceManager = SalesForceManager(_salesForceManager);
        
        // Initialize multi-sig
        _initializeMultiSig(_multiSigSigners, _requiredSignatures);
        
        // Initialize governance parameters
        govParams = GovernanceParams({
            votingDelay: 1 days,            // 1 day delay before voting
            votingPeriod: 7 days,           // 7 day voting period
            timelockDelay: 2 days,          // 2 day timelock
            proposalThreshold: 100000 * 10**18, // 100K tokens to propose
            quorumVotes: 1000000 * 10**18,  // 1M tokens for quorum
            maxBurnRate: 1000,              // 10% max burn rate
            maxCommissionRate: 5000         // 50% max commission
        });
    }
    
    /**
     * @dev Initialize multi-signature configuration
     */
    function _initializeMultiSig(
        address[] memory signers,
        uint256 requiredSigs
    ) internal {
        require(signers.length >= requiredSigs, "Invalid signer count");
        require(requiredSigs > 0, "Must require at least one signature");
        
        multiSig.signers = signers;
        multiSig.requiredSignatures = requiredSigs;
        
        for (uint i = 0; i < signers.length; i++) {
            multiSig.isSigner[signers[i]] = true;
            _grantRole(GUARDIAN_ROLE, signers[i]);
        }
    }
    
    /**
     * @dev Create a new governance proposal
     */
    function propose(
        ProposalType proposalType,
        string memory title,
        string memory description,
        bytes memory executionData
    ) external returns (uint256) {
        require(
            unykornToken.balanceOf(msg.sender) >= govParams.proposalThreshold,
            "Insufficient tokens to propose"
        );
        
        uint256 proposalId = proposalCount++;
        Proposal storage proposal = proposals[proposalId];
        
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.proposalType = proposalType;
        proposal.title = title;
        proposal.description = description;
        proposal.executionData = executionData;
        proposal.startTime = block.timestamp + govParams.votingDelay;
        proposal.endTime = proposal.startTime + govParams.votingPeriod;
        proposal.status = ProposalStatus.PENDING;
        
        lastProposalId = proposalId;
        
        emit ProposalCreated(proposalId, msg.sender, proposalType, title);
        return proposalId;
    }
    
    /**
     * @dev Cast vote on a proposal
     */
    function castVote(
        uint256 proposalId,
        uint8 support,
        string memory reason
    ) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.ACTIVE, "Voting not active");
        require(block.timestamp >= proposal.startTime, "Voting not started");
        require(block.timestamp <= proposal.endTime, "Voting ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        uint256 votes = unykornToken.balanceOf(msg.sender);
        require(votes > 0, "No voting power");
        
        proposal.hasVoted[msg.sender] = true;
        proposal.voteWeight[msg.sender] = votes;
        
        if (support == 0) {
            proposal.againstVotes += votes;
        } else if (support == 1) {
            proposal.forVotes += votes;
        } else {
            proposal.abstainVotes += votes;
        }
        
        emit VoteCast(msg.sender, proposalId, support, votes, reason);
        
        // Auto-update status if voting period ended
        if (block.timestamp > proposal.endTime) {
            _updateProposalStatus(proposalId);
        }
    }
    
    /**
     * @dev Update proposal status based on voting results
     */
    function _updateProposalStatus(uint256 proposalId) internal {
        Proposal storage proposal = proposals[proposalId];
        
        if (proposal.status == ProposalStatus.PENDING && 
            block.timestamp >= proposal.startTime) {
            proposal.status = ProposalStatus.ACTIVE;
        }
        
        if (proposal.status == ProposalStatus.ACTIVE && 
            block.timestamp > proposal.endTime) {
            
            uint256 totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
            
            if (totalVotes >= govParams.quorumVotes && proposal.forVotes > proposal.againstVotes) {
                proposal.status = ProposalStatus.SUCCEEDED;
            } else {
                proposal.status = ProposalStatus.FAILED;
            }
        }
    }
    
    /**
     * @dev Queue successful proposal for execution (timelock)
     */
    function queue(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.SUCCEEDED, "Proposal not succeeded");
        
        proposal.executionTime = block.timestamp + govParams.timelockDelay;
        proposal.status = ProposalStatus.QUEUED;
        
        emit ProposalQueued(proposalId, proposal.executionTime);
    }
    
    /**
     * @dev Execute queued proposal with multi-sig requirement
     */
    function execute(uint256 proposalId) external onlyRole(EXECUTOR_ROLE) nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.QUEUED, "Proposal not queued");
        require(block.timestamp >= proposal.executionTime, "Timelock not expired");
        require(!proposal.executed, "Already executed");
        
        // Require multi-sig approval for execution
        bytes32 executionHash = keccak256(abi.encode(proposalId, proposal.executionData));
        require(
            multiSig.signatureCount[executionHash] >= multiSig.requiredSignatures,
            "Insufficient multi-sig signatures"
        );
        
        proposal.executed = true;
        proposal.status = ProposalStatus.EXECUTED;
        
        // Execute the proposal
        bool success = _executeProposal(proposal);
        
        emit ProposalExecuted(proposalId, success);
    }
    
    /**
     * @dev Execute proposal based on type
     */
    function _executeProposal(Proposal storage proposal) internal returns (bool) {
        if (proposal.proposalType == ProposalType.BURN_RATE) {
            return _executeBurnRateChange(proposal.executionData);
        } else if (proposal.proposalType == ProposalType.COMMISSION_STRUCTURE) {
            return _executeCommissionChange(proposal.executionData);
        } else if (proposal.proposalType == ProposalType.VAULT_ALLOCATION) {
            return _executeVaultAllocationChange(proposal.executionData);
        } else if (proposal.proposalType == ProposalType.GENERAL) {
            return _executeGeneralProposal(proposal.executionData);
        }
        
        return false;
    }
    
    /**
     * @dev Execute burn rate change
     */
    function _executeBurnRateChange(bytes memory data) internal returns (bool) {
        try this.decodeBurnRateData(data) returns (uint256 newBurnRate) {
            require(newBurnRate <= govParams.maxBurnRate, "Exceeds max burn rate");
            unykornToken.setBurnRate(newBurnRate);
            return true;
        } catch {
            return false;
        }
    }
    
    /**
     * @dev Execute commission structure change
     */
    function _executeCommissionChange(bytes memory data) internal returns (bool) {
        try this.decodeCommissionData(data) returns (
            uint256 advocateRate,
            uint256 hustlerRate,
            uint256 overrideRate,
            uint256 foundingBrokerBonus
        ) {
            require(advocateRate <= govParams.maxCommissionRate, "Advocate rate too high");
            require(hustlerRate <= govParams.maxCommissionRate, "Hustler rate too high");
            
            salesForceManager.updateCommissionRates(
                advocateRate,
                hustlerRate,
                overrideRate,
                foundingBrokerBonus
            );
            return true;
        } catch {
            return false;
        }
    }
    
    /**
     * @dev Execute vault allocation change
     */
    function _executeVaultAllocationChange(bytes memory data) internal returns (bool) {
        try this.decodeVaultAllocationData(data) returns (
            uint256 stablecoins,
            uint256 bitcoin,
            uint256 gold,
            uint256 ethereum,
            uint256 rwa,
            uint256 tolerance
        ) {
            assetVault.updateAllocationTargets(
                stablecoins,
                bitcoin,
                gold,
                ethereum,
                rwa,
                tolerance
            );
            return true;
        } catch {
            return false;
        }
    }
    
    /**
     * @dev Execute general proposal
     */
    function _executeGeneralProposal(bytes memory data) internal returns (bool) {
        // General proposals would require custom execution logic
        // For now, just return true if data is valid
        return data.length > 0;
    }
    
    /**
     * @dev Multi-sig signature for proposal execution
     */
    function signProposalExecution(
        uint256 proposalId
    ) external onlyRole(GUARDIAN_ROLE) {
        require(multiSig.isSigner[msg.sender], "Not a signer");
        
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.QUEUED, "Proposal not queued");
        
        bytes32 executionHash = keccak256(abi.encode(proposalId, proposal.executionData));
        require(!multiSig.signatures[executionHash][msg.sender], "Already signed");
        
        multiSig.signatures[executionHash][msg.sender] = true;
        multiSig.signatureCount[executionHash]++;
        
        emit MultiSigSignature(executionHash, msg.sender);
    }
    
    /**
     * @dev Cancel proposal (admin emergency function)
     */
    function cancel(uint256 proposalId) external onlyRole(ADMIN_ROLE) {
        Proposal storage proposal = proposals[proposalId];
        require(
            proposal.status == ProposalStatus.PENDING ||
            proposal.status == ProposalStatus.ACTIVE ||
            proposal.status == ProposalStatus.QUEUED,
            "Cannot cancel"
        );
        
        proposal.status = ProposalStatus.CANCELLED;
        emit ProposalCancelled(proposalId);
    }
    
    /**
     * @dev Get proposal details
     */
    function getProposal(uint256 proposalId) 
        external 
        view 
        returns (
            uint256 id,
            address proposer,
            ProposalType proposalType,
            string memory title,
            string memory description,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 abstainVotes,
            uint256 startTime,
            uint256 endTime,
            ProposalStatus status
        ) 
    {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.proposalType,
            proposal.title,
            proposal.description,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.abstainVotes,
            proposal.startTime,
            proposal.endTime,
            proposal.status
        );
    }
    
    /**
     * @dev Get voting power for address
     */
    function getVotingPower(address voter) external view returns (uint256) {
        return unykornToken.balanceOf(voter);
    }
    
    /**
     * @dev Check if address has voted on proposal
     */
    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        return proposals[proposalId].hasVoted[voter];
    }
    
    /**
     * @dev Get multi-sig status for proposal
     */
    function getMultiSigStatus(uint256 proposalId) 
        external 
        view 
        returns (uint256 signatureCount, uint256 requiredSignatures, bool canExecute) 
    {
        Proposal storage proposal = proposals[proposalId];
        bytes32 executionHash = keccak256(abi.encode(proposalId, proposal.executionData));
        
        signatureCount = multiSig.signatureCount[executionHash];
        requiredSignatures = multiSig.requiredSignatures;
        canExecute = signatureCount >= requiredSignatures && 
                    proposal.status == ProposalStatus.QUEUED &&
                    block.timestamp >= proposal.executionTime;
    }
    
    // Data encoding functions (external for try/catch)
    function decodeBurnRateData(bytes memory data) external pure returns (uint256 burnRate) {
        return abi.decode(data, (uint256));
    }
    
    function decodeCommissionData(bytes memory data) 
        external 
        pure 
        returns (uint256, uint256, uint256, uint256) 
    {
        return abi.decode(data, (uint256, uint256, uint256, uint256));
    }
    
    function decodeVaultAllocationData(bytes memory data) 
        external 
        pure 
        returns (uint256, uint256, uint256, uint256, uint256, uint256) 
    {
        return abi.decode(data, (uint256, uint256, uint256, uint256, uint256, uint256));
    }
    
    // Admin functions
    function updateGovernanceParams(
        uint256 votingDelay,
        uint256 votingPeriod,
        uint256 timelockDelay,
        uint256 proposalThreshold,
        uint256 quorumVotes
    ) external onlyRole(ADMIN_ROLE) {
        govParams.votingDelay = votingDelay;
        govParams.votingPeriod = votingPeriod;
        govParams.timelockDelay = timelockDelay;
        govParams.proposalThreshold = proposalThreshold;
        govParams.quorumVotes = quorumVotes;
    }
    
    function updateMaxRates(
        uint256 maxBurnRate,
        uint256 maxCommissionRate
    ) external onlyRole(ADMIN_ROLE) {
        govParams.maxBurnRate = maxBurnRate;
        govParams.maxCommissionRate = maxCommissionRate;
    }
    
    function addMultiSigSigner(address newSigner) external onlyRole(ADMIN_ROLE) {
        require(!multiSig.isSigner[newSigner], "Already a signer");
        
        multiSig.signers.push(newSigner);
        multiSig.isSigner[newSigner] = true;
        _grantRole(GUARDIAN_ROLE, newSigner);
    }
    
    function removeMultiSigSigner(address signer) external onlyRole(ADMIN_ROLE) {
        require(multiSig.isSigner[signer], "Not a signer");
        require(multiSig.signers.length > multiSig.requiredSignatures, "Would break multi-sig");
        
        multiSig.isSigner[signer] = false;
        _revokeRole(GUARDIAN_ROLE, signer);
        
        // Remove from signers array
        for (uint i = 0; i < multiSig.signers.length; i++) {
            if (multiSig.signers[i] == signer) {
                multiSig.signers[i] = multiSig.signers[multiSig.signers.length - 1];
                multiSig.signers.pop();
                break;
            }
        }
    }
    
    function updateRequiredSignatures(uint256 newRequired) external onlyRole(ADMIN_ROLE) {
        require(newRequired <= multiSig.signers.length, "Too many required signatures");
        require(newRequired > 0, "Must require at least one signature");
        
        multiSig.requiredSignatures = newRequired;
    }
}