#!/bin/bash
# ProveRank — Remove "2026" from Auth Pages (Direct Fix)
G='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; N='\033[0m'

LOGIN=~/workspace/frontend/app/login/page.tsx
REG=~/workspace/frontend/app/register/page.tsx

echo -e "${Y}Checking file locations...${N}"
ls "$LOGIN" && echo -e "${G}✓ login found${N}" || echo -e "${R}✗ login NOT found at $LOGIN${N}"
ls "$REG"   && echo -e "${G}✓ register found${N}" || echo -e "${R}✗ register NOT found at $REG${N}"

echo -e "\n${Y}Removing 2026 from login page...${N}"
python3 -c "
import re, sys
f = open('$LOGIN', 'r')
c = f.read()
f.close()
c2 = c.replace('NEET 2026 Preparation Platform', 'NEET Preparation Platform')
c2 = c2.replace('NEET 2026', 'NEET')
c2 = c2.replace('· 2026 ·', '·')
c2 = c2.replace(' 2026 ', ' ')
c2 = c2.replace('·2026·', '·')
if c2 != c:
    open('$LOGIN', 'w').write(c2)
    print('✓ login page — 2026 removed')
else:
    print('– login page — no 2026 found (already clean or check path)')
"

echo -e "\n${Y}Removing 2026 from register page...${N}"
python3 -c "
import re, sys
f = open('$REG', 'r')
c = f.read()
f.close()
c2 = c.replace('NEET 2026 Preparation Platform', 'NEET Preparation Platform')
c2 = c2.replace('NEET 2026', 'NEET')
c2 = c2.replace('· 2026 ·', '·')
c2 = c2.replace(' 2026 ', ' ')
c2 = c2.replace('·2026·', '·')
if c2 != c:
    open('$REG', 'w').write(c2)
    print('✓ register page — 2026 removed')
else:
    print('– register page — no 2026 found (already clean or check path)')
"

echo ""
echo -e "${Y}Verifying — searching for any remaining '2026' in both files:${N}"
grep -n "2026" "$LOGIN" && echo -e "${R}^ 2026 still found in login!${N}" || echo -e "${G}✓ login page — 2026 completely gone${N}"
grep -n "2026" "$REG"   && echo -e "${R}^ 2026 still found in register!${N}" || echo -e "${G}✓ register page — 2026 completely gone${N}"

echo ""
echo -e "${Y}Now push to deploy:${N}"
echo "cd ~/workspace/frontend && git add -A && git commit -m 'fix: remove 2026 everywhere' && git push"
