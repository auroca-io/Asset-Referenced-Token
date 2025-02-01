// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./MultiAssetWrapperToken.sol"; // Previous contract
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PricedMultiAssetWrapper is MultiAssetWrapperToken {
    // Price feed configuration
    struct PriceFeed {
        AggregatorV3Interface oracle;
        uint8 decimals;
        bool isActive;
    }

    mapping(address => PriceFeed) public priceFeeds;
    uint256 public constant PRICE_PRECISION = 1e18;
    uint256 public slippageTolerance = 100; // 1% default (basis points)

    // Events
    event PriceFeedUpdated(address indexed token, address indexed feed);
    event SlippageToleranceUpdated(uint256 newTolerance);
    event PriceCheckFailed(address indexed token, uint256 expectedPrice, uint256 actualPrice);

    // Errors
    error PriceFeedNotFound();
    error StalePrice();
    error PriceSlippageExceeded();
    error InvalidPriceFeed();

    constructor(
        string memory name,
        string memory symbol
    ) MultiAssetWrapperToken(name, symbol) {}

    /**
     * @notice Configure price feed for an asset
     */
    function configurePriceFeed(
        address token,
        address priceFeed
    ) external onlyOwner {
        if (priceFeed == address(0)) revert InvalidPriceFeed();

        AggregatorV3Interface oracle = AggregatorV3Interface(priceFeed);
        
        priceFeeds[token] = PriceFeed({
            oracle: oracle,
            decimals: oracle.decimals(),
            isActive: true
        });

        emit PriceFeedUpdated(token, priceFeed);
    }

    /**
     * @notice Set slippage tolerance
     */
    function setSlippageTolerance(uint256 _tolerance) external onlyOwner {
        if (_tolerance > BASIS_POINTS) revert InvalidPercentage();
        slippageTolerance = _tolerance;
        emit SlippageToleranceUpdated(_tolerance);
    }

    /**
     * @notice Get latest price for an asset
     */
    function getLatestPrice(address token) public view returns (uint256) {
        PriceFeed memory feed = priceFeeds[token];
        if (!feed.isActive) revert PriceFeedNotFound();

        (, int256 price,, uint256 updatedAt,) = feed.oracle.latestRoundData();
        
        // Check for stale price
        if (block.timestamp - updatedAt > 1 hours) revert StalePrice();
        if (price <= 0) revert InvalidPriceFeed();

        // Normalize price to 18 decimals
        return uint256(price) * (PRICE_PRECISION / 10 ** feed.decimals);
    }

    /**
     * @notice Get total value of basket in USD
     */
    function getTotalValue(uint256 amount) public view returns (uint256) {
        uint256 totalValue;
        
        for (uint256 i = 0; i < assets.length; i++) {
            if (!assets[i].isActive) continue;
            
            uint256 assetAmount = (amount * assets[i].percentage) / BASIS_POINTS;
            uint256 assetPrice = getLatestPrice(address(assets[i].token));
            totalValue += (assetAmount * assetPrice) / PRICE_PRECISION;
        }
        
        return totalValue;
    }

    /**
     * @notice Override mint with price checks
     */
    function mint(uint256 amount, uint256 maxValue) external nonReentrant whenNotPaused {
        uint256 totalValue = getTotalValue(amount);
        
        // Check if total value is within slippage tolerance
        uint256 maxAllowedValue = (maxValue * (BASIS_POINTS + slippageTolerance)) / BASIS_POINTS;
        if (totalValue > maxAllowedValue) revert PriceSlippageExceeded();
        
        super.mint(amount);
    }

    /**
     * @notice Override burn with price checks
     */
    function burn(uint256 amount, uint256 minValue) external nonReentrant whenNotPaused {
        uint256 totalValue = getTotalValue(amount);
        
        // Check if total value is within slippage tolerance
        uint256 minAllowedValue = (minValue * (BASIS_POINTS - slippageTolerance)) / BASIS_POINTS;
        if (totalValue < minAllowedValue) revert PriceSlippageExceeded();
        
        super.burn(amount);
    }
}
