#!/bin/bash
echo "=== Login ==="
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
-H "Content-Type: application/json" \
-d '{"email":"admin@proverank.com","password":"ProveRankSuperAdmin123"}' \
| grep -o '"token":"[^"]*"' | cut -d'"' -f4)
echo "Token OK: ${TOKEN:0:20}..."

echo "=== Add Question ==="
RESP=$(curl -s -X POST http://localhost:3000/api/questions \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{"text":"Calculate karo electron ki velocity","options":["A","B","C","D"],"correct":[0],"subject":"Physics","difficulty":"Easy","type":"SCQ"}')
echo $RESP | grep -o '"success":[^,]*'
QID=$(echo $RESP | grep -o '"_id":"[^"]*"' | cut -d'"' -f4)
echo "QID: $QID"

echo "=== Step 4: Edit ==="
curl -s -X PUT http://localhost:3000/api/questions/$QID \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{"difficulty":"Hard"}' | grep -o '"message":"[^"]*"'

echo "=== Step 5: Delete ==="
DELRESP=$(curl -s -X POST http://localhost:3000/api/questions \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{"text":"Delete wala question","options":["A","B","C","D"],"correct":[0],"subject":"Physics","difficulty":"Easy","type":"SCQ"}')
DELID=$(echo $DELRESP | grep -o '"_id":"[^"]*"' | cut -d'"' -f4)
curl -s -X DELETE http://localhost:3000/api/questions/$DELID \
-H "Authorization: Bearer $TOKEN" | grep -o '"message":"[^"]*"'

echo "=== Step 6: Manual Difficulty ==="
curl -s -X PUT http://localhost:3000/api/questions/$QID/difficulty \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{"difficulty":"Medium"}' | grep -o '"message":"[^"]*"'

echo "=== Step 7: AI Difficulty ==="
curl -s -X POST http://localhost:3000/api/questions/$QID/ai-tag-difficulty \
-H "Authorization: Bearer $TOKEN" | grep -o '"suggestedDifficulty":"[^"]*"'

echo "=== Step 8: AI Classify ==="
curl -s -X POST http://localhost:3000/api/questions/$QID/ai-classify \
-H "Authorization: Bearer $TOKEN" | grep -o '"detectedSubject":"[^"]*"'

echo "🎉 Steps 4-8 ALL DONE!"
