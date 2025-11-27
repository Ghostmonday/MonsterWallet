#!/bin/bash
# KryptoClaw Docker Integration Test Script
# Run this to verify the iOS simulator can connect to Docker containers

set -e

echo "🔗 KryptoClaw Docker Integration Test"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_endpoint() {
    local name=$1
    local cmd=$2
    local expected=$3
    
    echo -n "Testing $name... "
    result=$(eval "$cmd" 2>/dev/null || echo "FAILED")
    
    if [[ "$result" == *"$expected"* ]]; then
        echo -e "${GREEN}✓ PASSED${NC}"
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "  Expected: $expected"
        echo "  Got: $result"
        return 1
    fi
}

echo "📦 Phase 1: Container Health"
echo "----------------------------"

# Check containers are running
if docker ps | grep -q "kryptoclaw-eth"; then
    echo -e "${GREEN}✓${NC} Ethereum container running"
else
    echo -e "${RED}✗${NC} Ethereum container NOT running"
    exit 1
fi

if docker ps | grep -q "kryptoclaw-sol"; then
    echo -e "${GREEN}✓${NC} Solana container running"
else
    echo -e "${RED}✗${NC} Solana container NOT running"
    exit 1
fi

if docker ps | grep -q "kryptoclaw-btc"; then
    echo -e "${GREEN}✓${NC} Bitcoin container running"
else
    echo -e "${RED}✗${NC} Bitcoin container NOT running"
    exit 1
fi

echo ""
echo "🔌 Phase 2: RPC Connectivity"
echo "----------------------------"

test_endpoint "ETH Chain ID" \
    "curl -s -X POST http://localhost:8545 -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"eth_chainId\",\"params\":[],\"id\":1}' | jq -r '.result'" \
    "0x7a69"

test_endpoint "SOL Health" \
    "curl -s -X POST http://localhost:8899 -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"getHealth\",\"id\":1}' | jq -r '.result'" \
    "ok"

test_endpoint "BTC Chain" \
    "curl -s -X POST http://localhost:18443 -u kryptoclaw:testpass123 -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"1.0\",\"id\":\"test\",\"method\":\"getblockchaininfo\",\"params\":[]}' | jq -r '.result.chain'" \
    "regtest"

echo ""
echo "💰 Phase 3: Balance Queries"
echo "----------------------------"

ETH_BALANCE=$(curl -s -X POST http://localhost:8545 \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266","latest"],"id":1}' | jq -r '.result')

if [[ "$ETH_BALANCE" == "0x21e19e0c9bab2400000" ]]; then
    echo -e "${GREEN}✓${NC} ETH test account has 10,000 ETH"
else
    echo -e "${YELLOW}⚠${NC} ETH balance: $ETH_BALANCE"
fi

echo ""
echo "📱 Phase 4: iOS Simulator"
echo "-------------------------"

# Check if simulator is running
if xcrun simctl list devices booted | grep -q "iPhone"; then
    echo -e "${GREEN}✓${NC} iOS Simulator is running"
    
    # Check if KryptoClaw is installed
    if xcrun simctl listapps booted 2>/dev/null | grep -q "com.kryptoclaw.app"; then
        echo -e "${GREEN}✓${NC} KryptoClaw app is installed"
    else
        echo -e "${YELLOW}⚠${NC} KryptoClaw app not installed"
    fi
else
    echo -e "${YELLOW}⚠${NC} iOS Simulator not running"
fi

echo ""
echo "======================================"
echo -e "${GREEN}Integration test complete!${NC}"
echo ""
echo "📋 Next Steps:"
echo "   1. Open KryptoClaw in the simulator"
echo "   2. Create or import a wallet"
echo "   3. Navigate to Receive to see your address"
echo "   4. Fund it using: cast send <YOUR_ADDRESS> --value 1ether --private-key 0xac0974..."
echo "   5. Pull to refresh and watch the balance update!"

