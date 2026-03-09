FRONTEND="$HOME/workspace/frontend"
PASS=0; FAIL=0; WARN=0
GREEN="\033[0;32m"; RED="\033[0;31m"; YELLOW="\033[1;33m"; CYAN="\033[0;36m"; BOLD="\033[1m"; RESET="\033[0m"
pass() { echo -e "  ${GREEN}✅ PASS${RESET} — $1"; ((PASS++)); }
fail() { echo -e "  ${RED}❌ FAIL${RESET} — $1"; ((FAIL++)); }
warn() { echo -e "  ${YELLOW}⚠️  WARN${RESET} — $1"; ((WARN++)); }
section() { echo -e "\n${CYAN}${BOLD}▶ $1${RESET}"; }
section "STEP 1 — Folder & Framework"
[ -d "$FRONTEND" ] && pass "Frontend folder exists" || fail "Frontend folder MISSING"
[ -f "$FRONTEND/package.json" ] && pass "package.json exists" || fail "package.json MISSING"
if [ -f "$FRONTEND/package.json" ]; then
  NEXT_VER=$(grep '"next"' "$FRONTEND/package.json" | grep -o '"[0-9][^"]*"' | tr -d '"')
  [ -n "$NEXT_VER" ] && pass "Next.js found: $NEXT_VER" || fail "Next.js MISSING"
  grep -q "tailwindcss" "$FRONTEND/package.json" && pass "Tailwind found" || fail "Tailwind MISSING"
  grep -q "typescript" "$FRONTEND/package.json" && pass "TypeScript found" || warn "TypeScript devDeps mein hoga"
fi
[ -f "$FRONTEND/tailwind.config.ts" ] || [ -f "$FRONTEND/tailwind.config.js" ] && pass "Tailwind config found" || fail "tailwind.config MISSING"
[ -f "$FRONTEND/tsconfig.json" ] && pass "tsconfig.json found" || fail "tsconfig.json MISSING"
section "STEP 2 — Login Page"
[ -f "$FRONTEND/app/login/page.tsx" ] && pass "Login page exists" || fail "Login page MISSING"
if [ -f "$FRONTEND/app/login/page.tsx" ]; then
  grep -qi "backdrop-blur\|glass" "$FRONTEND/app/login/page.tsx" && pass "Glassmorphism found" || warn "Glassmorphism detect nahi hua"
  grep -qi "particle\|ParticlesBg\|canvas" "$FRONTEND/app/login/page.tsx" && pass "Particles found" || warn "Particles nahi mila"
fi
section "STEP 3 — Register Page"
[ -f "$FRONTEND/app/register/page.tsx" ] && pass "Register page exists" || fail "Register page MISSING"
if [ -f "$FRONTEND/app/register/page.tsx" ]; then
  grep -qi "otp\|OTP\|digit" "$FRONTEND/app/register/page.tsx" && pass "OTP logic found" || warn "OTP detect nahi hua"
fi
section "STEP 5 — JWT (lib/auth.ts)"
[ -f "$FRONTEND/lib/auth.ts" ] && pass "lib/auth.ts exists" || fail "lib/auth.ts MISSING"
AUTH_FILE=""; [ -f "$FRONTEND/lib/auth.ts" ] && AUTH_FILE="$FRONTEND/lib/auth.ts"
if [ -n "$AUTH_FILE" ]; then
  grep -q "pr_token" "$AUTH_FILE" && pass "'pr_token' key found" || fail "'pr_token' MISSING"
  grep -q "pr_role" "$AUTH_FILE" && pass "'pr_role' key found" || fail "'pr_role' MISSING"
fi
section "STEP 6 — Protected Routes (useAuth.ts)"
[ -f "$FRONTEND/lib/useAuth.ts" ] && pass "lib/useAuth.ts exists" || fail "lib/useAuth.ts MISSING"
section "STEP 7 — Terms Page"
[ -f "$FRONTEND/app/terms/page.tsx" ] && pass "Terms page exists" || fail "Terms page MISSING"
section "STEP 8 — Dark/Light Mode"
[ -f "$FRONTEND/lib/theme.ts" ] && pass "lib/theme.ts exists" || fail "lib/theme.ts MISSING"
THEME_FILE=""; [ -f "$FRONTEND/lib/theme.ts" ] && THEME_FILE="$FRONTEND/lib/theme.ts"
if [ -n "$THEME_FILE" ]; then
  grep -q "pr_theme" "$THEME_FILE" && pass "'pr_theme' key found" || fail "'pr_theme' MISSING"
fi
TOGGLE_FOUND=0
[ -f "$FRONTEND/components/ui/ThemeToggle.tsx" ] && TOGGLE_FOUND=1
[ -f "$FRONTEND/components/ThemeToggle.tsx" ] && TOGGLE_FOUND=1
[ "$TOGGLE_FOUND" -eq 1 ] && pass "ThemeToggle.tsx found" || fail "ThemeToggle.tsx MISSING"
section "STEP 9 — Custom 404 Page"
[ -f "$FRONTEND/app/not-found.tsx" ] && pass "not-found.tsx exists" || fail "not-found.tsx MISSING"
if [ -f "$FRONTEND/app/not-found.tsx" ]; then
  grep -qi "hexagon\|hex\|spin\|rotat" "$FRONTEND/app/not-found.tsx" && pass "Hexagon animation found" || warn "Hexagon animate detect nahi hua"
fi
section "EXTRA — layout + env + colors"
[ -f "$FRONTEND/app/layout.tsx" ] && pass "layout.tsx exists" || fail "layout.tsx MISSING"
[ -f "$FRONTEND/app/page.tsx" ] && pass "page.tsx exists" || fail "page.tsx MISSING"
[ -f "$FRONTEND/.env.local" ] && pass ".env.local exists" || warn ".env.local nahi mila"
CSS_FILE=""; [ -f "$FRONTEND/app/globals.css" ] && CSS_FILE="$FRONTEND/app/globals.css"
if [ -n "$CSS_FILE" ]; then
  grep -qi "000a18\|000A18" "$CSS_FILE" && pass "#000A18 color found" || warn "#000A18 nahi mila globals.css"
  grep -qi "4d9fff\|4D9FFF" "$CSS_FILE" && pass "#4D9FFF color found" || warn "#4D9FFF nahi mila globals.css"
fi
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${GREEN}✅ PASS : $PASS${RESET}  |  ${RED}❌ FAIL : $FAIL${RESET}  |  ${YELLOW}⚠️  WARN : $WARN${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
if [ "$FAIL" -eq 0 ]; then
  echo -e "${GREEN}${BOLD}🎉 Phase 7.1 VERIFIED! Phase 7.2 ready!${RESET}"
elif [ "$FAIL" -le 2 ]; then
  echo -e "${YELLOW}${BOLD}⚠️  $FAIL item(s) fix karo phir aage bado.${RESET}"
else
  echo -e "${RED}${BOLD}🚨 $FAIL FAIL items — pehle fix karo!${RESET}"
fi
