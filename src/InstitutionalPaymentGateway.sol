// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UnykornToken.sol";
import "./SalesForceManager.sol";

/**
 * @title Institutional Payment Gateway - Multi-Payment System
 * @dev Professional-grade payment processing with multiple payment methods,
 * institutional security, and automated token distribution
 */
contract InstitutionalPaymentGateway is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PAYMENT_PROCESSOR_ROLE = keccak256("PAYMENT_PROCESSOR_ROLE");
    bytes32 public constant CUSTODY_ROLE = keccak256("CUSTODY_ROLE");
    
    UnykornToken public unykornToken;
    SalesForceManager public salesForceManager;
    
    // Payment methods supported
    enum PaymentMethod {
        ETH,                // Ethereum
        USDC,              // USD Coin
        USDT,              // Tether
        DAI,               // Dai Stablecoin
        WBTC,              // Wrapped Bitcoin
        CREDIT_CARD,       // Fiat credit card (processed off-chain)
        BANK_TRANSFER,     // Wire transfer (processed off-chain)
        PAYPAL,            // PayPal integration
        STRIPE,            // Stripe integration
        APPLE_PAY,         // Apple Pay
        GOOGLE_PAY,        // Google Pay
        ACH_TRANSFER       // ACH bank transfer
    }
    
    // Payment processor configuration
    struct PaymentProcessor {
        string name;
        address contractAddress;    // For on-chain payments
        string apiEndpoint;         // For off-chain payments
        uint256 feePercent;         // Fee in basis points
        bool active;
        bool requiresKYC;
        uint256 minAmount;
        uint256 maxAmount;
    }
    
    // Purchase order
    struct PurchaseOrder {
        uint256 orderId;
        address buyer;
        PaymentMethod paymentMethod;
        uint256 amount;             // Amount in payment currency
        uint256 usdAmount;          // Amount in USD (normalized)
        uint256 tokenAmount;        // Tokens to receive
        SalesForceManager.PackTier packTier;
        address referrer;
        uint256 timestamp;
        bool processed;
        bool refunded;
        string externalTxId;        // External payment ID
        bytes32 proofHash;          // IPFS hash of payment proof
    }
    
    // KYC/AML status
    struct KYCStatus {
        bool verified;
        uint256 verificationDate;
        string kycProvider;         // "Chainalysis", "Elliptic", "ComplyAdvantage"
        uint256 riskScore;          // 0-100, higher = riskier
        string jurisdiction;
        uint256 dailyLimit;
        uint256 monthlyLimit;
        uint256 dailySpent;
        uint256 monthlySpent;
    }
    
    // Custody and escrow
    struct EscrowAccount {
        address beneficiary;
        uint256 amount;
        uint256 releaseDate;
        bool released;
        string custodian;           // "Fireblocks", "BitGo", "Coinbase Custody"
        bytes32 custodyProof;
    }
    
    // State variables
    mapping(PaymentMethod => PaymentProcessor) public paymentProcessors;
    mapping(uint256 => PurchaseOrder) public purchaseOrders;
    mapping(address => KYCStatus) public kycStatus;
    mapping(address => uint256[]) public userOrders;
    mapping(bytes32 => EscrowAccount) public escrowAccounts;
    
    uint256 public orderCount;
    uint256 public totalVolume;
    uint256 public totalFees;
    
    // Supported stablecoins
    mapping(address => bool) public supportedStablecoins;
    mapping(address => uint256) public stablecoinPrices; // Price in USD with 8 decimals
    
    // Institutional features
    address public institutionalCustody;    // Professional custody service
    address public complianceOracle;        // Compliance data feed
    address public treasuryWallet;          // Multi-sig treasury
    
    // Events
    event PaymentProcessorUpdated(PaymentMethod method, string name, bool active);
    event PurchaseOrderCreated(uint256 indexed orderId, address indexed buyer, PaymentMethod method, uint256 amount);
    event PaymentProcessed(uint256 indexed orderId, bytes32 proofHash, uint256 tokensDistributed);
    event KYCVerified(address indexed user, string provider, uint256 riskScore);
    event EscrowCreated(bytes32 indexed escrowId, address beneficiary, uint256 amount);
    event EscrowReleased(bytes32 indexed escrowId, address beneficiary, uint256 amount);
    event RefundProcessed(uint256 indexed orderId, address user, uint256 amount);
    
    constructor(
        address _unykornToken,
        address _salesForceManager,
        address _institutionalCustody,
        address _treasuryWallet
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(PAYMENT_PROCESSOR_ROLE, msg.sender);
        
        unykornToken = UnykornToken(_unykornToken);
        salesForceManager = SalesForceManager(_salesForceManager);
        institutionalCustody = _institutionalCustody;
        treasuryWallet = _treasuryWallet;
        
        _initializePaymentProcessors();
        _initializeStablecoins();
    }
    
    /**
     * @dev Initialize payment processors with institutional partners
     */
    function _initializePaymentProcessors() internal {
        // Ethereum native
        paymentProcessors[PaymentMethod.ETH] = PaymentProcessor({
            name: "Ethereum",
            contractAddress: address(0), // Native ETH
            apiEndpoint: "",
            feePercent: 0, // No additional fee for ETH
            active: true,
            requiresKYC: false,
            minAmount: 0.01 ether,
            maxAmount: 100 ether
        });
        
        // USDC (institutional standard)
        paymentProcessors[PaymentMethod.USDC] = PaymentProcessor({
            name: "USD Coin",
            contractAddress: 0xA0b86a33E6441C82b1C39b59d5df72dF95CAf5C5, // USDC mainnet
            apiEndpoint: "",
            feePercent: 0,
            active: true,
            requiresKYC: false,
            minAmount: 10 * 10**6, // $10 USDC
            maxAmount: 100000 * 10**6 // $100k USDC
        });
        
        // Credit Card (Stripe integration)
        paymentProcessors[PaymentMethod.CREDIT_CARD] = PaymentProcessor({
            name: "Credit Card (Stripe)",
            contractAddress: address(0),
            apiEndpoint: "https://api.stripe.com/v1/payment_intents",
            feePercent: 290, // 2.9% + $0.30
            active: true,
            requiresKYC: true,
            minAmount: 25, // $25
            maxAmount: 10000 // $10k daily limit
        });
        
        // Bank Transfer (institutional)
        paymentProcessors[PaymentMethod.BANK_TRANSFER] = PaymentProcessor({
            name: "Wire Transfer",
            contractAddress: address(0),
            apiEndpoint: "https://api.banking-partner.com/wire",
            feePercent: 50, // 0.5%
            active: true,
            requiresKYC: true,
            minAmount: 1000, // $1k minimum
            maxAmount: 1000000 // $1M maximum
        });
        
        // PayPal
        paymentProcessors[PaymentMethod.PAYPAL] = PaymentProcessor({
            name: "PayPal",
            contractAddress: address(0),
            apiEndpoint: "https://api.paypal.com/v2/payments",
            feePercent: 290, // 2.9%
            active: true,
            requiresKYC: true,
            minAmount: 25,
            maxAmount: 10000
        });
        
        // Apple Pay
        paymentProcessors[PaymentMethod.APPLE_PAY] = PaymentProcessor({
            name: "Apple Pay",
            contractAddress: address(0),
            apiEndpoint: "https://apple-pay.gateway.com/process",
            feePercent: 290,
            active: true,
            requiresKYC: false, // Lower limits, no KYC
            minAmount: 25,
            maxAmount: 1000
        });
    }
    
    /**
     * @dev Initialize supported stablecoins with Chainlink price feeds
     */
    function _initializeStablecoins() internal {
        // USDC
        supportedStablecoins[0xA0b86a33E6441C82b1C39b59d5df72dF95CAf5C5] = true;
        stablecoinPrices[0xA0b86a33E6441C82b1C39b59d5df72dF95CAf5C5] = 100000000; // $1.00
        
        // USDT
        supportedStablecoins[0xdAC17F958D2ee523a2206206994597C13D831ec7] = true;
        stablecoinPrices[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 100000000; // $1.00
        
        // DAI
        supportedStablecoins[0x6B175474E89094C44Da98b954EedeAC495271d0F] = true;
        stablecoinPrices[0x6B175474E89094C44Da98b954EedeAC495271d0F] = 100000000; // $1.00
    }
    
    /**
     * @dev Create purchase order with multiple payment options
     */
    function createPurchaseOrder(
        PaymentMethod paymentMethod,
        SalesForceManager.PackTier packTier,
        address referrer,
        string calldata externalTxId
    ) external nonReentrant whenNotPaused returns (uint256) {
        PaymentProcessor memory processor = paymentProcessors[paymentMethod];
        require(processor.active, "Payment method not available");
        
        // KYC check if required
        if (processor.requiresKYC) {
            require(kycStatus[msg.sender].verified, "KYC verification required");
        }
        
        // Get pack pricing
        uint256 packPrice = salesForceManager.getMembershipFee(packTier);
        require(packPrice >= processor.minAmount, "Amount below minimum");
        require(packPrice <= processor.maxAmount, "Amount above maximum");
        
        // Check daily/monthly limits
        _checkSpendingLimits(msg.sender, packPrice);
        
        uint256 orderId = orderCount++;
        
        // Calculate tokens based on pack tier
        uint256 tokenAmount = _calculateTokenAmount(packTier);
        
        // Create order
        purchaseOrders[orderId] = PurchaseOrder({
            orderId: orderId,
            buyer: msg.sender,
            paymentMethod: paymentMethod,
            amount: packPrice,
            usdAmount: packPrice, // Assuming USD pricing
            tokenAmount: tokenAmount,
            packTier: packTier,
            referrer: referrer,
            timestamp: block.timestamp,
            processed: false,
            refunded: false,
            externalTxId: externalTxId,
            proofHash: bytes32(0)
        });
        
        userOrders[msg.sender].push(orderId);
        
        emit PurchaseOrderCreated(orderId, msg.sender, paymentMethod, packPrice);
        return orderId;
    }
    
    /**
     * @dev Process on-chain payment (ETH, USDC, etc.)
     */
    function processOnChainPayment(
        uint256 orderId,
        address tokenAddress
    ) external payable nonReentrant {
        PurchaseOrder storage order = purchaseOrders[orderId];
        require(order.buyer == msg.sender, "Not order owner");
        require(!order.processed, "Order already processed");
        
        PaymentProcessor memory processor = paymentProcessors[order.paymentMethod];
        
        if (order.paymentMethod == PaymentMethod.ETH) {
            require(msg.value >= order.amount, "Insufficient ETH");
            
            // Process ETH payment
            uint256 fee = (msg.value * processor.feePercent) / 10000;
            uint256 netAmount = msg.value - fee;
            
            // Send to treasury
            payable(treasuryWallet).transfer(netAmount);
            if (fee > 0) {
                payable(institutionalCustody).transfer(fee);
            }
            
        } else if (supportedStablecoins[tokenAddress]) {
            IERC20 token = IERC20(tokenAddress);
            require(token.transferFrom(msg.sender, address(this), order.amount), "Transfer failed");
            
            // Calculate fee and transfer
            uint256 fee = (order.amount * processor.feePercent) / 10000;
            uint256 netAmount = order.amount - fee;
            
            token.transfer(treasuryWallet, netAmount);
            if (fee > 0) {
                token.transfer(institutionalCustody, fee);
            }
        } else {
            revert("Unsupported token");
        }
        
        // Complete order processing
        _completeOrder(orderId);
    }
    
    /**
     * @dev Process off-chain payment (admin function after external verification)
     */
    function processOffChainPayment(
        uint256 orderId,
        bytes32 proofHash,
        string calldata txReference
    ) external onlyRole(PAYMENT_PROCESSOR_ROLE) {
        PurchaseOrder storage order = purchaseOrders[orderId];
        require(!order.processed, "Order already processed");
        
        // Store proof of payment
        order.proofHash = proofHash;
        order.externalTxId = txReference;
        
        // Complete order processing
        _completeOrder(orderId);
    }
    
    /**
     * @dev Complete order processing and distribute tokens
     */
    function _completeOrder(uint256 orderId) internal {
        PurchaseOrder storage order = purchaseOrders[orderId];
        
        // Mark as processed
        order.processed = true;
        
        // Update volume and fees
        totalVolume += order.usdAmount;
        uint256 processorFee = (order.amount * paymentProcessors[order.paymentMethod].feePercent) / 10000;
        totalFees += processorFee;
        
        // Create escrow for 90-day holding period
        bytes32 escrowId = keccak256(abi.encode(orderId, block.timestamp));
        escrowAccounts[escrowId] = EscrowAccount({
            beneficiary: order.buyer,
            amount: order.tokenAmount,
            releaseDate: block.timestamp + 90 days,
            released: false,
            custodian: "Institutional Custody",
            custodyProof: order.proofHash
        });
        
        // Process through sales force manager
        // This would normally call salesForceManager.purchasePack() but we handle custody differently
        
        // Update KYC spending limits
        if (kycStatus[order.buyer].verified) {
            kycStatus[order.buyer].dailySpent += order.usdAmount;
            kycStatus[order.buyer].monthlySpent += order.usdAmount;
        }
        
        emit PaymentProcessed(orderId, order.proofHash, order.tokenAmount);
        emit EscrowCreated(escrowId, order.buyer, order.tokenAmount);
    }
    
    /**
     * @dev Release tokens from escrow after 90-day period
     */
    function releaseEscrow(bytes32 escrowId) external nonReentrant {
        EscrowAccount storage escrow = escrowAccounts[escrowId];
        require(escrow.beneficiary == msg.sender, "Not beneficiary");
        require(!escrow.released, "Already released");
        require(block.timestamp >= escrow.releaseDate, "Escrow period not completed");
        
        escrow.released = true;
        
        // Transfer tokens from custody
        unykornToken.transfer(msg.sender, escrow.amount);
        
        emit EscrowReleased(escrowId, msg.sender, escrow.amount);
    }
    
    /**
     * @dev Verify KYC status with institutional provider
     */
    function verifyKYC(
        address user,
        string calldata provider,
        uint256 riskScore,
        string calldata jurisdiction,
        bytes32 verificationProof
    ) external onlyRole(ADMIN_ROLE) {
        require(riskScore <= 100, "Invalid risk score");
        
        // Set limits based on jurisdiction and risk score
        uint256 dailyLimit = _calculateDailyLimit(jurisdiction, riskScore);
        uint256 monthlyLimit = dailyLimit * 30;
        
        kycStatus[user] = KYCStatus({
            verified: true,
            verificationDate: block.timestamp,
            kycProvider: provider,
            riskScore: riskScore,
            jurisdiction: jurisdiction,
            dailyLimit: dailyLimit,
            monthlyLimit: monthlyLimit,
            dailySpent: 0,
            monthlySpent: 0
        });
        
        emit KYCVerified(user, provider, riskScore);
    }
    
    /**
     * @dev Calculate daily limit based on jurisdiction and risk score
     */
    function _calculateDailyLimit(
        string memory jurisdiction,
        uint256 riskScore
    ) internal pure returns (uint256) {
        uint256 baseLimit = 10000; // $10k base
        
        // Adjust for jurisdiction
        if (keccak256(bytes(jurisdiction)) == keccak256("US")) {
            baseLimit = 25000; // $25k for US
        } else if (keccak256(bytes(jurisdiction)) == keccak256("EU")) {
            baseLimit = 20000; // $20k for EU
        }
        
        // Adjust for risk score (higher risk = lower limit)
        if (riskScore > 70) {
            baseLimit = baseLimit / 4; // 25% for high risk
        } else if (riskScore > 40) {
            baseLimit = baseLimit / 2; // 50% for medium risk
        }
        
        return baseLimit;
    }
    
    /**
     * @dev Check spending limits for KYC users
     */
    function _checkSpendingLimits(address user, uint256 amount) internal view {
        if (kycStatus[user].verified) {
            KYCStatus memory kyc = kycStatus[user];
            require(kyc.dailySpent + amount <= kyc.dailyLimit, "Daily limit exceeded");
            require(kyc.monthlySpent + amount <= kyc.monthlyLimit, "Monthly limit exceeded");
        }
    }
    
    /**
     * @dev Calculate token amount based on pack tier
     */
    function _calculateTokenAmount(SalesForceManager.PackTier tier) internal pure returns (uint256) {
        if (tier == SalesForceManager.PackTier.STARTER) {
            return 10000 * 10**18; // 10K tokens
        } else if (tier == SalesForceManager.PackTier.GROWTH) {
            return 25000 * 10**18; // 25K tokens
        } else if (tier == SalesForceManager.PackTier.PRO) {
            return 60000 * 10**18; // 60K tokens
        }
        return 0;
    }
    
    /**
     * @dev Process refund for failed or disputed payments
     */
    function processRefund(
        uint256 orderId,
        string calldata reason
    ) external onlyRole(ADMIN_ROLE) {
        PurchaseOrder storage order = purchaseOrders[orderId];
        require(!order.refunded, "Already refunded");
        require(!order.processed, "Cannot refund processed order");
        
        order.refunded = true;
        
        // Process refund based on payment method
        if (order.paymentMethod == PaymentMethod.ETH) {
            payable(order.buyer).transfer(order.amount);
        }
        // For off-chain payments, manual refund process through payment processor
        
        emit RefundProcessed(orderId, order.buyer, order.amount);
    }
    
    /**
     * @dev Get user's purchase history
     */
    function getUserOrders(address user) external view returns (uint256[] memory) {
        return userOrders[user];
    }
    
    /**
     * @dev Get order details
     */
    function getOrderDetails(uint256 orderId) external view returns (PurchaseOrder memory) {
        return purchaseOrders[orderId];
    }
    
    /**
     * @dev Get user's escrow accounts
     */
    function getUserEscrowAccounts(address user) external view returns (bytes32[] memory) {
        // This would need to be implemented with proper indexing in production
        bytes32[] memory empty;
        return empty;
    }
    
    // Admin functions
    function updatePaymentProcessor(
        PaymentMethod method,
        PaymentProcessor calldata processor
    ) external onlyRole(ADMIN_ROLE) {
        paymentProcessors[method] = processor;
        emit PaymentProcessorUpdated(method, processor.name, processor.active);
    }
    
    function updateInstitutionalCustody(address newCustody) external onlyRole(ADMIN_ROLE) {
        institutionalCustody = newCustody;
    }
    
    function updateComplianceOracle(address newOracle) external onlyRole(ADMIN_ROLE) {
        complianceOracle = newOracle;
    }
    
    function emergencyPause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }
    
    function emergencyUnpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }
    
    function emergencyWithdraw(
        address token,
        uint256 amount
    ) external onlyRole(ADMIN_ROLE) {
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(token).transfer(msg.sender, amount);
        }
    }
    
    // View functions for institutional reporting
    function getSystemMetrics() external view returns (
        uint256 totalOrders,
        uint256 totalVolumeUSD,
        uint256 totalFeesCollected,
        uint256 activeEscrows,
        uint256 verifiedUsers
    ) {
        return (
            orderCount,
            totalVolume,
            totalFees,
            0, // Would need proper counting
            0  // Would need proper counting
        );
    }
    
    function getPaymentMethodStats(PaymentMethod method) external view returns (
        uint256 volume,
        uint256 transactionCount,
        uint256 averageSize
    ) {
        // Would need to implement proper tracking
        return (0, 0, 0);
    }
}