// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract NFTTimestampSystem is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    Counters.Counter private _tokenIdCounter;

    struct TimestampRecord {
        uint256 tokenId;
        address user;
        string recordType; // "POI", "POC", "TRADEMARK", "DOCUMENT"
        string ipfsHash;
        uint256 timestamp;
        string location; // GPS coordinates or description
        bytes32 verificationHash;
        address verifier;
        bool isVerified;
        mapping(string => string) metadata;
        string[] metadataKeys;
    }

    struct POCRecord {
        address user;
        string beaconId;
        int256 latitude;
        int256 longitude;
        uint256 timestamp;
        uint256 streakCount;
        uint256 rewardAmount;
        bool isValidated;
        string ipfsProof;
    }

    struct POIRecord {
        address introducer;
        address introduced;
        string introducedName;
        string introducedContact;
        uint256 timestamp;
        uint256 commissionEarned;
        bool isVerified;
        string ipfsData;
    }

    struct TrademarkRecord {
        string trademarkName;
        address owner;
        string ipfsDocuments;
        uint256 filingTimestamp;
        uint256 approvalTimestamp;
        string jurisdiction;
        string classificationCodes;
        bool isApproved;
        uint256 renewalDate;
    }

    mapping(uint256 => TimestampRecord) public timestampRecords;
    mapping(address => uint256[]) public userTimestamps;
    mapping(string => uint256[]) public recordsByType;
    mapping(string => bool) public usedIPFSHashes;
    mapping(bytes32 => bool) public usedVerificationHashes;
    mapping(address => POCRecord[]) public pocRecords;
    mapping(address => POIRecord[]) public poiRecords;
    mapping(string => TrademarkRecord) public trademarkRecords;
    mapping(address => bool) public authorizedVerifiers;
    mapping(string => address) public beaconOwners;
    mapping(address => uint256) public userPOCStreaks;
    mapping(address => uint256) public lastPOCTimestamp;

    string public ipfsGateway;
    uint256 public verificationReward;
    uint256 public pocBaseReward;
    uint256 public poiBaseReward;
    uint256 public streakMultiplier;
    uint256 public constant MAX_STREAK_MULTIPLIER = 500; // 5x max
    uint256 public constant POC_COOLDOWN = 24 hours;

    event TimestampCreated(
        uint256 indexed tokenId,
        address indexed user,
        string recordType,
        string ipfsHash,
        uint256 timestamp
    );

    event POCRecorded(
        address indexed user,
        string beaconId,
        int256 latitude,
        int256 longitude,
        uint256 streakCount,
        uint256 reward
    );

    event POIRecorded(
        address indexed introducer,
        address indexed introduced,
        string introducedName,
        uint256 commission
    );

    event TrademarkFiled(
        string indexed trademarkName,
        address indexed owner,
        string ipfsDocuments,
        string jurisdiction
    );

    event VerificationCompleted(
        uint256 indexed tokenId,
        address indexed verifier,
        bool isVerified
    );

    event IPFSHashStored(string indexed ipfsHash, uint256 indexed tokenId);

    modifier onlyAuthorizedVerifier() {
        require(authorizedVerifiers[msg.sender] || msg.sender == owner(), "Not authorized verifier");
        _;
    }

    constructor(
        string memory _ipfsGateway,
        uint256 _verificationReward,
        uint256 _pocBaseReward,
        uint256 _poiBaseReward
    ) ERC721("UnykornTimestamp", "UNYTM") {
        ipfsGateway = _ipfsGateway;
        verificationReward = _verificationReward;
        pocBaseReward = _pocBaseReward;
        poiBaseReward = _poiBaseReward;
        streakMultiplier = 110; // 10% increase per streak day
        _tokenIdCounter.increment(); // Start from token ID 1
    }

    function createTimestamp(
        string memory _recordType,
        string memory _ipfsHash,
        string memory _location,
        string[] memory _metadataKeys,
        string[] memory _metadataValues
    ) external nonReentrant returns (uint256) {
        require(bytes(_ipfsHash).length > 0, "IPFS hash required");
        require(!usedIPFSHashes[_ipfsHash], "IPFS hash already used");
        require(_metadataKeys.length == _metadataValues.length, "Metadata arrays length mismatch");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        bytes32 verificationHash = keccak256(
            abi.encodePacked(msg.sender, _recordType, _ipfsHash, block.timestamp, tokenId)
        );
        
        require(!usedVerificationHashes[verificationHash], "Verification hash collision");
        usedVerificationHashes[verificationHash] = true;

        _safeMint(msg.sender, tokenId);

        TimestampRecord storage record = timestampRecords[tokenId];
        record.tokenId = tokenId;
        record.user = msg.sender;
        record.recordType = _recordType;
        record.ipfsHash = _ipfsHash;
        record.timestamp = block.timestamp;
        record.location = _location;
        record.verificationHash = verificationHash;
        record.verifier = address(0);
        record.isVerified = false;
        record.metadataKeys = _metadataKeys;

        for (uint256 i = 0; i < _metadataKeys.length; i++) {
            record.metadata[_metadataKeys[i]] = _metadataValues[i];
        }

        usedIPFSHashes[_ipfsHash] = true;
        userTimestamps[msg.sender].push(tokenId);
        recordsByType[_recordType].push(tokenId);

        string memory tokenURI = _generateTokenURI(tokenId, record);
        _setTokenURI(tokenId, tokenURI);

        emit TimestampCreated(tokenId, msg.sender, _recordType, _ipfsHash, block.timestamp);
        emit IPFSHashStored(_ipfsHash, tokenId);

        return tokenId;
    }

    function recordPOC(
        string memory _beaconId,
        int256 _latitude,
        int256 _longitude,
        string memory _ipfsProof,
        bytes memory _signature
    ) external nonReentrant returns (uint256) {
        require(beaconOwners[_beaconId] != address(0), "Beacon not registered");
        require(
            block.timestamp >= lastPOCTimestamp[msg.sender] + POC_COOLDOWN,
            "POC cooldown not met"
        );

        bytes32 messageHash = keccak256(
            abi.encodePacked(msg.sender, _beaconId, _latitude, _longitude, block.timestamp)
        );
        address signer = messageHash.toEthSignedMessageHash().recover(_signature);
        require(authorizedVerifiers[signer], "Invalid signature");

        uint256 currentStreak = _calculatePOCStreak(msg.sender);
        uint256 rewardAmount = _calculatePOCReward(currentStreak);

        POCRecord memory pocRecord = POCRecord({
            user: msg.sender,
            beaconId: _beaconId,
            latitude: _latitude,
            longitude: _longitude,
            timestamp: block.timestamp,
            streakCount: currentStreak,
            rewardAmount: rewardAmount,
            isValidated: true,
            ipfsProof: _ipfsProof
        });

        pocRecords[msg.sender].push(pocRecord);
        userPOCStreaks[msg.sender] = currentStreak;
        lastPOCTimestamp[msg.sender] = block.timestamp;

        uint256 tokenId = createTimestamp(
            "POC",
            _ipfsProof,
            _formatCoordinates(_latitude, _longitude),
            _getPOCMetadataKeys(),
            _getPOCMetadataValues(pocRecord)
        );

        emit POCRecorded(msg.sender, _beaconId, _latitude, _longitude, currentStreak, rewardAmount);

        return tokenId;
    }

    function recordPOI(
        address _introduced,
        string memory _introducedName,
        string memory _introducedContact,
        string memory _ipfsData,
        uint256 _commissionEarned
    ) external nonReentrant returns (uint256) {
        require(_introduced != address(0), "Invalid introduced address");
        require(_introduced != msg.sender, "Cannot introduce yourself");
        require(bytes(_introducedName).length > 0, "Name required");

        POIRecord memory poiRecord = POIRecord({
            introducer: msg.sender,
            introduced: _introduced,
            introducedName: _introducedName,
            introducedContact: _introducedContact,
            timestamp: block.timestamp,
            commissionEarned: _commissionEarned,
            isVerified: false,
            ipfsData: _ipfsData
        });

        poiRecords[msg.sender].push(poiRecord);

        uint256 tokenId = createTimestamp(
            "POI",
            _ipfsData,
            "Introduction Record",
            _getPOIMetadataKeys(),
            _getPOIMetadataValues(poiRecord)
        );

        emit POIRecorded(msg.sender, _introduced, _introducedName, _commissionEarned);

        return tokenId;
    }

    function fileTrademark(
        string memory _trademarkName,
        string memory _ipfsDocuments,
        string memory _jurisdiction,
        string memory _classificationCodes
    ) external nonReentrant returns (uint256) {
        require(bytes(_trademarkName).length > 0, "Trademark name required");
        require(trademarkRecords[_trademarkName].owner == address(0), "Trademark already filed");

        TrademarkRecord memory trademark = TrademarkRecord({
            trademarkName: _trademarkName,
            owner: msg.sender,
            ipfsDocuments: _ipfsDocuments,
            filingTimestamp: block.timestamp,
            approvalTimestamp: 0,
            jurisdiction: _jurisdiction,
            classificationCodes: _classificationCodes,
            isApproved: false,
            renewalDate: block.timestamp + (10 * 365 days) // 10 years
        });

        trademarkRecords[_trademarkName] = trademark;

        uint256 tokenId = createTimestamp(
            "TRADEMARK",
            _ipfsDocuments,
            _jurisdiction,
            _getTrademarkMetadataKeys(),
            _getTrademarkMetadataValues(trademark)
        );

        emit TrademarkFiled(_trademarkName, msg.sender, _ipfsDocuments, _jurisdiction);

        return tokenId;
    }

    function verifyTimestamp(
        uint256 _tokenId,
        bool _isVerified
    ) external onlyAuthorizedVerifier {
        require(_exists(_tokenId), "Token does not exist");
        require(!timestampRecords[_tokenId].isVerified, "Already verified");

        timestampRecords[_tokenId].isVerified = _isVerified;
        timestampRecords[_tokenId].verifier = msg.sender;

        if (_isVerified && verificationReward > 0) {
            payable(ownerOf(_tokenId)).transfer(verificationReward);
        }

        emit VerificationCompleted(_tokenId, msg.sender, _isVerified);
    }

    function registerBeacon(
        string memory _beaconId,
        address _owner
    ) external onlyOwner {
        beaconOwners[_beaconId] = _owner;
    }

    function setAuthorizedVerifier(address _verifier, bool _authorized) external onlyOwner {
        authorizedVerifiers[_verifier] = _authorized;
    }

    function _calculatePOCStreak(address _user) private view returns (uint256) {
        if (lastPOCTimestamp[_user] == 0) {
            return 1;
        }

        uint256 timeSinceLastPOC = block.timestamp - lastPOCTimestamp[_user];
        
        if (timeSinceLastPOC <= 48 hours) { // Within 48 hours maintains streak
            return userPOCStreaks[_user] + 1;
        } else {
            return 1; // Reset streak
        }
    }

    function _calculatePOCReward(uint256 _streakCount) private view returns (uint256) {
        if (_streakCount == 0) return pocBaseReward;
        
        uint256 multiplier = streakMultiplier;
        uint256 streakBonus = 100;
        
        for (uint256 i = 1; i < _streakCount && streakBonus < MAX_STREAK_MULTIPLIER; i++) {
            streakBonus = (streakBonus * multiplier) / 100;
        }
        
        return (pocBaseReward * streakBonus) / 100;
    }

    function _formatCoordinates(int256 _lat, int256 _lng) private pure returns (string memory) {
        return string(abi.encodePacked(
            _int256ToString(_lat / 1000000), ".", _uint256ToString(uint256((_lat % 1000000) >= 0 ? _lat % 1000000 : -(_lat % 1000000))),
            ",",
            _int256ToString(_lng / 1000000), ".", _uint256ToString(uint256((_lng % 1000000) >= 0 ? _lng % 1000000 : -(_lng % 1000000)))
        ));
    }

    function _getPOCMetadataKeys() private pure returns (string[] memory) {
        string[] memory keys = new string[](6);
        keys[0] = "beaconId";
        keys[1] = "coordinates";
        keys[2] = "streakCount";
        keys[3] = "rewardAmount";
        keys[4] = "timestamp";
        keys[5] = "type";
        return keys;
    }

    function _getPOCMetadataValues(POCRecord memory _record) private pure returns (string[] memory) {
        string[] memory values = new string[](6);
        values[0] = _record.beaconId;
        values[1] = _formatCoordinates(_record.latitude, _record.longitude);
        values[2] = _uint256ToString(_record.streakCount);
        values[3] = _uint256ToString(_record.rewardAmount);
        values[4] = _uint256ToString(_record.timestamp);
        values[5] = "Proof of Contact";
        return values;
    }

    function _getPOIMetadataKeys() private pure returns (string[] memory) {
        string[] memory keys = new string[](5);
        keys[0] = "introducedName";
        keys[1] = "introducedAddress";
        keys[2] = "commission";
        keys[3] = "timestamp";
        keys[4] = "type";
        return keys;
    }

    function _getPOIMetadataValues(POIRecord memory _record) private pure returns (string[] memory) {
        string[] memory values = new string[](5);
        values[0] = _record.introducedName;
        values[1] = _addressToString(_record.introduced);
        values[2] = _uint256ToString(_record.commissionEarned);
        values[3] = _uint256ToString(_record.timestamp);
        values[4] = "Proof of Introduction";
        return values;
    }

    function _getTrademarkMetadataKeys() private pure returns (string[] memory) {
        string[] memory keys = new string[](5);
        keys[0] = "trademarkName";
        keys[1] = "jurisdiction";
        keys[2] = "classificationCodes";
        keys[3] = "filingDate";
        keys[4] = "type";
        return keys;
    }

    function _getTrademarkMetadataValues(TrademarkRecord memory _record) private pure returns (string[] memory) {
        string[] memory values = new string[](5);
        values[0] = _record.trademarkName;
        values[1] = _record.jurisdiction;
        values[2] = _record.classificationCodes;
        values[3] = _uint256ToString(_record.filingTimestamp);
        values[4] = "Trademark Filing";
        return values;
    }

    function _generateTokenURI(uint256 _tokenId, TimestampRecord storage _record) private view returns (string memory) {
        string memory json = string(abi.encodePacked(
            '{"name": "Unykorn Timestamp #', _uint256ToString(_tokenId), '",',
            '"description": "Immutable timestamp record on blockchain with IPFS storage",',
            '"image": "', ipfsGateway, _record.ipfsHash, '",',
            '"external_url": "', ipfsGateway, _record.ipfsHash, '",',
            '"attributes": [',
            '{"trait_type": "Record Type", "value": "', _record.recordType, '"},',
            '{"trait_type": "Timestamp", "value": ', _uint256ToString(_record.timestamp), '},',
            '{"trait_type": "Location", "value": "', _record.location, '"},',
            '{"trait_type": "Verified", "value": ', _record.isVerified ? 'true' : 'false', '}',
            _generateMetadataAttributes(_record),
            ']}'
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));
    }

    function _generateMetadataAttributes(TimestampRecord storage _record) private view returns (string memory) {
        if (_record.metadataKeys.length == 0) return "";

        string memory attributes = "";
        for (uint256 i = 0; i < _record.metadataKeys.length; i++) {
            attributes = string(abi.encodePacked(
                attributes,
                ',{"trait_type": "', _record.metadataKeys[i], '", "value": "', _record.metadata[_record.metadataKeys[i]], '"}'
            ));
        }
        return attributes;
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

    function _int256ToString(int256 _value) private pure returns (string memory) {
        if (_value >= 0) {
            return _uint256ToString(uint256(_value));
        } else {
            return string(abi.encodePacked("-", _uint256ToString(uint256(-_value))));
        }
    }

    function _addressToString(address _addr) private pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes20 value = bytes20(_addr);
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }

    function getUserTimestamps(address _user) external view returns (uint256[] memory) {
        return userTimestamps[_user];
    }

    function getRecordsByType(string memory _recordType) external view returns (uint256[] memory) {
        return recordsByType[_recordType];
    }

    function getUserPOCRecords(address _user) external view returns (POCRecord[] memory) {
        return pocRecords[_user];
    }

    function getUserPOIRecords(address _user) external view returns (POIRecord[] memory) {
        return poiRecords[_user];
    }

    function getTimestampMetadata(uint256 _tokenId, string memory _key) external view returns (string memory) {
        return timestampRecords[_tokenId].metadata[_key];
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function setIPFSGateway(string memory _gateway) external onlyOwner {
        ipfsGateway = _gateway;
    }

    function setRewards(
        uint256 _verificationReward,
        uint256 _pocBaseReward,
        uint256 _poiBaseReward
    ) external onlyOwner {
        verificationReward = _verificationReward;
        pocBaseReward = _pocBaseReward;
        poiBaseReward = _poiBaseReward;
    }

    receive() external payable {}
    
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}