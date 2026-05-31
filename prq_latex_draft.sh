#!/bin/bash
set -e

echo "=== ProveRank: LaTeX + Auto-save Draft → Question Bank ==="
echo ""

# Paths
export PRPAGE="$HOME/workspace/frontend/app/admin/x7k2p/page.tsx"
cd "$HOME/workspace/frontend"

# ── Step 1: Install KaTeX ──────────────────────────────────────────
echo "📦 Step 1: Installing KaTeX..."
npm install katex --save --silent
echo "✅ KaTeX installed"
echo ""

# ── Step 2: Apply changes via Node.js ─────────────────────────────
echo "✏️  Step 2: Applying changes to page.tsx..."

cat > /tmp/prq_add_features.js << 'NODEOF'
const fs = require('fs')
const FILE = process.env.PRPAGE
let c = fs.readFileSync(FILE, 'utf8')
let n = 0

// Helper: safe replace with logging
const rep = (from, to, label) => {
  if (!c.includes(from)) {
    console.log('❌ Anchor missing:', label)
    console.log('   Expected:', from.substring(0, 60))
    return
  }
  const checkStr = to.substring(0, 25)
  if (c.includes(checkStr)) {
    console.log('⏭  Already exists:', label)
    return
  }
  c = c.replace(from, to)
  console.log('✅', label)
  n++
}

// ── 1. KaTeX import ───────────────────────────────────────────────
rep(
  `import { getToken, getRole, clearAuth } from '@/lib/auth'`,
  `import { getToken, getRole, clearAuth } from '@/lib/auth'
import * as katex from 'katex'`,
  'katex import'
)

// ── 2. renderLatex helper (after API const) ───────────────────────
rep(
  `const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'`,
  `const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'

// ── LaTeX/Math render helper ──
const renderLatex = (text: string): string => {
  if (!text) return text
  try {
    return text
      .replace(/\$\$([^$]+)\$\$/g, (a: string, m: string) => {
        try { return katex.renderToString(m, { displayMode: true, throwOnError: false }) }
        catch { return a }
      })
      .replace(/\$([^$\n]+)\$/g, (a: string, m: string) => {
        try { return katex.renderToString(m, { displayMode: false, throwOnError: false }) }
        catch { return a }
      })
  } catch { return text }
}`,
  'renderLatex helper'
)

// ── 3. States + draft functions after addQ dep array ─────────────
rep(
  `},[qSubj,qDiff,qType,qAns,token,T])`,
  `},[qSubj,qDiff,qType,qAns,token,T])

  // ── LaTeX preview state ──
  const [showQPreview, setShowQPreview] = useState(false)
  const [qMathHtml, setQMathHtml] = useState('')
  const updateMathPrev = () => setQMathHtml(renderLatex(qTxtR.current || ''))

  // ── Auto-save draft functions ──
  const saveDraft = () => {
    try {
      localStorage.setItem('prq_draft', JSON.stringify({
        text: qTxtR.current,
        hindi: qHindi,
        subj: qSubj,
        chap: qChap,
        topic: qTopic,
        diff: qDiff,
        type: qType,
        exp: qExpR.current,
        img: qImageR.current
      }))
      T('Draft saved ✅')
    } catch { T('Save failed', 'e') }
  }

  const restoreDraft = () => {
    const raw = localStorage.getItem('prq_draft')
    if (!raw) return T('No saved draft found', 'e')
    try {
      const d = JSON.parse(raw)
      if (d.text) qTxtR.current = d.text
      if (d.exp) qExpR.current = d.exp
      if (d.img) qImageR.current = d.img
      if (d.subj) setQSubj(d.subj)
      if (d.chap) setQChap(d.chap)
      if (d.topic) setQTopic(d.topic)
      if (d.diff) setQDiff(d.diff)
      if (d.type) setQType(d.type)
      if (d.hindi) setQHindi(d.hindi)
      T('Draft restored ✅ — Review fields & submit.')
    } catch { T('Restore failed', 'e') }
  }

  // ── Mount: KaTeX CSS (CDN) + draft notification ──
  useEffect(() => {
    if (!document.getElementById('katex-css')) {
      const l = document.createElement('link')
      l.id = 'katex-css'
      l.rel = 'stylesheet'
      l.href = 'https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css'
      document.head.appendChild(l)
    }
    try {
      const r = localStorage.getItem('prq_draft')
      if (r) {
        const d = JSON.parse(r)
        if (d && d.text && d.text.length > 2) T('📝 Saved draft found — click Restore Draft', 'w')
      }
    } catch {}
  }, [])`,
  'Draft states + functions'
)

// ── 4. Clear draft on successful submit ───────────────────────────
rep(
  `T('Question added to bank successfully.')`,
  `T('Question added to bank successfully.'); localStorage.removeItem('prq_draft')`,
  'Clear draft on submit success'
)

// ── 5. Draft buttons after Clear button ──────────────────────────
const CB = `>🗑️Clear</button>`
const DB = `>💾 Save Draft</button>`
if (c.includes(CB) && !c.includes(DB)) {
  c = c.replace(CB,
    CB +
    `<button onClick={saveDraft} style={{padding:'8px 14px',borderRadius:8,background:'rgba(255,165,0,0.12)',border:'1px solid rgba(255,165,0,0.4)',color:'#FFA500',cursor:'pointer',fontSize:12,flexShrink:0}}>💾 Save Draft</button>` +
    `<button onClick={restoreDraft} style={{padding:'8px 14px',borderRadius:8,background:'rgba(0,200,255,0.1)',border:'1px solid rgba(0,200,255,0.3)',color:'#00C8FF',cursor:'pointer',fontSize:12,flexShrink:0}}>📂 Restore Draft</button>`
  )
  console.log('✅ Draft buttons added'); n++
} else if (c.includes(DB)) {
  console.log('⏭  Already exists: Draft buttons')
} else {
  console.log('❌ Anchor missing: Clear button — check emoji in file')
}

// ── 6. Math preview block after submit button ─────────────────────
const SB = `'✅ Add to Question Bank'}</button>`
const MP = `updateMathPrev`
if (c.includes(SB) && !c.includes(MP + '();')) {
  c = c.replace(SB,
    SB +
    `<div style={{width:'100%',marginTop:10}}>` +
      `<div style={{display:'flex',gap:8,alignItems:'center',marginBottom:6}}>` +
        `<button onClick={()=>{updateMathPrev();setShowQPreview(v=>!v)}} style={{fontSize:11,padding:'4px 12px',borderRadius:6,background:showQPreview?'rgba(168,85,247,0.25)':'rgba(80,80,80,0.18)',border:'1px solid rgba(168,85,247,0.4)',color:'#C084FC',cursor:'pointer'}}>` +
          `{showQPreview?'🔢 Hide Math Preview':'🔢 Show Math Preview'}` +
        `</button>` +
        `<span style={{fontSize:10,color:'#555'}}>Tip: use $formula$ for inline, $$formula$$ for block</span>` +
      `</div>` +
      `{showQPreview&&<div dangerouslySetInnerHTML={{__html:qMathHtml||'Enter formula in Question Text above, then click Show Math Preview'}} style={{padding:'10px 14px',background:'rgba(168,85,247,0.07)',borderRadius:8,border:'1px solid rgba(168,85,247,0.2)',fontSize:13,color:'#E2D9F3',lineHeight:'1.8',minHeight:40}}/>}` +
    `</div>`
  )
  console.log('✅ Math preview block added'); n++
} else if (c.includes(MP + '();')) {
  console.log('⏭  Already exists: Math preview')
} else {
  console.log('❌ Anchor missing: Submit button marker')
}

// ── Save file ────────────────────────────────────────────────────
if (n > 0) {
  fs.writeFileSync(FILE, c)
  console.log('\n✅ page.tsx saved! Total changes applied:', n)
} else {
  console.log('\n⚠️  Nothing changed — all features already present or anchors missing')
}
NODEOF

node /tmp/prq_add_features.js

# ── Step 3: Verify ─────────────────────────────────────────────────
echo ""
echo "=== 🔍 Verifying changes ==="
grep -n "katex\|renderLatex\|saveDraft\|restoreDraft\|showQPreview\|prq_draft\|Save Draft\|Math Preview" \
  "$PRPAGE" | head -25

# ── Step 4: TypeScript check ───────────────────────────────────────
echo ""
echo "=== 🔧 TypeScript check ==="
npx tsc --noEmit 2>&1 | head -30
echo ""
echo "=== ✅ Script complete ==="
echo "If 0 TypeScript errors above → git commit & push to Vercel"
