// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./TerritoryNFT.sol";
import "./RealtorMembershipSystem.sol";
import "./BrokerReferralSystem.sol";
import "./RealtorComplianceModule.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Atlanta Realtor Territory Package - Complete Market Solution
 * @dev Specialized territory package for Atlanta metropolitan real estate market
 * Includes zip code territories, MLS integration hooks, and local compliance
 */
contract AtlantaRealtorTerritory is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant TERRITORY_MANAGER_ROLE = keccak256("TERRITORY_MANAGER_ROLE");
    
    TerritoryNFT public territoryNFT;
    RealtorMembershipSystem public membershipSystem;
    BrokerReferralSystem public referralSystem;
    RealtorComplianceModule public complianceModule;
    
    struct AtlantaZipTerritory {
        uint256 territoryId;
        string zipCode;
        string neighborhoodName;
        uint256 averageHomePrice;
        uint256 annualTransactionVolume;
        uint256 competitorCount;
        bool mlsIntegrated;
        uint256 memberCount;
        uint256 monthlyRevenue;
        string mlsRegion; // "Atlanta MLS", "GAMLS", etc.
    }
    
    struct MarketData {
        uint256 timestamp;
        uint256 medianHomePrice;
        uint256 averageDaysOnMarket;
        uint256 inventoryCount;
        uint256 newListings;
        uint256 soldVolume;
        string dataSource; // "Zillow", "Realtor.com", "GAMLS"
    }
    
    // Atlanta Metro Zip Codes with High Opportunity
    mapping(string => AtlantaZipTerritory) public atlantaZipTerritories;
    mapping(uint256 => MarketData) public marketData; // territoryId -> latest market data
    mapping(string => uint256) public zipToTerritoryId;
    mapping(uint256 => string[]) public territoryNeighborhoods; // territoryId -> neighborhood list
    
    string[] public availableZipCodes;
    uint256 public totalAtlantaTerritories;
    uint256 public totalAtlantaRevenue;
    
    // Atlanta-specific pricing (in wei)
    uint256 public constant PREMIUM_TERRITORY_PRICE = 5000 * 10**18;  // $5,000 (Buckhead, Midtown)
    uint256 public constant STANDARD_TERRITORY_PRICE = 2500 * 10**18; // $2,500 (Most areas)
    uint256 public constant EMERGING_TERRITORY_PRICE = 1000 * 10**18; // $1,000 (Growth areas)
    
    event AtlantaTerritoryCreated(uint256 indexed territoryId, string zipCode, string neighborhood, uint256 price);
    event MarketDataUpdated(uint256 indexed territoryId, uint256 medianHomePrice, uint256 newListings);
    event MLSIntegrationEnabled(uint256 indexed territoryId, string mlsRegion);
    
    constructor(
        address _territoryNFT,
        address _membershipSystem,
        address _referralSystem,
        address _complianceModule
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        
        territoryNFT = TerritoryNFT(_territoryNFT);
        membershipSystem = RealtorMembershipSystem(_membershipSystem);
        referralSystem = BrokerReferralSystem(_referralSystem);
        complianceModule = RealtorComplianceModule(_complianceModule);
        
        _initializeAtlantaTerritories();
    }
    
    /**
     * @dev Initialize high-opportunity Atlanta territories
     */
    function _initializeAtlantaTerritories() internal {
        // Premium Territories - High-end markets
        _createAtlantaTerritory("30309", "Midtown Atlanta", 650000, 450, 25, true, PREMIUM_TERRITORY_PRICE, "Atlanta MLS");
        _createAtlantaTerritory("30305", "Buckhead", 850000, 380, 30, true, PREMIUM_TERRITORY_PRICE, "Atlanta MLS");
        _createAtlantaTerritory("30318", "West Midtown", 420000, 520, 20, true, PREMIUM_TERRITORY_PRICE, "Atlanta MLS");
        
        // Standard Territories - Strong markets
        _createAtlantaTerritory("30306", "Virginia Highland", 480000, 340, 18, true, STANDARD_TERRITORY_PRICE, "Atlanta MLS");
        _createAtlantaTerritory("30307", "Little Five Points", 385000, 290, 15, true, STANDARD_TERRITORY_PRICE, "Atlanta MLS");
        _createAtlantaTerritory("30312", "Downtown Atlanta", 320000, 680, 35, true, STANDARD_TERRITORY_PRICE, "Atlanta MLS");
        _createAtlantaTerritory("30324", "Brookhaven", 425000, 380, 22, true, STANDARD_TERRITORY_PRICE, "Atlanta MLS");
        _createAtlantaTerritory("30327", "Sandy Springs", 390000, 420, 28, true, STANDARD_TERRITORY_PRICE, "GAMLS");
        
        // Emerging Territories - High growth potential
        _createAtlantaTerritory("30315", "The Westside", 285000, 650, 12, false, EMERGING_TERRITORY_PRICE, "Atlanta MLS");
        _createAtlantaTerritory("30316", "East Atlanta", 245000, 580, 10, false, EMERGING_TERRITORY_PRICE, "Atlanta MLS");
        _createAtlantaTerritory("30317", "Decatur", 365000, 310, 16, true, EMERGING_TERRITORY_PRICE, "GAMLS");
        _createAtlantaTerritory("30319", "Brookhaven", 355000, 295, 14, true, EMERGING_TERRITORY_PRICE, "GAMLS");
        
        // Suburban Growth Areas
        _createAtlantaTerritory("30328", "Dunwoody", 385000, 340, 20, true, STANDARD_TERRITORY_PRICE, "GAMLS");
        _createAtlantaTerritory("30350", "Dunwoody North", 295000, 460, 18, true, EMERGING_TERRITORY_PRICE, "GAMLS");
        _createAtlantaTerritory("30092", "Norcross", 275000, 520, 15, false, EMERGING_TERRITORY_PRICE, "GAMLS");
        
        totalAtlantaTerritories = availableZipCodes.length;
    }
    
    function _createAtlantaTerritory(
        string memory zipCode,
        string memory neighborhoodName,
        uint256 averageHomePrice,
        uint256 annualTransactionVolume,
        uint256 competitorCount,
        bool mlsIntegrated,
        uint256 price,
        string memory mlsRegion
    ) internal {
        // Create territory NFT
        uint256 territoryId = territoryNFT.createTerritory(
            string(abi.encodePacked("Atlanta ", neighborhoodName, " (", zipCode, ")")),
            price,
            "Real Estate Territory - Atlanta Metro",
            address(this)
        );
        
        // Store Atlanta-specific data
        atlantaZipTerritories[zipCode] = AtlantaZipTerritory({
            territoryId: territoryId,
            zipCode: zipCode,
            neighborhoodName: neighborhoodName,
            averageHomePrice: averageHomePrice,
            annualTransactionVolume: annualTransactionVolume,
            competitorCount: competitorCount,
            mlsIntegrated: mlsIntegrated,
            memberCount: 0,
            monthlyRevenue: 0,
            mlsRegion: mlsRegion
        });
        
        zipToTerritoryId[zipCode] = territoryId;
        availableZipCodes.push(zipCode);
        
        // Add neighborhood data
        territoryNeighborhoods[territoryId].push(neighborhoodName);
        
        emit AtlantaTerritoryCreated(territoryId, zipCode, neighborhoodName, price);
        
        if (mlsIntegrated) {
            emit MLSIntegrationEnabled(territoryId, mlsRegion);
        }
    }
    
    /**
     * @dev Purchase Atlanta territory with realtor membership bundle
     */
    function purchaseAtlantaTerritoryBundle(
        string calldata zipCode,
        string calldata licenseNumber,
        RealtorMembershipSystem.MembershipTier membershipTier
    ) external payable {
        AtlantaZipTerritory storage territory = atlantaZipTerritories[zipCode];
        require(territory.territoryId != 0, "Territory not found");
        require(complianceModule.isLicensedRealtor(msg.sender), "Must be licensed realtor");
        
        uint256 territoryPrice = territoryNFT.territories(territory.territoryId).price;
        uint256 membershipPrice = membershipSystem.getMembershipFee(membershipTier);
        uint256 totalPrice = territoryPrice + membershipPrice;
        
        require(msg.value >= totalPrice, "Insufficient payment");
        
        // Purchase territory
        territoryNFT.purchaseTerritory{value: territoryPrice}(territory.territoryId);
        
        // Join membership system
        membershipSystem.joinMembership{value: membershipPrice}(
            membershipTier,
            territory.territoryId,
            licenseNumber
        );
        
        // Update territory stats
        territory.memberCount++;
        territory.monthlyRevenue += membershipPrice;
        totalAtlantaRevenue += membershipPrice;
        
        // Refund excess
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }
    
    /**
     * @dev Update market data for territory (oracle integration point)
     */
    function updateMarketData(
        uint256 territoryId,
        uint256 medianHomePrice,
        uint256 averageDaysOnMarket,
        uint256 inventoryCount,
        uint256 newListings,
        uint256 soldVolume,
        string calldata dataSource
    ) external onlyRole(ADMIN_ROLE) {
        marketData[territoryId] = MarketData({
            timestamp: block.timestamp,
            medianHomePrice: medianHomePrice,
            averageDaysOnMarket: averageDaysOnMarket,
            inventoryCount: inventoryCount,
            newListings: newListings,
            soldVolume: soldVolume,
            dataSource: dataSource
        });
        
        emit MarketDataUpdated(territoryId, medianHomePrice, newListings);
    }
    
    /**
     * @dev Get territory recommendations based on criteria
     */
    function getTerritoryRecommendations(
        uint256 maxPrice,
        uint256 minTransactionVolume,
        bool requireMLSIntegration
    ) external view returns (string[] memory recommendedZipCodes) {
        uint256 count = 0;
        
        // Count qualifying territories
        for (uint i = 0; i < availableZipCodes.length; i++) {
            string memory zip = availableZipCodes[i];
            AtlantaZipTerritory memory territory = atlantaZipTerritories[zip];
            uint256 price = territoryNFT.territories(territory.territoryId).price;
            
            if (price <= maxPrice && 
                territory.annualTransactionVolume >= minTransactionVolume &&
                (!requireMLSIntegration || territory.mlsIntegrated)) {
                count++;
            }
        }
        
        // Build recommendations array
        recommendedZipCodes = new string[](count);
        uint256 index = 0;
        
        for (uint i = 0; i < availableZipCodes.length; i++) {
            string memory zip = availableZipCodes[i];
            AtlantaZipTerritory memory territory = atlantaZipTerritories[zip];
            uint256 price = territoryNFT.territories(territory.territoryId).price;
            
            if (price <= maxPrice && 
                territory.annualTransactionVolume >= minTransactionVolume &&
                (!requireMLSIntegration || territory.mlsIntegration)) {
                recommendedZipCodes[index] = zip;
                index++;
            }
        }
    }
    
    /**
     * @dev Get complete Atlanta market overview
     */
    function getAtlantaMarketOverview() external view returns (
        uint256 totalTerritories,
        uint256 availableTerritories,
        uint256 totalRevenue,
        uint256 averageHomePrice,
        uint256 totalTransactionVolume
    ) {
        uint256 available = 0;
        uint256 totalPrice = 0;
        uint256 totalVolume = 0;
        
        for (uint i = 0; i < availableZipCodes.length; i++) {
            string memory zip = availableZipCodes[i];
            AtlantaZipTerritory memory territory = atlantaZipTerritories[zip];
            
            if (territoryNFT.ownerOf(territory.territoryId) == address(this)) {
                available++;
            }
            
            totalPrice += territory.averageHomePrice;
            totalVolume += territory.annualTransactionVolume;
        }
        
        return (
            totalAtlantaTerritories,
            available,
            totalAtlantaRevenue,
            totalAtlantaTerritories > 0 ? totalPrice / totalAtlantaTerritories : 0,
            totalVolume
        );
    }
    
    /**
     * @dev Get detailed territory information
     */
    function getTerritoryDetails(string calldata zipCode) 
        external 
        view 
        returns (
            AtlantaZipTerritory memory territory,
            MarketData memory market,
            address owner,
            bool available
        ) 
    {
        territory = atlantaZipTerritories[zipCode];
        market = marketData[territory.territoryId];
        owner = territoryNFT.ownerOf(territory.territoryId);
        available = (owner == address(this));
    }
    
    /**
     * @dev Get neighborhoods in territory
     */
    function getTerritoryNeighborhoods(uint256 territoryId) 
        external 
        view 
        returns (string[] memory) 
    {
        return territoryNeighborhoods[territoryId];
    }
    
    /**
     * @dev Check if zip code territory is available
     */
    function isZipCodeAvailable(string calldata zipCode) external view returns (bool) {
        uint256 territoryId = zipToTerritoryId[zipCode];
        if (territoryId == 0) return false;
        return territoryNFT.ownerOf(territoryId) == address(this);
    }
    
    /**
     * @dev Calculate ROI potential for territory
     */
    function calculateTerritoryROI(string calldata zipCode) 
        external 
        view 
        returns (
            uint256 territoryPrice,
            uint256 annualCommissionPotential,
            uint256 roiPercent,
            uint256 paybackMonths
        ) 
    {
        AtlantaZipTerritory memory territory = atlantaZipTerritories[zipCode];
        territoryPrice = territoryNFT.territories(territory.territoryId).price;
        
        // Assume 3% average commission, realtor gets 50% after broker split
        uint256 avgCommissionPerDeal = (territory.averageHomePrice * 300) / 10000 / 2;
        annualCommissionPotential = avgCommissionPerDeal * territory.annualTransactionVolume;
        
        if (territoryPrice > 0) {
            roiPercent = (annualCommissionPotential * 100) / territoryPrice;
            paybackMonths = territoryPrice > 0 ? (territoryPrice * 12) / annualCommissionPotential : 0;
        }
    }
    
    // Admin functions
    function addNewTerritory(
        string calldata zipCode,
        string calldata neighborhoodName,
        uint256 averageHomePrice,
        uint256 annualTransactionVolume,
        uint256 competitorCount,
        uint256 price,
        string calldata mlsRegion
    ) external onlyRole(ADMIN_ROLE) {
        _createAtlantaTerritory(
            zipCode,
            neighborhoodName,
            averageHomePrice,
            annualTransactionVolume,
            competitorCount,
            false, // MLS integration starts disabled
            price,
            mlsRegion
        );
    }
    
    function enableMLSIntegration(string calldata zipCode) external onlyRole(ADMIN_ROLE) {
        atlantaZipTerritories[zipCode].mlsIntegrated = true;
        uint256 territoryId = zipToTerritoryId[zipCode];
        emit MLSIntegrationEnabled(territoryId, atlantaZipTerritories[zipCode].mlsRegion);
    }
    
    function updateTerritoryPricing(string calldata zipCode, uint256 newPrice) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        uint256 territoryId = zipToTerritoryId[zipCode];
        territoryNFT.updateTerritoryPrice(territoryId, newPrice);
    }
    
    // View functions
    function getAllAvailableZipCodes() external view returns (string[] memory) {
        return availableZipCodes;
    }
    
    function getTerritoryIdByZip(string calldata zipCode) external view returns (uint256) {
        return zipToTerritoryId[zipCode];
    }
}