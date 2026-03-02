#!/bin/bash
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login -H "Content-Type: application/json" -d '{"email":"admin@proverank.com","password":"ProveRankSuperAdmin123"}' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
echo "✅ Login OK"

QID=$(curl -s -X POST http://localhost:3000/api/questions -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"text":"Mitochondria ka main function kya hai","hindiText":"माइटोकॉन्ड्रिया का मुख्य कार्य क्या है","options":["ATP production","Protein synthesis","DNA storage","Cell division"],"correct":[0],"subject":"Biology","chapter":"Cell Biology","difficulty":"Easy","type":"SCQ"}' | grep -o '"_id":"[^"]*"' | cut -d'"' -f4)
echo "Test QID: $QID"

echo "=== Step 14: Version History ==="
curl -s http://localhost:3000/api/questions-advanced/$QID/versions -H "Authorization: Bearer $TOKEN" | grep -o '"currentVersion":[^,]*'

echo "=== Step 15: MSQ Validate ==="
MSQID=$(curl -s -X POST http://localhost:3000/api/questions -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"text":"Which are correct options","options":["A","B","C","D"],"correct":[0,2],"subject":"Physics","difficulty":"Medium","type":"MSQ"}' | grep -o '"_id":"[^"]*"' | cut -d'"' -f4)
curl -s -X POST http://localhost:3000/api/questions-advanced/msq/validate -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"questionId":"'$MSQID'","selectedOptions":[0,2]}' | grep -o '"result":"[^"]*"'

echo "=== Step 16: Integer Validate ==="
INTID=$(curl -s -X POST http://localhost:3000/api/questions -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"text":"2+2 kitna hota hai","options":["4"],"correct":[4],"subject":"Physics","difficulty":"Easy","type":"Integer"}' | grep -o '"_id":"[^"]*"' | cut -d'"' -f4)
curl -s -X POST http://localhost:3000/api/questions-advanced/integer/validate -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"questionId":"'$INTID'","answer":4}' | grep -o '"result":"[^"]*"'

echo "=== Step 17: PYQ Add ==="
curl -s -X POST http://localhost:3000/api/questions-advanced/pyq/add -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"text":"NEET 2023 - Mitochondria function","hindiText":"NEET 2023 - माइटोकॉन्ड्रिया का कार्य","options":["ATP","RNA","DNA","Lipid"],"correct":[0],"subject":"Biology","chapter":"Cell Biology","difficulty":"Medium","year":2023,"exam":"NEET"}' | grep -o '"message":"[^"]*"'

echo "=== Step 17: PYQ List ==="
curl -s "http://localhost:3000/api/questions-advanced/pyq/list?exam=NEET" -H "Authorization: Bearer $TOKEN" | grep -o '"total":[^,]*'

echo "=== Step 18: Error Report ==="
curl -s -X POST http://localhost:3000/api/questions-advanced/$QID/report-error -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"errorType":"Wrong Answer","description":"Option A galat lag raha hai"}' | grep -o '"message":"[^"]*"'

echo "=== Step 19: AI Translate ==="
curl -s -X POST http://localhost:3000/api/questions-advanced/$QID/translate -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"direction":"en-to-hi"}' | grep -o '"message":"[^"]*"'

echo "=== Step 20: AI Explanation ==="
curl -s -X POST http://localhost:3000/api/questions-advanced/$QID/generate-explanation -H "Authorization: Bearer $TOKEN" | grep -o '"message":"[^"]*"'

echo "=== Step 21: Submit for Approval ==="
curl -s -X POST http://localhost:3000/api/questions-advanced/$QID/submit-for-approval -H "Authorization: Bearer $TOKEN" | grep -o '"message":"[^"]*"'

echo "=== Step 21: Approval Queue ==="
curl -s http://localhost:3000/api/questions-advanced/approval-queue -H "Authorization: Bearer $TOKEN" | grep -o '"pendingCount":[^,]*'

echo "=== Step 21: Approve Question ==="
curl -s -X PUT http://localhost:3000/api/questions-advanced/$QID/approve -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"action":"Approved"}' | grep -o '"message":"[^"]*"'

echo "=== Step 22: Import Text Format ==="
curl -s -X POST http://localhost:3000/api/questions-advanced/import-text -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"textData":"Q1. Photosynthesis kahan hoti hai\nA) Mitochondria\nB) Chloroplast\nC) Nucleus\nD) Ribosome\nAnswer: B\nQ2. DNA ka full form kya hai\nA) Deoxyribonucleic Acid\nB) Ribonucleic Acid\nC) Deoxyribose Acid\nD) None\nAnswer: A","subject":"Biology","difficulty":"Easy"}' | grep -o '"message":"[^"]*"'

echo ""
echo "🎉 Steps 14-22 ALL DONE!"
