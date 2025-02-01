const { ethers } = require("hardhat");

async function main() {
  console.log("Starting deployment...");

  // Deploy the wrapper token
  const WrapperToken = await ethers.getContractFactory("PricedMultiAssetWrapper");
  const wrapperToken = await WrapperToken.deploy(
    "Multi-Asset Wrapper",  // name
    "MAW"                   // symbol
  );
  await wrapperToken.deployed();
  console.log("WrapperToken deployed to:", wrapperToken.address);

  // Example configuration (for testnet)
  const testConfig = {
    assets: [
      { 
        token: "0x...", // USDC address
        percentage: 4000,  // 40%
        priceFeed: "0x..." // Chainlink USDC/USD feed
      },
      { 
        token: "0x...", // WETH address
        percentage: 3500,  // 35%
        priceFeed: "0x..." // Chainlink ETH/USD feed
      },
      { 
        token: "0x...", // WBTC address
        percentage: 2500,  // 25%
        priceFeed: "0x..." // Chainlink BTC/USD feed
      }
    ]
  };

  // Configure assets
  const tokens = testConfig.assets.map(a => a.token);
  const percentages = testConfig.assets.map(a => a.percentage);
  
  console.log("Configuring assets...");
  await wrapperToken.configureAssets(tokens, percentages);

  // Configure price feeds
  console.log("Configuring price feeds...");
  for (const asset of testConfig.assets) {
    await wrapperToken.configurePriceFeed(
      asset.token,
      asset.priceFeed
    );
  }

  console.log("Deployment and configuration complete!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
