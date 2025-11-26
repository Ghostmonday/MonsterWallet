#!/bin/bash
echo "═══════════════════════════════════════════════════════════════"
echo "  Blockchain Test Environment"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "Starting Docker containers..."
docker-compose up -d
sleep 5

echo ""
echo "Checking container status..."
docker-compose ps
echo ""

echo "Testing Ethereum (port 8545)..."
ETH_RESULT=$(curl -s -X POST http://localhost:8545 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}')
if [[ $ETH_RESULT == *"0x7a69"* ]]; then
    echo "  ✅ Ethereum OK (Chain ID: 31337)"
else
    echo "  ❌ Ethereum not responding"
fi

echo ""
echo "Testing Solana (port 8899)..."
SOL_RESULT=$(curl -s -X POST http://localhost:8899 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}')
if [[ $SOL_RESULT == *"ok"* ]]; then
    echo "  ✅ Solana OK"
else
    echo "  ❌ Solana not responding"
fi

echo ""
echo "Testing Bitcoin (port 18443)..."
BTC_RESULT=$(curl -s --user kryptoclaw:testpass123 -X POST http://localhost:18443 -H "Content-Type: application/json" -d '{"jsonrpc":"1.0","id":"test","method":"getblockchaininfo","params":[]}')
if [[ $BTC_RESULT == *"regtest"* ]]; then
    echo "  ✅ Bitcoin OK (regtest)"
else
    echo "  ❌ Bitcoin not responding"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ENDPOINTS READY:"
echo "═══════════════════════════════════════════════════════════════"
echo "  Ethereum:  http://localhost:8545"
echo "  Solana:    http://localhost:8899"
echo "  Bitcoin:   http://localhost:18443"
echo "  Proxy:     http://localhost:8080"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Run 'docker-compose logs -f' to see live logs"
echo "Run 'docker-compose down' to stop"

