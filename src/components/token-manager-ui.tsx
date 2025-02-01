import React, { useState } from 'react';
import { LineChart, Line, CartesianGrid, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';
import { Wallet, Search, ArrowUpRight, ArrowDownRight, Filter, Settings, RefreshCw } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

const TokenManagerDashboard = () => {
  const [state, setState] = useState({
    connected: false,
    account: '',
    searchQuery: '',
    selectedToken: null,
  });

  const [tokens] = useState([
    {
      id: '1',
      name: 'Tesla Stock Token',
      symbol: 'wTSLA',
      stockPrice: 238.45,
      tvl: 12345678,
      assets: [{
        name: 'TSLA',
        percentage: 100,
        lastPrice: 238.45,
        change: 2.5,
        marketCap: '756.8B',
        volume: '15.2B'
      }],
      priceChange: 2.5,
      volume24h: 3456789,
      holders: 1234
    },
    {
      id: '2',
      name: 'Apple Stock Token',
      symbol: 'wAAPL',
      stockPrice: 185.92,
      tvl: 23456789,
      assets: [{
        name: 'AAPL',
        percentage: 100,
        lastPrice: 185.92,
        change: -0.8,
        marketCap: '2.89T',
        volume: '20.1B'
      }],
      priceChange: -0.8,
      volume24h: 4567890,
      holders: 2345
    },
    {
      id: '3',
      name: 'Tech Giants Token',
      symbol: 'wTECH',
      stockPrice: 156.78,
      tvl: 34567890,
      assets: [
        { name: 'AAPL', percentage: 40, lastPrice: 185.92, change: -0.8 },
        { name: 'TSLA', percentage: 35, lastPrice: 238.45, change: 2.5 },
        { name: 'MSFT', percentage: 25, lastPrice: 402.12, change: 1.2 }
      ],
      priceChange: 1.2,
      volume24h: 5678901,
      holders: 3456
    }
  ]);

  const connectWallet = async () => {
    if (typeof window.ethereum === 'undefined') {
      alert('Please install MetaMask to use this application');
      return;
    }

    try {
      const accounts = await window.ethereum.request({
        method: 'eth_requestAccounts'
      });
      
      if (accounts.length > 0) {
        setState(prev => ({
          ...prev,
          connected: true,
          account: accounts[0]
        }));

        // Setup wallet event listeners
        window.ethereum.on('accountsChanged', handleAccountsChanged);
        window.ethereum.on('chainChanged', handleChainChanged);
      }
    } catch (error) {
      console.error('Error connecting wallet:', error);
    }
  };

  const handleAccountsChanged = (accounts) => {
    if (accounts.length === 0) {
      setState(prev => ({
        ...prev,
        connected: false,
        account: ''
      }));
    } else {
      setState(prev => ({
        ...prev,
        account: accounts[0]
      }));
    }
  };

  const handleChainChanged = () => {
    window.location.reload();
  };

  const handleMint = (tokenSymbol) => {
    if (!state.connected) {
      alert('Please connect your wallet first');
      return;
    }
    console.log(`Minting ${tokenSymbol}`);
  };

  const handleBurn = (tokenSymbol) => {
    if (!state.connected) {
      alert('Please connect your wallet first');
      return;
    }
    console.log(`Burning ${tokenSymbol}`);
  };

  const handleSearch = (e) => {
    setState(prev => ({
      ...prev,
      searchQuery: e.target.value
    }));
  };

  React.useEffect(() => {
    return () => {
      if (window.ethereum) {
        window.ethereum.removeListener('accountsChanged', handleAccountsChanged);
        window.ethereum.removeListener('chainChanged', handleChainChanged);
      }
    };
  }, []);

  return (
    <div className="min-h-screen bg-white text-gray-900 p-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex justify-between items-center mb-6">
          <div className="flex items-center space-x-4">
            <img 
              src="/api/placeholder/200/50" 
              alt="Auroca" 
              className="h-12 object-contain"
            />
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Stock Wrapper Manager</h1>
              <p className="text-gray-500">Manage your wrapped stock tokens</p>
            </div>
          </div>
          
          {!state.connected ? (
            <button
              onClick={connectWallet}
              className="px-6 py-3 bg-blue-500 hover:bg-blue-600 text-white rounded-lg flex items-center space-x-3 transition-all duration-200 shadow-sm"
            >
              <Wallet className="h-5 w-5" />
              <span>Connect Wallet</span>
            </button>
          ) : (
            <div className="flex items-center space-x-4 bg-white px-6 py-3 rounded-lg shadow-sm border border-gray-200">
              <span className="text-sm text-gray-600">{state.account.slice(0, 6)}...{state.account.slice(-4)}</span>
              <div className="h-2 w-2 rounded-full bg-green-500"></div>
            </div>
          )}
        </div>

        {/* Search and Filters */}
        <div className="flex items-center justify-between mt-8">
          <div className="flex items-center space-x-4 flex-1 max-w-2xl">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-5 w-5" />
              <input
                type="text"
                placeholder="Search stock tokens..."
                className="w-full pl-12 pr-4 py-3 bg-white border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent shadow-sm"
                value={state.searchQuery}
                onChange={handleSearch}
              />
            </div>
            <button className="p-3 bg-white border border-gray-200 rounded-lg hover:bg-gray-50 shadow-sm">
              <Filter className="h-5 w-5 text-gray-600" />
            </button>
            <button className="px-6 py-3 bg-blue-500 hover:bg-blue-600 text-white rounded-lg flex items-center space-x-2 shadow-sm">
              <span>Create New Wrapper</span>
            </button>
          </div>
        </div>
      </div>

      {/* Token Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {tokens
          .filter(token => 
            state.searchQuery 
              ? token.name.toLowerCase().includes(state.searchQuery.toLowerCase()) ||
                token.symbol.toLowerCase().includes(state.searchQuery.toLowerCase())
              : true
          )
          .map(token => (
          <Card key={token.id} className="bg-white border border-gray-200 shadow-sm hover:shadow-md transition-all duration-200">
            <CardHeader className="flex flex-row items-center justify-between border-b border-gray-100 bg-gray-50">
              <CardTitle className="text-xl font-bold text-gray-900">{token.name}</CardTitle>
              <button className="p-2 hover:bg-gray-100 rounded-lg text-gray-600">
                <Settings className="h-5 w-5" />
              </button>
            </CardHeader>
            <CardContent className="p-6">
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <span className="text-gray-500">Symbol</span>
                  <span className="font-medium text-gray-900">{token.symbol}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-gray-500">Stock Price</span>
                  <span className="font-medium text-gray-900">${token.stockPrice.toFixed(2)}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-gray-500">24h Change</span>
                  <span className={`font-medium flex items-center ${
                    token.priceChange >= 0 ? 'text-green-600' : 'text-red-600'
                  }`}>
                    {token.priceChange >= 0 ? <ArrowUpRight className="h-4 w-4 mr-1" /> : <ArrowDownRight className="h-4 w-4 mr-1" />}
                    {Math.abs(token.priceChange)}%
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-gray-500">TVL</span>
                  <span className="font-medium text-gray-900">${token.tvl.toLocaleString()}</span>
                </div>

                {/* Assets Distribution */}
                <div className="mt-4">
                  <div className="text-sm text-gray-500 mb-2">Underlying Stocks</div>
                  <div className="space-y-2">
                    {token.assets.map((asset, index) => (
                      <div 
                        key={asset.name}
                        className="flex justify-between items-center p-3 bg-gray-50 rounded-lg"
                      >
                        <div>
                          <div className="font-medium text-gray-900">{asset.name}</div>
                          <div className="text-sm text-gray-500">{asset.percentage}%</div>
                        </div>
                        <div className="text-right">
                          <div className="font-medium text-gray-900">${asset.lastPrice}</div>
                          <div className={`text-sm ${asset.change >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                            {asset.change >= 0 ? '+' : ''}{asset.change}%
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Action Buttons */}
                <div className="grid grid-cols-2 gap-4 mt-6">
                  <button 
                    onClick={() => handleMint(token.symbol)}
                    className="py-2 px-4 bg-blue-500 hover:bg-blue-600 text-white rounded-lg shadow-sm transition-colors duration-200"
                  >
                    Mint
                  </button>
                  <button 
                    onClick={() => handleBurn(token.symbol)}
                    className="py-2 px-4 bg-red-500 hover:bg-red-600 text-white rounded-lg shadow-sm transition-colors duration-200"
                  >
                    Burn
                  </button>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
};

export default TokenManagerDashboard;
