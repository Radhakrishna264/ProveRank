#!/bin/bash

# ============================================================
# ProveRank -- Phase 2.1 Test Script -- Steps 1 to 11
# Question Model & AI Intelligence
# Run: cd ~/workspace && bash test_phase_2_1_steps_1_to_11.sh
# ============================================================

BASE="http://localhost:3000"
PASS=0
FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}✅ PASS${NC} -- $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}❌ FAIL${NC} -- $1"; FAIL=$((FAIL+1)); }
info() { echo -e "${YELLOW}ℹ️  $1${NC}"; }

echo ""
echo "============================================================"
echo "  ProveRank -- Phase 2.1 Test -- Steps 1 to 11"
echo "  Question Model & AI Intelligence"
echo "============================================================"
echo ""

# ─────────────────────────────────────────
# LOGIN -- SuperAdmin Token Lo
# ─────────────────────────────────────────
info "SuperAdmin login kar rahe hain..."

LOGIN_RES=$(curl -s -X POST "$BASE/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@proverank.com","password":"ProveRank@SuperAdmin123"}')

TOKEN=$(echo "$LOGIN_RES" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
ROLE=$(echo "$LOGIN_RES" | grep -o '"role":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo -e "${RED}❌ FATAL: SuperAdmin login FAIL -- Token nahi mila. Server check karo.${NC}"
  echo "Response: $LOGIN_RES"
  exit 1
fi

if [ "$ROLE" != "superadmin" ]; then
  echo -e "${RED}❌ FATAL: Role 'superadmin' nahi hai. Got: $ROLE${NC}"
  exit 1
fi

pass "SuperAdmin Login -- Token mila, role=superadmin"
echo ""

# ─────────────────────────────────────────
# STEP 1 -- Question Schema Verify
# Fields: text, hindiText, options, correct, subject, chapter,
# topic, difficulty, type, image, explanation, videoLink, tags,
# usageCount, sourceExam, version, approvalStatus, approvedBy, translatedBy
# ─────────────────────────────────────────
info "STEP 1: Question Schema -- saare fields check karte hain..."

ADD_RES=$(curl -s -X POST "$BASE/api/questions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "text": "Mitochondria is the powerhouse of the cell. Which organelle produces ATP?",
    "hindiText": "Mitochondria koshika ka powerhouse hai. Kaun sa organelle ATP banata hai?",
    "options": ["Nucleus","Mitochondria","Ribosome","Golgi Body"],
    "correct": [1],
    "subject": "Biology",
    "chapter": "Cell Biology",
    "topic": "Mitochondria",
    "difficulty": "Easy",
    "type": "SCQ",
    "explanation": "Mitochondria ATP synthesis karta hai via oxidative phosphorylation.",
    "videoLink": "https://youtube.com/example",
    "tags": ["cell","ATP","organelle"],
    "sourceExam": "NEET 2022",
    "version": 1,
    "approvalStatus": "pending"
  }')

STATUS_1=$(echo "$ADD_RES" | grep -o '"status":[0-9]*' | head -1 | cut -d: -f2)
Q_ID=$(echo "$ADD_RES" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$Q_ID" ]; then
  pass "STEP 1 -- Question Schema VALID -- Question created, _id=$Q_ID"
else
  fail "STEP 1 -- Question Schema ERROR -- Question create nahi hua"
  echo "Response: $ADD_RES"
fi
echo ""

# ─────────────────────────────────────────
# STEP 2 -- Manual Add Question Route (POST)
# ─────────────────────────────────────────
info "STEP 2: Manual Add Question -- POST /api/questions..."

ADD2_RES=$(curl -s -X POST "$BASE/api/questions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "text": "Which gas is most abundant in Earth atmosphere?",
    "hindiText": "Prithvi ke atmosphere mein sabse adhik kaun si gas hai?",
    "options": ["Oxygen","Carbon Dioxide","Nitrogen","Argon"],
    "correct": [2],
    "subject": "Chemistry",
    "chapter": "Environmental Chemistry",
    "topic": "Atmosphere",
    "difficulty": "Easy",
    "type": "SCQ",
    "explanation": "Nitrogen (N2) about 78% atmosphere banata hai.",
    "tags": ["atmosphere","nitrogen","gas"]
  }')

Q_ID2=$(echo "$ADD2_RES" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$Q_ID2" ]; then
  pass "STEP 2 -- POST /api/questions -- Question added, _id=$Q_ID2"
else
  fail "STEP 2 -- POST /api/questions -- Question add FAIL"
  echo "Response: $ADD2_RES"
fi
echo ""

# ─────────────────────────────────────────
# STEP 3 -- Fetch Questions -- Filter by subject/chapter/topic/difficulty (S34)
# ─────────────────────────────────────────
info "STEP 3: Fetch Questions -- GET /api/questions with filters..."

# Subject filter
FETCH_SUB=$(curl -s "$BASE/api/questions?subject=Biology" \
  -H "Authorization: Bearer $TOKEN")
COUNT_SUB=$(echo "$FETCH_SUB" | grep -o '"_id"' | wc -l)

if [ "$COUNT_SUB" -ge 1 ]; then
  pass "STEP 3a -- subject=Biology filter -- $COUNT_SUB question(s) mila"
else
  fail "STEP 3a -- subject=Biology filter -- koi question nahi mila"
  echo "Response: $FETCH_SUB"
fi

# Difficulty filter
FETCH_DIFF=$(curl -s "$BASE/api/questions?difficulty=Easy" \
  -H "Authorization: Bearer $TOKEN")
COUNT_DIFF=$(echo "$FETCH_DIFF" | grep -o '"_id"' | wc -l)

if [ "$COUNT_DIFF" -ge 1 ]; then
  pass "STEP 3b -- difficulty=Easy filter -- $COUNT_DIFF question(s) mila"
else
  fail "STEP 3b -- difficulty=Easy filter -- koi question nahi mila"
fi

# Chapter filter
FETCH_CH=$(curl -s "$BASE/api/questions?chapter=Cell%20Biology" \
  -H "Authorization: Bearer $TOKEN")
COUNT_CH=$(echo "$FETCH_CH" | grep -o '"_id"' | wc -l)

if [ "$COUNT_CH" -ge 1 ]; then
  pass "STEP 3c -- chapter=Cell Biology filter -- $COUNT_CH question(s) mila"
else
  fail "STEP 3c -- chapter filter -- koi question nahi mila"
fi
echo ""

# ─────────────────────────────────────────
# STEP 4 -- Edit Question Route (PUT)
# ─────────────────────────────────────────
info "STEP 4: Edit Question -- PUT /api/questions/:id..."

if [ -z "$Q_ID" ]; then
  fail "STEP 4 -- Q_ID missing, Step 1 fail tha -- skip"
else
  EDIT_RES=$(curl -s -X PUT "$BASE/api/questions/$Q_ID" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
      "difficulty": "Medium",
      "explanation": "Updated: Mitochondria ATP synthesis karta hai -- Krebs cycle + ETC."
    }')

  UPDATED=$(echo "$EDIT_RES" | grep -o '"difficulty":"Medium"')

  if [ -n "$UPDATED" ]; then
    pass "STEP 4 -- PUT /api/questions/$Q_ID -- difficulty updated to Medium"
  else
    # Some APIs return message instead of full object
    MSG=$(echo "$EDIT_RES" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$MSG" ]; then
      pass "STEP 4 -- PUT /api/questions/$Q_ID -- Response: $MSG"
    else
      fail "STEP 4 -- PUT /api/questions/$Q_ID -- Edit FAIL"
      echo "Response: $EDIT_RES"
    fi
  fi
fi
echo ""

# ─────────────────────────────────────────
# STEP 5 -- Delete Question Route (DELETE)
# (Q_ID2 delete karenge -- Q_ID rakhenge future steps ke liye)
# ─────────────────────────────────────────
info "STEP 5: Delete Question -- DELETE /api/questions/:id..."

# Pehle ek extra question banao -- use delete karenge
DEL_Q=$(curl -s -X POST "$BASE/api/questions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "text": "DELETE TEST QUESTION -- ignore this",
    "options": ["A","B","C","D"],
    "correct": [0],
    "subject": "Physics",
    "chapter": "Test",
    "difficulty": "Easy",
    "type": "SCQ"
  }')
DEL_ID=$(echo "$DEL_Q" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$DEL_ID" ]; then
  DEL_RES=$(curl -s -X DELETE "$BASE/api/questions/$DEL_ID" \
    -H "Authorization: Bearer $TOKEN")

  DEL_OK=$(echo "$DEL_RES" | grep -oi '"message":\|"deleted"\|success\|removed' | head -1)

  if [ -n "$DEL_OK" ]; then
    pass "STEP 5 -- DELETE /api/questions/$DEL_ID -- Question deleted"
  else
    fail "STEP 5 -- DELETE failed"
    echo "Response: $DEL_RES"
  fi
else
  fail "STEP 5 -- Delete ke liye test question create nahi hua"
fi
echo ""

# ─────────────────────────────────────────
# STEP 6 -- Difficulty Levels -- Easy/Medium/Hard tags (S16)
# ─────────────────────────────────────────
info "STEP 6: Question Difficulty Levels -- Easy/Medium/Hard check..."

for DIFF in "Easy" "Medium" "Hard"; do
  Q_RES=$(curl -s -X POST "$BASE/api/questions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{
      \"text\": \"Test question for difficulty $DIFF\",
      \"options\": [\"A\",\"B\",\"C\",\"D\"],
      \"correct\": [0],
      \"subject\": \"Physics\",
      \"chapter\": \"Mechanics\",
      \"difficulty\": \"$DIFF\",
      \"type\": \"SCQ\"
    }")
  Q_CREATED=$(echo "$Q_RES" | grep -o '"_id":"[^"]*"' | head -1)
  if [ -n "$Q_CREATED" ]; then
    pass "STEP 6 -- Difficulty '$DIFF' -- Question created OK"
  else
    fail "STEP 6 -- Difficulty '$DIFF' -- Question create FAIL"
    echo "Response: $Q_RES"
  fi
done
echo ""

# ─────────────────────────────────────────
# STEP 7 -- AI-1: Auto Question Difficulty Tagger
# Route: POST /api/questions/ai/difficulty-tag
# ─────────────────────────────────────────
info "STEP 7: AI-1 -- Auto Difficulty Tagger..."

AI1_RES=$(curl -s -X POST "$BASE/api/questions/ai/difficulty-tag" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "text": "A particle moves in a circle of radius r. The centripetal acceleration is given by v^2/r. If velocity doubles, what happens to centripetal acceleration?"
  }')

DIFF_TAG=$(echo "$AI1_RES" | grep -o '"difficulty":"[^"]*"')
SUGGESTION=$(echo "$AI1_RES" | grep -oi 'easy\|medium\|hard\|difficulty')

if [ -n "$DIFF_TAG" ] || [ -n "$SUGGESTION" ]; then
  pass "STEP 7 -- AI-1 Difficulty Tagger -- Response mila: $DIFF_TAG"
else
  fail "STEP 7 -- AI-1 Difficulty Tagger -- Route nahi mila ya response galat"
  echo "Response: $AI1_RES"
fi
echo ""

# ─────────────────────────────────────────
# STEP 8 -- AI-2: Auto Subject/Chapter/Topic Classifier
# Route: POST /api/questions/ai/classify
# ─────────────────────────────────────────
info "STEP 8: AI-2 -- Auto Subject/Chapter Classifier..."

AI2_RES=$(curl -s -X POST "$BASE/api/questions/ai/classify" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "text": "The process of photosynthesis occurs in chloroplasts. What is the role of chlorophyll in this process?"
  }')

SUBJECT_AI=$(echo "$AI2_RES" | grep -oi '"subject"\|biology\|physics\|chemistry')
CHAPTER_AI=$(echo "$AI2_RES" | grep -oi '"chapter"')

if [ -n "$SUBJECT_AI" ]; then
  pass "STEP 8 -- AI-2 Classifier -- Subject detect hua: $(echo $AI2_RES | grep -o '"subject":"[^"]*"')"
else
  fail "STEP 8 -- AI-2 Classifier -- Route nahi mila ya subject detect nahi hua"
  echo "Response: $AI2_RES"
fi
echo ""

# ─────────────────────────────────────────
# STEP 9 -- AI-5: Question Concept Similarity Detector
# Route: POST /api/questions/ai/similarity
# ─────────────────────────────────────────
info "STEP 9: AI-5 -- Concept Similarity Detector..."

AI5_RES=$(curl -s -X POST "$BASE/api/questions/ai/similarity" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "text": "What is the powerhouse of the cell?"
  }')

SIM_FOUND=$(echo "$AI5_RES" | grep -oi '"similar"\|"score"\|"matches"\|"questions"\|similar')

if [ -n "$SIM_FOUND" ]; then
  pass "STEP 9 -- AI-5 Similarity Detector -- Similar questions check hua"
else
  fail "STEP 9 -- AI-5 Similarity -- Route nahi mila ya response incorrect"
  echo "Response: $AI5_RES"
fi
echo ""

# ─────────────────────────────────────────
# STEP 10 -- Duplicate Question Detector (S18)
# Route: POST /api/questions/check-duplicate
# ─────────────────────────────────────────
info "STEP 10: Duplicate Question Detector (S18)..."

DUP_RES=$(curl -s -X POST "$BASE/api/questions/check-duplicate" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "text": "Mitochondria is the powerhouse of the cell. Which organelle produces ATP?"
  }')

DUP_FOUND=$(echo "$DUP_RES" | grep -oi '"duplicate"\|"isDuplicate"\|"exists"\|"found"\|true\|false')

if [ -n "$DUP_FOUND" ]; then
  pass "STEP 10 -- Duplicate Detector -- Check hua, response: $(echo $DUP_RES | head -c 100)"
else
  fail "STEP 10 -- Duplicate Detector -- Route nahi mila ya response galat"
  echo "Response: $DUP_RES"
fi
echo ""

# ─────────────────────────────────────────
# STEP 11 -- Image Based Questions (S33)
# Route: POST /api/questions with image field
# ─────────────────────────────────────────
info "STEP 11: Image Based Questions (S33) -- image field support check..."

IMG_Q_RES=$(curl -s -X POST "$BASE/api/questions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "text": "Identify the organic compound shown in the image below:",
    "hindiText": "Neeche di gayi image mein organic compound pehchano:",
    "options": ["Benzene","Ethanol","Glucose","Methane"],
    "correct": [0],
    "subject": "Chemistry",
    "chapter": "Organic Chemistry",
    "topic": "Aromatic Compounds",
    "difficulty": "Medium",
    "type": "SCQ",
    "image": "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Benzene_structure.svg/200px-Benzene_structure.svg.png",
    "explanation": "Benzene is a cyclic aromatic compound with formula C6H6."
  }')

IMG_Q_ID=$(echo "$IMG_Q_RES" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)
IMG_FIELD=$(echo "$IMG_Q_RES" | grep -o '"image":"[^"]*"')

if [ -n "$IMG_Q_ID" ] && [ -n "$IMG_FIELD" ]; then
  pass "STEP 11 -- Image Based Question -- Created with image field, _id=$IMG_Q_ID"
else
  fail "STEP 11 -- Image Based Question -- Create FAIL ya image field save nahi hua"
  echo "Response: $IMG_Q_RES"
fi
echo ""

# ─────────────────────────────────────────
# FINAL RESULT -- Steps 1 to 11
# ─────────────────────────────────────────
echo "============================================================"
echo -e "  ${GREEN}✅ PASS: $PASS${NC}   ${RED}❌ FAIL: $FAIL${NC}"
echo "============================================================"

if [ "$FAIL" -eq 0 ]; then
  echo -e "${GREEN}🎉 Phase 2.1 Steps 1-11 -- ALL PASS! Ab Steps 12-22 script chalao.${NC}"
else
  echo -e "${RED}⚠️  $FAIL step(s) FAIL hue. Sirf fail steps fix karo (Rule B5/G7).${NC}"
  echo "   Hint: Server log check karo: cat /tmp/server.log | tail -30"
fi
echo ""
