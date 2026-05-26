#!/bin/bash
# ═══════════════════════════════════════════════════════════
#  ProveRank – M2 Custom Registration Fields PERSISTENCE FIX
#  Fixes: Fields not saving to DB on Add / Remove
#  4 Fixes: useState clear + useEffect fetch + POST + DELETE
# ═══════════════════════════════════════════════════════════
set -e

FILE="$HOME/workspace/frontend/app/admin/x7k2p/page.tsx"

if [ ! -f "$FILE" ]; then
  echo "❌ File not found: $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_m2_$(date +%Y%m%d_%H%M%S)"
cp "$FILE" "$BACKUP"
echo "📁 Backup: $BACKUP"
echo ""

node << 'NODEEOF'
const fs = require('fs');
const FILE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let code = fs.readFileSync(FILE, 'utf8');
const ok = [];
const skip = [];

// ══════════════════════════════════════════════════════════
// FIX 1 — Clear hardcoded initial values from useState
//   Before: useState([{key:'school_name',...},{key:'city',...},...])
//   After : useState([])
// ══════════════════════════════════════════════════════════
const stRx = /const \[customFields,setCustomFields\]=useState\(\[[\s\S]*?\]\)/;
if (stRx.test(code)) {
  code = code.replace(stRx, 'const [customFields,setCustomFields]=useState([])');
  ok.push('✅ Fix 1 — useState hardcoded values cleared');
} else {
  skip.push('⚠️  Fix 1 — Pattern not matched (may already be fixed)');
}

// ══════════════════════════════════════════════════════════
// FIX 2 — Inject useEffect to load fields from backend DB
//   GET /api/auth/registration-fields on mount
//   Maps backend field names to frontend keys
// ══════════════════════════════════════════════════════════
const stMark = 'const [customFields,setCustomFields]=useState([])';
if (code.includes(stMark) && !code.includes('/api/auth/registration-fields')) {
  const eff = `
  // M2: Fetch custom fields from DB on mount
  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => {
    (async () => {
      try {
        const r = await fetch(\`\${API}/api/auth/registration-fields\`, { headers: H() });
        const d = await r.json();
        if (d.success && d.fields) {
          setCustomFields(
            d.fields.map(f => ({ ...f, key: f.fieldName || f.key, type: f.fieldType || f.type }))
          );
        }
      } catch (e) { console.error('M2 fetch error:', e); }
    })();
  }, []);`;
  code = code.replace(stMark, stMark + eff);
  ok.push('✅ Fix 2 — useEffect DB fetch injected');
} else if (code.includes('/api/auth/registration-fields')) {
  skip.push('⚠️  Fix 2 — useEffect already present, skipped');
} else {
  skip.push('⚠️  Fix 2 — Marker not found after Fix 1');
}

// ══════════════════════════════════════════════════════════
// FIX 3 — Add Field button: state-only → API POST
//   Before: setCustomFields(p=>[...p, {...}]) only
//   After : POST /api/auth/registration-fields then update state
// ══════════════════════════════════════════════════════════
const addRx = /onClick=\{\(\)=>\{if\(!cfLabelR\.current\|\|!cfKeyR\.current\)\{T\('Label and key required\.','e'\);return\}setCustomFields\(p=>\[\.\.\.p,\{key:cfKeyR\.current,label:cfLabelR\.current,type:cfType,required:cfRequired,options:cfOptsR\.current\}\]\);T\('Field added\.'\);cfLabelR\.current='';cfKeyR\.current=''\}\}/;

const addNew = `onClick={async () => {
  if (!cfLabelR.current || !cfKeyR.current) { T('Label and key required.', 'e'); return; }
  try {
    const r = await fetch(\`\${API}/api/auth/registration-fields\`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...H() },
      body: JSON.stringify({
        fieldName: cfKeyR.current,
        label: cfLabelR.current,
        fieldType: cfType,
        required: cfRequired,
        options: cfOptsR.current || []
      })
    });
    const d = await r.json();
    if (d.success && d.field) {
      const nf = d.field;
      setCustomFields(p => [...p, { ...nf, key: nf.fieldName, type: nf.fieldType }]);
      T('Field added.', 's');
      cfLabelR.current = '';
      cfKeyR.current = '';
    } else {
      T(d.message || 'Add failed', 'e');
    }
  } catch (e) { T('Server error', 'e'); }
}}`;

if (addRx.test(code)) {
  code = code.replace(addRx, addNew);
  ok.push('✅ Fix 3 — Add Field button wired to API POST');
} else {
  skip.push('⚠️  Fix 3 — Add button pattern not matched');
}

// ══════════════════════════════════════════════════════════
// FIX 4 — Remove button: state-only → API DELETE
//   Before: setCustomFields(p=>p.filter((_,j)=>j!==i)) only
//   After : DELETE /api/auth/registration-fields/:id then update state
// ══════════════════════════════════════════════════════════
const remOld = `onClick={()=>setCustomFields(p=>p.filter((_,j)=>j!==i))}`;
const remNew = `onClick={async () => {
  try {
    if (f._id) {
      const r = await fetch(\`\${API}/api/auth/registration-fields/\${f._id}\`, {
        method: 'DELETE',
        headers: H()
      });
      const d = await r.json();
      if (!d.success) { T(d.message || 'Remove failed', 'e'); return; }
    }
    setCustomFields(p => p.filter((_, j) => j !== i));
    T('Field removed.', 's');
  } catch (e) { T('Server error', 'e'); }
}}`;

if (code.includes(remOld)) {
  code = code.replace(remOld, remNew);
  ok.push('✅ Fix 4 — Remove button wired to API DELETE');
} else {
  skip.push('⚠️  Fix 4 — Remove button pattern not matched');
}

// ══════════════════════════════════════════════════════════
// Write file
// ══════════════════════════════════════════════════════════
fs.writeFileSync(FILE, code, 'utf8');

console.log('\n══════════ RESULT ══════════');
ok.forEach(m => console.log(m));
if (skip.length) { console.log(''); skip.forEach(m => console.log(m)); }
console.log('════════════════════════════');
console.log(`\n${ok.length}/4 fixes applied.`);
if (ok.length === 4) {
  console.log('🎉 All fixes applied! Restart dev server.');
} else {
  console.log('⚠️  Some fixes skipped — share output for manual fix.');
}
NODEEOF

echo ""
echo "══════════════════════════════════════"
echo "▶  Restart dev server:"
echo "   pkill -f 'next dev' 2>/dev/null"
echo "   sleep 2"
echo "   cd ~/workspace/frontend && npm run dev"
echo "══════════════════════════════════════"
