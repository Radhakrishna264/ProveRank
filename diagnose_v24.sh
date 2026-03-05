#!/bin/bash
echo "=============================="
echo " ProveRank V24 DIAGNOSE SCRIPT"
echo "=============================="

echo ""
echo "--- STEP 1: Route Order in index.js ---"
grep -n "examFeaturesRoutes\|examPatchRoutes\|examRoutes" ~/workspace/src/index.js

echo ""
echo "--- STEP 2: examFeatures.js routes ---"
grep -n "router\." ~/workspace/src/routes/examFeatures.js | head -30

echo ""
echo "--- STEP 3: exam_patch.js accept-terms ---"
grep -n "accept-terms\|Exam.find" ~/workspace/src/routes/exam_patch.js

echo ""
echo "--- STEP 4: Server restart ---"
pkill -9 -f node 2>/dev/null
sleep 3
cd ~/workspace && node src/index.js > /tmp/server.log 2>&1 &
sleep 6
echo "Server started"

echo ""
echo "--- STEP 5: Auto Login + Token fetch ---"
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@proverank.com","password":"ProveRank@SuperAdmin123"}' \
  | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "LOGIN FAILED - token nahi mila"
  echo "Server log:"
  cat /tmp/server.log | tail -20
  exit 1
fi
echo "Token fetched OK: ${TOKEN:0:30}..."

echo ""
echo "--- STEP 6: start-attempt test ---"
curl -s -X POST http://localhost:3000/api/exams/69a695892217ac6201221bfa/start-attempt \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"

echo ""
echo ""
echo "--- STEP 7: accept-terms test ---"
curl -s -X POST http://localhost:3000/api/exams/69a695892217ac6201221bfa/accept-terms \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"

echo ""
echo ""
echo "--- STEP 8: Server Log (last 25 lines) ---"
cat /tmp/server.log | tail -25

echo ""
echo "=============================="
echo " DIAGNOSE COMPLETE"
echo "=============================="
