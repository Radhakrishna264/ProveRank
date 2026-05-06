#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  ProveRank Dashboard Fix                                    ║
# ║  FIX 1: Remove all "2026" from dashboard                   ║
# ║  FIX 2: Streak "od" → "0d" display fix                    ║
# ║  Uses Node.js (python3 not available on Replit)            ║
# ╚══════════════════════════════════════════════════════════════╝
G='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; N='\033[0m'

DASH=~/workspace/frontend/app/dashboard/page.tsx

echo -e "${Y}Checking file...${N}"
ls "$DASH" && echo -e "${G}✓ dashboard found${N}" || { echo -e "${R}✗ NOT found at $DASH${N}"; exit 1; }

echo -e "\n${Y}Applying fixes via Node.js...${N}"
node -e "
const fs = require('fs');
let c = fs.readFileSync('$DASH', 'utf8');

// ── FIX 1: Remove 2026 occurrences ──────────────────────────

// StatCard sub label
c = c.replace(/sub=\"NEET 2026\"/g, 'sub=\"NEET\"');

// Section headers
c = c.replace(/🏆 NEET 2026 Countdown/g, '🏆 NEET Countdown');
c = c.replace(/🏆 NEET 2026/g, '🏆 NEET');

// Detail lines with date
c = c.replace(
  /NEET 2026 — May 3, 2026 · 180 Questions · 720 Marks/g,
  'NEET · 180 Questions · 720 Marks'
);
c = c.replace(
  /NEET 2026 — 3 मई 2026 · 180 प्रश्न · 720 अंक/g,
  'NEET · 180 प्रश्न · 720 अंक'
);

// Footer countdown text
c = c.replace(
  /days remaining for NEET 2026 — Make every day count!/g,
  'days remaining — Make every day count!'
);
c = c.replace(
  /NEET 2026 के लिए '/g,
  \"'\"
);
c = c.replace(
  /NEET 2026 के लिए \\\`/g,
  '\`'
);

// Notification messages
c = c.replace(
  /Start preparing for NEET 2026 today!/g,
  'Start preparing for NEET today!'
);
c = c.replace(
  /आज NEET 2026 की तैयारी शुरू करें!/g,
  'आज NEET की तैयारी शुरू करें!'
);
c = c.replace(/NEET 2026 Date Announced/g, 'NEET Date Announced');
c = c.replace(/NEET 2026 तारीख घोषित/g, 'NEET तारीख घोषित');
c = c.replace(
  /NEET 2026 is scheduled for May 3, 2026\. Make sure you are prepared!/g,
  'NEET exam is coming up. Make sure you are prepared!'
);
c = c.replace(
  /NEET 2026, 3 मई 2026 को है\। सुनिश्चित करें कि आप तैयार हैं!/g,
  'NEET परीक्षा आने वाली है। सुनिश्चित करें कि आप तैयार हैं!'
);

// Performance report
c = c.replace(/NEET 2026 Performance Report/g, 'NEET Performance Report');
c = c.replace(/NEET 2026 प्रदर्शन रिपोर्ट/g, 'NEET प्रदर्शन रिपोर्ट');

// Profile target exam options & defaults
c = c.replace(/useState\('NEET 2026'\)/g, \"useState('NEET')\");
c = c.replace(/targetExam\|\|'NEET 2026'/g, \"targetExam||'NEET'\");
c = c.replace(/target\|\|'NEET 2026'/g, \"target||'NEET'\");
c = c.replace(/<option value=\"NEET 2026\">NEET 2026<\/option>/g, '<option value=\"NEET\">NEET</option>');
c = c.replace(/<option value=\"JEE 2026\">JEE 2026<\/option>/g, '<option value=\"JEE\">JEE</option>');

// Roll number prefix PR2026 → PRK
c = c.replace(/PR2026-/g, 'PRK-');

// Any remaining loose 2026 (except dates in JS Date constructor - keep those)
// Keep: new Date('2026-05-03') — this is needed for countdown logic
// Remove all other 2026
c = c.replace(/(?<!Date\(')NEET 2026(?!')/g, 'NEET');
c = c.replace(/\bJEE 2026\b/g, 'JEE');

// ── FIX 2: Streak 'od' bug ───────────────────────────────────
// Ensure streak value is always a proper number string
c = c.replace(
  /value={\`\\\${user\?\.streak\|\|0}d\`}/g,
  'value={String(Math.floor(Number(user?.streak)||0))+\"d\"}'
);

fs.writeFileSync('$DASH', c, 'utf8');
console.log('✓ All fixes applied to dashboard/page.tsx');
"

echo -e "\n${Y}Verifying — checking for remaining 2026...${N}"
grep -n "2026" "$DASH" | grep -v "new Date\|2026-05-03\|//\|tDate" \
  && echo -e "${R}^ Some 2026 still found (check above lines)${N}" \
  || echo -e "${G}✓ Dashboard — 2026 CLEAN (only Date constructor preserved)${N}"

echo -e "\n${Y}Verifying — streak fix...${N}"
grep -n "streak" "$DASH" | head -5

echo ""
echo -e "${Y}Now deploy:${N}"
echo "cd ~/workspace/frontend && git add -A && git commit -m 'fix: remove 2026 from dashboard + streak display fix' && git push"
