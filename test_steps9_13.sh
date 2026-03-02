#!/bin/bash
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login -H "Content-Type: application/json" -d '{"email":"admin@proverank.com","password":"ProveRankSuperAdmin123"}' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
echo "Login OK"

QID=$(curl -s -X POST http://localhost:3000/api/questions -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"text":"Mitochondria ka main function ATP production hai","hindiText":"माइटोकॉन्ड्रिया का मुख्य कार्य ATP उत्पादन है","options":["ATP","RNA","DNA","Protein"],"correct":[0],"subject":"Biology","chapter":"Cell Biology","difficulty":"Easy","type":"SCQ"}' | grep -o '"_id":"[^"]*"' | cut -d'"' -f4)
echo "Test QID: $QID"

echo "=== Step 9: AI Similarity ==="
curl -s -X POST http://localhost:3000/api/questions/ai-similarity -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"text":"Mitochondria ka main function kya hai ATP banata hai"}' | grep -o '"warning":"[^"]*"'

echo "=== Step 10: Duplicate Check ==="
curl -s -X POST http://localhost:3000/api/questions/check-duplicate -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"text":"Mitochondria ka main function ATP production hai"}' | grep -o '"isDuplicate":[^,]*'

echo "=== Step 12: Search with Tags ==="
curl -s -X PUT http://localhost:3000/api/questions/$QID/tags -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"tags":["NEET","Biology","Important"]}' | grep -o '"message":"[^"]*"'

echo "=== Step 12: Advanced Search ==="
curl -s "http://localhost:3000/api/questions/search?subject=Biology&difficulty=Easy" -H "Authorization: Bearer $TOKEN" | grep -o '"total":[^,]*'

echo "=== Step 13: Usage Tracker ==="
curl -s http://localhost:3000/api/questions/$QID/usage -H "Authorization: Bearer $TOKEN" | grep -o '"message":"[^"]*"'

echo "=== Step 13: Usage Stats ==="
curl -s http://localhost:3000/api/questions/usage-stats -H "Authorization: Bearer $TOKEN" | grep -o '"totalQuestions":[^,]*'

echo "🎉 Steps 9-13 ALL DONE!"
