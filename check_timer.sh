#!/bin/bash
WS=~/workspace

echo "=== Test script Timer check karta kya hai ==="
grep -A 20 "Timer Logic\|Step 3\|timer" $WS/test_phase_4_2.js | head -40

echo ""
echo "=== Timer route response (live) ==="
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"student@proverank.com","password":"ProveRank@123"}' \
  | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

curl -s http://localhost:3000/api/attempts/69a84803bf3cd6ffdab84326/timer \
  -H "Authorization: Bearer $TOKEN"

echo ""
echo ""
echo "=== Timer handler in attemptRoutes ==="
grep -n "timer\|remainingSec\|totalDuration\|elapsed" $WS/src/routes/attemptRoutes.js | head -20
