/**
 * @title MultiAssetWrapperToken
 * @dev A wrapper token backed by multiple ERC20 tokens in specified proportions.
 *
 * ## Features:
 * - Allows minting of wrapper tokens by depositing underlying assets in predefined proportions.
 * - Supports burning wrapper tokens to redeem underlying assets.
 * - Uses SafeERC20 for secure token transfers.
 * - Includes pausable and reentrancy guard mechanisms for security.
 * - Allows emergency token recovery by the owner.
 *
 * ## Usage:
 * - The owner configures the asset composition using `configureAssets()`.
 * - Users can mint tokens by calling `mint(amount)` with the required deposits.
 * - Users can burn tokens by calling `burn(amount)` to receive underlying assets.
 * - The owner can pause and unpause the contract as needed.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title MultiAssetWrapperToken
 * @notice A wrapper token backed by multiple ERC20 tokens in specified proportions
 */
contract MultiAssetWrapperToken is ERC20, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    struct Asset {
        IERC20 token;        // Token contract address
        uint16 percentage;   // Percentage in basis points (100% = 10000)
        bool isActive;       // Whether this asset is active
    }

    // Asset configuration
    Asset[] public assets;
    uint256 public constant BASIS_POINTS = 10000;
    
    // Events
    event AssetConfigured(address[] tokens, uint256[] percentages);
    event Minted(address indexed user, uint256 amount);
    event Burned(address indexed user, uint256 amount);

    // Errors
    error InvalidPercentage();
    error InvalidAssetCount();
    error InvalidDistribution();
    error InsufficientAllowance();
    error InsufficientBalance();
    error TransferFailed();
    error NoAssetsConfigured();

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
     * @dev Can only be called by the owner. Ensures total distribution is 100%.
     * @param _tokens Array of token addresses
     * @param _percentages Array of percentages in basis points
     */
    function configureAssets(
        address[] calldata _tokens,
        uint16[] calldata _percentages
    ) external onlyOwner {
        if (_tokens.length != _percentages.length) revert InvalidAssetCount();
        
        uint256 totalPercentage;
        Asset[] memory newAssets = new Asset[](_tokens.length);
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            totalPercentage += _percentages[i];
            newAssets[i] = Asset({
                token: IERC20(_tokens[i]),
                percentage: _percentages[i],
                isActive: true
            });
        }
        
        if (totalPercentage != BASIS_POINTS) revert InvalidDistribution();
        
        // Replace existing assets only after validation
        delete assets;
        for (uint256 i = 0; i < _tokens.length; i++) {
            assets.push(newAssets[i]);
        }
        
        emit AssetConfigured(_tokens, _percentages);
    }

    /**
     * @notice Mint wrapper tokens by depositing underlying assets
     * @param amount Amount of wrapper tokens to mint
     * @dev Requires sufficient token allowance for each asset.
     */
    function mint(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0 || assets.length == 0) revert InvalidDistribution();
        
        uint256 length = assets.length;
        for (uint256 i = 0; i < length; i++) {
            Asset storage asset = assets[i];
            if (!asset.isActive) continue;
            
            uint256 assetAmount = (amount * asset.percentage) / BASIS_POINTS;
            if (asset.token.allowance(msg.sender, address(this)) < assetAmount) revert InsufficientAllowance();
            asset.token.safeTransferFrom(msg.sender, address(this), assetAmount);
        }
        
        _mint(msg.sender, amount);
        emit Minted(msg.sender, amount);
    }

    /**
     * @notice Burn wrapper tokens to receive underlying assets
     * @param amount Amount of wrapper tokens to burn
     * @dev Fails if no assets are configured or if user has insufficient balance.
     */
    function burn(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0 || balanceOf(msg.sender) < amount) revert InsufficientBalance();
        if (assets.length == 0) revert NoAssetsConfigured();
        
        _burn(msg.sender, amount);
        
        uint256 length = assets.length;
        for (uint256 i = 0; i < length; i++) {
            Asset storage asset = assets[i];
            if (!asset.isActive) continue;
            
            uint256 assetAmount = (amount * asset.percentage) / BASIS_POINTS;
            asset.token.safeTransfer(msg.sender, assetAmount);
        }
        
        emit Burned(msg.sender, amount);
    }

    /**
     * @notice Emergency asset recovery
     * @param token Token to recover
     * @dev Can only be called by the contract owner.
     */
    function recoverToken(address token) external onlyOwner {
        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.safeTransfer(owner(), balance);
    }
}
