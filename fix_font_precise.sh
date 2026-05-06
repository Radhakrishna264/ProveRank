#!/bin/bash
# ProveRank — Precise fix: Playfair Display → Inter for numeric values
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'

DASH=~/workspace/frontend/app/dashboard/page.tsx

echo -e "${Y}Applying precise font fix...${N}"
node -e "
const fs = require('fs');
let c = fs.readFileSync('$DASH', 'utf8');
const before = c;

// FIX 1: StatCard value div - Playfair → Inter
// Exact match from source
c = c.replace(
  \`fontSize:26,fontWeight:800,color:col,fontFamily:'Playfair Display,serif',lineHeight:1,textShadow:\\\`0 0 20px \\\${col}44\\\`\`,
  \`fontSize:26,fontWeight:800,color:col,fontFamily:'Inter,sans-serif',lineHeight:1,textShadow:\\\`0 0 20px \\\${col}44\\\`\`
);

// FIX 2: Also target with slightly different spacing just in case
c = c.replace(
  \"fontFamily:'Playfair Display,serif',lineHeight:1,textShadow\",
  \"fontFamily:'Inter,sans-serif',lineHeight:1,textShadow\"
);

// FIX 3: Large daysLeft number in countdown - may use Playfair too
// Target: fontSize:22 or 28, color gold, Playfair - for the big number
c = c.replace(
  /(<span style=\{\{color:C\.gold[^}]*?)fontFamily:'Playfair Display,serif'([^}]*\}\}>)/g,
  (m, a, b) => a + \"fontFamily:'Inter,sans-serif'\" + b
);

const changed = c !== before;
fs.writeFileSync('$DASH', c, 'utf8');
console.log(changed ? '✓ Font fix applied!' : '⚠ No exact match found - checking alternate...');
"

echo -e "\n${Y}Verifying StatCard value font:${N}"
grep -n "fontFamily.*Playfair\|fontFamily.*Inter" "$DASH" | grep -A1 -B1 "26\|28\|value" | head -15

echo ""
echo -e "${Y}Deploy:${N}"
echo "cd ~/workspace/frontend && git add -A && git commit -m 'fix: StatCard use Inter font for numeric values' && git push"
