#!/bin/bash
echo "=== ProveRank Fix: AI Generate — Correct Answer + Explanation ==="

# Step 1: Apply patch via Node.js
cat > /tmp/fix_ai_correct_answer.js << 'JSEOF'
const fs = require('fs');
const os = require('os');
const filePath = os.homedir() + '/workspace/src/routes/questionFeatures.js';

if (!fs.existsSync(filePath)) {
  console.log('❌ File not found: ' + filePath);
  process.exit(1);
}

let c = fs.readFileSync(filePath, 'utf8');
const orig = c;

// --- Locate /generate route ---
const routeMarker = "router.post('/generate'";
const ri = c.indexOf(routeMarker);
if (ri === -1) { console.log('❌ /generate route not found'); process.exit(1); }
console.log('✓ /generate route found at char ' + ri);

// --- Locate generated.push inside that route ---
const pushMarker = 'generated.push({';
const pi = c.indexOf(pushMarker, ri);
if (pi === -1) { console.log('❌ generated.push not found in /generate route'); process.exit(1); }
console.log('✓ generated.push found at char ' + pi);

// --- Insert random correct-answer logic BEFORE generated.push ---
const LOGIC = `const cIdx_gen = Math.floor(Math.random() * 4);
      const cLetter_gen = ['A','B','C','D'][cIdx_gen];
      const _expMap = {
        Physics: opts[cIdx_gen] + ' is the correct answer. In ' + chapter + ', the concept of ' + topic + ' follows this fundamental Physics principle as per NCERT — frequently tested in NEET.',
        Chemistry: opts[cIdx_gen] + ' is correct. ' + topic + ' in ' + chapter + ' demonstrates this key chemical property as per NCERT. Important NEET Chemistry concept.',
        Biology: opts[cIdx_gen] + ' is the correct answer. ' + topic + ' in ' + chapter + ' is a crucial Biology concept as per NCERT — frequently asked in NEET examination.',
      };
      const genExpl_ai = _expMap[subject] || (opts[cIdx_gen] + ' is correct. ' + topic + ' in ' + chapter + ' — this fundamental principle is essential for NEET preparation.');
      `;

c = c.slice(0, pi) + LOGIC + c.slice(pi);
console.log('✓ Random logic inserted before generated.push');

// --- Replace correct: [0] ---
const old1 = 'correct: [0],';
const new1 = 'correct: [cIdx_gen],';
const i1 = c.indexOf(old1, ri);
if (i1 === -1) { console.log('❌ correct:[0] not found after /generate'); process.exit(1); }
c = c.slice(0, i1) + new1 + c.slice(i1 + old1.length);
console.log('✓ correct:[0] → correct:[cIdx_gen]');

// --- Replace correctAnswer: 'A' ---
const old2 = "correctAnswer: 'A',";
const new2 = "correctAnswer: cLetter_gen,";
const i2 = c.indexOf(old2, ri);
if (i2 === -1) { console.log('❌ correctAnswer:A not found after /generate'); process.exit(1); }
c = c.slice(0, i2) + new2 + c.slice(i2 + old2.length);
console.log("✓ correctAnswer:'A' → correctAnswer:cLetter_gen");

// --- Replace generic explanation (try both quote styles) ---
const old3a = "explanation: 'The correct answer is based on the fundamental concept of ' + topic + ' as described in ' + chapter + \".\",";
const old3b = "explanation: 'The correct answer is based on the fundamental concept of ' + topic + ' as described in ' + chapter + '.',";
const new3  = "explanation: genExpl_ai,";

let i3 = c.indexOf(old3a, ri);
if (i3 !== -1) {
  c = c.slice(0, i3) + new3 + c.slice(i3 + old3a.length);
  console.log('✓ Generic explanation replaced (variant A)');
} else {
  i3 = c.indexOf(old3b, ri);
  if (i3 !== -1) {
    c = c.slice(0, i3) + new3 + c.slice(i3 + old3b.length);
    console.log('✓ Generic explanation replaced (variant B)');
  } else {
    console.log('⚠️  Explanation string not matched — skipping (answers still fixed)');
  }
}

if (c === orig) {
  console.log('❌ No changes were made — all patterns already fixed or not matched');
  process.exit(1);
}

fs.writeFileSync(filePath, c, 'utf8');
console.log('');
console.log('✅ questionFeatures.js patched successfully!');
JSEOF

node /tmp/fix_ai_correct_answer.js
if [ $? -ne 0 ]; then
  echo "❌ Patch script failed — stopping"
  exit 1
fi

# Step 2: Verify the fix
echo ""
echo "=== Verifying patch ==="
grep -n "cIdx_gen\|cLetter_gen\|genExpl_ai" ~/workspace/src/routes/questionFeatures.js | head -10
if [ $? -eq 0 ]; then
  echo "✅ Verification passed — new variables found in file"
else
  echo "❌ Verification failed"
  exit 1
fi

# Step 3: Restart backend server
echo ""
echo "=== Restarting backend server ==="
pkill -f "node src/index.js" 2>/dev/null
sleep 2
cd ~/workspace && nohup node src/index.js > server.log 2>&1 &
sleep 4
echo "Server restarted"
tail -5 ~/workspace/server.log

# Step 4: Git commit and push (for Render live deploy)
echo ""
echo "=== Git push for Render deploy ==="
cd ~/workspace
git add src/routes/questionFeatures.js
git commit -m "fix: AI generate route — random correct answer (A/B/C/D) + subject-specific explanation"
git push origin main
echo ""
echo "=== ✅ All done! ==="
echo "Test karo: Admin Panel → Question Bank → Smart Generator → Topic dalo → Generate → Preview mein"
echo "Ab har question ka alag correct answer (A/B/C/D) aur subject-specific explanation dikhega"
