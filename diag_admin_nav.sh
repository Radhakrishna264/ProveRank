#!/bin/bash
echo "══════════════════════════════════════════"
echo "🔍 Admin Nav Structure Diagnosis"
echo "══════════════════════════════════════════"

FILE=~/workspace/frontend/app/admin/x7k2p/page.tsx

echo ""
echo "── 1. Nav section/group/category structure ──"
grep -n "section\|group\|category\|OVERVIEW\|EXAMS\|STORE\|SETTING" $FILE | grep -v "//" | head -30

echo ""
echo "── 2. Lines 295-320 (around Store nav item) ──"
sed -n '295,320p' $FILE

echo ""
echo "── 3. How sidebar renders nav items ──"
grep -n "navItem\|renderNav\|sideBar\|sidebar\|NavItem\|\.map.*label\|\.map.*tab" $FILE | head -20

echo ""
echo "── 4. Lines 1680-1750 (main sidebar render area) ──"
sed -n '1680,1750p' $FILE

echo ""
echo "── 5. Sidebar render — search for nav group rendering ──"
grep -n "group\|section\|category\|NAV\b" $FILE | grep -v "//\|import\|require" | head -20
echo "══════════════════════════════════════════"
