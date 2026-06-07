#!/bin/bash
echo "══════════════════════════════════════════"
echo "🔍 STORE SETUP DIAGNOSIS"
echo "══════════════════════════════════════════"

echo ""
echo "── 1. Admin page.tsx — activeTab patterns ──"
grep -n "activeTab" ~/workspace/frontend/app/admin/x7k2p/page.tsx | tail -20

echo ""
echo "── 2. Admin page.tsx — last 30 lines of tab renders ──"
grep -n "activeTab ===" ~/workspace/frontend/app/admin/x7k2p/page.tsx | tail -15

echo ""
echo "── 3. StudentShell — find all Shell/layout files ──"
find ~/workspace/frontend -name "*.tsx" | xargs grep -l "dashboard" 2>/dev/null | grep -i "shell\|layout\|nav" | head -10

echo ""
echo "── 4. StudentShell — find nav href patterns ──"
find ~/workspace/frontend/app/dashboard -name "*.tsx" -not -path "*/store/*" | head -10

echo ""
echo "── 5. Check if store/page.tsx exists ──"
ls -la ~/workspace/frontend/app/dashboard/store/

echo ""
echo "── 6. StudentShell exact file check ──"
find ~/workspace/frontend -name "StudentShell*" -o -name "*Shell*" 2>/dev/null | head -5

echo "══════════════════════════════════════════"
echo "✅ Diagnosis Complete — Screenshot lo"
echo "══════════════════════════════════════════"
