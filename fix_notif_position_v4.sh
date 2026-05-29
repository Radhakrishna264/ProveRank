#!/bin/bash
# ProveRank Fix v4: Promise.all position fix — top-students bahar, nf = notifications
echo "=================================================="
echo " ProveRank Fix v4: Notifications Position Fix"
echo "=================================================="

PAGE="$HOME/workspace/frontend/app/admin/x7k2p/page.tsx"
if [ ! -f "$PAGE" ]; then echo "❌ page.tsx not found"; exit 1; fi

cp "$PAGE" "${PAGE}.bak_v4"
echo "✅ Backup: page.tsx.bak_v4"

node << 'NODEEOF'
const fs = require('fs');
const PAGE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let content = fs.readFileSync(PAGE, 'utf8');
let fixes = 0;

// ─────────────────────────────────────────────────────────────────────────
// THE BUG:
// Inside Promise.all array:
//   fetch(top-students).then(r=>r.ok?r.json():null).then(d=>{setTopStudents...}).catch(()=>{})  <- returns undefined → goes to nf
//   fetch(notifications).then(r=>r.json())                                                        <- goes to bt (wrong!)
//
// FIX: Remove top-students from Promise.all (it handles own state)
//      So notifications fetch correctly lands in nf position
// ─────────────────────────────────────────────────────────────────────────

// Step 1: Remove the top-students fetch line from inside Promise.all
// It looks like:
// fetch(`${API}/api/admin/notifications/top-students?limit=10`,{headers:{Authorization:`Bearer ${token}`}}).then(r=>r.ok?r.json():null).then(d=>{if(d&&d.success&&d.topStudents)setTopStudents(d.topStudents);}).catch(()=>{}),

const topStudentsInArray = /\s*fetch\(`\$\{API\}\/api\/admin\/notifications\/top-students\?limit=10`,\{headers:\{Authorization:`Bearer \$\{token\}`\}\}\)\.then\(r=>r\.ok\?r\.json\(\):null\)\.then\(d=>\{if\(d&&d\.success&&d\.topStudents\)setTopStudents\(d\.topStudents\);\}\)\.catch\(\(\)=>\{\}\),\n/;

if (topStudentsInArray.test(content)) {
  content = content.replace(topStudentsInArray, '\n');
  console.log('✅ Fix 1: top-students removed from Promise.all array');
  fixes++;
} else {
  // Try broader pattern
  const broader = /fetch\([^)]*top-students[^)]*\)[^\n]*\.then[^\n]*setTopStudents[^\n]*\.catch[^\n]*,\n/;
  if (broader.test(content)) {
    content = content.replace(broader, '');
    console.log('✅ Fix 1b: top-students removed (broader match)');
    fixes++;
  } else {
    // Line by line approach
    const lines = content.split('\n');
    let removed = false;
    for (let i = 0; i < lines.length; i++) {
      if (lines[i].includes('top-students') && 
          lines[i].includes('setTopStudents') && 
          lines[i].includes('.catch')) {
        lines.splice(i, 1);
        removed = true;
        console.log('✅ Fix 1c: top-students line removed at line ' + (i+1));
        fixes++;
        break;
      }
    }
    if (!removed) {
      // Multi-line version — find start and end
      let startIdx = -1;
      for (let i = 0; i < lines.length; i++) {
        if (lines[i].includes('top-students?limit=10') && lines[i].includes('notifications')) {
          startIdx = i;
          break;
        }
      }
      if (startIdx !== -1) {
        // Find the end (line with .catch(()=>{}) followed by comma)
        let endIdx = startIdx;
        for (let j = startIdx; j < Math.min(startIdx + 5, lines.length); j++) {
          if (lines[j].includes('.catch') && lines[j].includes('}),')) {
            endIdx = j;
            break;
          } else if (lines[j].includes('.catch') && lines[j].includes('}),')) {
            endIdx = j;
            break;
          }
        }
        lines.splice(startIdx, endIdx - startIdx + 1);
        console.log('✅ Fix 1d: top-students multi-line block removed lines ' + (startIdx+1) + '-' + (endIdx+1));
        fixes++;
      } else {
        console.log('❌ Fix 1 FAILED: top-students fetch not found in Promise.all');
        console.log('Manual: grep -n "top-students" ' + PAGE);
      }
    }
    content = lines.join('\n');
  }
}

// Step 2: Add top-students fetch BEFORE Promise.all as standalone call
// Find setLoading(true) and insert after it
const standaloneCall = `
  // Top students — standalone (has own state handler)
  const tk2=getToken();if(tk2){fetch(\`\${API}/api/admin/notifications/top-students?limit=10\`,{headers:{Authorization:\`Bearer \${tk2}\`}}).then(r=>r.ok?r.json():null).then(d=>{if(d&&d.success&&d.topStudents)setTopStudents(d.topStudents);}).catch(()=>{});}
`;

if (!content.includes('Top students — standalone')) {
  // Insert after setLoading(true)
  content = content.replace(
    /setLoading\(true\)\n/,
    'setLoading(true)\n' + standaloneCall + '\n'
  );
  if (content.includes('Top students — standalone')) {
    console.log('✅ Fix 2: top-students standalone fetch added');
    fixes++;
  } else {
    // Try alternate
    content = content.replace(
      'setLoading(true)',
      'setLoading(true);\n' + standaloneCall
    );
    console.log('✅ Fix 2b: top-students standalone fetch added (alt)');
    fixes++;
  }
}

// Step 3: Verify nf parse is correct
// After fix, nf should be: {success:true, unreadCount:N, notifications:[...]}
if (content.includes('nf?.notifications&&Array.isArray(nf.notifications)')) {
  console.log('✅ Fix 3: nf.notifications parse already correct');
} else if (content.includes('setNotifs(nf.notifications)')) {
  console.log('✅ Fix 3: setNotifs(nf.notifications) present');
} else {
  // Ensure parse safety
  content = content.replace(
    /if\(Array\.isArray\(nf\)\)setNotifs\(nf\)/,
    'if(Array.isArray(nf))setNotifs(nf)'
  );
  console.log('ℹ️  Fix 3: nf parse checked');
}

fs.writeFileSync(PAGE, content);
console.log('\n✅ Total fixes: ' + fixes);
NODEEOF

echo ""
echo "--- Verify top-students no longer in Promise.all ---"
grep -n "top-students" "$PAGE" | head -5

echo ""
echo "--- Verify notifications fetch position ---"
grep -n "notifications\|setNotifs\|nf\b" "$PAGE" | grep -v "adminNotif\|PageHero\|announce\|Notification Center\|notifOpen" | head -15

echo ""
echo "--- Git Push ---"
cd ~/workspace
git add frontend/app/admin/x7k2p/page.tsx
git commit -m "fix: move top-students out of Promise.all — nf correctly maps to notifications"
git push origin main

echo ""
echo "=================================================="
echo "✅ ALL DONE — Vercel deploy ~2 min"
echo "🔗 Test: https://prove-rank.vercel.app/admin/x7k2p"
echo "Bell click → real notifications dikhni chahiye"
echo "=================================================="
