#!/bin/bash

# ============================================================
# ProveRank -- Phase 2.1 Test Script -- Steps 12 to 22
# Question Model & AI Intelligence (Continued)
# Run: cd ~/workspace && bash test_phase_2_1_steps_12_to_22.sh
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
echo "  ProveRank -- Phase 2.1 Test -- Steps 12 to 22"
echo "  Question Model & AI Intelligence (Continued)"
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

pass "SuperAdmin Login -- Token mila, role=$ROLE"
echo ""

# ─────────────────────────────────────────
# Setup: Test Question Create karenge Steps 12+ ke liye
# ─────────────────────────────────────────
info "Setup: Base test question create kar rahe hain..."

BASE_Q=$(curl -s -X POST "$BASE/api/questions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "text": "Which of the following is correct about Newton law of motion?",
    "options": ["F=ma","F=mv","F=m/a","F=a/m"],
    "correct": [0],
    "subject": "Physics",
    "chapter": "Laws of Motion",
    "topic": "Newton Laws",
    "difficulty": "Easy",
    "type": "SCQ",
    "tags": ["newton","force","mass","acceleration"],
    "explanation": "Newton 2nd law: F = ma"
  }')

Q_ID=$(echo "$BASE_Q" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$Q_ID" ]; then
  info "Base question ready -- _id=$Q_ID"
else
  info "Base question create nahi hua -- kuch steps existing data pe chalenge"
fi
echo ""

# ─────────────────────────────────────────
# STEP 12 -- Question Tags & Search
# Routes: POST with tags, GET /api/questions?tags=xxx
# ─────────────────────────────────────────
info "STEP 12: Question Tags & Search..."

# Tag wali question create
TAG_Q=$(curl -s -X POST "$BASE/api/questions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "text": "Explain the concept of osmosis in cell biology context.",
    "options": ["Water moves high to low conc","Water moves low to high conc","Both A and B","None"],
    "correct": [0],
    "subject": "Biology",
    "chapter": "Cell Transport",
    "difficulty": "Medium",
    "type": "SCQ",
    "tags": ["osmosis","cell","biology","transport"]
  }')

TAG_Q_ID=$(echo "$TAG_Q" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)

# Tags se search
SEARCH_RES=$(curl -s "$BASE/api/questions?tags=osmosis" \
  -H "Authorization: Bearer $TOKEN")
TAG_COUNT=$(echo "$SEARCH_RES" | grep -o '"_id"' | wc -l)

# Text search
TEXT_SEARCH=$(curl -s "$BASE/api/questions?search=osmosis" \
  -H "Authorization: Bearer $TOKEN")
TEXT_COUNT=$(echo "$TEXT_SEARCH" | grep -o '"_id"' | wc -l)

if [ -n "$TAG_Q_ID" ]; then
  pass "STEP 12a -- Tags field save hua -- _id=$TAG_Q_ID"
else
  fail "STEP 12a -- Tag question create FAIL"
fi

if [ "$TAG_COUNT" -ge 1 ] || [ "$TEXT_COUNT" -ge 1 ]; then
  pass "STEP 12b -- Tags/Search filter working -- results mile"
else
  fail "STEP 12b -- Tags search/filter -- koi result nahi"
  echo "Tags response: $SEARCH_RES"
fi
echo ""

# ─────────────────────────────────────────
# STEP 13 -- Question Usage Tracker (S35)
# Route: GET /api/questions/:id/usage
# ─────────────────────────────────────────
info "STEP 13: Question Usage Tracker (S35)..."

if [ -n "$Q_ID" ]; then
  USAGE_RES=$(curl -s "$BASE/api/questions/$Q_ID/usage" \
    -H "Authorization: Bearer $TOKEN")

  USAGE_FOUND=$(echo "$USAGE_RES" | grep -oi '"usageCount"\|"accuracy"\|"exams"\|"lastUsed"\|usagecount')

  if [ -n "$USAGE_FOUND" ]; then
    pass "STEP 13 -- Usage Tracker -- Route working, data: $(echo $USAGE_RES | head -c 120)"
  else
    # Try alternate -- usageCount in question detail
    Q_DETAIL=$(curl -s "$BASE/api/questions/$Q_ID" \
      -H "Authorization: Bearer $TOKEN")
    USAGE_IN_Q=$(echo "$Q_DETAIL" | grep -oi '"usageCount"')
    if [ -n "$USAGE_IN_Q" ]; then
      pass "STEP 13 -- usageCount field question detail mein hai"
    else
      fail "STEP 13 -- Usage Tracker -- Route ya usageCount field missing"
      echo "Response: $USAGE_RES"
    fi
  fi
else
  fail "STEP 13 -- Q_ID nahi hai -- skip"
fi
echo ""

# ─────────────────────────────────────────
# STEP 14 -- Question Version History (S87)
# Route: GET /api/questions/:id/versions
# ─────────────────────────────────────────
info "STEP 14: Question Version History (S87) -- edit history check..."

if [ -n "$Q_ID" ]; then
  # Pehle edit karo
  curl -s -X PUT "$BASE/api/questions/$Q_ID" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"difficulty":"Hard","explanation":"Updated for version test."}' > /dev/null

  # Version history fetch
  VER_RES=$(curl -s "$BASE/api/questions/$Q_ID/versions" \
    -H "Authorization: Bearer $TOKEN")

  VER_FOUND=$(echo "$VER_RES" | grep -oi '"version"\|"versions"\|"history"\|"editHistory"\|"changedAt"')

  if [ -n "$VER_FOUND" ]; then
    pass "STEP 14 -- Version History -- Route working: $(echo $VER_RES | head -c 120)"
  else
    fail "STEP 14 -- Version History (S87) -- Route nahi mila"
    echo "Response: $VER_RES"
  fi
else
  fail "STEP 14 -- Q_ID nahi -- skip"
fi
echo ""

# ─────────────────────────────────────────
# STEP 15 -- Multi-Select Questions (MSQ) (S90)
# JEE Advanced style partial marking
# ─────────────────────────────────────────
info "STEP 15: MSQ -- Multi-Select Questions (S90)..."

MSQ_RES=$(curl -s -X POST "$BASE/api/questions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "text": "Which of the following are properties of metals? (Select all correct)",
    "options": ["Good conductor of electricity","High melting point","Lustrous","Poor thermal conductor"],
    "correct": [0, 1, 2],
    "subject": "Chemistry",
    "chapter": "Metals and Non-Metals",
    "difficulty": "Medium",
    "type": "MSQ",
    "explanation": "Metals are good conductors, lustrous, and generally have high melting points."
  }')

MSQ_ID=$(echo "$MSQ_RES" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)
MSQ_TYPE=$(echo "$MSQ_RES" | grep -o '"type":"MSQ"')

if [ -n "$MSQ_ID" ] && [ -n "$MSQ_TYPE" ]; then
  pass "STEP 15 -- MSQ Question created -- _id=$MSQ_ID, type=MSQ, correct=[0,1,2]"
else
  fail "STEP 15 -- MSQ Question create FAIL"
  echo "Response: $MSQ_RES"
fi
echo ""

# ─────────────────────────────────────────
# STEP 16 -- Integer Type Questions
# Numerical answer input
# ─────────────────────────────────────────
info "STEP 16: Integer Type Questions -- Numerical answer..."

INT_RES=$(curl -s -X POST "$BASE/api/questions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "text": "A body of mass 5 kg is acted upon by a force of 20N. Calculate acceleration in m/s^2.",
    "options": [],
    "correct": [4],
    "subject": "Physics",
    "chapter": "Laws of Motion",
    "topic": "Newton Laws",
    "difficulty": "Easy",
    "type": "Integer",
    "integerAnswer": 4,
    "explanation": "F=ma => a = F/m = 20/5 = 4 m/s^2"
  }')

INT_ID=$(echo "$INT_RES" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)
INT_TYPE=$(echo "$INT_RES" | grep -o '"type":"Integer"')

if [ -n "$INT_ID" ]; then
  pass "STEP 16 -- Integer Type Question created -- _id=$INT_ID"
else
  fail "STEP 16 -- Integer Type Question create FAIL"
  echo "Response: $INT_RES"
fi
echo ""

# ─────────────────────────────────────────
# STEP 17 -- Previous Year Questions (PYQ) Bank (S104)
# Route: GET /api/questions?sourceExam=NEET 2022
# ─────────────────────────────────────────
info "STEP 17: PYQ Bank (S104) -- sourceExam filter check..."

# PYQ question add
PYQ_ADD=$(curl -s -X POST "$BASE/api/questions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "text": "In NEET 2023, which hormone is responsible for blood glucose regulation?",
    "options": ["Insulin","Glucagon","Cortisol","Thyroxine"],
    "correct": [0],
    "subject": "Biology",
    "chapter": "Endocrine System",
    "difficulty": "Medium",
    "type": "SCQ",
    "sourceExam": "NEET 2023",
    "tags": ["PYQ","NEET 2023","hormone","insulin"]
  }')

PYQ_ID=$(echo "$PYQ_ADD" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)

# Filter by sourceExam
PYQ_FETCH=$(curl -s "$BASE/api/questions?sourceExam=NEET%202023" \
  -H "Authorization: Bearer $TOKEN")
PYQ_COUNT=$(echo "$PYQ_FETCH" | grep -o '"_id"' | wc -l)

if [ -n "$PYQ_ID" ]; then
  pass "STEP 17a -- PYQ Question added with sourceExam -- _id=$PYQ_ID"
else
  fail "STEP 17a -- PYQ Question add FAIL"
fi

if [ "$PYQ_COUNT" -ge 1 ]; then
  pass "STEP 17b -- sourceExam=NEET 2023 filter -- $PYQ_COUNT question(s) mila"
else
  fail "STEP 17b -- PYQ filter -- koi result nahi"
  echo "Response: $PYQ_FETCH"
fi
echo ""

# ─────────────────────────────────────────
# STEP 18 -- Question Error Reporting (S84)
# Student exam mein question report kare
# Route: POST /api/questions/:id/report
# ─────────────────────────────────────────
info "STEP 18: Question Error Reporting (S84)..."

# Student login
STU_LOGIN=$(curl -s -X POST "$BASE/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"student@proverank.com","password":"ProveRank@123"}')

STU_TOKEN=$(echo "$STU_LOGIN" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$STU_TOKEN" ]; then
  fail "STEP 18 -- Student login fail -- skip"
else
  REPORT_Q_ID=${Q_ID:-$MSQ_ID}
  if [ -n "$REPORT_Q_ID" ]; then
    REPORT_RES=$(curl -s -X POST "$BASE/api/questions/$REPORT_Q_ID/report" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $STU_TOKEN" \
      -d '{
        "issue": "Wrong answer key",
        "description": "Option A should be correct but answer key shows B"
      }')

    REPORT_OK=$(echo "$REPORT_RES" | grep -oi '"message"\|"report"\|success\|created')

    if [ -n "$REPORT_OK" ]; then
      pass "STEP 18 -- Error Report (S84) -- Report submitted OK"
    else
      fail "STEP 18 -- Error Report -- Route nahi mila"
      echo "Response: $REPORT_RES"
    fi
  else
    fail "STEP 18 -- No question ID available to report"
  fi
fi
echo ""

# ─────────────────────────────────────────
# STEP 19 -- AI-8: Auto Hindi-English Translator
# Route: POST /api/questions/ai/translate
# ─────────────────────────────────────────
info "STEP 19: AI-8 -- Auto Hindi-English Translator..."

TRANS_RES=$(curl -s -X POST "$BASE/api/questions/ai/translate" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "text": "What is the process of photosynthesis?",
    "targetLanguage": "hi"
  }')

TRANS_OK=$(echo "$TRANS_RES" | grep -oi '"translatedText"\|"translation"\|"result"\|translated')

if [ -n "$TRANS_OK" ]; then
  pass "STEP 19 -- AI-8 Translator -- Route working: $(echo $TRANS_RES | head -c 120)"
else
  fail "STEP 19 -- AI-8 Translator -- Route nahi mila"
  echo "Response: $TRANS_RES"
fi
echo ""

# ─────────────────────────────────────────
# STEP 20 -- AI-10: Auto Explanation Generator
# Hugging Face / AI se explanation generate
# Route: POST /api/questions/ai/explain
# ─────────────────────────────────────────
info "STEP 20: AI-10 -- Auto Explanation Generator..."

EXPLAIN_RES=$(curl -s -X POST "$BASE/api/questions/ai/explain" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "text": "Which organelle is the powerhouse of the cell?",
    "correct": "Mitochondria"
  }')

EXPLAIN_OK=$(echo "$EXPLAIN_RES" | grep -oi '"explanation"\|"generated"\|"result"')

if [ -n "$EXPLAIN_OK" ]; then
  pass "STEP 20 -- AI-10 Explanation Generator -- Route working"
else
  fail "STEP 20 -- AI-10 Explanation Generator -- Route nahi mila"
  echo "Response: $EXPLAIN_RES"
fi
echo ""

# ─────────────────────────────────────────
# STEP 21 -- N7: Question Approval Workflow
# Sub-admin adds -> SuperAdmin approves/rejects
# Routes: GET /api/questions/pending
#         POST /api/questions/:id/approve
#         POST /api/questions/:id/reject
# ─────────────────────────────────────────
info "STEP 21: N7 -- Question Approval Workflow..."

# Add question with approvalStatus: pending
PEND_Q=$(curl -s -X POST "$BASE/api/questions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "text": "Approval workflow test question -- Newton 3rd law?",
    "options": ["Every action has equal opposite reaction","F=ma","v=u+at","None"],
    "correct": [0],
    "subject": "Physics",
    "chapter": "Laws of Motion",
    "difficulty": "Easy",
    "type": "SCQ",
    "approvalStatus": "pending"
  }')

PEND_ID=$(echo "$PEND_Q" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)

# Fetch pending queue
PEND_LIST=$(curl -s "$BASE/api/questions/pending" \
  -H "Authorization: Bearer $TOKEN")
PEND_COUNT=$(echo "$PEND_LIST" | grep -o '"_id"' | wc -l)

if [ -n "$PEND_ID" ]; then
  pass "STEP 21a -- Pending question created -- _id=$PEND_ID"
else
  fail "STEP 21a -- Pending question create FAIL"
fi

if [ "$PEND_COUNT" -ge 1 ]; then
  pass "STEP 21b -- GET /api/questions/pending -- $PEND_COUNT pending question(s) mila"
else
  fail "STEP 21b -- Pending queue route missing ya empty"
  echo "Response: $PEND_LIST"
fi

# Approve test
if [ -n "$PEND_ID" ]; then
  APPROVE_RES=$(curl -s -X POST "$BASE/api/questions/$PEND_ID/approve" \
    -H "Authorization: Bearer $TOKEN")
  APPROVE_OK=$(echo "$APPROVE_RES" | grep -oi '"message"\|approved\|success')
  if [ -n "$APPROVE_OK" ]; then
    pass "STEP 21c -- Approve route working -- $PEND_ID approved"
  else
    fail "STEP 21c -- Approve route missing"
    echo "Response: $APPROVE_RES"
  fi
fi
echo ""

# ─────────────────────────────────────────
# STEP 22 -- Question Bank Import from XML/Moodle (M11)
# Route: POST /api/questions/import/moodle
# ─────────────────────────────────────────
info "STEP 22: M11 -- XML/Moodle Import..."

MOODLE_XML='<?xml version="1.0" ?><quiz><question type="multichoice"><name><text>Test Moodle Q</text></name><questiontext format="html"><text>What is 2+2?</text></questiontext><answer fraction="100"><text>4</text></answer><answer fraction="0"><text>3</text></answer></question></quiz>'

MOODLE_RES=$(curl -s -X POST "$BASE/api/questions/import/moodle" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"xmlContent\": \"$MOODLE_XML\"}")

MOODLE_OK=$(echo "$MOODLE_RES" | grep -oi '"imported"\|"questions"\|"success"\|"count"\|"message"')

if [ -n "$MOODLE_OK" ]; then
  pass "STEP 22 -- Moodle XML Import (M11) -- Route working: $(echo $MOODLE_RES | head -c 120)"
else
  # Try XML/Moodle alternate route
  MOODLE_ALT=$(curl -s -X POST "$BASE/api/questions/import/xml" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{\"xmlContent\": \"$MOODLE_XML\"}")
  ALT_OK=$(echo "$MOODLE_ALT" | grep -oi '"imported"\|"message"\|success')
  if [ -n "$ALT_OK" ]; then
    pass "STEP 22 -- XML Import alternate route -- working"
  else
    fail "STEP 22 -- Moodle/XML Import (M11) -- Route nahi mila"
    echo "Main Response: $MOODLE_RES"
    echo "Alt Response: $MOODLE_ALT"
  fi
fi
echo ""

# ─────────────────────────────────────────
# FINAL RESULT -- Steps 12 to 22
# ─────────────────────────────────────────
echo "============================================================"
echo -e "  ${GREEN}✅ PASS: $PASS${NC}   ${RED}❌ FAIL: $FAIL${NC}"
echo "============================================================"

if [ "$FAIL" -eq 0 ]; then
  echo -e "${GREEN}🎉 Phase 2.1 Steps 12-22 -- ALL PASS!${NC}"
  echo -e "${GREEN}🚀 Phase 2.1 COMPLETE -- Git push karo aur Phase 2.2 shuru karo!${NC}"
  echo ""
  echo "  Git push commands:"
  echo "  cd ~/workspace"
  echo "  git add ."
  echo '  git commit -m "Phase 2.1 PASS -- Question Model & AI Intelligence complete"'
  echo "  git push"
else
  echo -e "${RED}⚠️  $FAIL step(s) FAIL hue.${NC}"
  echo "  Hint: Sirf FAIL steps fix karo (Rule B5 / G7)"
  echo "  Server log: cat /tmp/server.log | tail -30"
fi
echo ""
