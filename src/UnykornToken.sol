// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title Unykorn Token - Enhanced ERC20 with POC/POI Tracking and Deflationary Mechanics
 * @dev Global participation engine backed by real assets with burn mechanics and engagement tracking
 */
contract UnykornToken is ERC20, AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant POC_MANAGER_ROLE = keccak256("POC_MANAGER_ROLE");
    bytes32 public constant SALES_FORCE_ROLE = keccak256("SALES_FORCE_ROLE");
    
    // Supply and burn mechanics
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000_000 * 10**18; // 1 trillion tokens
    uint256 public burnRatePercent = 300; // 3% default burn rate (in basis points)
    uint256 public totalBurned;
    uint256 public maxBurnRate = 500; // 5% maximum burn rate
    
    // POC (Proof of Contact) System
    struct POCRecord {
        uint256 lastCheckIn;
        uint256 streakDays;
        uint256 totalCheckIns;
        uint256 longestStreak;
        uint256 tokensEarned;
        bool eligibleToday;
    }
    
    // POI (Proof of Introduction) System
    struct POIRecord {
        address introducer;
        address introduced;
        uint256 timestamp;
        uint256 value; // Future revenue potential
        bool permanent;
        uint256 commissionRate; // Basis points for future revenue sharing
    }
    
    // Commission and utility tracking
    struct UserStats {
        uint256 totalCommissionsEarned;
        uint256 totalUtilitySpent;
        uint256 totalBurnsFromActivity;
        uint256 referralCount;
        uint256 teamOverrides;
        uint256 lastActivityTimestamp;
    }
    
    // State mappings
    mapping(address => POCRecord) public pocRecords;
    mapping(address => POIRecord[]) public poiRecords;
    mapping(address => UserStats) public userStats;
    mapping(address => mapping(address => uint256)) public poiCommissionRates;
    mapping(address => bool) public dailyPOCClaimed;
    mapping(uint256 => mapping(address => bool)) public dailyClaimTracker; // day => user => claimed
    
    // System parameters
    uint256 public dailyPOCReward = 100 * 10**18; // 100 tokens per day
    uint256 public streakBonusMultiplier = 10; // 0.1% bonus per day
    uint256 public maxStreakBonus = 1000; // 10% max bonus
    uint256 public constant SECONDS_PER_DAY = 86400;
    
    // MLM-like structure
    mapping(address => address) public upline; // User's direct upline
    mapping(address => address[]) public downline; // User's direct downline
    mapping(address => uint256) public teamSize; // Total team size
    mapping(address => uint256) public teamVolume; // Team's total volume
    
    // Events
    event POCCheckIn(address indexed user, uint256 streak, uint256 reward);
    event POIRecorded(address indexed introducer, address indexed introduced, uint256 commissionRate);
    event TokensBurned(address indexed user, uint256 amount, string reason);
    event CommissionPaid(address indexed recipient, uint256 amount, string source);
    event UtilityUsage(address indexed user, uint256 amount, uint256 burned);
    event TeamStructureUpdated(address indexed user, address indexed upline, uint256 teamSize);
    event BurnRateUpdated(uint256 oldRate, uint256 newRate);
    
    constructor() ERC20("Unykorn Token", "UNY") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _grantRole(POC_MANAGER_ROLE, msg.sender);
        
        _mint(msg.sender, INITIAL_SUPPLY);
    }
    
    /**
     * @dev Daily POC check-in with streak tracking
     */
    function dailyPOCCheckIn() external nonReentrant whenNotPaused {
        address user = msg.sender;
        POCRecord storage record = pocRecords[user];
        uint256 currentDay = block.timestamp / SECONDS_PER_DAY;
        
        require(!dailyClaimTracker[currentDay][user], "Already claimed today");
        require(balanceOf(address(this)) >= dailyPOCReward, "Insufficient reward pool");
        
        // Update streak
        if (record.lastCheckIn > 0) {
            uint256 lastDay = record.lastCheckIn / SECONDS_PER_DAY;
            if (currentDay == lastDay + 1) {
                // Consecutive day - increment streak
                record.streakDays++;
            } else if (currentDay > lastDay + 1) {
                // Missed days - reset streak
                record.streakDays = 1;
            }
        } else {
            // First check-in
            record.streakDays = 1;
        }
        
        // Update records
        record.lastCheckIn = block.timestamp;
        record.totalCheckIns++;
        if (record.streakDays > record.longestStreak) {
            record.longestStreak = record.streakDays;
        }
        
        // Calculate reward with streak bonus
        uint256 streakBonus = (record.streakDays * streakBonusMultiplier);
        if (streakBonus > maxStreakBonus) streakBonus = maxStreakBonus;
        
        uint256 reward = dailyPOCReward + (dailyPOCReward * streakBonus / 10000);
        
        // Transfer reward
        _transfer(address(this), user, reward);
        record.tokensEarned += reward;
        dailyClaimTracker[currentDay][user] = true;
        
        // Update user stats
        userStats[user].lastActivityTimestamp = block.timestamp;
        
        emit POCCheckIn(user, record.streakDays, reward);
    }
    
    /**
     * @dev Record Proof of Introduction for future revenue sharing
     */
    function recordPOI(
        address introduced,
        uint256 commissionRate,
        uint256 estimatedValue
    ) external onlyRole(POC_MANAGER_ROLE) {
        require(introduced != address(0), "Invalid address");
        require(commissionRate <= 5000, "Commission too high"); // Max 50%
        
        POIRecord memory newPOI = POIRecord({
            introducer: msg.sender,
            introduced: introduced,
            timestamp: block.timestamp,
            value: estimatedValue,
            permanent: true,
            commissionRate: commissionRate
        });
        
        poiRecords[msg.sender].push(newPOI);
        poiCommissionRates[msg.sender][introduced] = commissionRate;
        
        // Update referral count
        userStats[msg.sender].referralCount++;
        
        emit POIRecorded(msg.sender, introduced, commissionRate);
    }
    
    /**
     * @dev Use tokens for utility with automatic burn
     */
    function useUtility(uint256 amount, string calldata purpose) external nonReentrant {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        // Calculate burn amount
        uint256 burnAmount = (amount * burnRatePercent) / 10000;
        uint256 usageAmount = amount - burnAmount;
        
        // Burn tokens
        if (burnAmount > 0) {
            _burn(msg.sender, burnAmount);
            totalBurned += burnAmount;
            emit TokensBurned(msg.sender, burnAmount, purpose);
        }
        
        // Transfer usage amount to contract for utility
        _transfer(msg.sender, address(this), usageAmount);
        
        // Update stats
        userStats[msg.sender].totalUtilitySpent += amount;
        userStats[msg.sender].totalBurnsFromActivity += burnAmount;
        userStats[msg.sender].lastActivityTimestamp = block.timestamp;
        
        emit UtilityUsage(msg.sender, amount, burnAmount);
    }
    
    /**
     * @dev Pay commission with automatic burn
     */
    function payCommission(
        address recipient,
        uint256 amount,
        string calldata source
    ) external onlyRole(SALES_FORCE_ROLE) nonReentrant {
        require(recipient != address(0), "Invalid recipient");
        require(balanceOf(address(this)) >= amount, "Insufficient contract balance");
        
        // Calculate burn on commission
        uint256 burnAmount = (amount * burnRatePercent) / 10000;
        uint256 netCommission = amount - burnAmount;
        
        // Burn portion
        if (burnAmount > 0) {
            _transfer(address(this), address(0), burnAmount);
            totalBurned += burnAmount;
            emit TokensBurned(address(this), burnAmount, source);
        }
        
        // Pay commission
        _transfer(address(this), recipient, netCommission);
        
        // Update recipient stats
        userStats[recipient].totalCommissionsEarned += netCommission;
        userStats[recipient].lastActivityTimestamp = block.timestamp;
        
        emit CommissionPaid(recipient, netCommission, source);
    }
    
    /**
     * @dev Set up MLM-like team structure
     */
    function setUpline(address user, address uplineAddress) 
        external 
        onlyRole(SALES_FORCE_ROLE) 
    {
        require(user != address(0) && uplineAddress != address(0), "Invalid addresses");
        require(upline[user] == address(0), "Upline already set");
        require(user != uplineAddress, "Cannot be own upline");
        
        upline[user] = uplineAddress;
        downline[uplineAddress].push(user);
        
        // Update team sizes up the chain
        address current = uplineAddress;
        while (current != address(0)) {
            teamSize[current]++;
            current = upline[current];
        }
        
        emit TeamStructureUpdated(user, uplineAddress, teamSize[uplineAddress]);
    }
    
    /**
     * @dev Add team volume and distribute overrides
     */
    function addTeamVolume(address user, uint256 volume) 
        external 
        onlyRole(SALES_FORCE_ROLE) 
    {
        // Add volume up the chain
        address current = user;
        while (current != address(0)) {
            teamVolume[current] += volume;
            current = upline[current];
        }
        
        // Pay team override to direct upline (2%)
        if (upline[user] != address(0)) {
            uint256 override = (volume * 200) / 10000; // 2%
            if (balanceOf(address(this)) >= override) {
                _transfer(address(this), upline[user], override);
                userStats[upline[user]].teamOverrides += override;
                emit CommissionPaid(upline[user], override, "Team Override");
            }
        }
    }
    
    /**
     * @dev Get POI records for an introducer
     */
    function getPOIRecords(address introducer) 
        external 
        view 
        returns (POIRecord[] memory) 
    {
        return poiRecords[introducer];
    }
    
    /**
     * @dev Get downline for a user
     */
    function getDownline(address user) 
        external 
        view 
        returns (address[] memory) 
    {
        return downline[user];
    }
    
    /**
     * @dev Check if user can claim POC today
     */
    function canClaimPOCToday(address user) external view returns (bool) {
        uint256 currentDay = block.timestamp / SECONDS_PER_DAY;
        return !dailyClaimTracker[currentDay][user];
    }
    
    /**
     * @dev Get user's current streak and stats
     */
    function getUserPOCStats(address user) 
        external 
        view 
        returns (
            uint256 currentStreak,
            uint256 totalCheckIns,
            uint256 longestStreak,
            uint256 tokensEarned,
            bool canClaimToday
        ) 
    {
        POCRecord memory record = pocRecords[user];
        uint256 currentDay = block.timestamp / SECONDS_PER_DAY;
        
        return (
            record.streakDays,
            record.totalCheckIns,
            record.longestStreak,
            record.tokensEarned,
            !dailyClaimTracker[currentDay][user]
        );
    }
    
    /**
     * @dev Calculate potential POC reward including streak bonus
     */
    function calculatePOCReward(address user) external view returns (uint256) {
        POCRecord memory record = pocRecords[user];
        uint256 streakBonus = (record.streakDays * streakBonusMultiplier);
        if (streakBonus > maxStreakBonus) streakBonus = maxStreakBonus;
        
        return dailyPOCReward + (dailyPOCReward * streakBonus / 10000);
    }
    
    // Admin functions
    function setBurnRate(uint256 newRate) external onlyRole(ADMIN_ROLE) {
        require(newRate <= maxBurnRate, "Exceeds maximum burn rate");
        uint256 oldRate = burnRatePercent;
        burnRatePercent = newRate;
        emit BurnRateUpdated(oldRate, newRate);
    }
    
    function setDailyPOCReward(uint256 newReward) external onlyRole(ADMIN_ROLE) {
        dailyPOCReward = newReward;
    }
    
    function setStreakParameters(
        uint256 bonusMultiplier,
        uint256 maxBonus
    ) external onlyRole(ADMIN_ROLE) {
        streakBonusMultiplier = bonusMultiplier;
        maxStreakBonus = maxBonus;
    }
    
    function emergencyMint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
    
    function emergencyBurn(address from, uint256 amount) external onlyRole(BURNER_ROLE) {
        _burn(from, amount);
        totalBurned += amount;
    }
    
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }
    
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }
    
    // View functions for analytics
    function getTotalStats() 
        external 
        view 
        returns (
            uint256 _totalSupply,
            uint256 _totalBurned,
            uint256 _burnRatePercent,
            uint256 _circulatingSupply
        ) 
    {
        return (
            totalSupply(),
            totalBurned,
            burnRatePercent,
            totalSupply() - balanceOf(address(this))
        );
    }
    
    function getTeamStats(address user) 
        external 
        view 
        returns (
            address _upline,
            uint256 _teamSize,
            uint256 _teamVolume,
            uint256 directReferrals
        ) 
    {
        return (
            upline[user],
            teamSize[user],
            teamVolume[user],
            downline[user].length
        );
    }
}