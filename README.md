# Auroca Wrapper Token Interface

A web interface for managing wrapped tokens on the EVM blockchain. This interface allows users to mint, burn, and manage wrapped tokens with multiple underlying assets.

## Features

- Wallet Connection (MetaMask support)
- Token Minting
- Token Burning
- Asset Distribution Display
- Price History Tracking
- Real-time Price Updates
- Transaction Notifications

## Tech Stack

- React
- TailwindCSS
- Recharts
- Web3
- Solidity (Smart Contracts)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/auroca-wrapper.git
cd auroca-wrapper
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file and add your configuration:
```env
VITE_CONTRACT_ADDRESS=your_contract_address
VITE_CHAIN_ID=your_chain_id
```

4. Start the development server:
```bash
npm run dev
```

## Smart Contracts

The smart contracts are located in the `src/contracts` directory. Before deploying:

1. Configure your network in `hardhat.config.js`
2. Set up your deployment variables
3. Deploy using deployment script:
```bash
npx hardhat run scripts/deploy.js --network your_network
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

Your Name - [@aurocacommunity](https://x.com/aurocacommunity)
Project Link: [https://github.com/auroca-io/Asset-Referenced-Token](https://github.com/auroca-io/Asset-Referenced-Token)
