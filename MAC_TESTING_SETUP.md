# KryptoClaw Mac Testing Setup

Quick guide to get local blockchain testing running on your Mac.

---

## Prerequisites

1. **Docker Desktop for Mac** must be installed and running
   - Download: https://www.docker.com/products/docker-desktop/
   - After install, ensure Docker is running (whale icon in menu bar)

2. **Verify Docker is working:**
   ```bash
   docker --version
   docker-compose --version
   ```

---

## Step 1: Navigate to Project

```bash
cd ~/path/to/MonsterWallet
```

---

## Step 2: Start All Blockchain Nodes

```bash
docker-compose up -d
```

This starts:
- Ethereum (Anvil) on port 8545
- Solana (Test Validator) on port 8899
- Bitcoin (Regtest) on port 18443
- Nginx Proxy on port 8080

---

## Step 3: Verify Containers Are Running

```bash
docker-compose ps
```

You should see all 4 containers with status "Up":
```
NAME                 STATUS
kryptoclaw-eth       Up
kryptoclaw-sol       Up
kryptoclaw-btc       Up
kryptoclaw-proxy     Up
```

---

## Step 4: Test Each Endpoint

### Ethereum
```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```
Expected: Returns current block number

### Solana
```bash
curl -X POST http://localhost:8899 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}'
```
Expected: `{"jsonrpc":"2.0","result":"ok","id":1}`

### Bitcoin
```bash
curl --user kryptoclaw:testpass123 \
  -X POST http://localhost:18443 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"1.0","id":"test","method":"getblockchaininfo","params":[]}'
```
Expected: Returns blockchain info JSON

---

## Endpoints Summary

| Chain    | URL                      | Notes                          |
|----------|--------------------------|--------------------------------|
| Ethereum | `http://localhost:8545`  | Chain ID: 31337                |
| Solana   | `http://localhost:8899`  | WebSocket: `ws://localhost:8900` |
| Bitcoin  | `http://localhost:18443` | User: `kryptoclaw` Pass: `testpass123` |
| Proxy    | `http://localhost:8080`  | `/eth`, `/sol`, `/btc` routes  |

---

## For iOS Simulator Testing

Use `localhost` - it works directly with the simulator.

```swift
// In your app's test configuration:
let ethRPC = "http://localhost:8545"
let solRPC = "http://localhost:8899"
let btcRPC = "http://localhost:18443"
```

---

## For Physical Device Testing

Use your Mac's local IP instead of `localhost`:

```bash
# Find your Mac's IP:
ipconfig getifaddr en0
```

Then use that IP (e.g., `http://192.168.1.100:8545`)

---

## Get Test Funds

### Ethereum (already pre-funded)
Anvil creates 10 accounts with 10,000 ETH each. Get the keys:
```bash
docker logs kryptoclaw-eth 2>&1 | head -50
```

### Solana
```bash
docker exec kryptoclaw-sol solana airdrop 100 YOUR_WALLET_ADDRESS
```

### Bitcoin
```bash
# Generate 101 blocks to your address (required for spendable BTC)
docker exec kryptoclaw-btc bitcoin-cli -regtest \
  -rpcuser=kryptoclaw -rpcpassword=testpass123 \
  generatetoaddress 101 YOUR_BTC_ADDRESS
```

---

## Common Commands

```bash
# View logs (all containers)
docker-compose logs -f

# View specific container logs
docker-compose logs -f ethereum

# Stop everything
docker-compose down

# Restart fresh
docker-compose down && docker-compose up -d

# Check resource usage
docker stats
```

---

## Troubleshooting

### "Port already in use"
```bash
# Find what's using the port
lsof -i :8545

# Kill it or change ports in docker-compose.yml
```

### Container won't start
```bash
docker-compose logs ethereum
docker-compose logs solana
docker-compose logs bitcoin
```

### Can't connect from app
1. Ensure Docker Desktop is running
2. Check containers are up: `docker-compose ps`
3. Test endpoint manually with curl (see Step 4)

---

## Quick Start Script

Save this as `start-test.sh` and run with `chmod +x start-test.sh && ./start-test.sh`:

```bash
#!/bin/bash
echo "Starting blockchain test environment..."
docker-compose up -d
sleep 5
echo ""
echo "Checking containers..."
docker-compose ps
echo ""
echo "Testing Ethereum..."
curl -s -X POST http://localhost:8545 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
echo ""
echo ""
echo "Testing Solana..."
curl -s -X POST http://localhost:8899 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}'
echo ""
echo ""
echo "✅ Ready for testing!"
```

---

**Push this repo, pull on Mac, run `docker-compose up -d`, and you're ready to test.**

