// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./UnykornToken.sol";

/**
 * @title Revenue Vault - Automated Commerce Revenue Sharing
 * @dev Multi-merchant revenue splitting with instant transparent distribution
 */
contract RevVault is AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MERCHANT_ROLE = keccak256("MERCHANT_ROLE");
    bytes32 public constant COMMISSION_MANAGER_ROLE = keccak256("COMMISSION_MANAGER_ROLE");
    
    UnykornToken public unykornToken;
    
    // Offer types
    enum OfferType {
        VOUCHER,        // Discount vouchers
        MEMBERSHIP,     // Subscription services
        SERVICE,        // One-time services
        PRODUCT,        // Physical/digital products
        EVENT           // Event tickets
    }
    
    // Revenue split configuration
    struct RevenueSplit {
        uint256 merchantPercent;        // 90-95%
        uint256 directCommissionPercent;// up to 50%
        uint256 teamOverridePercent;    // 3-5%
        uint256 poiSplitPercent;        // 1-3%
        uint256 territoryPoolPercent;   // 1-2%
        uint256 platformFeePercent;     // 1-3%
        uint256 tokenBurnPercent;       // configurable %
    }
    
    // Merchant offer
    struct MerchantOffer {
        uint256 offerId;
        address merchant;
        string name;
        string description;
        OfferType offerType;
        uint256 price;                  // Price in wei
        uint256 tokenPrice;             // Price in UNY tokens
        uint256 maxSupply;
        uint256 totalSold;
        bool active;
        RevenueSplit revenueSplit;
        string metadataURI;
        uint256 createdAt;
        uint256 expiresAt;
    }
    
    // Purchase record
    struct Purchase {
        uint256 purchaseId;
        uint256 offerId;
        address buyer;
        address referrer;               // Direct commission recipient
        uint256 amountPaid;
        uint256 tokensBurned;
        uint256 timestamp;
        bool fulfilled;
        string fulfillmentData;
    }
    
    // Commission tracking
    struct CommissionEarner {
        address earner;
        uint256 totalEarned;
        uint256 directCommissions;
        uint256 teamOverrides;
        uint256 poiCommissions;
        uint256 territoryCommissions;
        uint256 lastActivity;
    }
    
    // State variables
    mapping(uint256 => MerchantOffer) public offers;
    mapping(uint256 => Purchase) public purchases;
    mapping(address => CommissionEarner) public commissionEarners;
    mapping(address => uint256[]) public merchantOffers;
    mapping(address => uint256[]) public userPurchases;
    mapping(address => bool) public approvedMerchants;
    
    uint256 public offerCount;
    uint256 public purchaseCount;
    uint256 public totalRevenue;
    uint256 public totalCommissionsPaid;
    uint256 public totalTokensBurned;
    
    // Default revenue split (basis points - 10000 = 100%)
    RevenueSplit public defaultSplit = RevenueSplit({
        merchantPercent: 9200,          // 92%
        directCommissionPercent: 300,   // 3%
        teamOverridePercent: 200,       // 2%
        poiSplitPercent: 100,           // 1%
        territoryPoolPercent: 100,      // 1%
        platformFeePercent: 100,        // 1%
        tokenBurnPercent: 0             // 0% (can be increased)
    });
    
    // Territory pool for geographic rewards
    mapping(uint256 => uint256) public territoryPools; // territoryId => accumulated rewards
    mapping(address => uint256) public userTerritories; // user => assigned territory
    
    // Events
    event OfferCreated(uint256 indexed offerId, address indexed merchant, string name, uint256 price);
    event OfferPurchased(uint256 indexed purchaseId, uint256 indexed offerId, address indexed buyer, uint256 amount);
    event RevenueDistributed(uint256 indexed purchaseId, uint256 totalAmount, uint256 commissionsPaid);
    event CommissionPaid(address indexed recipient, uint256 amount, string commissionType);
    event TokensBurned(uint256 amount, uint256 purchaseId);
    event MerchantApproved(address indexed merchant);
    event OfferFulfilled(uint256 indexed purchaseId, string fulfillmentData);
    
    constructor(address _unykornToken) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(COMMISSION_MANAGER_ROLE, msg.sender);
        
        unykornToken = UnykornToken(_unykornToken);
    }
    
    /**
     * @dev Approve merchant to create offers
     */
    function approveMerchant(address merchant) external onlyRole(ADMIN_ROLE) {
        approvedMerchants[merchant] = true;
        _grantRole(MERCHANT_ROLE, merchant);
        emit MerchantApproved(merchant);
    }
    
    /**
     * @dev Create merchant offer
     */
    function createOffer(
        string memory name,
        string memory description,
        OfferType offerType,
        uint256 price,
        uint256 tokenPrice,
        uint256 maxSupply,
        uint256 expirationTime,
        string memory metadataURI,
        RevenueSplit memory customSplit
    ) external onlyRole(MERCHANT_ROLE) nonReentrant returns (uint256) {
        require(approvedMerchants[msg.sender], "Not approved merchant");
        require(price > 0 || tokenPrice > 0, "Must have price");
        require(expirationTime > block.timestamp, "Invalid expiration");
        
        // Validate revenue split (must sum to 100% or less for burns)
        uint256 totalSplit = customSplit.merchantPercent + 
                           customSplit.directCommissionPercent +
                           customSplit.teamOverridePercent +
                           customSplit.poiSplitPercent +
                           customSplit.territoryPoolPercent +
                           customSplit.platformFeePercent +
                           customSplit.tokenBurnPercent;
        require(totalSplit <= 10000, "Split exceeds 100%");
        
        uint256 offerId = offerCount++;
        
        offers[offerId] = MerchantOffer({
            offerId: offerId,
            merchant: msg.sender,
            name: name,
            description: description,
            offerType: offerType,
            price: price,
            tokenPrice: tokenPrice,
            maxSupply: maxSupply,
            totalSold: 0,
            active: true,
            revenueSplit: customSplit.merchantPercent > 0 ? customSplit : defaultSplit,
            metadataURI: metadataURI,
            createdAt: block.timestamp,
            expiresAt: expirationTime
        });
        
        merchantOffers[msg.sender].push(offerId);
        
        emit OfferCreated(offerId, msg.sender, name, price);
        return offerId;
    }
    
    /**
     * @dev Purchase offer with automatic revenue splitting
     */
    function purchaseOffer(
        uint256 offerId,
        address referrer,
        bool useTokens
    ) external payable nonReentrant whenNotPaused {
        MerchantOffer storage offer = offers[offerId];
        require(offer.active, "Offer not active");
        require(block.timestamp <= offer.expiresAt, "Offer expired");
        require(offer.totalSold < offer.maxSupply || offer.maxSupply == 0, "Sold out");
        
        uint256 paymentAmount;
        uint256 tokensBurned = 0;
        
        if (useTokens) {
            require(offer.tokenPrice > 0, "Token payment not accepted");
            paymentAmount = offer.tokenPrice;
            
            // Use utility function which includes automatic burn
            unykornToken.useUtility(paymentAmount, string(abi.encodePacked("Purchase: ", offer.name)));
            tokensBurned = (paymentAmount * unykornToken.burnRatePercent()) / 10000;
        } else {
            require(offer.price > 0, "ETH payment not accepted");
            require(msg.value >= offer.price, "Insufficient payment");
            paymentAmount = offer.price;
        }
        
        // Create purchase record
        uint256 purchaseId = purchaseCount++;
        purchases[purchaseId] = Purchase({
            purchaseId: purchaseId,
            offerId: offerId,
            buyer: msg.sender,
            referrer: referrer,
            amountPaid: paymentAmount,
            tokensBurned: tokensBurned,
            timestamp: block.timestamp,
            fulfilled: false,
            fulfillmentData: ""
        });
        
        userPurchases[msg.sender].push(purchaseId);
        offer.totalSold++;
        totalRevenue += paymentAmount;
        
        // Execute revenue split
        _executeRevenueSplit(purchaseId, paymentAmount, useTokens);
        
        emit OfferPurchased(purchaseId, offerId, msg.sender, paymentAmount);
        if (tokensBurned > 0) {
            totalTokensBurned += tokensBurned;
            emit TokensBurned(tokensBurned, purchaseId);
        }
    }
    
    /**
     * @dev Execute revenue splitting
     */
    function _executeRevenueSplit(
        uint256 purchaseId,
        uint256 totalAmount,
        bool useTokens
    ) internal {
        Purchase memory purchase = purchases[purchaseId];
        MerchantOffer memory offer = offers[purchase.offerId];
        RevenueSplit memory split = offer.revenueSplit;
        
        uint256 remaining = totalAmount;
        uint256 totalCommissions = 0;
        
        // 1. Merchant payment (largest portion)
        uint256 merchantAmount = (totalAmount * split.merchantPercent) / 10000;
        if (merchantAmount > 0) {
            if (useTokens) {
                // Transfer tokens to merchant
                unykornToken.transfer(offer.merchant, merchantAmount);
            } else {
                payable(offer.merchant).transfer(merchantAmount);
            }
            remaining -= merchantAmount;
        }
        
        // 2. Direct commission to referrer
        if (purchase.referrer != address(0) && split.directCommissionPercent > 0) {
            uint256 directCommission = (totalAmount * split.directCommissionPercent) / 10000;
            if (directCommission > 0 && remaining >= directCommission) {
                _payCommission(purchase.referrer, directCommission, "Direct Commission", useTokens);
                totalCommissions += directCommission;
                remaining -= directCommission;
            }
        }
        
        // 3. Team override commission
        if (split.teamOverridePercent > 0) {
            uint256 teamOverride = (totalAmount * split.teamOverridePercent) / 10000;
            if (teamOverride > 0 && remaining >= teamOverride) {
                address upline = unykornToken.upline(purchase.buyer);
                if (upline != address(0)) {
                    _payCommission(upline, teamOverride, "Team Override", useTokens);
                    totalCommissions += teamOverride;
                    remaining -= teamOverride;
                }
            }
        }
        
        // 4. POI commission split
        if (split.poiSplitPercent > 0) {
            uint256 poiCommission = (totalAmount * split.poiSplitPercent) / 10000;
            if (poiCommission > 0 && remaining >= poiCommission) {
                _distributePOICommissions(purchase.buyer, poiCommission, useTokens);
                totalCommissions += poiCommission;
                remaining -= poiCommission;
            }
        }
        
        // 5. Territory pool contribution
        if (split.territoryPoolPercent > 0) {
            uint256 territoryAmount = (totalAmount * split.territoryPoolPercent) / 10000;
            if (territoryAmount > 0 && remaining >= territoryAmount) {
                uint256 territory = userTerritories[purchase.buyer];
                if (territory > 0) {
                    territoryPools[territory] += territoryAmount;
                }
                remaining -= territoryAmount;
            }
        }
        
        // 6. Platform fee (to contract for operations)
        if (split.platformFeePercent > 0) {
            uint256 platformFee = (totalAmount * split.platformFeePercent) / 10000;
            if (platformFee > 0 && remaining >= platformFee) {
                // Platform fee stays in contract
                remaining -= platformFee;
            }
        }
        
        // 7. Token burn (if specified and using tokens)
        if (useTokens && split.tokenBurnPercent > 0) {
            uint256 burnAmount = (totalAmount * split.tokenBurnPercent) / 10000;
            if (burnAmount > 0) {
                // Additional burn beyond the automatic utility burn
                totalTokensBurned += burnAmount;
                emit TokensBurned(burnAmount, purchaseId);
            }
        }
        
        totalCommissionsPaid += totalCommissions;
        emit RevenueDistributed(purchaseId, totalAmount, totalCommissions);
    }
    
    /**
     * @dev Pay commission to recipient
     */
    function _payCommission(
        address recipient,
        uint256 amount,
        string memory commissionType,
        bool useTokens
    ) internal {
        if (useTokens) {
            unykornToken.transfer(recipient, amount);
        } else {
            payable(recipient).transfer(amount);
        }
        
        // Update commission tracking
        CommissionEarner storage earner = commissionEarners[recipient];
        earner.earner = recipient;
        earner.totalEarned += amount;
        earner.lastActivity = block.timestamp;
        
        if (keccak256(bytes(commissionType)) == keccak256("Direct Commission")) {
            earner.directCommissions += amount;
        } else if (keccak256(bytes(commissionType)) == keccak256("Team Override")) {
            earner.teamOverrides += amount;
        } else if (keccak256(bytes(commissionType)) == keccak256("POI Commission")) {
            earner.poiCommissions += amount;
        }
        
        emit CommissionPaid(recipient, amount, commissionType);
    }
    
    /**
     * @dev Distribute POI commissions based on historical introductions
     */
    function _distributePOICommissions(
        address buyer,
        uint256 totalAmount,
        bool useTokens
    ) internal {
        // Get POI records for this buyer
        // This would need to interface with the token contract's POI records
        // Simplified implementation - in practice would split among multiple introducers
        
        // For now, send to contract for manual distribution
        // In full implementation, would iterate through POI records and distribute proportionally
    }
    
    /**
     * @dev Fulfill purchase order
     */
    function fulfillPurchase(
        uint256 purchaseId,
        string memory fulfillmentData
    ) external {
        Purchase storage purchase = purchases[purchaseId];
        MerchantOffer memory offer = offers[purchase.offerId];
        
        require(msg.sender == offer.merchant, "Only merchant can fulfill");
        require(!purchase.fulfilled, "Already fulfilled");
        
        purchase.fulfilled = true;
        purchase.fulfillmentData = fulfillmentData;
        
        emit OfferFulfilled(purchaseId, fulfillmentData);
    }
    
    /**
     * @dev Set user territory for pool rewards
     */
    function setUserTerritory(
        address user,
        uint256 territoryId
    ) external onlyRole(COMMISSION_MANAGER_ROLE) {
        userTerritories[user] = territoryId;
    }
    
    /**
     * @dev Claim territory pool rewards
     */
    function claimTerritoryRewards(uint256 territoryId) external {
        require(userTerritories[msg.sender] == territoryId, "Not your territory");
        require(territoryPools[territoryId] > 0, "No rewards available");
        
        uint256 rewards = territoryPools[territoryId];
        territoryPools[territoryId] = 0;
        
        payable(msg.sender).transfer(rewards);
        
        CommissionEarner storage earner = commissionEarners[msg.sender];
        earner.territoryCommissions += rewards;
        earner.totalEarned += rewards;
        
        emit CommissionPaid(msg.sender, rewards, "Territory Pool");
    }
    
    /**
     * @dev Get merchant's offers
     */
    function getMerchantOffers(address merchant) external view returns (uint256[] memory) {
        return merchantOffers[merchant];
    }
    
    /**
     * @dev Get user's purchases
     */
    function getUserPurchases(address user) external view returns (uint256[] memory) {
        return userPurchases[user];
    }
    
    /**
     * @dev Get offer details
     */
    function getOfferDetails(uint256 offerId) external view returns (MerchantOffer memory) {
        return offers[offerId];
    }
    
    /**
     * @dev Get commission stats for user
     */
    function getCommissionStats(address user) external view returns (CommissionEarner memory) {
        return commissionEarners[user];
    }
    
    /**
     * @dev Get territory pool balance
     */
    function getTerritoryPool(uint256 territoryId) external view returns (uint256) {
        return territoryPools[territoryId];
    }
    
    // Admin functions
    function updateDefaultSplit(RevenueSplit memory newSplit) external onlyRole(ADMIN_ROLE) {
        uint256 totalSplit = newSplit.merchantPercent + 
                           newSplit.directCommissionPercent +
                           newSplit.teamOverridePercent +
                           newSplit.poiSplitPercent +
                           newSplit.territoryPoolPercent +
                           newSplit.platformFeePercent +
                           newSplit.tokenBurnPercent;
        require(totalSplit <= 10000, "Split exceeds 100%");
        
        defaultSplit = newSplit;
    }
    
    function deactivateOffer(uint256 offerId) external {
        MerchantOffer storage offer = offers[offerId];
        require(
            msg.sender == offer.merchant || hasRole(ADMIN_ROLE, msg.sender),
            "Not authorized"
        );
        offer.active = false;
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
    
    // Receive ETH
    receive() external payable {
        // Accept ETH deposits for revenue splitting
    }
}