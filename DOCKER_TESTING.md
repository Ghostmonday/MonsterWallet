# KryptoClaw Docker Testing Environment

Local blockchain testnets for realistic wallet testing.

## 🚀 Quick Start

```bash
# Start all chains
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Stop everything
docker-compose down
```

## 🔗 Endpoints

| Chain | Direct URL | Proxy URL |
|-------|-----------|-----------|
| **Ethereum** | `http://localhost:8545` | `http://localhost:8080/eth` |
| **Solana** | `http://localhost:8899` | `http://localhost:8080/sol` |
| **Bitcoin** | `http://localhost:18443` | `http://localhost:8080/btc` |

## ⚙️ Chain Details

### Ethereum (Anvil)
- **Chain ID**: 31337
- **Block Time**: 2 seconds
- **Pre-funded Accounts**: 10 accounts with 10,000 ETH each
- **Private Keys**: Standard Anvil keys (see `anvil` output)

```bash
# Get test accounts
docker exec kryptoclaw-eth cast accounts

# Fund an address
docker exec kryptoclaw-eth cast send <ADDRESS> --value 1ether --private-key <ANVIL_KEY>
```

### Solana (Test Validator)
- **RPC**: http://localhost:8899
- **WebSocket**: ws://localhost:8900

```bash
# Airdrop SOL to test wallet
docker exec kryptoclaw-sol solana airdrop 100 <WALLET_ADDRESS>

# Check balance
docker exec kryptoclaw-sol solana balance <WALLET_ADDRESS>
```

### Bitcoin (Regtest)
- **RPC User**: `kryptoclaw`
- **RPC Password**: `testpass123`
- **Network**: Regtest

```bash
# Generate blocks (needed to get BTC)
docker exec kryptoclaw-btc bitcoin-cli -regtest -rpcuser=kryptoclaw -rpcpassword=testpass123 generatetoaddress 101 <YOUR_BTC_ADDRESS>

# Check balance
docker exec kryptoclaw-btc bitcoin-cli -regtest -rpcuser=kryptoclaw -rpcpassword=testpass123 getbalance
```

## 📱 iOS App Configuration

Update your app's RPC endpoints for testing:

```swift
// Development/Testing endpoints
struct TestConfig {
    static let ethereumRPC = "http://localhost:8545"  // or Mac's IP for simulator
    static let solanaRPC = "http://localhost:8899"
    static let bitcoinRPC = "http://localhost:18443"
}
```

**Note**: When testing on iOS Simulator, use `localhost`. When testing on a physical device, use your Mac's local IP address (e.g., `192.168.1.x`).

## 🧪 Testing Scenarios

### 1. Basic Transaction Flow
1. Start Docker environment
2. Fund test wallet from faucet
3. Send transaction from app
4. Verify on local chain

### 2. Network Latency
```bash
# Add 500ms latency to Ethereum
docker exec kryptoclaw-eth tc qdisc add dev eth0 root netem delay 500ms
```

### 3. RPC Failures
```bash
# Stop Ethereum node temporarily
docker stop kryptoclaw-eth

# Verify app handles gracefully, then restart
docker start kryptoclaw-eth
```

### 4. Chain Reorg (Ethereum)
```bash
# Anvil supports instant mining and reorgs
docker exec kryptoclaw-eth cast rpc anvil_mine 10
```

## 🔧 Troubleshooting

### Port Conflicts
```bash
# Check what's using ports
netstat -an | findstr "8545\|8899\|18443"

# Kill conflicting process or change ports in docker-compose.yml
```

### Container Won't Start
```bash
# Check logs
docker-compose logs ethereum
docker-compose logs solana
docker-compose logs bitcoin

# Rebuild
docker-compose down
docker-compose up --build -d
```

### Can't Connect from iOS Simulator
- Ensure Docker Desktop is running
- Use `localhost` for simulator
- Check firewall isn't blocking ports

## 📊 Monitoring

```bash
# Watch all container logs
docker-compose logs -f

# Check resource usage
docker stats
```

---

**Built for KryptoClaw** | Neural Draft LLC

