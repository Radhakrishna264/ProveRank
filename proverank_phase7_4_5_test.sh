#!/bin/bash
# ================================================
# ProveRank - Phase 7.4 + 7.5 Combined Test Script
# Tests all pages: Results/Analytics + Admin Panel
# ================================================

BASE_URL="http://localhost:3000"
PASS=0
FAIL=0

echo "======================================"
echo "  ProveRank Phase 7.4 + 7.5 Tests"
echo "======================================"
echo ""

# --- Helper function ---
check_url() {
  local url=$1
  local label=$2
  local code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null)
  if [ "$code" = "200" ]; then
    echo "✅ PASS - $label ($code)"
    PASS=$((PASS+1))
  else
    echo "❌ FAIL - $label ($code)"
    FAIL=$((FAIL+1))
  fi
}

check_file() {
  local path=$1
  local label=$2
  if [ -f "$path" ]; then
    local lines=$(wc -l < "$path")
    echo "✅ FILE OK - $label ($lines lines)"
    PASS=$((PASS+1))
  else
    echo "❌ FILE MISSING - $label"
    FAIL=$((FAIL+1))
  fi
}

content_check() {
  local file=$1
  local keyword=$2
  local label=$3
  if grep -q "$keyword" "$file" 2>/dev/null; then
    echo "✅ CONTENT OK - $label"
    PASS=$((PASS+1))
  else
    echo "❌ CONTENT MISS - $label"
    FAIL=$((FAIL+1))
  fi
}

# ================================================
# PHASE 7.4 - FILE CHECKS
# ================================================

echo "🟡 PHASE 7.4 - File Checks"
echo "------------------------------------"

FRONT=~/workspace/frontend/app

check_file "$FRONT/dashboard/results/[attemptId]/page.tsx" "Result Detail Page"
check_file "$FRONT/dashboard/results/history/page.tsx" "Result History Page"
check_file "$FRONT/dashboard/leaderboard/page.tsx" "Leaderboard Page"

echo ""

# ================================================
# PHASE 7.5 - FILE CHECKS
# ================================================

echo "🟡 PHASE 7.5 - File Checks"
echo "------------------------------------"

check_file "$FRONT/admin/layout.tsx" "Admin Layout + Sidebar"
check_file "$FRONT/admin/page.tsx" "Admin Dashboard"
check_file "$FRONT/admin/students/page.tsx" "Student Management"
check_file "$FRONT/admin/exams/page.tsx" "Exam Management"
check_file "$FRONT/admin/questions/page.tsx" "Question Bank"
check_file "$FRONT/admin/results/page.tsx" "Results Overview"
check_file "$FRONT/admin/announcements/page.tsx" "Announcements"
check_file "$FRONT/admin/settings/page.tsx" "Settings"

echo ""

# ================================================
# CONTENT CHECKS
# ================================================

echo "🔍 Content Checks"
echo "------------------------------------"

# Phase 7.4 content
content_check "$FRONT/dashboard/results/[attemptId]/page.tsx" "DonutChart" "R1: Donut Chart component"
content_check "$FRONT/dashboard/results/[attemptId]/page.tsx" "BarChart" "C2: Bar Chart component"
content_check "$FRONT/dashboard/results/[attemptId]/page.tsx" "AnswerRow" "A1: Answer Key component"
content_check "$FRONT/dashboard/results/[attemptId]/page.tsx" "percentile" "R1: Percentile stat"
content_check "$FRONT/dashboard/results/[attemptId]/page.tsx" "subjects" "R2: Subject breakdown"
content_check "$FRONT/dashboard/results/[attemptId]/page.tsx" "trend" "P1: Trend tab"
content_check "$FRONT/dashboard/results/history/page.tsx" "avgScore" "H1: History avg score"
content_check "$FRONT/dashboard/leaderboard/page.tsx" "Podium" "L1: Leaderboard podium"

echo ""

# Phase 7.5 content
content_check "$FRONT/admin/layout.tsx" "getRole" "Role protection check"
content_check "$FRONT/admin/layout.tsx" "NAV" "Sidebar navigation"
content_check "$FRONT/admin/page.tsx" "totalStudents" "Dashboard stats"
content_check "$FRONT/admin/page.tsx" "recentActivity" "Recent activity feed"
content_check "$FRONT/admin/students/page.tsx" "search" "Student search"
content_check "$FRONT/admin/students/page.tsx" "Deactivate" "Student deactivate button"
content_check "$FRONT/admin/exams/page.tsx" "statusColor" "Exam status colors"
content_check "$FRONT/admin/questions/page.tsx" "difficulty" "Question difficulty filter"
content_check "$FRONT/admin/announcements/page.tsx" "handleSend" "Send announcement function"
content_check "$FRONT/admin/settings/page.tsx" "ToggleSwitch" "Settings toggle component"
content_check "$FRONT/admin/settings/page.tsx" "negativeMarking" "Negative marking setting"

echo ""

# ================================================
# URL TESTS (frontend running honi chahiye)
# ================================================

echo "🌐 URL Tests (localhost:3000)"
echo "------------------------------------"
echo "Note: Frontend chalu hona chahiye..."
echo ""

# Phase 7.4 URLs
check_url "$BASE_URL/dashboard/results/test123" "Phase 7.4 - Result Detail Page"
check_url "$BASE_URL/dashboard/results/history" "Phase 7.4 - Result History Page"
check_url "$BASE_URL/dashboard/leaderboard" "Phase 7.4 - Leaderboard Page"

# Phase 7.5 URLs
check_url "$BASE_URL/admin/x7k2p" "Phase 7.5 - Admin Dashboard"
check_url "$BASE_URL/admin/students" "Phase 7.5 - Student Management"
check_url "$BASE_URL/admin/exams" "Phase 7.5 - Exam Management"
check_url "$BASE_URL/admin/questions" "Phase 7.5 - Question Bank"
check_url "$BASE_URL/admin/results" "Phase 7.5 - Results Overview"
check_url "$BASE_URL/admin/announcements" "Phase 7.5 - Announcements"
check_url "$BASE_URL/admin/settings" "Phase 7.5 - Settings"

echo ""
echo "======================================"
echo "  TEST SUMMARY"
echo "======================================"
echo "✅ PASS: $PASS"
echo "❌ FAIL: $FAIL"
TOTAL=$((PASS+FAIL))
SCORE=$((PASS*100/TOTAL))
echo "📊 Score: $SCORE% ($PASS/$TOTAL)"
echo ""

if [ $FAIL -eq 0 ]; then
  echo "🏆 ALL TESTS PASSED!"
  echo "Phase 7.4 ✅ + Phase 7.5 ✅ - COMPLETE!"
elif [ $SCORE -ge 80 ]; then
  echo "✅ PASS (with minor issues)"
  echo "$FAIL Tests failed - check above"
else
  echo "⚠️Some tests failed - script dobara chalao"
fi

echo "======================================"
