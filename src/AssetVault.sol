// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Asset Vault - Multi-Asset Backing System
 * @dev Diversified vault supporting stablecoins, Bitcoin, gold, ETH, and RWAs with leverage
 */
contract AssetVault is AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VAULT_MANAGER_ROLE = keccak256("VAULT_MANAGER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");
    
    // Asset categories
    enum AssetType {
        STABLECOIN,     // USDC, USDT, DAI
        BITCOIN,        // WBTC, renBTC
        GOLD,           // PAXG, tokenized gold
        ETHEREUM,       // ETH, stETH
        RWA,            // Real World Assets
        OTHER           // Other approved assets
    }
    
    // Vault composition targets (basis points - 10000 = 100%)
    struct AllocationTargets {
        uint256 stablecoins;    // Target: 4000 (40%)
        uint256 bitcoin;        // Target: 2000 (20%)
        uint256 gold;          // Target: 2000 (20%)
        uint256 ethereum;      // Target: 1000 (10%)
        uint256 rwa;           // Target: 1000 (10%)
        uint256 tolerance;     // Rebalancing tolerance (500 = 5%)
    }
    
    // Asset information
    struct AssetInfo {
        IERC20 token;
        AssetType assetType;
        uint256 balance;
        uint256 price;          // Price in USD (18 decimals)
        uint256 lastPriceUpdate;
        bool active;
        uint256 minDeposit;
        uint256 maxAllocation;  // Maximum allocation in basis points
    }
    
    // Share holder information
    struct ShareHolder {
        uint256 shares;
        uint256 lockedUntil;    // Vesting period for early adopters
        uint256 depositedValue; // USD value when deposited
        uint256 lastDeposit;
        uint256 totalReturns;
        bool earlyAdopter;      // 60-90 day lock for early adopters
    }
    
    // Leverage and borrowing
    struct LeverageInfo {
        uint256 totalBorrowed;
        uint256 maxLTV;         // Maximum Loan-to-Value ratio (8000 = 80%)
        uint256 interestRate;   // Annual interest rate in basis points
        uint256 liquidationThreshold; // Liquidation threshold (8500 = 85%)
    }
    
    // State variables
    AllocationTargets public allocationTargets;
    LeverageInfo public leverageInfo;
    
    mapping(address => AssetInfo) public assets;
    mapping(address => ShareHolder) public shareHolders;
    mapping(AssetType => address[]) public assetsByType;
    
    address[] public allAssets;
    uint256 public totalShares;
    uint256 public totalVaultValue; // USD value with 18 decimals
    uint256 public lastRebalance;
    uint256 public rebalanceInterval = 7 days;
    
    // Lock periods
    uint256 public constant EARLY_ADOPTER_LOCK = 60 days;
    uint256 public constant STANDARD_LOCK = 30 days;
    
    // Events
    event AssetAdded(address indexed token, AssetType assetType);
    event SharesIssued(address indexed holder, uint256 shares, uint256 value);
    event SharesRedeemed(address indexed holder, uint256 shares, uint256 value);
    event VaultRebalanced(uint256 totalValue, uint256 timestamp);
    event PriceUpdated(address indexed asset, uint256 oldPrice, uint256 newPrice);
    event LeverageUpdated(uint256 borrowed, uint256 totalValue, uint256 ltv);
    event AssetDeposited(address indexed asset, uint256 amount, uint256 value);
    event AssetWithdrawn(address indexed asset, uint256 amount, uint256 value);
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(VAULT_MANAGER_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);
        
        // Set initial allocation targets (basis points)
        allocationTargets = AllocationTargets({
            stablecoins: 4000,  // 40%
            bitcoin: 2000,      // 20%
            gold: 2000,         // 20%
            ethereum: 1000,     // 10%
            rwa: 1000,          // 10%
            tolerance: 500      // 5% tolerance
        });
        
        // Set initial leverage parameters
        leverageInfo = LeverageInfo({
            totalBorrowed: 0,
            maxLTV: 8000,       // 80% max LTV
            interestRate: 800,  // 8% annual
            liquidationThreshold: 8500 // 85%
        });
    }
    
    /**
     * @dev Add supported asset to the vault
     */
    function addAsset(
        address token,
        AssetType assetType,
        uint256 minDeposit,
        uint256 maxAllocation,
        uint256 initialPrice
    ) external onlyRole(VAULT_MANAGER_ROLE) {
        require(token != address(0), "Invalid token address");
        require(!assets[token].active, "Asset already exists");
        
        assets[token] = AssetInfo({
            token: IERC20(token),
            assetType: assetType,
            balance: 0,
            price: initialPrice,
            lastPriceUpdate: block.timestamp,
            active: true,
            minDeposit: minDeposit,
            maxAllocation: maxAllocation
        });
        
        allAssets.push(token);
        assetsByType[assetType].push(token);
        
        emit AssetAdded(token, assetType);
    }
    
    /**
     * @dev Deposit asset and receive vault shares
     */
    function depositAsset(
        address asset,
        uint256 amount,
        bool isEarlyAdopter
    ) external nonReentrant whenNotPaused {
        AssetInfo storage assetInfo = assets[asset];
        require(assetInfo.active, "Asset not supported");
        require(amount >= assetInfo.minDeposit, "Below minimum deposit");
        
        // Transfer asset to vault
        assetInfo.token.safeTransferFrom(msg.sender, address(this), amount);
        
        // Calculate USD value
        uint256 usdValue = (amount * assetInfo.price) / 10**18;
        
        // Calculate shares to issue
        uint256 shares;
        if (totalShares == 0) {
            shares = usdValue; // 1:1 initial ratio
        } else {
            shares = (usdValue * totalShares) / totalVaultValue;
        }
        
        // Update records
        assetInfo.balance += amount;
        totalVaultValue += usdValue;
        totalShares += shares;
        
        ShareHolder storage holder = shareHolders[msg.sender];
        holder.shares += shares;
        holder.depositedValue += usdValue;
        holder.lastDeposit = block.timestamp;
        holder.earlyAdopter = isEarlyAdopter;
        
        // Set lock period
        uint256 lockPeriod = isEarlyAdopter ? EARLY_ADOPTER_LOCK : STANDARD_LOCK;
        if (holder.lockedUntil < block.timestamp + lockPeriod) {
            holder.lockedUntil = block.timestamp + lockPeriod;
        }
        
        emit AssetDeposited(asset, amount, usdValue);
        emit SharesIssued(msg.sender, shares, usdValue);
    }
    
    /**
     * @dev Redeem shares for proportional assets
     */
    function redeemShares(uint256 shares) external nonReentrant {
        ShareHolder storage holder = shareHolders[msg.sender];
        require(holder.shares >= shares, "Insufficient shares");
        require(block.timestamp >= holder.lockedUntil, "Shares still locked");
        
        // Calculate redemption value
        uint256 redemptionValue = (shares * totalVaultValue) / totalShares;
        
        // Update records
        holder.shares -= shares;
        totalShares -= shares;
        totalVaultValue -= redemptionValue;
        
        // Redeem proportionally from all assets
        _redeemProportionally(msg.sender, redemptionValue);
        
        emit SharesRedeemed(msg.sender, shares, redemptionValue);
    }
    
    /**
     * @dev Internal function to redeem assets proportionally
     */
    function _redeemProportionally(address recipient, uint256 totalValue) internal {
        for (uint i = 0; i < allAssets.length; i++) {
            address asset = allAssets[i];
            AssetInfo storage assetInfo = assets[asset];
            
            if (assetInfo.balance > 0) {
                uint256 assetValue = (assetInfo.balance * assetInfo.price) / 10**18;
                uint256 assetShare = (assetValue * totalValue) / totalVaultValue;
                uint256 assetAmount = (assetShare * 10**18) / assetInfo.price;
                
                if (assetAmount > 0 && assetAmount <= assetInfo.balance) {
                    assetInfo.balance -= assetAmount;
                    assetInfo.token.safeTransfer(recipient, assetAmount);
                    emit AssetWithdrawn(asset, assetAmount, assetShare);
                }
            }
        }
    }
    
    /**
     * @dev Update asset price (oracle function)
     */
    function updateAssetPrice(
        address asset,
        uint256 newPrice
    ) external onlyRole(ORACLE_ROLE) {
        AssetInfo storage assetInfo = assets[asset];
        require(assetInfo.active, "Asset not active");
        
        uint256 oldPrice = assetInfo.price;
        assetInfo.price = newPrice;
        assetInfo.lastPriceUpdate = block.timestamp;
        
        // Update total vault value
        _updateTotalVaultValue();
        
        emit PriceUpdated(asset, oldPrice, newPrice);
    }
    
    /**
     * @dev Rebalance vault to target allocations
     */
    function rebalanceVault() external onlyRole(VAULT_MANAGER_ROLE) {
        require(block.timestamp >= lastRebalance + rebalanceInterval, "Too soon to rebalance");
        
        _updateTotalVaultValue();
        
        // Calculate current allocations
        uint256[6] memory currentAllocations = _getCurrentAllocations();
        uint256[6] memory targetAllocations = [
            allocationTargets.stablecoins,
            allocationTargets.bitcoin,
            allocationTargets.gold,
            allocationTargets.ethereum,
            allocationTargets.rwa,
            0 // OTHER
        ];
        
        // Check if rebalancing is needed
        bool needsRebalancing = false;
        for (uint i = 0; i < 5; i++) {
            uint256 deviation = currentAllocations[i] > targetAllocations[i] 
                ? currentAllocations[i] - targetAllocations[i]
                : targetAllocations[i] - currentAllocations[i];
            
            if (deviation > allocationTargets.tolerance) {
                needsRebalancing = true;
                break;
            }
        }
        
        if (needsRebalancing) {
            // Implement rebalancing logic here
            // This would involve selling over-allocated assets and buying under-allocated ones
            _executeRebalancing(currentAllocations, targetAllocations);
        }
        
        lastRebalance = block.timestamp;
        emit VaultRebalanced(totalVaultValue, block.timestamp);
    }
    
    /**
     * @dev Execute vault rebalancing
     */
    function _executeRebalancing(
        uint256[6] memory current,
        uint256[6] memory targets
    ) internal {
        // Simplified rebalancing - in production would use DEX integration
        // For now, just emit event to track rebalancing needs
        for (uint i = 0; i < 5; i++) {
            if (current[i] != targets[i]) {
                // Log rebalancing action needed
            }
        }
    }
    
    /**
     * @dev Get current allocations by asset type
     */
    function _getCurrentAllocations() internal view returns (uint256[6] memory) {
        uint256[6] memory allocations;
        
        if (totalVaultValue == 0) return allocations;
        
        for (uint i = 0; i < allAssets.length; i++) {
            address asset = allAssets[i];
            AssetInfo memory assetInfo = assets[asset];
            
            uint256 assetValue = (assetInfo.balance * assetInfo.price) / 10**18;
            uint256 allocation = (assetValue * 10000) / totalVaultValue;
            
            allocations[uint(assetInfo.assetType)] += allocation;
        }
        
        return allocations;
    }
    
    /**
     * @dev Update total vault value based on current prices
     */
    function _updateTotalVaultValue() internal {
        uint256 newTotalValue = 0;
        
        for (uint i = 0; i < allAssets.length; i++) {
            address asset = allAssets[i];
            AssetInfo memory assetInfo = assets[asset];
            
            uint256 assetValue = (assetInfo.balance * assetInfo.price) / 10**18;
            newTotalValue += assetValue;
        }
        
        totalVaultValue = newTotalValue;
    }
    
    /**
     * @dev Borrow against vault assets (leverage)
     */
    function borrowAgainstAssets(
        uint256 borrowAmount
    ) external onlyRole(VAULT_MANAGER_ROLE) {
        require(borrowAmount > 0, "Invalid borrow amount");
        
        uint256 newTotalBorrowed = leverageInfo.totalBorrowed + borrowAmount;
        uint256 currentLTV = (newTotalBorrowed * 10000) / totalVaultValue;
        
        require(currentLTV <= leverageInfo.maxLTV, "Exceeds max LTV");
        
        leverageInfo.totalBorrowed = newTotalBorrowed;
        
        emit LeverageUpdated(newTotalBorrowed, totalVaultValue, currentLTV);
    }
    
    /**
     * @dev Get vault performance metrics
     */
    function getVaultMetrics() external view returns (
        uint256 _totalShares,
        uint256 _totalValue,
        uint256 _sharePrice,
        uint256[6] memory _allocations,
        uint256 _leverage
    ) {
        _sharePrice = totalShares > 0 ? (totalVaultValue * 10**18) / totalShares : 0;
        _allocations = _getCurrentAllocations();
        _leverage = totalVaultValue > 0 ? (leverageInfo.totalBorrowed * 10000) / totalVaultValue : 0;
        
        return (totalShares, totalVaultValue, _sharePrice, _allocations, _leverage);
    }
    
    /**
     * @dev Get share holder information
     */
    function getShareHolderInfo(address holder) external view returns (
        uint256 shares,
        uint256 value,
        uint256 lockedUntil,
        uint256 returns,
        bool isEarlyAdopter
    ) {
        ShareHolder memory sh = shareHolders[holder];
        uint256 currentValue = totalShares > 0 ? (sh.shares * totalVaultValue) / totalShares : 0;
        uint256 totalReturns = currentValue > sh.depositedValue ? currentValue - sh.depositedValue : 0;
        
        return (
            sh.shares,
            currentValue,
            sh.lockedUntil,
            totalReturns,
            sh.earlyAdopter
        );
    }
    
    /**
     * @dev Check if shares are unlocked
     */
    function areSharesUnlocked(address holder) external view returns (bool) {
        return block.timestamp >= shareHolders[holder].lockedUntil;
    }
    
    // Admin functions
    function updateAllocationTargets(
        uint256 stablecoins,
        uint256 bitcoin,
        uint256 gold,
        uint256 ethereum,
        uint256 rwa,
        uint256 tolerance
    ) external onlyRole(ADMIN_ROLE) {
        require(stablecoins + bitcoin + gold + ethereum + rwa == 10000, "Must sum to 100%");
        
        allocationTargets = AllocationTargets({
            stablecoins: stablecoins,
            bitcoin: bitcoin,
            gold: gold,
            ethereum: ethereum,
            rwa: rwa,
            tolerance: tolerance
        });
    }
    
    function updateLeverageParameters(
        uint256 maxLTV,
        uint256 interestRate,
        uint256 liquidationThreshold
    ) external onlyRole(ADMIN_ROLE) {
        leverageInfo.maxLTV = maxLTV;
        leverageInfo.interestRate = interestRate;
        leverageInfo.liquidationThreshold = liquidationThreshold;
    }
    
    function emergencyPause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }
    
    function emergencyUnpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }
    
    function emergencyWithdraw(address asset, uint256 amount) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        IERC20(asset).safeTransfer(msg.sender, amount);
    }
}