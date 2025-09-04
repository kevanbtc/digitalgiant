// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./UnykornToken.sol";
import "./SalesForceManager.sol";
import "./InstitutionalPaymentGateway.sol";

contract QRCodeOnboardingSystem is Ownable, ReentrancyGuard, Pausable {
    using ECDSA for bytes32;

    UnykornToken public unykornToken;
    SalesForceManager public salesForceManager;
    InstitutionalPaymentGateway public paymentGateway;

    struct QRCode {
        string qrId;
        address creator;
        string qrType; // "REFERRAL", "PACK_SALE", "POC_BEACON", "MERCHANT"
        uint256 creationTime;
        uint256 expirationTime;
        bool isActive;
        uint256 usageCount;
        uint256 maxUsages;
        mapping(string => string) parameters;
        string[] parameterKeys;
        bytes32 verificationHash;
    }

    struct OnboardingSession {
        string sessionId;
        address user;
        string phoneNumber;
        string email;
        string preferredName;
        address referrer;
        string qrCodeUsed;
        uint256 startTime;
        uint256 completionTime;
        bool isCompleted;
        bool smsVerified;
        bool emailVerified;
        uint256 welcomeTokens;
        string onboardingMethod; // "QR", "SMS", "EMAIL", "MANUAL"
    }

    struct SMSVerification {
        string phoneNumber;
        string verificationCode;
        uint256 expirationTime;
        bool isVerified;
        uint256 attempts;
    }

    struct ReferralReward {
        address referrer;
        address referee;
        uint256 rewardAmount;
        uint256 timestamp;
        string rewardType;
        bool isPaid;
    }

    mapping(string => QRCode) public qrCodes;
    mapping(string => OnboardingSession) public onboardingSessions;
    mapping(string => SMSVerification) public smsVerifications;
    mapping(address => string[]) public userQRCodes;
    mapping(address => string[]) public userSessions;
    mapping(string => bool) public usedPhoneNumbers;
    mapping(string => bool) public usedEmails;
    mapping(bytes32 => bool) public usedVerificationHashes;
    mapping(address => ReferralReward[]) public referralRewards;
    mapping(address => bool) public authorizedSMSProviders;

    string[] public activeQRCodes;
    string[] public activeSessions;

    uint256 public welcomeTokenAmount;
    uint256 public referralBonus;
    uint256 public qrCodeFee;
    uint256 public maxQRCodeLifetime;
    uint256 public smsVerificationTimeout;
    uint256 public maxSMSAttempts;
    string public smsApiEndpoint;
    string public emailApiEndpoint;

    event QRCodeCreated(
        string indexed qrId,
        address indexed creator,
        string qrType,
        uint256 expirationTime
    );

    event QRCodeScanned(
        string indexed qrId,
        address indexed user,
        string sessionId,
        uint256 timestamp
    );

    event OnboardingStarted(
        string indexed sessionId,
        address indexed user,
        string onboardingMethod,
        address referrer
    );

    event OnboardingCompleted(
        string indexed sessionId,
        address indexed user,
        uint256 welcomeTokens,
        address referrer
    );

    event SMSVerificationSent(
        string indexed phoneNumber,
        string sessionId,
        uint256 expirationTime
    );

    event SMSVerificationCompleted(
        string indexed phoneNumber,
        string sessionId,
        bool success
    );

    event ReferralRewardPaid(
        address indexed referrer,
        address indexed referee,
        uint256 amount,
        string rewardType
    );

    event AccessibilityModeActivated(
        address indexed user,
        string accessibilityType,
        string sessionId
    );

    modifier onlyAuthorizedSMSProvider() {
        require(authorizedSMSProviders[msg.sender] || msg.sender == owner(), "Not authorized SMS provider");
        _;
    }

    constructor(
        address _unykornToken,
        address _salesForceManager,
        address _paymentGateway,
        uint256 _welcomeTokenAmount,
        uint256 _referralBonus
    ) {
        unykornToken = UnykornToken(_unykornToken);
        salesForceManager = SalesForceManager(_salesForceManager);
        paymentGateway = InstitutionalPaymentGateway(_paymentGateway);
        welcomeTokenAmount = _welcomeTokenAmount;
        referralBonus = _referralBonus;
        qrCodeFee = 0.001 ether;
        maxQRCodeLifetime = 30 days;
        smsVerificationTimeout = 10 minutes;
        maxSMSAttempts = 3;
    }

    function createQRCode(
        string memory _qrId,
        string memory _qrType,
        uint256 _expirationTime,
        uint256 _maxUsages,
        string[] memory _parameterKeys,
        string[] memory _parameterValues
    ) external payable nonReentrant whenNotPaused returns (string memory) {
        require(msg.value >= qrCodeFee, "Insufficient QR code fee");
        require(bytes(_qrId).length > 0, "QR ID required");
        require(qrCodes[_qrId].creator == address(0), "QR ID already exists");
        require(_expirationTime <= block.timestamp + maxQRCodeLifetime, "Expiration too far");
        require(_parameterKeys.length == _parameterValues.length, "Parameter arrays mismatch");

        bytes32 verificationHash = keccak256(
            abi.encodePacked(_qrId, msg.sender, _qrType, block.timestamp)
        );
        require(!usedVerificationHashes[verificationHash], "Hash collision");
        usedVerificationHashes[verificationHash] = true;

        QRCode storage qrCode = qrCodes[_qrId];
        qrCode.qrId = _qrId;
        qrCode.creator = msg.sender;
        qrCode.qrType = _qrType;
        qrCode.creationTime = block.timestamp;
        qrCode.expirationTime = _expirationTime;
        qrCode.isActive = true;
        qrCode.usageCount = 0;
        qrCode.maxUsages = _maxUsages;
        qrCode.parameterKeys = _parameterKeys;
        qrCode.verificationHash = verificationHash;

        for (uint256 i = 0; i < _parameterKeys.length; i++) {
            qrCode.parameters[_parameterKeys[i]] = _parameterValues[i];
        }

        userQRCodes[msg.sender].push(_qrId);
        activeQRCodes.push(_qrId);

        emit QRCodeCreated(_qrId, msg.sender, _qrType, _expirationTime);

        return _qrId;
    }

    function scanQRCode(
        string memory _qrId,
        string memory _phoneNumber,
        string memory _email,
        string memory _preferredName
    ) external nonReentrant whenNotPaused returns (string memory sessionId) {
        QRCode storage qrCode = qrCodes[_qrId];
        require(qrCode.isActive, "QR code not active");
        require(block.timestamp <= qrCode.expirationTime, "QR code expired");
        require(qrCode.usageCount < qrCode.maxUsages || qrCode.maxUsages == 0, "QR code usage limit reached");

        sessionId = _generateSessionId(_qrId, msg.sender);
        
        OnboardingSession storage session = onboardingSessions[sessionId];
        session.sessionId = sessionId;
        session.user = msg.sender;
        session.phoneNumber = _phoneNumber;
        session.email = _email;
        session.preferredName = _preferredName;
        session.referrer = qrCode.creator;
        session.qrCodeUsed = _qrId;
        session.startTime = block.timestamp;
        session.isCompleted = false;
        session.onboardingMethod = "QR";

        qrCode.usageCount++;
        userSessions[msg.sender].push(sessionId);
        activeSessions.push(sessionId);

        emit QRCodeScanned(_qrId, msg.sender, sessionId, block.timestamp);
        emit OnboardingStarted(sessionId, msg.sender, "QR", qrCode.creator);

        if (bytes(_phoneNumber).length > 0) {
            _initiateSMSVerification(_phoneNumber, sessionId);
        }

        return sessionId;
    }

    function startSMSOnboarding(
        string memory _phoneNumber,
        string memory _referralCode,
        string memory _preferredName
    ) external nonReentrant whenNotPaused returns (string memory sessionId) {
        require(bytes(_phoneNumber).length >= 10, "Valid phone number required");
        require(!usedPhoneNumbers[_phoneNumber], "Phone number already registered");

        sessionId = _generateSessionId("SMS", msg.sender);
        
        address referrer = address(0);
        if (bytes(_referralCode).length > 0) {
            referrer = _getReferrerFromCode(_referralCode);
        }

        OnboardingSession storage session = onboardingSessions[sessionId];
        session.sessionId = sessionId;
        session.user = msg.sender;
        session.phoneNumber = _phoneNumber;
        session.preferredName = _preferredName;
        session.referrer = referrer;
        session.startTime = block.timestamp;
        session.isCompleted = false;
        session.onboardingMethod = "SMS";

        userSessions[msg.sender].push(sessionId);
        activeSessions.push(sessionId);

        _initiateSMSVerification(_phoneNumber, sessionId);

        emit OnboardingStarted(sessionId, msg.sender, "SMS", referrer);
        emit AccessibilityModeActivated(msg.sender, "SMS_ONBOARDING", sessionId);

        return sessionId;
    }

    function _initiateSMSVerification(
        string memory _phoneNumber,
        string memory _sessionId
    ) private {
        string memory verificationCode = _generateVerificationCode();
        
        SMSVerification storage smsVerif = smsVerifications[_phoneNumber];
        smsVerif.phoneNumber = _phoneNumber;
        smsVerif.verificationCode = verificationCode;
        smsVerif.expirationTime = block.timestamp + smsVerificationTimeout;
        smsVerif.isVerified = false;
        smsVerif.attempts = 0;

        emit SMSVerificationSent(_phoneNumber, _sessionId, smsVerif.expirationTime);
    }

    function verifySMS(
        string memory _phoneNumber,
        string memory _verificationCode,
        string memory _sessionId
    ) external nonReentrant whenNotPaused {
        SMSVerification storage smsVerif = smsVerifications[_phoneNumber];
        OnboardingSession storage session = onboardingSessions[_sessionId];
        
        require(session.user == msg.sender, "Session user mismatch");
        require(!smsVerif.isVerified, "Already verified");
        require(smsVerif.attempts < maxSMSAttempts, "Max attempts exceeded");
        require(block.timestamp <= smsVerif.expirationTime, "Verification expired");
        require(
            keccak256(abi.encodePacked(smsVerif.verificationCode)) == 
            keccak256(abi.encodePacked(_verificationCode)),
            "Invalid verification code"
        );

        smsVerif.isVerified = true;
        session.smsVerified = true;

        emit SMSVerificationCompleted(_phoneNumber, _sessionId, true);

        if (_canCompleteOnboarding(session)) {
            _completeOnboarding(_sessionId);
        }
    }

    function completeOnboardingManually(
        string memory _sessionId,
        bool _skipVerification
    ) external nonReentrant whenNotPaused {
        OnboardingSession storage session = onboardingSessions[_sessionId];
        require(session.user == msg.sender, "Session user mismatch");
        require(!session.isCompleted, "Session already completed");

        if (!_skipVerification) {
            require(_canCompleteOnboarding(session), "Verification requirements not met");
        }

        _completeOnboarding(_sessionId);
    }

    function _completeOnboarding(string memory _sessionId) private {
        OnboardingSession storage session = onboardingSessions[_sessionId];
        
        session.isCompleted = true;
        session.completionTime = block.timestamp;
        session.welcomeTokens = welcomeTokenAmount;

        // Mark phone/email as used
        if (bytes(session.phoneNumber).length > 0) {
            usedPhoneNumbers[session.phoneNumber] = true;
        }
        if (bytes(session.email).length > 0) {
            usedEmails[session.email] = true;
        }

        // Distribute welcome tokens
        if (welcomeTokenAmount > 0) {
            unykornToken.transfer(session.user, welcomeTokenAmount);
        }

        // Process referral rewards
        if (session.referrer != address(0) && referralBonus > 0) {
            _processReferralReward(session.referrer, session.user, _sessionId);
        }

        // Register in sales force if QR code based
        if (bytes(session.qrCodeUsed).length > 0) {
            QRCode storage qrCode = qrCodes[session.qrCodeUsed];
            if (keccak256(abi.encodePacked(qrCode.qrType)) == keccak256(abi.encodePacked("REFERRAL"))) {
                salesForceManager.registerBroker(session.user, session.referrer);
            }
        }

        emit OnboardingCompleted(
            _sessionId,
            session.user,
            session.welcomeTokens,
            session.referrer
        );
    }

    function _processReferralReward(
        address _referrer,
        address _referee,
        string memory _sessionId
    ) private {
        ReferralReward memory reward = ReferralReward({
            referrer: _referrer,
            referee: _referee,
            rewardAmount: referralBonus,
            timestamp: block.timestamp,
            rewardType: "ONBOARDING_REFERRAL",
            isPaid: false
        });

        referralRewards[_referrer].push(reward);

        if (referralBonus > 0) {
            unykornToken.transfer(_referrer, referralBonus);
            referralRewards[_referrer][referralRewards[_referrer].length - 1].isPaid = true;
        }

        emit ReferralRewardPaid(_referrer, _referee, referralBonus, "ONBOARDING_REFERRAL");
    }

    function _canCompleteOnboarding(OnboardingSession memory _session) private pure returns (bool) {
        if (bytes(_session.onboardingMethod).length == 0) return false;
        
        if (keccak256(abi.encodePacked(_session.onboardingMethod)) == keccak256(abi.encodePacked("SMS"))) {
            return _session.smsVerified;
        }
        
        return true; // QR codes and other methods can complete without additional verification
    }

    function _generateSessionId(string memory _prefix, address _user) private view returns (string memory) {
        bytes32 hash = keccak256(abi.encodePacked(_prefix, _user, block.timestamp, block.difficulty));
        return string(abi.encodePacked(_prefix, "_", _toHexString(uint256(hash))));
    }

    function _generateVerificationCode() private view returns (string memory) {
        uint256 code = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 1000000;
        return _padNumber(code, 6);
    }

    function _getReferrerFromCode(string memory _referralCode) private view returns (address) {
        // This would lookup referral code in a mapping
        // For now, return zero address
        return address(0);
    }

    function _toHexString(uint256 value) private pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(8); // First 8 characters
        for (uint256 i = 0; i < 4; i++) {
            str[i * 2] = alphabet[uint8(value >> (4 * (7 - i))) & 0xf];
            str[i * 2 + 1] = alphabet[uint8(value >> (4 * (6 - i))) & 0xf];
        }
        return string(str);
    }

    function _padNumber(uint256 _number, uint256 _digits) private pure returns (string memory) {
        bytes memory result = new bytes(_digits);
        for (uint256 i = _digits; i > 0; i--) {
            result[i - 1] = bytes1(uint8(48 + (_number % 10)));
            _number /= 10;
        }
        return string(result);
    }

    function createAccessibleQRCode(
        string memory _description,
        string memory _audioDescription,
        uint256 _fontSize,
        string memory _contrastMode
    ) external payable returns (string memory qrId) {
        qrId = string(abi.encodePacked("ACCESSIBLE_", _toHexString(uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp))))));
        
        string[] memory keys = new string[](4);
        string[] memory values = new string[](4);
        
        keys[0] = "description";
        values[0] = _description;
        keys[1] = "audioDescription";
        values[1] = _audioDescription;
        keys[2] = "fontSize";
        values[2] = _uint256ToString(_fontSize);
        keys[3] = "contrastMode";
        values[3] = _contrastMode;

        createQRCode(
            qrId,
            "ACCESSIBLE_REFERRAL",
            block.timestamp + 30 days,
            0, // unlimited usage
            keys,
            values
        );

        emit AccessibilityModeActivated(msg.sender, "QR_ACCESSIBLE", qrId);
        
        return qrId;
    }

    function sendSMSToUser(
        string memory _phoneNumber,
        string memory _message,
        string memory _sessionId
    ) external onlyAuthorizedSMSProvider {
        // This would integrate with external SMS API
        // For now, just emit event
        emit SMSVerificationSent(_phoneNumber, _sessionId, block.timestamp + smsVerificationTimeout);
    }

    function getQRCodeParameters(string memory _qrId) external view returns (
        string[] memory keys,
        string[] memory values
    ) {
        QRCode storage qrCode = qrCodes[_qrId];
        keys = qrCode.parameterKeys;
        values = new string[](keys.length);
        
        for (uint256 i = 0; i < keys.length; i++) {
            values[i] = qrCode.parameters[keys[i]];
        }
        
        return (keys, values);
    }

    function getUserQRCodes(address _user) external view returns (string[] memory) {
        return userQRCodes[_user];
    }

    function getUserSessions(address _user) external view returns (string[] memory) {
        return userSessions[_user];
    }

    function getActiveQRCodes() external view returns (string[] memory) {
        return activeQRCodes;
    }

    function getReferralRewards(address _referrer) external view returns (ReferralReward[] memory) {
        return referralRewards[_referrer];
    }

    function _uint256ToString(uint256 _value) private pure returns (string memory) {
        if (_value == 0) return "0";
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        return string(buffer);
    }

    function setAuthorizedSMSProvider(address _provider, bool _authorized) external onlyOwner {
        authorizedSMSProviders[_provider] = _authorized;
    }

    function updateSettings(
        uint256 _welcomeTokenAmount,
        uint256 _referralBonus,
        uint256 _qrCodeFee,
        uint256 _maxQRCodeLifetime
    ) external onlyOwner {
        welcomeTokenAmount = _welcomeTokenAmount;
        referralBonus = _referralBonus;
        qrCodeFee = _qrCodeFee;
        maxQRCodeLifetime = _maxQRCodeLifetime;
    }

    function setAPIEndpoints(
        string memory _smsApiEndpoint,
        string memory _emailApiEndpoint
    ) external onlyOwner {
        smsApiEndpoint = _smsApiEndpoint;
        emailApiEndpoint = _emailApiEndpoint;
    }

    function deactivateQRCode(string memory _qrId) external {
        QRCode storage qrCode = qrCodes[_qrId];
        require(qrCode.creator == msg.sender || msg.sender == owner(), "Not authorized");
        qrCode.isActive = false;
    }

    function emergencyPause() external onlyOwner {
        _pause();
    }

    function resume() external onlyOwner {
        _unpause();
    }

    receive() external payable {}

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}