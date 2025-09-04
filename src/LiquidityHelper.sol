// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UnykornToken.sol";

/**
 * @title Liquidity Helper - Enhanced Liquidity Bootstrapping
 * @dev DEX integration with team allocation and automated liquidity seeding
 */
contract LiquidityHelper is AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant LIQUIDITY_MANAGER_ROLE = keccak256("LIQUIDITY_MANAGER_ROLE");
    
    UnykornToken public unykornToken;
    
    // DEX integration interfaces (Uniswap V2 compatible)
    interface IUniswapV2Factory {
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
    }
    
    interface IUniswapV2Router {
        function factory() external pure returns (address);
        function WETH() external pure returns (address);
        
        function addLiquidityETH(
            address token,
            uint amountTokenDesired,
            uint amountTokenMin,
            uint amountETHMin,
            address to,
            uint deadline
        ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
        
        function swapExactETHForTokens(
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external payable returns (uint[] memory amounts);
        
        function swapExactTokensForETH(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external returns (uint[] memory amounts);
    }
    
    interface IERC20Extended is IERC20 {
        function decimals() external view returns (uint8);
    }
    
    // Liquidity configuration
    struct LiquidityConfig {
        address dexRouter;
        address dexFactory;
        address weth;
        uint256 teamAllocationPercent;      // 90% community, 10% team
        uint256 vestingPeriod;              // Team vesting period
        uint256 minLiquidityETH;            // Minimum ETH for liquidity
        uint256 maxSlippage;                // Maximum slippage tolerance
        bool autoLiquidityEnabled;          // Auto-add liquidity from sales
    }
    
    // Team allocation tracking
    struct TeamMember {
        address member;
        uint256 allocation;                 // Percentage of team allocation (basis points)
        uint256 vestedAmount;               // Total vested tokens
        uint256 claimedAmount;              // Already claimed tokens
        uint256 vestingStart;               // When vesting started
        uint256 vestingDuration;            // Vesting duration
        bool active;
    }
    
    // Liquidity pool information
    struct PoolInfo {
        address pairAddress;
        uint256 tokenReserve;
        uint256 ethReserve;
        uint256 lpTokenBalance;
        uint256 lastUpdate;
    }
    
    // State variables
    LiquidityConfig public liquidityConfig;
    PoolInfo public poolInfo;
    
    mapping(address => TeamMember) public teamMembers;
    address[] public teamMemberAddresses;
    
    uint256 public totalTeamAllocation;
    uint256 public totalVestedTokens;
    uint256 public totalLiquidityAdded;
    uint256 public liquidityETHBalance;
    
    // Launch configuration
    bool public liquidityLaunched = false;
    uint256 public launchTime;
    uint256 public initialTokenPrice;       // Price in wei per token
    
    // Events
    event LiquidityAdded(uint256 tokenAmount, uint256 ethAmount, uint256 lpTokens);
    event TeamMemberAdded(address indexed member, uint256 allocation);
    event TokensVested(address indexed member, uint256 amount);
    event TokensClaimed(address indexed member, uint256 amount);
    event LiquidityLaunched(address indexed pair, uint256 tokenAmount, uint256 ethAmount);
    event AutoLiquidityTriggered(uint256 tokenAmount, uint256 ethAmount);
    
    constructor(address _unykornToken) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(LIQUIDITY_MANAGER_ROLE, msg.sender);
        
        unykornToken = UnykornToken(_unykornToken);
        
        // Initialize with default config (Uniswap V2 on mainnet)
        liquidityConfig = LiquidityConfig({
            dexRouter: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,    // Uniswap V2 Router
            dexFactory: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,   // Uniswap V2 Factory
            weth: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,        // WETH
            teamAllocationPercent: 1000,    // 10% to team
            vestingPeriod: 365 days,        // 1 year vesting
            minLiquidityETH: 1 ether,       // 1 ETH minimum
            maxSlippage: 500,               // 5% max slippage
            autoLiquidityEnabled: true
        });
    }
    
    /**
     * @dev Add team member with allocation
     */
    function addTeamMember(
        address member,
        uint256 allocation,
        uint256 vestingDuration
    ) external onlyRole(ADMIN_ROLE) {
        require(member != address(0), "Invalid address");
        require(allocation > 0, "Invalid allocation");
        require(!teamMembers[member].active, "Member already exists");
        
        teamMembers[member] = TeamMember({
            member: member,
            allocation: allocation,
            vestedAmount: 0,
            claimedAmount: 0,
            vestingStart: 0, // Set when vesting starts
            vestingDuration: vestingDuration,
            active: true
        });
        
        teamMemberAddresses.push(member);
        totalTeamAllocation += allocation;
        
        emit TeamMemberAdded(member, allocation);
    }
    
    /**
     * @dev Launch initial liquidity with 90/10 split
     */
    function launchLiquidity(
        uint256 tokenAmount,
        uint256 initialPriceWei
    ) external payable onlyRole(LIQUIDITY_MANAGER_ROLE) nonReentrant {
        require(!liquidityLaunched, "Already launched");
        require(msg.value >= liquidityConfig.minLiquidityETH, "Insufficient ETH");
        require(tokenAmount > 0, "Invalid token amount");
        
        // Calculate allocations
        uint256 communityTokens = (tokenAmount * (10000 - liquidityConfig.teamAllocationPercent)) / 10000;
        uint256 teamTokens = tokenAmount - communityTokens;
        
        // Transfer tokens to this contract
        unykornToken.transferFrom(msg.sender, address(this), tokenAmount);
        
        // Add liquidity with community allocation
        _addLiquidityETH(communityTokens, msg.value);
        
        // Distribute team tokens to vesting
        _distributeTeamTokens(teamTokens);
        
        liquidityLaunched = true;
        launchTime = block.timestamp;
        initialTokenPrice = initialPriceWei;
        liquidityETHBalance += msg.value;
        
        emit LiquidityLaunched(poolInfo.pairAddress, communityTokens, msg.value);
    }
    
    /**
     * @dev Internal function to add liquidity
     */
    function _addLiquidityETH(uint256 tokenAmount, uint256 ethAmount) internal {
        IUniswapV2Router router = IUniswapV2Router(liquidityConfig.dexRouter);
        
        // Approve tokens
        unykornToken.approve(liquidityConfig.dexRouter, tokenAmount);
        
        // Add liquidity
        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = router.addLiquidityETH{value: ethAmount}(
            address(unykornToken),
            tokenAmount,
            tokenAmount * (10000 - liquidityConfig.maxSlippage) / 10000, // Min tokens
            ethAmount * (10000 - liquidityConfig.maxSlippage) / 10000,   // Min ETH
            address(this), // LP tokens to this contract
            block.timestamp + 3600 // 1 hour deadline
        );
        
        // Update pool info
        IUniswapV2Factory factory = IUniswapV2Factory(liquidityConfig.dexFactory);
        address pairAddress = factory.getPair(address(unykornToken), liquidityConfig.weth);
        
        poolInfo = PoolInfo({
            pairAddress: pairAddress,
            tokenReserve: amountToken,
            ethReserve: amountETH,
            lpTokenBalance: liquidity,
            lastUpdate: block.timestamp
        });
        
        totalLiquidityAdded += amountToken;
        
        emit LiquidityAdded(amountToken, amountETH, liquidity);
    }
    
    /**
     * @dev Distribute team tokens to vesting schedules
     */
    function _distributeTeamTokens(uint256 totalTeamTokens) internal {
        for (uint i = 0; i < teamMemberAddresses.length; i++) {
            address member = teamMemberAddresses[i];
            TeamMember storage teamMember = teamMembers[member];
            
            if (teamMember.active && teamMember.allocation > 0) {
                uint256 memberTokens = (totalTeamTokens * teamMember.allocation) / totalTeamAllocation;
                
                teamMember.vestedAmount = memberTokens;
                teamMember.vestingStart = block.timestamp;
                
                totalVestedTokens += memberTokens;
                
                emit TokensVested(member, memberTokens);
            }
        }
    }
    
    /**
     * @dev Claim vested tokens for team member
     */
    function claimVestedTokens() external nonReentrant {
        TeamMember storage teamMember = teamMembers[msg.sender];
        require(teamMember.active, "Not a team member");
        require(teamMember.vestedAmount > 0, "No vested tokens");
        
        uint256 claimableAmount = _calculateClaimableTokens(msg.sender);
        require(claimableAmount > 0, "No tokens to claim");
        
        teamMember.claimedAmount += claimableAmount;
        unykornToken.transfer(msg.sender, claimableAmount);
        
        emit TokensClaimed(msg.sender, claimableAmount);
    }
    
    /**
     * @dev Calculate claimable tokens for team member
     */
    function _calculateClaimableTokens(address member) internal view returns (uint256) {
        TeamMember memory teamMember = teamMembers[member];
        
        if (teamMember.vestingStart == 0 || !teamMember.active) {
            return 0;
        }
        
        uint256 elapsed = block.timestamp - teamMember.vestingStart;
        if (elapsed >= teamMember.vestingDuration) {
            // Fully vested
            return teamMember.vestedAmount - teamMember.claimedAmount;
        } else {
            // Partially vested
            uint256 vestedAmount = (teamMember.vestedAmount * elapsed) / teamMember.vestingDuration;
            return vestedAmount - teamMember.claimedAmount;
        }
    }
    
    /**
     * @dev Auto-add liquidity from revenue
     */
    function autoAddLiquidity() external payable onlyRole(LIQUIDITY_MANAGER_ROLE) {
        require(liquidityLaunched, "Liquidity not launched");
        require(liquidityConfig.autoLiquidityEnabled, "Auto-liquidity disabled");
        require(msg.value > 0, "No ETH provided");
        
        // Calculate token amount based on current price
        uint256 tokenAmount = _calculateTokensForETH(msg.value);
        
        // Check if contract has enough tokens
        require(unykornToken.balanceOf(address(this)) >= tokenAmount, "Insufficient tokens");
        
        _addLiquidityETH(tokenAmount, msg.value);
        
        emit AutoLiquidityTriggered(tokenAmount, msg.value);
    }
    
    /**
     * @dev Calculate tokens needed for ETH amount based on current pool ratio
     */
    function _calculateTokensForETH(uint256 ethAmount) internal view returns (uint256) {
        if (poolInfo.ethReserve == 0 || poolInfo.tokenReserve == 0) {
            // Use initial price if no pool data
            return (ethAmount * 10**18) / initialTokenPrice;
        }
        
        // Calculate based on current pool ratio
        return (ethAmount * poolInfo.tokenReserve) / poolInfo.ethReserve;
    }
    
    /**
     * @dev Update pool information
     */
    function updatePoolInfo() external {
        require(liquidityLaunched, "Not launched");
        
        IUniswapV2Factory factory = IUniswapV2Factory(liquidityConfig.dexFactory);
        address pairAddress = factory.getPair(address(unykornToken), liquidityConfig.weth);
        require(pairAddress != address(0), "Pair not found");
        
        IERC20 pair = IERC20(pairAddress);
        uint256 tokenBalance = unykornToken.balanceOf(pairAddress);
        uint256 wethBalance = IERC20(liquidityConfig.weth).balanceOf(pairAddress);
        
        poolInfo.tokenReserve = tokenBalance;
        poolInfo.ethReserve = wethBalance;
        poolInfo.lpTokenBalance = pair.balanceOf(address(this));
        poolInfo.lastUpdate = block.timestamp;
    }
    
    /**
     * @dev Get current token price in ETH
     */
    function getCurrentTokenPrice() external view returns (uint256) {
        if (poolInfo.tokenReserve == 0 || poolInfo.ethReserve == 0) {
            return initialTokenPrice;
        }
        
        return (poolInfo.ethReserve * 10**18) / poolInfo.tokenReserve;
    }
    
    /**
     * @dev Get team member vesting info
     */
    function getTeamMemberInfo(address member) 
        external 
        view 
        returns (
            uint256 allocation,
            uint256 vestedAmount,
            uint256 claimedAmount,
            uint256 claimableAmount,
            uint256 vestingStart,
            uint256 vestingDuration,
            bool active
        ) 
    {
        TeamMember memory teamMember = teamMembers[member];
        return (
            teamMember.allocation,
            teamMember.vestedAmount,
            teamMember.claimedAmount,
            _calculateClaimableTokens(member),
            teamMember.vestingStart,
            teamMember.vestingDuration,
            teamMember.active
        );
    }
    
    /**
     * @dev Get liquidity statistics
     */
    function getLiquidityStats() 
        external 
        view 
        returns (
            bool launched,
            uint256 totalLiquidity,
            uint256 currentPrice,
            uint256 lpTokens,
            uint256 teamAllocation,
            uint256 vestedTokens
        ) 
    {
        return (
            liquidityLaunched,
            totalLiquidityAdded,
            poolInfo.ethReserve > 0 ? (poolInfo.ethReserve * 10**18) / poolInfo.tokenReserve : initialTokenPrice,
            poolInfo.lpTokenBalance,
            totalTeamAllocation,
            totalVestedTokens
        );
    }
    
    /**
     * @dev Emergency withdraw LP tokens (admin only)
     */
    function emergencyWithdrawLP(uint256 amount) external onlyRole(ADMIN_ROLE) {
        IERC20 lpToken = IERC20(poolInfo.pairAddress);
        lpToken.transfer(msg.sender, amount);
    }
    
    /**
     * @dev Update liquidity configuration
     */
    function updateLiquidityConfig(
        address dexRouter,
        address dexFactory,
        uint256 teamAllocationPercent,
        uint256 minLiquidityETH,
        bool autoLiquidityEnabled
    ) external onlyRole(ADMIN_ROLE) {
        liquidityConfig.dexRouter = dexRouter;
        liquidityConfig.dexFactory = dexFactory;
        liquidityConfig.teamAllocationPercent = teamAllocationPercent;
        liquidityConfig.minLiquidityETH = minLiquidityETH;
        liquidityConfig.autoLiquidityEnabled = autoLiquidityEnabled;
    }
    
    /**
     * @dev Remove team member
     */
    function removeTeamMember(address member) external onlyRole(ADMIN_ROLE) {
        require(teamMembers[member].active, "Member not active");
        
        TeamMember storage teamMember = teamMembers[member];
        
        // Transfer any unclaimed tokens back to admin
        uint256 unclaimedTokens = teamMember.vestedAmount - teamMember.claimedAmount;
        if (unclaimedTokens > 0) {
            unykornToken.transfer(msg.sender, unclaimedTokens);
            totalVestedTokens -= unclaimedTokens;
        }
        
        totalTeamAllocation -= teamMember.allocation;
        teamMember.active = false;
    }
    
    // Emergency functions
    function emergencyPause() external onlyRole(ADMIN_ROLE) {
        liquidityConfig.autoLiquidityEnabled = false;
    }
    
    function emergencyWithdrawETH(uint256 amount) external onlyRole(ADMIN_ROLE) {
        payable(msg.sender).transfer(amount);
    }
    
    function emergencyWithdrawTokens(uint256 amount) external onlyRole(ADMIN_ROLE) {
        unykornToken.transfer(msg.sender, amount);
    }
    
    // Receive ETH for liquidity operations
    receive() external payable {
        liquidityETHBalance += msg.value;
    }
}