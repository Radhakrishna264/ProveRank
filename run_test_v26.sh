#!/bin/bash
echo "=== ProveRank V26 - Restart + Test ==="

pkill -9 -f node 2>/dev/null
sleep 4

cd ~/workspace && node src/index.js > /tmp/server.log 2>&1 &
sleep 8

echo "Server started - checking..."
cat /tmp/server.log | grep -E "running|Connected|Error" | head -5

echo ""
echo "=== Running Phase 4.2 Test ==="
MONGO_URI=$(grep MONGO_URI .env | cut -d= -f2-) node test_phase_4_2.js
