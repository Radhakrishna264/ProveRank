#!/bin/bash
echo "=== ProveRank Fix: Edit Modal — correct[] array sync on answer change ==="

FILE=~/workspace/frontend/app/admin/x7k2p/page.tsx
if [ ! -f "$FILE" ]; then echo "❌ File not found"; exit 1; fi

cp "$FILE" "$FILE.bak_editans_$(date +%s)"
echo "✓ Backup created"

node << 'JSEOF'
const fs = require('fs');
const file = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let c = fs.readFileSync(file, 'utf8');

// Target: correctAnswer dropdown onChange in aiEditQ modal
// Current — only updates correctAnswer string, NOT correct[] array
const OLD = `onChange={(e=>setAiEditQ((p:any)=>({...p,correctAnswer:e.target.value,correct_answer:e.target.value})))}`;

// Fix — also update correct[] index array and correctLetter
const NEW = `onChange={(e=>{const _opts=['Option A','Option B','Option C','Option D'];const _ci=_opts.indexOf(e.target.value);const _lt=e.target.value.replace('Option ','').trim();setAiEditQ((p:any)=>({...p,correctAnswer:e.target.value,correct_answer:e.target.value,correctLetter:_lt,correct:_ci>=0?[_ci]:p.correct}))})}`;

if (c.includes(OLD)) {
  c = c.replace(OLD, NEW);
  fs.writeFileSync(file, c, 'utf8');
  console.log('✅ Fix applied — correct[] array now syncs when dropdown changes');
} else {
  // Show what we have
  const idx = c.indexOf('correctAnswer:e.target.value,correct_answer:e.target.value');
  if (idx !== -1) {
    console.log('Found at char ' + idx + ':');
    console.log(c.slice(idx - 50, idx + 200));
    console.log('❌ Exact pattern mismatch — see above');
  } else {
    console.log('❌ Pattern not found at all');
  }
  process.exit(1);
}
JSEOF

if [ $? -ne 0 ]; then echo "❌ Fix failed"; exit 1; fi

# Verify
echo ""
echo "=== Verify ==="
grep -n "correct:_ci>=0" "$FILE" | head -3
echo "✅ Verified"

# Push
echo ""
echo "=== Git push ==="
cd ~/workspace
git add frontend/app/admin/x7k2p/page.tsx
git commit -m "fix: edit modal — sync correct[] array + correctLetter when answer dropdown changes"
git push origin main

echo ""
echo "=== ✅ Done! ==="
echo "Test: Edit karo → Option D select karo → Save → Preview mein D highlight hoga"
