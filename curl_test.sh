#!/bin/bash
BASE="http://localhost:3000"

echo "=== 1. Server log errors ==="
cat /tmp/server.log | grep -iE "error|cannot|failed|undefined|attempt" | head -20

echo ""
echo "=== 2. Token fetch ==="
TOKEN=$(curl -s -X POST $BASE/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"student@proverank.com","password":"ProveRank@123"}' \
  | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
echo "Token: ${TOKEN:0:40}..."

echo ""
echo "=== 3. T&C accept-terms ==="
curl -s -X POST $BASE/api/exams/69a695892217ac6201221bfa/accept-terms \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"

echo ""
echo ""
echo "=== 4. start-attempt ==="
curl -s -X POST $BASE/api/exams/69a695892217ac6201221bfa/start-attempt \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"

echo ""
echo ""
echo "=== 5. attempts save-answer (direct) ==="
curl -s -X PATCH $BASE/api/attempts/69a84803bf3cd6ffdab84326/save-answer \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"questionId":"test123","selectedOption":"A"}'

echo ""
echo ""
echo "=== 6. Route list check ==="
curl -s $BASE/api/attempts/69a84803bf3cd6ffdab84326/timer \
  -H "Authorization: Bearer $TOKEN"

echo ""
echo ""
echo "=== 7. Server log - last 30 ==="
cat /tmp/server.log | tail -30
