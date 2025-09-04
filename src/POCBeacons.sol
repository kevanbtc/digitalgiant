// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./UnykornToken.sol";

/**
 * @title POC Beacon Network - Physical Engagement Tracking
 * @dev Multiple methods: QR codes, NFC, SMS, IVR with anti-abuse protection
 */
contract POCBeacons is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant BEACON_MANAGER_ROLE = keccak256("BEACON_MANAGER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    
    UnykornToken public unykornToken;
    
    // Beacon interaction methods
    enum InteractionMethod {
        QR_CODE,        // QR code scan
        NFC,            // NFC tap
        SMS,            // SMS verification
        IVR,            // Phone call verification
        BLUETOOTH,      // Bluetooth beacon
        GPS             // GPS location verification
    }
    
    // Beacon information
    struct Beacon {
        uint256 beaconId;
        string name;
        string location;
        int256 latitude;        // Scaled by 10^6 for precision
        int256 longitude;       // Scaled by 10^6 for precision
        uint256 radius;         // Acceptable radius in meters
        address owner;
        bool active;
        uint256 totalInteractions;
        uint256 uniqueVisitors;
        uint256 rewardAmount;   // Tokens rewarded per interaction
        InteractionMethod[] allowedMethods;
        uint256 createdAt;
        string metadataURI;
    }
    
    // User interaction record
    struct Interaction {
        uint256 interactionId;
        uint256 beaconId;
        address user;
        InteractionMethod method;
        uint256 timestamp;
        int256 userLatitude;
        int256 userLongitude;
        uint256 tokensRewarded;
        string verificationData; // QR code, SMS confirmation, etc.
        bool verified;
    }
    
    // Daily interaction limits and cooldowns
    struct UserLimits {
        mapping(uint256 => uint256) dailyInteractions; // day => count
        mapping(uint256 => uint256) lastInteraction;   // beaconId => timestamp
        uint256 totalInteractions;
        uint256 totalRewardsEarned;
        uint256 streakDays;
        uint256 lastInteractionDay;
    }
    
    // Anti-abuse parameters
    struct BeaconLimits {
        uint256 maxDailyInteractions;   // Max interactions per day per beacon
        uint256 cooldownPeriod;         // Minimum time between interactions
        uint256 maxRadiusMeters;        // Maximum GPS radius for verification
        bool requiresGPS;               // GPS verification required
        bool requiresSecondary;         // Secondary verification (SMS/IVR)
    }
    
    // State variables
    mapping(uint256 => Beacon) public beacons;
    mapping(uint256 => Interaction) public interactions;
    mapping(address => UserLimits) public userLimits;
    mapping(uint256 => BeaconLimits) public beaconLimits;
    mapping(string => uint256) public qrCodeToBeacon;
    mapping(address => uint256[]) public userInteractions;
    mapping(uint256 => uint256[]) public beaconInteractions;
    
    uint256 public beaconCount;
    uint256 public interactionCount;
    uint256 public totalRewardsDistributed;
    
    // Global limits
    uint256 public maxDailyInteractionsGlobal = 10;
    uint256 public globalCooldownPeriod = 300; // 5 minutes
    uint256 public maxRewardPerInteraction = 50 * 10**18; // 50 tokens
    uint256 public streakBonusPercent = 10; // 1% per day
    
    // Events
    event BeaconCreated(uint256 indexed beaconId, string name, address owner);
    event InteractionRecorded(
        uint256 indexed interactionId,
        uint256 indexed beaconId,
        address indexed user,
        InteractionMethod method,
        uint256 tokensRewarded
    );
    event RewardsDistributed(address indexed user, uint256 amount, uint256 beaconId);
    event BeaconUpdated(uint256 indexed beaconId, string name, bool active);
    event AntiAbuseTriggered(address indexed user, uint256 beaconId, string reason);
    
    constructor(address _unykornToken) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(BEACON_MANAGER_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);
        
        unykornToken = UnykornToken(_unykornToken);
    }
    
    /**
     * @dev Create new beacon
     */
    function createBeacon(
        string memory name,
        string memory location,
        int256 latitude,
        int256 longitude,
        uint256 radius,
        uint256 rewardAmount,
        InteractionMethod[] memory allowedMethods,
        string memory metadataURI,
        BeaconLimits memory limits
    ) external onlyRole(BEACON_MANAGER_ROLE) returns (uint256) {
        require(bytes(name).length > 0, "Name required");
        require(rewardAmount <= maxRewardPerInteraction, "Reward too high");
        require(allowedMethods.length > 0, "Must allow at least one method");
        
        uint256 beaconId = beaconCount++;
        
        beacons[beaconId] = Beacon({
            beaconId: beaconId,
            name: name,
            location: location,
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            owner: msg.sender,
            active: true,
            totalInteractions: 0,
            uniqueVisitors: 0,
            rewardAmount: rewardAmount,
            allowedMethods: allowedMethods,
            createdAt: block.timestamp,
            metadataURI: metadataURI
        });
        
        beaconLimits[beaconId] = limits;
        
        // Generate QR code mapping
        string memory qrCode = string(abi.encodePacked("UNY-", toString(beaconId)));
        qrCodeToBeacon[qrCode] = beaconId;
        
        emit BeaconCreated(beaconId, name, msg.sender);
        return beaconId;
    }
    
    /**
     * @dev Record beacon interaction with anti-abuse checks
     */
    function recordInteraction(
        uint256 beaconId,
        InteractionMethod method,
        int256 userLatitude,
        int256 userLongitude,
        string memory verificationData
    ) external nonReentrant whenNotPaused {
        Beacon storage beacon = beacons[beaconId];
        require(beacon.active, "Beacon not active");
        
        BeaconLimits memory limits = beaconLimits[beaconId];
        UserLimits storage userLimit = userLimits[msg.sender];
        
        // Check if method is allowed
        bool methodAllowed = false;
        for (uint i = 0; i < beacon.allowedMethods.length; i++) {
            if (beacon.allowedMethods[i] == method) {
                methodAllowed = true;
                break;
            }
        }
        require(methodAllowed, "Method not allowed");
        
        // Anti-abuse checks
        _performAntiAbuseChecks(beaconId, method, userLatitude, userLongitude, limits);
        
        // Verify location if GPS required
        if (limits.requiresGPS) {
            require(
                _isWithinRadius(userLatitude, userLongitude, beacon.latitude, beacon.longitude, beacon.radius),
                "Outside beacon radius"
            );
        }
        
        // Record interaction
        uint256 interactionId = interactionCount++;
        
        interactions[interactionId] = Interaction({
            interactionId: interactionId,
            beaconId: beaconId,
            user: msg.sender,
            method: method,
            timestamp: block.timestamp,
            userLatitude: userLatitude,
            userLongitude: userLongitude,
            tokensRewarded: 0, // Will be set after verification
            verificationData: verificationData,
            verified: !limits.requiresSecondary // Auto-verify if no secondary required
        });
        
        userInteractions[msg.sender].push(interactionId);
        beaconInteractions[beaconId].push(interactionId);
        
        // Update limits tracking
        uint256 currentDay = block.timestamp / 1 days;
        userLimit.dailyInteractions[currentDay]++;
        userLimit.lastInteraction[beaconId] = block.timestamp;
        userLimit.totalInteractions++;
        
        // Update beacon stats
        beacon.totalInteractions++;
        
        // Check for new visitor
        bool isNewVisitor = true;
        for (uint i = 0; i < beaconInteractions[beaconId].length - 1; i++) {
            uint256 prevInteractionId = beaconInteractions[beaconId][i];
            if (interactions[prevInteractionId].user == msg.sender) {
                isNewVisitor = false;
                break;
            }
        }
        if (isNewVisitor) {
            beacon.uniqueVisitors++;
        }
        
        // Auto-reward if verified
        if (interactions[interactionId].verified) {
            _distributeRewards(interactionId);
        }
        
        emit InteractionRecorded(interactionId, beaconId, msg.sender, method, 0);
    }
    
    /**
     * @dev Verify interaction and distribute rewards
     */
    function verifyAndReward(
        uint256 interactionId,
        bool approved
    ) external onlyRole(ORACLE_ROLE) {
        Interaction storage interaction = interactions[interactionId];
        require(!interaction.verified, "Already verified");
        
        interaction.verified = approved;
        
        if (approved) {
            _distributeRewards(interactionId);
        }
    }
    
    /**
     * @dev Internal function to distribute rewards
     */
    function _distributeRewards(uint256 interactionId) internal {
        Interaction storage interaction = interactions[interactionId];
        Beacon memory beacon = beacons[interaction.beaconId];
        UserLimits storage userLimit = userLimits[interaction.user];
        
        uint256 baseReward = beacon.rewardAmount;
        
        // Calculate streak bonus
        uint256 currentDay = block.timestamp / 1 days;
        if (userLimit.lastInteractionDay == currentDay - 1) {
            userLimit.streakDays++;
        } else if (userLimit.lastInteractionDay != currentDay) {
            userLimit.streakDays = 1;
        }
        userLimit.lastInteractionDay = currentDay;
        
        // Apply streak bonus
        uint256 streakBonus = (baseReward * userLimit.streakDays * streakBonusPercent) / 10000;
        uint256 totalReward = baseReward + streakBonus;
        
        // Distribute reward through token contract
        unykornToken.payCommission(interaction.user, totalReward, "POC Beacon Reward");
        
        // Update records
        interaction.tokensRewarded = totalReward;
        userLimit.totalRewardsEarned += totalReward;
        totalRewardsDistributed += totalReward;
        
        emit RewardsDistributed(interaction.user, totalReward, interaction.beaconId);
    }
    
    /**
     * @dev Perform anti-abuse checks
     */
    function _performAntiAbuseChecks(
        uint256 beaconId,
        InteractionMethod method,
        int256 userLatitude,
        int256 userLongitude,
        BeaconLimits memory limits
    ) internal view {
        UserLimits storage userLimit = userLimits[msg.sender];
        uint256 currentDay = block.timestamp / 1 days;
        
        // Check daily interaction limit
        require(
            userLimit.dailyInteractions[currentDay] < maxDailyInteractionsGlobal,
            "Daily global limit exceeded"
        );
        require(
            userLimit.dailyInteractions[currentDay] < limits.maxDailyInteractions,
            "Daily beacon limit exceeded"
        );
        
        // Check cooldown period
        require(
            block.timestamp >= userLimit.lastInteraction[beaconId] + limits.cooldownPeriod,
            "Cooldown period active"
        );
        require(
            block.timestamp >= userLimit.lastInteraction[beaconId] + globalCooldownPeriod,
            "Global cooldown active"
        );
    }
    
    /**
     * @dev Check if user coordinates are within beacon radius
     */
    function _isWithinRadius(
        int256 userLat,
        int256 userLng,
        int256 beaconLat,
        int256 beaconLng,
        uint256 radius
    ) internal pure returns (bool) {
        // Simplified distance calculation - in production would use proper geodesic distance
        int256 latDiff = userLat - beaconLat;
        int256 lngDiff = userLng - beaconLng;
        
        // Approximate distance (not precise but good enough for most use cases)
        uint256 distanceSquared = uint256(latDiff * latDiff + lngDiff * lngDiff);
        uint256 radiusSquared = radius * radius * 1000000; // Scale for precision
        
        return distanceSquared <= radiusSquared;
    }
    
    /**
     * @dev Batch record interactions for IVR/SMS verification
     */
    function batchRecordInteractions(
        uint256[] memory beaconIds,
        address[] memory users,
        InteractionMethod method,
        string[] memory verificationCodes
    ) external onlyRole(ORACLE_ROLE) {
        require(beaconIds.length == users.length, "Array length mismatch");
        require(users.length == verificationCodes.length, "Array length mismatch");
        
        for (uint i = 0; i < beaconIds.length; i++) {
            // Record interaction without GPS (for SMS/IVR)
            uint256 interactionId = interactionCount++;
            
            interactions[interactionId] = Interaction({
                interactionId: interactionId,
                beaconId: beaconIds[i],
                user: users[i],
                method: method,
                timestamp: block.timestamp,
                userLatitude: 0, // No GPS for SMS/IVR
                userLongitude: 0,
                tokensRewarded: 0,
                verificationData: verificationCodes[i],
                verified: true // Pre-verified by oracle
            });
            
            userInteractions[users[i]].push(interactionId);
            beaconInteractions[beaconIds[i]].push(interactionId);
            
            _distributeRewards(interactionId);
        }
    }
    
    /**
     * @dev Get beacon interaction statistics
     */
    function getBeaconStats(uint256 beaconId) 
        external 
        view 
        returns (
            uint256 totalInteractions,
            uint256 uniqueVisitors,
            uint256 rewardsDistributed,
            uint256 avgRewardPerInteraction
        ) 
    {
        Beacon memory beacon = beacons[beaconId];
        uint256[] memory beaconInteractionIds = beaconInteractions[beaconId];
        
        uint256 totalRewards = 0;
        for (uint i = 0; i < beaconInteractionIds.length; i++) {
            totalRewards += interactions[beaconInteractionIds[i]].tokensRewarded;
        }
        
        return (
            beacon.totalInteractions,
            beacon.uniqueVisitors,
            totalRewards,
            beacon.totalInteractions > 0 ? totalRewards / beacon.totalInteractions : 0
        );
    }
    
    /**
     * @dev Get user's beacon interaction history
     */
    function getUserInteractionHistory(address user) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return userInteractions[user];
    }
    
    /**
     * @dev Check if user can interact with beacon
     */
    function canUserInteract(address user, uint256 beaconId) 
        external 
        view 
        returns (bool, string memory reason) 
    {
        if (!beacons[beaconId].active) {
            return (false, "Beacon not active");
        }
        
        UserLimits storage userLimit = userLimits[user];
        BeaconLimits memory limits = beaconLimits[beaconId];
        uint256 currentDay = block.timestamp / 1 days;
        
        if (userLimit.dailyInteractions[currentDay] >= maxDailyInteractionsGlobal) {
            return (false, "Daily global limit exceeded");
        }
        
        if (userLimit.dailyInteractions[currentDay] >= limits.maxDailyInteractions) {
            return (false, "Daily beacon limit exceeded");
        }
        
        if (block.timestamp < userLimit.lastInteraction[beaconId] + limits.cooldownPeriod) {
            return (false, "Cooldown period active");
        }
        
        return (true, "Can interact");
    }
    
    /**
     * @dev Get QR code for beacon
     */
    function getBeaconQRCode(uint256 beaconId) external view returns (string memory) {
        require(beacons[beaconId].active, "Beacon not active");
        return string(abi.encodePacked("UNY-", toString(beaconId)));
    }
    
    // Admin functions
    function updateBeacon(
        uint256 beaconId,
        string memory name,
        bool active,
        uint256 rewardAmount
    ) external onlyRole(BEACON_MANAGER_ROLE) {
        Beacon storage beacon = beacons[beaconId];
        require(beacon.owner == msg.sender || hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
        
        beacon.name = name;
        beacon.active = active;
        beacon.rewardAmount = rewardAmount;
        
        emit BeaconUpdated(beaconId, name, active);
    }
    
    function updateGlobalLimits(
        uint256 maxDaily,
        uint256 cooldown,
        uint256 maxReward,
        uint256 streakBonus
    ) external onlyRole(ADMIN_ROLE) {
        maxDailyInteractionsGlobal = maxDaily;
        globalCooldownPeriod = cooldown;
        maxRewardPerInteraction = maxReward;
        streakBonusPercent = streakBonus;
    }
    
    function emergencyPause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }
    
    function emergencyUnpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }
    
    // Utility functions
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}