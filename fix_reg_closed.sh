#!/bin/bash
# ═══════════════════════════════════════════════════
# Fix: Registration Closed UI + Bug3 T&C
# ═══════════════════════════════════════════════════
# Run from: ~/workspace/
# Usage: bash fix_reg_closed.sh

echo "════════════════════════════════════════════"
echo "  Fix: Reg Closed UI + Bug3 T&C"
echo "════════════════════════════════════════════"

BACKEND="src/routes/auth.js"
FRONTEND="frontend/app/register/page.tsx"

if [ ! -f "$BACKEND" ]; then echo "❌ Run from ~/workspace/"; exit 1; fi
if [ ! -f "$FRONTEND" ]; then echo "❌ $FRONTEND not found"; exit 1; fi

cp "$BACKEND"  "${BACKEND}.bak_regclosed"
cp "$FRONTEND" "${FRONTEND}.bak_regclosed"
echo "✅ Backups created"
echo ""

# ── BACKEND: Add registration-status endpoint ──────
echo "── Backend: Adding /registration-status ───"
node << 'JSEOF'
const fs = require('fs')
let code = fs.readFileSync('src/routes/auth.js', 'utf8')
if (code.includes('registration-status')) {
  console.log('ℹ️  Already exists — skipping')
  process.exit(0)
}
const endpoint = `
// ── Registration Status Check ────────────────────────────────────
router.get('/registration-status', (req, res) => {
  try {
    const open = global.featureFlags ? global.featureFlags['open_registration'] !== false : true
    res.json({ open, message: open ? 'Registration is open' : 'Registration is currently closed' })
  } catch (err) {
    res.json({ open: true, message: 'Registration is open' })
  }
})

`
code = code.replace('module.exports = router', endpoint + 'module.exports = router')
fs.writeFileSync('src/routes/auth.js', code)
console.log('✅ Added GET /registration-status endpoint')
JSEOF

echo ""
# ── FRONTEND: Bug3 + Reg Closed UI ─────────────────
echo "── Frontend: Bug3 + Reg Closed UI ─────────"
node << 'JSEOF'
const fs = require('fs')
let code = fs.readFileSync('frontend/app/register/page.tsx', 'utf8')
let fixed = 0

// Bug3-A: Remove T&C auto-accept from useEffect
const t3a_old = `  useEffect(() => {
    try {
      if (localStorage.getItem('pr_terms_viewed') === 'true') {
        setAgreedTnc(true)
        localStorage.removeItem('pr_terms_viewed') // consume it
      }
    } catch {}
  }, [])`
const t3a_new = `  // Bug3: clear stale flag only, never auto-accept
  useEffect(() => {
    try { localStorage.removeItem('pr_terms_viewed') } catch {}
  }, [])`
if (code.includes(t3a_old)) { code = code.replace(t3a_old, t3a_new); fixed++; console.log('✅ Bug3-A: T&C auto-accept removed') }
else console.log('⚠️  Bug3-A: already fixed or pattern not found')

// Bug3-B: Remove localStorage persist in accept btn
const t3b_old = `try { localStorage.setItem('pr_terms_viewed','true') } catch {}`
const t3b_new = `/* Bug3: session-only */`
if (code.includes(t3b_old)) { code = code.replace(t3b_old, t3b_new); fixed++; console.log('✅ Bug3-B: T&C localStorage removed from accept btn') }
else console.log('⚠️  Bug3-B: already fixed or pattern not found')

// RegClosed: Add state
if (!code.includes('regClosed')) {
  code = code.replace(
    `  const [resendCooldown, setResendCooldown] = useState(0)`,
    `  const [resendCooldown, setResendCooldown] = useState(0)\n  const [regClosed, setRegClosed] = useState(false)`
  ); fixed++; console.log('✅ RegClosed: state added')
} else console.log('ℹ️  RegClosed: state already exists')

// RegClosed: Add status check useEffect
if (!code.includes('registration-status')) {
  code = code.replace(
    `  // F35.8 — Email availability check (debounced 500ms)`,
    `  // Registration status check on mount\n  useEffect(() => {\n    fetch(\`\${API}/api/auth/registration-status\`)\n      .then(r => r.json())\n      .then(d => { if (!d.open) setRegClosed(true) })\n      .catch(() => {})\n  }, [])\n\n  // F35.8 — Email availability check (debounced 500ms)`
  ); fixed++; console.log('✅ RegClosed: status check useEffect added')
} else console.log('ℹ️  RegClosed: fetch already exists')

// RegClosed: Banner + conditional form
if (!code.includes('regClosed && step') && code.includes(`{step === 'details' && (`)) {
  code = code.replace(
    `      {step === 'details' && (`,
    `      {/* Reg Closed Banner */}
      {regClosed && step === 'details' && (
        <div style={{ position:'relative', background:'rgba(0,8,6,0.97)', border:'2px solid rgba(255,80,80,0.35)', borderRadius:18, padding:'38px 22px', textAlign:'center', backdropFilter:'blur(20px)', boxShadow:'0 12px 50px rgba(0,0,0,0.75)', overflow:'hidden' }}>
          <div style={{ position:'absolute', top:0, left:0, right:0, height:3, background:'linear-gradient(90deg,#FF6B6B,#FF4D4D,#FF8C42)' }} />
          <div style={{ fontSize:52, marginBottom:12 }}>🔒</div>
          <h2 style={{ fontFamily:'Playfair Display,serif', fontSize:20, fontWeight:700, color:'#FF8080', margin:'0 0 10px' }}>Registration Temporarily Closed</h2>
          <div style={{ background:'rgba(255,70,70,0.08)', border:'1px solid rgba(255,70,70,0.25)', borderRadius:10, padding:'12px 16px', marginBottom:16 }}>
            <p style={{ fontSize:13, color:'#FFAAAA', fontWeight:600, margin:0, lineHeight:1.6 }}>
              📢 Registration is currently closed. We&apos;ll be back soon. Please contact Admin for access.
            </p>
          </div>
          <p style={{ fontSize:13, color:'rgba(255,255,255,0.45)', marginBottom:22, lineHeight:1.65 }}>
            New student registrations are temporarily paused.<br/>Existing students can still login normally.
          </p>
          <div style={{ display:'flex', gap:10, justifyContent:'center', flexWrap:'wrap' }}>
            <a href="/login" style={{ padding:'11px 24px', background:'linear-gradient(135deg,#2DD4BF,#0D9488)', color:'#001A1A', borderRadius:11, fontWeight:700, fontSize:13, textDecoration:'none', display:'inline-block' }}>Login →</a>
            <a href="mailto:admin@proverank.com" style={{ padding:'11px 20px', background:'rgba(255,80,80,0.12)', border:'1px solid rgba(255,80,80,0.3)', color:'#FF9999', borderRadius:11, fontWeight:600, fontSize:13, textDecoration:'none', display:'inline-block' }}>📧 Contact Admin</a>
          </div>
        </div>
      )}

      {!regClosed && step === 'details' && (`
  ); fixed++; console.log('✅ RegClosed: banner + conditional form added')
} else console.log('ℹ️  RegClosed: banner already exists')

fs.writeFileSync('frontend/app/register/page.tsx', code)
console.log(`\n✅ Done — ${fixed} fixes applied`)
JSEOF

echo ""
echo "════════════════════════════════════════════"
echo "  ✅ ALL DONE"
echo "  → Restart backend"  
echo "  → git add -A && git commit -m 'Fix: reg"
echo "    closed UI + T&C reset' && git push"
echo "════════════════════════════════════════════"
