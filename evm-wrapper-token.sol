// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title MultiAssetWrapperToken
 * @notice A wrapper token backed by multiple ERC20 tokens in specified proportions
 */
contract MultiAssetWrapperToken is ERC20, Ownable, ReentrancyGuard, Pausable {
    struct Asset {
        IERC20 token;        // Token contract address
        uint256 percentage;  // Percentage in basis points (100% = 10000)
        bool isActive;      // Whether this asset is active
    }

    // Asset configuration
    Asset[] public assets;
    uint256 public constant BASIS_POINTS = 10000;
    
    // Events
    event AssetAdded(address indexed token, uint256 percentage);
    event AssetRemoved(address indexed token);
    event Minted(address indexed user, uint256 amount);
    event Burned(address indexed user, uint256 amount);

    // Errors
    error InvalidPercentage();
    error InvalidAssetCount();
    error AssetAlreadyExists();
    error AssetNotFound();
    error InvalidDistribution();
    error InsufficientAllowance();
    error InsufficientBalance();
    error TransferFailed();

    /**
     * @dev Constructor
     * @param name Token name
     * @param symbol Token symbol
     */
    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {}

    /**
     * @notice Configure initial asset distribution
     * @param _tokens Array of token addresses
     * @param _percentages Array of percentages in basis points
     */
    function configureAssets(
        address[] calldata _tokens,
        uint256[] calldata _percentages
    ) external onlyOwner {
        if (_tokens.length != _percentages.length) revert InvalidAssetCount();
        
        // Clear existing assets
        delete assets;
        
        uint256 totalPercentage;
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            totalPercentage += _percentages[i];
            
            assets.push(Asset({
                token: IERC20(_tokens[i]),
                percentage: _percentages[i],
                isActive: true
            }));
            
            emit AssetAdded(_tokens[i], _percentages[i]);
        }
        
        if (totalPercentage != BASIS_POINTS) revert InvalidDistribution();
    }

    /**
     * @notice Mint wrapper tokens by depositing underlying assets
     * @param amount Amount of wrapper tokens to mint
     */
    function mint(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert InvalidDistribution();
        
        // Transfer underlying assets from user
        for (uint256 i = 0; i < assets.length; i++) {
            if (!assets[i].isActive) continue;
            
            uint256 assetAmount = (amount * assets[i].percentage) / BASIS_POINTS;
            
            // Check allowance
            if (assets[i].token.allowance(msg.sender, address(this)) < assetAmount) {
                revert InsufficientAllowance();
            }
            
            // Transfer tokens to this contract
            bool success = assets[i].token.transferFrom(msg.sender, address(this), assetAmount);
            if (!success) revert TransferFailed();
        }
        
        // Mint wrapper tokens
        _mint(msg.sender, amount);
        
        emit Minted(msg.sender, amount);
    }

    /**
     * @notice Burn wrapper tokens to receive underlying assets
     * @param amount Amount of wrapper tokens to burn
     */
    function burn(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert InvalidDistribution();
        if (balanceOf(msg.sender) < amount) revert InsufficientBalance();
        
        // Burn wrapper tokens first (checks balance)
        _burn(msg.sender, amount);
        
        // Transfer underlying assets back to user
        for (uint256 i = 0; i < assets.length; i++) {
            if (!assets[i].isActive) continue;
            
            uint256 assetAmount = (amount * assets[i].percentage) / BASIS_POINTS;
            
            bool success = assets[i].token.transfer(msg.sender, assetAmount);
            if (!success) revert TransferFailed();
        }
        
        emit Burned(msg.sender, amount);
    }

    /**
     * @notice Get all active assets and their percentages
     * @return tokens Array of token addresses
     * @return percentages Array of percentages
     */
    function getAssets() external view returns (
        address[] memory tokens,
        uint256[] memory percentages
    ) {
        uint256 activeCount;
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].isActive) activeCount++;
        }
        
        tokens = new address[](activeCount);
        percentages = new uint256[](activeCount);
        
        uint256 j;
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].isActive) {
                tokens[j] = address(assets[i].token);
                percentages[j] = assets[i].percentage;
                j++;
            }
        }
    }

    /**
     * @notice Calculate amounts of underlying assets needed for minting
     * @param amount Amount of wrapper tokens
     * @return tokens Array of token addresses
     * @return amounts Array of token amounts needed
     */
    function calculateMintAmounts(uint256 amount) external view returns (
        address[] memory tokens,
        uint256[] memory amounts
    ) {
        uint256 activeCount;
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].isActive) activeCount++;
        }
        
        tokens = new address[](activeCount);
        amounts = new uint256[](activeCount);
        
        uint256 j;
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].isActive) {
                tokens[j] = address(assets[i].token);
                amounts[j] = (amount * assets[i].percentage) / BASIS_POINTS;
                j++;
            }
        }
    }

    /**
     * @notice Emergency pause
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Emergency asset recovery
     * @param token Token to recover
     */
    function recoverToken(address token) external onlyOwner {
        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        bool success = tokenContract.transfer(owner(), balance);
        if (!success) revert TransferFailed();
    }
}
