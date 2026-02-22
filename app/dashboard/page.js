'use client';
import { useState, useEffect } from 'react';
import Link from 'next/link';

const API_URL = 'https://api.trybarakah.com';
const USER_ID = 'demo-user';

export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [assets, setAssets] = useState([]);
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('overview');

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [statsRes, assetsRes, transactionsRes] = await Promise.all([
        fetch(`${API_URL}/api/mobile/quick-stats`, {
          headers: { 'X-User-Id': USER_ID }
        }),
        fetch(`${API_URL}/api/assets/list`, {
          headers: { 'X-User-Id': USER_ID }
        }),
        fetch(`${API_URL}/api/transactions/list?limit=5`, {
          headers: { 'X-User-Id': USER_ID }
        })
      ]);

      const statsData = await statsRes.json();
      const assetsData = await assetsRes.json();
      const transactionsData = await transactionsRes.json();

      setStats(statsData);
      setAssets(assetsData.assets || []);
      setTransactions(transactionsData.transactions || []);
      setLoading(false);
    } catch (error) {
      console.error('Error loading data:', error);
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-xl text-gray-600">Loading...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <nav className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16 items-center">
            <Link href="/" className="text-2xl font-bold text-emerald-600">
              Barakah
            </Link>
            <div className="flex items-center gap-4">
              <button className="text-gray-600 hover:text-gray-900">Settings</button>
              <div className="w-8 h-8 bg-emerald-600 rounded-full"></div>
            </div>
          </div>
        </div>
      </nav>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Stats Grid */}
        <div className="grid md:grid-cols-4 gap-6 mb-8">
          <StatCard 
            title="Total Assets"
            value={`$${stats?.totalAssets?.toLocaleString() || 0}`}
            color="emerald"
          />
          <StatCard 
            title="Monthly Income"
            value={`$${stats?.monthlyIncome?.toLocaleString() || 0}`}
            color="blue"
          />
          <StatCard 
            title="Monthly Expenses"
            value={`$${stats?.monthlyExpenses?.toLocaleString() || 0}`}
            color="red"
          />
          <StatCard 
            title="Net Income"
            value={`$${stats?.netIncome?.toLocaleString() || 0}`}
            color="green"
          />
        </div>

        {/* Tabs */}
        <div className="bg-white rounded-lg shadow-sm mb-8">
          <div className="border-b">
            <nav className="flex">
              <TabButton 
                active={activeTab === 'overview'} 
                onClick={() => setActiveTab('overview')}
              >
                Overview
              </TabButton>
              <TabButton 
                active={activeTab === 'assets'} 
                onClick={() => setActiveTab('assets')}
              >
                Assets
              </TabButton>
              <TabButton 
                active={activeTab === 'transactions'} 
                onClick={() => setActiveTab('transactions')}
              >
                Transactions
              </TabButton>
              <TabButton 
                active={activeTab === 'zakat'} 
                onClick={() => setActiveTab('zakat')}
              >
                Zakat Calculator
              </TabButton>
              <TabButton 
                active={activeTab === 'halal'} 
                onClick={() => setActiveTab('halal')}
              >
                Halal Checker
              </TabButton>
            </nav>
          </div>

          <div className="p-6">
            {activeTab === 'overview' && <OverviewTab assets={assets} transactions={transactions} />}
            {activeTab === 'assets' && <AssetsTab assets={assets} onRefresh={loadData} />}
            {activeTab === 'transactions' && <TransactionsTab transactions={transactions} onRefresh={loadData} />}
            {activeTab === 'zakat' && <ZakatTab assets={assets} />}
            {activeTab === 'halal' && <HalalTab />}
          </div>
        </div>
      </div>
    </div>
  );
}

function StatCard({ title, value, color }) {
  const colors = {
    emerald: 'bg-emerald-50 text-emerald-600',
    blue: 'bg-blue-50 text-blue-600',
    red: 'bg-red-50 text-red-600',
    green: 'bg-green-50 text-green-600'
  };

  return (
    <div className="bg-white p-6 rounded-lg shadow-sm">
      <p className="text-sm text-gray-600 mb-1">{title}</p>
      <p className={`text-2xl font-bold ${colors[color]}`}>{value}</p>
    </div>
  );
}

function TabButton({ active, onClick, children }) {
  return (
    <button
      onClick={onClick}
      className={`px-6 py-3 font-medium ${
        active 
          ? 'border-b-2 border-emerald-600 text-emerald-600' 
          : 'text-gray-600 hover:text-gray-900'
      }`}
    >
      {children}
    </button>
  );
}

function OverviewTab({ assets, transactions }) {
  return (
    <div className="grid md:grid-cols-2 gap-6">
      <div>
        <h3 className="text-lg font-semibold mb-4">Recent Assets</h3>
        {assets.slice(0, 3).map(asset => (
          <div key={asset.id} className="flex justify-between py-3 border-b">
            <span>{asset.name}</span>
            <span className="font-semibold">${asset.value.toLocaleString()}</span>
          </div>
        ))}
      </div>
      <div>
        <h3 className="text-lg font-semibold mb-4">Recent Transactions</h3>
        {transactions.slice(0, 3).map(tx => (
          <div key={tx.id} className="flex justify-between py-3 border-b">
            <span>{tx.description}</span>
            <span className={tx.type === 'income' ? 'text-green-600' : 'text-red-600'}>
              {tx.type === 'income' ? '+' : '-'}${tx.amount.toLocaleString()}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

function AssetsTab({ assets, onRefresh }) {
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({ name: '', type: 'cash', value: '' });

  const addAsset = async (e) => {
    e.preventDefault();
    try {
      await fetch(`${API_URL}/api/assets/add`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-User-Id': USER_ID
        },
        body: JSON.stringify({
          ...formData,
          value: parseFloat(formData.value)
        })
      });
      setFormData({ name: '', type: 'cash', value: '' });
      setShowForm(false);
      onRefresh();
    } catch (error) {
      console.error('Error adding asset:', error);
    }
  };

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h3 className="text-lg font-semibold">Your Assets</h3>
        <button
          onClick={() => setShowForm(!showForm)}
          className="bg-emerald-600 text-white px-4 py-2 rounded-lg hover:bg-emerald-700"
        >
          Add Asset
        </button>
      </div>

      {showForm && (
        <form onSubmit={addAsset} className="bg-gray-50 p-4 rounded-lg mb-6">
          <div className="grid md:grid-cols-3 gap-4">
            <input
              type="text"
              placeholder="Asset name"
              value={formData.name}
              onChange={(e) => setFormData({...formData, name: e.target.value})}
              className="px-4 py-2 border rounded-lg"
              required
            />
            <select
              value={formData.type}
              onChange={(e) => setFormData({...formData, type: e.target.value})}
              className="px-4 py-2 border rounded-lg"
            >
              <option value="cash">Cash</option>
              <option value="gold">Gold</option>
              <option value="property">Property</option>
              <option value="investment">Investment</option>
              <option value="business">Business</option>
              <option value="529">529 Plan</option>
            </select>
            <input
              type="number"
              placeholder="Value"
              value={formData.value}
              onChange={(e) => setFormData({...formData, value: e.target.value})}
              className="px-4 py-2 border rounded-lg"
              required
            />
          </div>
          <button type="submit" className="mt-4 bg-emerald-600 text-white px-6 py-2 rounded-lg hover:bg-emerald-700">
            Save Asset
          </button>
        </form>
      )}

      <div className="space-y-4">
        {assets.map(asset => (
          <div key={asset.id} className="flex justify-between items-center p-4 bg-gray-50 rounded-lg">
            <div>
              <p className="font-semibold">{asset.name}</p>
              <p className="text-sm text-gray-600 capitalize">{asset.type}</p>
            </div>
            <p className="text-xl font-bold text-emerald-600">${asset.value.toLocaleString()}</p>
          </div>
        ))}
      </div>
    </div>
  );
}

function TransactionsTab({ transactions, onRefresh }) {
  return (
    <div>
      <h3 className="text-lg font-semibold mb-6">Transaction History</h3>
      <div className="space-y-3">
        {transactions.map(tx => (
          <div key={tx.id} className="flex justify-between items-center p-4 bg-gray-50 rounded-lg">
            <div>
              <p className="font-semibold">{tx.description}</p>
              <p className="text-sm text-gray-600">{tx.category}</p>
            </div>
            <p className={`text-xl font-bold ${tx.type === 'income' ? 'text-green-600' : 'text-red-600'}`}>
              {tx.type === 'income' ? '+' : '-'}${tx.amount.toLocaleString()}
            </p>
          </div>
        ))}
      </div>
    </div>
  );
}

function ZakatTab({ assets }) {
  const [zakatInfo, setZakatInfo] = useState(null);
  const totalWealth = assets.reduce((sum, asset) => sum + asset.value, 0);
  const nisab = 5686.2;
  const zakatDue = totalWealth >= nisab ? totalWealth * 0.025 : 0;

  return (
    <div>
      <h3 className="text-lg font-semibold mb-6">Zakat Calculator</h3>
      <div className="bg-emerald-50 p-6 rounded-lg mb-6">
        <div className="grid md:grid-cols-3 gap-6">
          <div>
            <p className="text-sm text-gray-600 mb-1">Total Wealth</p>
            <p className="text-2xl font-bold text-emerald-600">${totalWealth.toLocaleString()}</p>
          </div>
          <div>
            <p className="text-sm text-gray-600 mb-1">Nisab Threshold</p>
            <p className="text-2xl font-bold text-gray-700">${nisab.toLocaleString()}</p>
          </div>
          <div>
            <p className="text-sm text-gray-600 mb-1">Zakat Due (2.5%)</p>
            <p className="text-2xl font-bold text-emerald-600">${zakatDue.toLocaleString()}</p>
          </div>
        </div>
      </div>
      <div className="bg-blue-50 p-4 rounded-lg">
        <p className="text-sm text-blue-800">
          {totalWealth >= nisab 
            ? `✅ You are above the Nisab threshold. Zakat is obligatory on your wealth.`
            : `ℹ️ Your wealth is below the Nisab threshold. Zakat is not yet obligatory.`
          }
        </p>
      </div>
    </div>
  );
}

function HalalTab() {
  const [symbol, setSymbol] = useState('');
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);

  const checkStock = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await fetch(`${API_URL}/api/halal/check/${symbol.toUpperCase()}`);
      const data = await res.json();
      setResult(data);
    } catch (error) {
      console.error('Error checking stock:', error);
    }
    setLoading(false);
  };

  return (
    <div>
      <h3 className="text-lg font-semibold mb-6">Halal Investment Checker</h3>
      <form onSubmit={checkStock} className="mb-6">
        <div className="flex gap-4">
          <input
            type="text"
            placeholder="Enter stock symbol (e.g., AAPL)"
            value={symbol}
            onChange={(e) => setSymbol(e.target.value)}
            className="flex-1 px-4 py-2 border rounded-lg"
            required
          />
          <button
            type="submit"
            disabled={loading}
            className="bg-emerald-600 text-white px-6 py-2 rounded-lg hover:bg-emerald-700 disabled:bg-gray-400"
          >
            {loading ? 'Checking...' : 'Check'}
          </button>
        </div>
      </form>

      {result && result.found && (
        <div className={`p-6 rounded-lg ${result.isHalal ? 'bg-green-50' : 'bg-red-50'}`}>
          <div className="flex items-start justify-between mb-4">
            <div>
              <p className="text-2xl font-bold">{result.symbol}</p>
              <p className="text-gray-600">{result.name}</p>
            </div>
            <span className={`px-4 py-2 rounded-full font-semibold ${
              result.isHalal ? 'bg-green-200 text-green-800' : 'bg-red-200 text-red-800'
            }`}>
              {result.isHalal ? '✅ Halal' : '❌ Not Halal'}
            </span>
          </div>
          <p className="text-gray-700">{result.reason}</p>
        </div>
      )}

      {result && !result.found && (
        <div className="p-6 bg-yellow-50 rounded-lg">
          <p className="text-yellow-800">Stock symbol not found in our database.</p>
        </div>
      )}
    </div>
  );
}