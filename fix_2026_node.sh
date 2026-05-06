#!/bin/bash
# ProveRank — Remove "2026" using Node.js (python3 not available on Replit)
G='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; N='\033[0m'

LOGIN=~/workspace/frontend/app/login/page.tsx
REG=~/workspace/frontend/app/register/page.tsx

echo -e "${Y}Removing 2026 from login page...${N}"
node -e "
const fs = require('fs');
const path = '$LOGIN';
let c = fs.readFileSync(path, 'utf8');
let c2 = c
  .replace(/NEET 2026 Preparation Platform/g, 'NEET Preparation Platform')
  .replace(/NEET 2026/g, 'NEET')
  .replace(/· 2026 ·/g, '·')
  .replace(/· 2026/g, '')
  .replace(/2026 ·/g, '')
  .replace(/\s*·\s*2026\s*/g, '')
  .replace(/2026/g, '');
fs.writeFileSync(path, c2, 'utf8');
console.log('✓ login page done');
"

echo -e "${Y}Removing 2026 from register page...${N}"
node -e "
const fs = require('fs');
const path = '$REG';
let c = fs.readFileSync(path, 'utf8');
let c2 = c
  .replace(/NEET 2026 Preparation Platform/g, 'NEET Preparation Platform')
  .replace(/NEET 2026/g, 'NEET')
  .replace(/· 2026 ·/g, '·')
  .replace(/· 2026/g, '')
  .replace(/2026 ·/g, '')
  .replace(/\s*·\s*2026\s*/g, '')
  .replace(/2026/g, '');
fs.writeFileSync(path, c2, 'utf8');
console.log('✓ register page done');
"

echo -e "\n${Y}Verifying — any 2026 left?${N}"
grep -n "2026" "$LOGIN" && echo -e "${R}✗ still found in login!${N}" || echo -e "${G}✓ login — CLEAN${N}"
grep -n "2026" "$REG"   && echo -e "${R}✗ still found in register!${N}" || echo -e "${G}✓ register — CLEAN${N}"

echo ""
echo -e "${Y}Now deploy:${N}"
echo "cd ~/workspace/frontend && git add -A && git commit -m 'fix: remove 2026' && git push"
