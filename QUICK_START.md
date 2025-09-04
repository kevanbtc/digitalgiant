# 🚀 UNYKORN AI - QUICK START GUIDE

## ⚡ Immediate Actions

### 1. Restart with Live Blockchain Data
Your AI system is now configured with **working public RPC endpoints**:

```bash
# Option A: Quick restart (recommended)
./restart_with_live_rpcs.sh

# Option B: Manual restart  
python3 launch_unykorn_ai.py --mode interactive
```

### 2. View Your Live Dashboard
Open in browser: **http://localhost:8080/dashboard**

You should now see:
- ✅ **4/5 chains online** (Ethereum, Polygon, Solana, Cosmos)
- ✅ **Live balance data** for your master addresses
- ✅ **Real-time block heights** and network status

## 🔗 Live RPC Endpoints (Working Now)

| Chain | Endpoint | Status |
|-------|----------|--------|
| **Ethereum** | `https://ethereum-rpc.publicnode.com` | ✅ Tested |
| **Polygon** | `https://polygon-rpc.com` | ✅ Tested |
| **Solana** | `https://api.mainnet-beta.solana.com` | ✅ Tested |
| **Cosmos** | `https://cosmos-rpc.publicnode.com:443` | ✅ Available |
| **Unykorn** | `http://localhost:9650` | ⚠️ Local node required |

## 📊 Your Live Data

Your AI is now monitoring these **real addresses**:

### Polygon Master
- **Address**: `0x8aced25DC8530FDaf0f86D53a0A1E02AAfA7Ac7A`
- **Status**: ✅ Live monitoring  
- **Contracts**: Diversegy Registry, GenieBroker, OptimaVault

### Solana Master  
- **Address**: `GFHJQ7JgcRGYToPf2KXdGWDABRVnqzMU7ePDu4b3BqZg`
- **Status**: ✅ Live monitoring

## ⚙️ Optional: Add Premium API Keys

For **higher rate limits** and **additional features**:

```bash
# Run the API setup wizard
python3 setup_api_keys.py
```

This will help you add:
- 🌐 **Infura** keys (higher reliability)  
- 🧪 **Alchemy** keys (advanced features)
- 🦎 **CoinGecko** Pro (price data)
- 🌿 **Moralis** (NFT/DeFi data)

## 🎯 What Should Work Now

### Dashboard Features
- **System Overview**: Live asset count and USD values
- **Chain Status**: 4/5 chains showing as ONLINE  
- **Balance Monitoring**: Real-time updates every 30 seconds
- **Compliance Dashboard**: Automated regulatory checks
- **Emergency Controls**: Immediate response protocols

### CLI Commands
```bash
UNYKORN> status    # Show live system status
UNYKORN> scan      # Full asset inventory with live data  
UNYKORN> check     # Health check all systems
```

### API Endpoints  
- `GET /api/status` - Overall system with live chain data
- `GET /api/balances` - Real-time balance data
- `GET /api/compliance` - Live compliance status

## 🔥 Expected Results

After restart, your dashboard should show:
```
✅ Systems Online: 5/5
✅ Chains Online: 4/5  
✅ Total Assets: [Your asset count]
✅ Total Value: $[Live calculated value]
✅ Active Alerts: [Compliance status]
```

## 🆘 Troubleshooting

### If chains still show offline:
```bash
# Test RPC connections manually
curl -X POST https://ethereum-rpc.publicnode.com \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

### If dashboard won't load:
```bash
# Check if port 8080 is free
netstat -ln | grep :8080

# Kill any existing processes
pkill -f "launch_unykorn_ai.py"
```

### If you want to add API keys later:
```bash
# Edit the config file directly
nano /home/unykorn/config/chain_endpoints.yaml

# Or use the setup wizard
python3 setup_api_keys.py
```

## 🎉 Success Criteria

You'll know it's working when:

1. **Dashboard loads** at http://localhost:8080/dashboard
2. **Chain status shows** 4+ chains online
3. **Balance data appears** for your master addresses  
4. **Block heights update** in real-time
5. **No RPC connection errors** in the logs

---

**🦄 Your UNYKORN AI Empire is now connected to live blockchain data and ready for autonomous management!**