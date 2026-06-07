#!/bin/bash
echo "══════════════════════════════════════════"
echo "🔍 Finding Main Component Tab Structure"
echo "══════════════════════════════════════════"

FILE=~/workspace/frontend/app/admin/x7k2p/page.tsx

echo ""
echo "── 1. All export default / main component ──"
grep -n "export default\|function Admin\|const Admin\|export function" $FILE | head -10

echo ""
echo "── 2. How tab content is rendered (map/switch/ternary) ──"
grep -n "tab\]\|tab)\|tabMap\|TABS\[tab\]\|\[tab\]\|switch.*tab\|case '" $FILE | head -20

echo ""
echo "── 3. Lines around useState('overview') ──"
grep -n "overview\|setTab\|useState('over" $FILE | head -10

echo ""
echo "── 4. Last 50 lines of main component return ──"
# Find last 'export default' or main return
TOTAL=$(wc -l < $FILE)
echo "Total lines: $TOTAL"
tail -80 $FILE | head -60

echo ""
echo "── 5. Lines containing 'tab' with component names ──"
grep -n "tab.*<[A-Z]\|<[A-Z].*tab" $FILE | head -20

echo ""
echo "── 6. Current wrong position ──"
grep -n "StoreAdminTab\|store.*Store" $FILE | head -10

echo "══════════════════════════════════════════"
