// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./UnykornToken.sol";
import "./AssetVault.sol";
import "./SalesForceManager.sol";
import "./InstitutionalPaymentGateway.sol";

contract AIOrchestrationSystem is Ownable, ReentrancyGuard, Pausable {
    using ECDSA for bytes32;

    UnykornToken public unykornToken;
    AssetVault public assetVault;
    SalesForceManager public salesForceManager;
    InstitutionalPaymentGateway public paymentGateway;

    struct AIAgent {
        address agentAddress;
        string agentType;
        bool isActive;
        uint256 priority;
        uint256 executedTasks;
        uint256 successRate;
        uint256 lastExecution;
    }

    struct AutomationTask {
        uint256 taskId;
        string taskType;
        bytes taskData;
        address targetContract;
        uint256 executionTime;
        bool isRecurring;
        uint256 recurringInterval;
        bool isCompleted;
        address assignedAgent;
        uint256 gasLimit;
        uint256 priority;
    }

    struct WorkflowTemplate {
        uint256 templateId;
        string workflowName;
        uint256[] taskSequence;
        mapping(uint256 => bytes) taskParameters;
        bool isActive;
        uint256 executionCount;
    }

    struct AIDecisionNode {
        uint256 nodeId;
        string decisionType;
        bytes conditionData;
        uint256[] trueBranch;
        uint256[] falseBranch;
        address oracleAddress;
        bool requiresConsensus;
        uint256 consensusThreshold;
    }

    mapping(address => AIAgent) public aiAgents;
    mapping(uint256 => AutomationTask) public automationTasks;
    mapping(uint256 => WorkflowTemplate) public workflowTemplates;
    mapping(uint256 => AIDecisionNode) public decisionNodes;
    mapping(string => address[]) public agentsByType;
    mapping(address => bool) public authorizedOracles;
    mapping(bytes32 => bool) public executedSignatures;

    address[] public activeAgents;
    uint256[] public pendingTasks;
    uint256[] public activeWorkflows;

    uint256 public taskCounter;
    uint256 public workflowCounter;
    uint256 public nodeCounter;
    uint256 public constant MAX_GAS_PER_TASK = 5000000;
    uint256 public constant CONSENSUS_TIMEOUT = 3600;

    event AIAgentRegistered(address indexed agent, string agentType, uint256 priority);
    event TaskScheduled(uint256 indexed taskId, string taskType, uint256 executionTime);
    event TaskExecuted(uint256 indexed taskId, address indexed agent, bool success);
    event WorkflowTriggered(uint256 indexed workflowId, string workflowName);
    event DecisionMade(uint256 indexed nodeId, bool decision, bytes evidence);
    event ConsensusReached(uint256 indexed nodeId, uint256 agentCount, bool decision);
    event EmergencyStop(address indexed trigger, string reason);

    modifier onlyAIAgent() {
        require(aiAgents[msg.sender].isActive, "Only active AI agents");
        _;
    }

    modifier onlyAuthorizedOracle() {
        require(authorizedOracles[msg.sender], "Only authorized oracles");
        _;
    }

    constructor(
        address _unykornToken,
        address _assetVault,
        address _salesForceManager,
        address _paymentGateway
    ) {
        unykornToken = UnykornToken(_unykornToken);
        assetVault = AssetVault(_assetVault);
        salesForceManager = SalesForceManager(_salesForceManager);
        paymentGateway = InstitutionalPaymentGateway(_paymentGateway);
        
        taskCounter = 1;
        workflowCounter = 1;
        nodeCounter = 1;
    }

    function registerAIAgent(
        address _agent,
        string memory _agentType,
        uint256 _priority
    ) external onlyOwner {
        require(_agent != address(0), "Invalid agent address");
        require(!aiAgents[_agent].isActive, "Agent already registered");

        aiAgents[_agent] = AIAgent({
            agentAddress: _agent,
            agentType: _agentType,
            isActive: true,
            priority: _priority,
            executedTasks: 0,
            successRate: 100,
            lastExecution: block.timestamp
        });

        agentsByType[_agentType].push(_agent);
        activeAgents.push(_agent);

        emit AIAgentRegistered(_agent, _agentType, _priority);
    }

    function scheduleTask(
        string memory _taskType,
        bytes memory _taskData,
        address _targetContract,
        uint256 _executionTime,
        bool _isRecurring,
        uint256 _recurringInterval,
        uint256 _gasLimit,
        uint256 _priority
    ) external onlyOwner returns (uint256) {
        require(_executionTime >= block.timestamp, "Invalid execution time");
        require(_gasLimit <= MAX_GAS_PER_TASK, "Gas limit too high");

        uint256 taskId = taskCounter++;
        
        automationTasks[taskId] = AutomationTask({
            taskId: taskId,
            taskType: _taskType,
            taskData: _taskData,
            targetContract: _targetContract,
            executionTime: _executionTime,
            isRecurring: _isRecurring,
            recurringInterval: _recurringInterval,
            isCompleted: false,
            assignedAgent: address(0),
            gasLimit: _gasLimit,
            priority: _priority
        });

        pendingTasks.push(taskId);
        emit TaskScheduled(taskId, _taskType, _executionTime);
        
        return taskId;
    }

    function createWorkflowTemplate(
        string memory _workflowName,
        uint256[] memory _taskSequence
    ) external onlyOwner returns (uint256) {
        uint256 templateId = workflowCounter++;
        
        WorkflowTemplate storage template = workflowTemplates[templateId];
        template.templateId = templateId;
        template.workflowName = _workflowName;
        template.taskSequence = _taskSequence;
        template.isActive = true;
        template.executionCount = 0;

        return templateId;
    }

    function executeTaskWithAI(
        uint256 _taskId,
        bytes memory _signature
    ) external onlyAIAgent nonReentrant whenNotPaused {
        AutomationTask storage task = automationTasks[_taskId];
        require(!task.isCompleted, "Task already completed");
        require(task.executionTime <= block.timestamp, "Execution time not reached");
        require(task.assignedAgent == address(0) || task.assignedAgent == msg.sender, "Task assigned to different agent");

        bytes32 messageHash = keccak256(abi.encodePacked(_taskId, msg.sender, block.timestamp));
        require(!executedSignatures[messageHash], "Signature already used");
        executedSignatures[messageHash] = true;

        task.assignedAgent = msg.sender;
        bool success = false;

        if (keccak256(abi.encodePacked(task.taskType)) == keccak256(abi.encodePacked("TOKEN_DISTRIBUTION"))) {
            success = _executeTokenDistribution(task.taskData);
        } else if (keccak256(abi.encodePacked(task.taskType)) == keccak256(abi.encodePacked("COMMISSION_CALCULATION"))) {
            success = _executeCommissionCalculation(task.taskData);
        } else if (keccak256(abi.encodePacked(task.taskType)) == keccak256(abi.encodePacked("LIQUIDITY_MANAGEMENT"))) {
            success = _executeLiquidityManagement(task.taskData);
        } else if (keccak256(abi.encodePacked(task.taskType)) == keccak256(abi.encodePacked("PAYMENT_PROCESSING"))) {
            success = _executePaymentProcessing(task.taskData);
        } else if (keccak256(abi.encodePacked(task.taskType)) == keccak256(abi.encodePacked("KYC_VERIFICATION"))) {
            success = _executeKYCVerification(task.taskData);
        }

        if (success) {
            task.isCompleted = true;
            aiAgents[msg.sender].executedTasks++;
            _updateAgentSuccessRate(msg.sender, true);
            
            if (task.isRecurring && task.recurringInterval > 0) {
                _scheduleRecurringTask(_taskId);
            }
        } else {
            _updateAgentSuccessRate(msg.sender, false);
        }

        aiAgents[msg.sender].lastExecution = block.timestamp;
        emit TaskExecuted(_taskId, msg.sender, success);
    }

    function executeWorkflow(
        uint256 _workflowId,
        bytes memory _triggerData
    ) external onlyAIAgent nonReentrant whenNotPaused {
        WorkflowTemplate storage workflow = workflowTemplates[_workflowId];
        require(workflow.isActive, "Workflow not active");

        workflow.executionCount++;
        activeWorkflows.push(_workflowId);

        emit WorkflowTriggered(_workflowId, workflow.workflowName);

        for (uint256 i = 0; i < workflow.taskSequence.length; i++) {
            uint256 taskId = workflow.taskSequence[i];
            if (!automationTasks[taskId].isCompleted) {
                automationTasks[taskId].assignedAgent = msg.sender;
                automationTasks[taskId].executionTime = block.timestamp;
            }
        }
    }

    function createDecisionNode(
        string memory _decisionType,
        bytes memory _conditionData,
        uint256[] memory _trueBranch,
        uint256[] memory _falseBranch,
        address _oracleAddress,
        bool _requiresConsensus,
        uint256 _consensusThreshold
    ) external onlyOwner returns (uint256) {
        uint256 nodeId = nodeCounter++;

        AIDecisionNode storage node = decisionNodes[nodeId];
        node.nodeId = nodeId;
        node.decisionType = _decisionType;
        node.conditionData = _conditionData;
        node.trueBranch = _trueBranch;
        node.falseBranch = _falseBranch;
        node.oracleAddress = _oracleAddress;
        node.requiresConsensus = _requiresConsensus;
        node.consensusThreshold = _consensusThreshold;

        return nodeId;
    }

    function makeAIDecision(
        uint256 _nodeId,
        bool _decision,
        bytes memory _evidence
    ) external onlyAIAgent {
        AIDecisionNode storage node = decisionNodes[_nodeId];
        require(node.nodeId != 0, "Decision node not found");

        emit DecisionMade(_nodeId, _decision, _evidence);

        uint256[] memory nextTasks = _decision ? node.trueBranch : node.falseBranch;
        
        for (uint256 i = 0; i < nextTasks.length; i++) {
            if (nextTasks[i] < taskCounter && !automationTasks[nextTasks[i]].isCompleted) {
                automationTasks[nextTasks[i]].executionTime = block.timestamp;
                automationTasks[nextTasks[i]].assignedAgent = msg.sender;
            }
        }
    }

    function _executeTokenDistribution(bytes memory _data) private returns (bool) {
        try this.parseTokenDistributionData(_data) returns (
            address recipient,
            uint256 amount,
            string memory reason
        ) {
            return unykornToken.transfer(recipient, amount);
        } catch {
            return false;
        }
    }

    function _executeCommissionCalculation(bytes memory _data) private returns (bool) {
        try this.parseCommissionData(_data) returns (
            address broker,
            uint256 saleAmount,
            uint256 level
        ) {
            return salesForceManager.processCommission(broker, saleAmount, level);
        } catch {
            return false;
        }
    }

    function _executeLiquidityManagement(bytes memory _data) private returns (bool) {
        try this.parseLiquidityData(_data) returns (
            uint256 ethAmount,
            uint256 tokenAmount,
            bool isAddition
        ) {
            if (isAddition) {
                return assetVault.addLiquidity{value: ethAmount}(tokenAmount);
            } else {
                return assetVault.removeLiquidity(ethAmount, tokenAmount);
            }
        } catch {
            return false;
        }
    }

    function _executePaymentProcessing(bytes memory _data) private returns (bool) {
        try this.parsePaymentData(_data) returns (
            uint256 orderId,
            bool isRelease
        ) {
            if (isRelease) {
                return paymentGateway.releaseEscrow(orderId);
            } else {
                return paymentGateway.processRefund(orderId);
            }
        } catch {
            return false;
        }
    }

    function _executeKYCVerification(bytes memory _data) private returns (bool) {
        try this.parseKYCData(_data) returns (
            address user,
            bool isVerified,
            uint256 riskScore
        ) {
            return paymentGateway.updateKYCStatus(user, isVerified, riskScore);
        } catch {
            return false;
        }
    }

    function _scheduleRecurringTask(uint256 _taskId) private {
        AutomationTask storage task = automationTasks[_taskId];
        
        uint256 newTaskId = taskCounter++;
        automationTasks[newTaskId] = AutomationTask({
            taskId: newTaskId,
            taskType: task.taskType,
            taskData: task.taskData,
            targetContract: task.targetContract,
            executionTime: block.timestamp + task.recurringInterval,
            isRecurring: task.isRecurring,
            recurringInterval: task.recurringInterval,
            isCompleted: false,
            assignedAgent: address(0),
            gasLimit: task.gasLimit,
            priority: task.priority
        });

        pendingTasks.push(newTaskId);
    }

    function _updateAgentSuccessRate(address _agent, bool _success) private {
        AIAgent storage agent = aiAgents[_agent];
        uint256 totalTasks = agent.executedTasks;
        uint256 currentSuccessRate = agent.successRate;
        
        if (_success) {
            agent.successRate = (currentSuccessRate * (totalTasks - 1) + 100) / totalTasks;
        } else {
            agent.successRate = (currentSuccessRate * (totalTasks - 1)) / totalTasks;
        }
    }

    function parseTokenDistributionData(bytes memory _data) external pure returns (address, uint256, string memory) {
        return abi.decode(_data, (address, uint256, string));
    }

    function parseCommissionData(bytes memory _data) external pure returns (address, uint256, uint256) {
        return abi.decode(_data, (address, uint256, uint256));
    }

    function parseLiquidityData(bytes memory _data) external pure returns (uint256, uint256, bool) {
        return abi.decode(_data, (uint256, uint256, bool));
    }

    function parsePaymentData(bytes memory _data) external pure returns (uint256, bool) {
        return abi.decode(_data, (uint256, bool));
    }

    function parseKYCData(bytes memory _data) external pure returns (address, bool, uint256) {
        return abi.decode(_data, (address, bool, uint256));
    }

    function emergencyStop(string memory _reason) external onlyOwner {
        _pause();
        emit EmergencyStop(msg.sender, _reason);
    }

    function resumeOperations() external onlyOwner {
        _unpause();
    }

    function setAuthorizedOracle(address _oracle, bool _authorized) external onlyOwner {
        authorizedOracles[_oracle] = _authorized;
    }

    function getAgentsByType(string memory _agentType) external view returns (address[] memory) {
        return agentsByType[_agentType];
    }

    function getPendingTasks() external view returns (uint256[] memory) {
        return pendingTasks;
    }

    function getActiveWorkflows() external view returns (uint256[] memory) {
        return activeWorkflows;
    }

    function getAgentStats(address _agent) external view returns (
        string memory agentType,
        bool isActive,
        uint256 priority,
        uint256 executedTasks,
        uint256 successRate,
        uint256 lastExecution
    ) {
        AIAgent memory agent = aiAgents[_agent];
        return (
            agent.agentType,
            agent.isActive,
            agent.priority,
            agent.executedTasks,
            agent.successRate,
            agent.lastExecution
        );
    }

    receive() external payable {}
}