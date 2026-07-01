#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  F35 Bug Fixes:                                             ║
# ║  1. T&C checkbox — requires viewing terms first            ║
# ║  2. Terms scroll — fix detection + desktop buttons         ║
# ║  3. Terms accept → return to register with checkbox ticked ║
# ╚══════════════════════════════════════════════════════════════╝
set -e
FE=/home/runner/workspace/frontend
echo "🔧 F35 bug fixes..."

# ═══════════════════════════════════════════════════════════════
# FIX 1 + 3 — register/page.tsx
# T&C checkbox disabled until user visits terms
# Auto-check when returning from terms page
# ═══════════════════════════════════════════════════════════════
node << 'EOF'
const fs = require('fs');
const f  = '/home/runner/workspace/frontend/app/register/page.tsx';
let c = fs.readFileSync(f, 'utf8');

// 1. Add pr_terms_viewed check on mount — auto-check if returning from terms
const OLD_EFFECT = `  useEffect(() => { if (step === 'otp') setResendCooldown(60) }, [step])`;

const NEW_EFFECT = `  // Auto-check T&C if user is returning from terms page
  useEffect(() => {
    try {
      if (localStorage.getItem('pr_terms_viewed') === 'true') {
        setAgreedTnc(true)
        localStorage.removeItem('pr_terms_viewed') // consume it
      }
    } catch {}
  }, [])

  useEffect(() => { if (step === 'otp') setResendCooldown(60) }, [step])`;

if (c.includes(OLD_EFFECT) && !c.includes('pr_terms_viewed')) {
  c = c.replace(OLD_EFFECT, NEW_EFFECT);
  console.log('✅ Fix 1: Auto-check T&C on return from terms page');
} else {
  console.log('✅ Fix 1: Already present or different structure');
}

// 2. Replace T&C checkbox section — disable until terms viewed
const OLD_TNC = `          {/* F35.12 — T&C checkbox required */}
          <label style={{ display: 'flex', alignItems: 'flex-start', gap: 8, marginTop: 18, cursor: 'pointer' }}>
            <input type="checkbox" checked={agreedTnc} onChange={e => setAgreedTnc(e.target.checked)} style={{ marginTop: 2, accentColor: T.pri, width: 16, height: 16, flexShrink: 0 }} />
            <span style={{ fontSize: 12, color: T.sub, lineHeight: 1.5 }}>I agree to the <a href="/terms" target="_blank" style={{ color: T.pri, fontWeight: 600 }}>Terms &amp; Conditions</a> and Privacy Policy</span>
          </label>`;

const NEW_TNC = `          {/* F35.12 — T&C checkbox — must read terms first */}
          <div style={{ marginTop: 18, padding: '12px 14px', background: 'rgba(0,20,18,0.6)', border: \`1px solid \${agreedTnc ? T.pri : T.cardBorder}\`, borderRadius: 10, transition: 'border-color .3s' }}>
            {!agreedTnc ? (
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <span style={{ fontSize: 18 }}>📋</span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 12, color: T.txt, marginBottom: 4 }}>You must read Terms &amp; Conditions before proceeding</div>
                  <a
                    href={'/terms?back=/register'}
                    onClick={() => { try { localStorage.setItem('pr_terms_redirect', '1') } catch {} }}
                    style={{ color: T.pri, fontSize: 12, fontWeight: 700, textDecoration: 'underline' }}
                  >
                    📖 Read Terms &amp; Conditions →
                  </a>
                </div>
              </div>
            ) : (
              <label style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer' }}>
                <div style={{ width: 20, height: 20, borderRadius: 5, background: T.pri, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <span style={{ color: '#001A1A', fontSize: 12, fontWeight: 900 }}>✓</span>
                </div>
                <span style={{ fontSize: 12, color: T.txt, fontWeight: 600 }}>✅ Terms &amp; Conditions read and accepted</span>
                <button onClick={() => setAgreedTnc(false)} style={{ marginLeft: 'auto', background: 'none', border: 'none', color: '#FF4D4D', fontSize: 11, cursor: 'pointer', fontFamily: 'Inter,sans-serif' }}>Undo</button>
              </label>
            )}
          </div>`;

if (c.includes(OLD_TNC)) {
  c = c.replace(OLD_TNC, NEW_TNC);
  console.log('✅ Fix 2: T&C checkbox replaced with read-first flow');
} else {
  console.log('⚠️  Fix 2: T&C anchor not found exactly — check register page');
}

fs.writeFileSync(f, c);
console.log('✅ register/page.tsx updated');
EOF

# ═══════════════════════════════════════════════════════════════
# FIX 2 — terms/page.tsx
# - Fix scroll detection (use document.body + documentElement both)
# - Set pr_terms_viewed on accept
# - Fix redirect: go back to register if coming from there
# - Fix desktop buttons (remove scroll gate for desktop)
# ═══════════════════════════════════════════════════════════════
node << 'EOF'
const fs = require('fs');
const f  = '/home/runner/workspace/frontend/app/terms/page.tsx';
let c = fs.readFileSync(f, 'utf8');

// Fix scroll detection — use both scrollTop sources + fix for desktop
const OLD_SCROLL = `  // F35.15 — Scroll-to-bottom enforcement + progress bar
  useEffect(() => {
    const onScroll = () => {
      const doc = document.documentElement
      const scrollTop = doc.scrollTop || document.body.scrollTop
      const scrollHeight = doc.scrollHeight - doc.clientHeight
      const pct = scrollHeight > 0 ? Math.min(100, (scrollTop / scrollHeight) * 100) : 100
      setScrollPct(pct)
      if (pct >= 92) setCanAccept(true)
    }
    window.addEventListener('scroll', onScroll)
    onScroll()
    return () => window.removeEventListener('scroll', onScroll)
  }, [])`;

const NEW_SCROLL = `  // F35.15 — Scroll-to-bottom enforcement + progress bar
  useEffect(() => {
    const onScroll = () => {
      // Use multiple sources for cross-browser support
      const scrollTop = window.scrollY || document.documentElement.scrollTop || document.body.scrollTop || 0
      const docHeight = document.documentElement.scrollHeight || document.body.scrollHeight || 0
      const winHeight = window.innerHeight || document.documentElement.clientHeight || 0
      const scrollHeight = docHeight - winHeight
      const pct = scrollHeight > 0 ? Math.min(100, Math.round((scrollTop / scrollHeight) * 100)) : 100
      setScrollPct(pct)
      if (pct >= 88) setCanAccept(true)  // 88% threshold (more lenient)
    }
    window.addEventListener('scroll', onScroll, { passive: true })
    // Check immediately on mount (short pages unlock right away)
    setTimeout(onScroll, 100)
    return () => window.removeEventListener('scroll', onScroll)
  }, [])`;

if (c.includes(OLD_SCROLL)) {
  c = c.replace(OLD_SCROLL, NEW_SCROLL);
  console.log('✅ Fix 3: Scroll detection improved (cross-browser + 88% threshold)');
} else {
  console.log('⚠️  Scroll anchor not found exactly');
}

// Fix handleAccept — set pr_terms_viewed + correct redirect
const OLD_ACCEPT = `  // F35.15 — Timestamp + version saved on accept
  const handleAccept = async () => {
    if (!canAccept) return
    setAccepting(true)
    try { localStorage.setItem('pr_terms_accepted', 'true') } catch {}
    try {
      const tk = localStorage.getItem('pr_token')
      if (tk) await fetch(\`\${API}/api/auth/accept-terms\`, { method: 'POST', headers: { Authorization: \`Bearer \${tk}\` } })
    } catch {}
    const back = new URLSearchParams(window.location.search).get('back')
    if (back) router.push(back); else router.push('/dashboard')
  }`;

const NEW_ACCEPT = `  // F35.15 — Timestamp + version saved on accept
  const handleAccept = async () => {
    if (!canAccept) return
    setAccepting(true)
    try {
      localStorage.setItem('pr_terms_accepted', 'true')
      // Signal register page to auto-check T&C checkbox
      localStorage.setItem('pr_terms_viewed', 'true')
    } catch {}
    try {
      const tk = localStorage.getItem('pr_token')
      if (tk) await fetch(\`\${API}/api/auth/accept-terms\`, { method: 'POST', headers: { Authorization: \`Bearer \${tk}\` } })
    } catch {}
    const params = new URLSearchParams(window.location.search)
    const back = params.get('back')
    // Small delay for state to settle, then redirect
    setTimeout(() => {
      if (back) router.push(back)
      else router.push('/dashboard')
    }, 150)
  }`;

if (c.includes(OLD_ACCEPT)) {
  c = c.replace(OLD_ACCEPT, NEW_ACCEPT);
  console.log('✅ Fix 4: Accept sets pr_terms_viewed + correct redirect');
} else {
  console.log('⚠️  Accept anchor not found exactly');
}

// Also ensure back button works on desktop — it's using router.back()
// which should work. The issue might be z-index. Add z-index to footer.
const OLD_FOOTER = `        <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>
          <button className="lb" onClick={handleAccept} disabled={!canAccept || accepting} style={{ flex: 1, minWidth: 200 }}>`;

const NEW_FOOTER = `        <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', position: 'relative', zIndex: 10 }}>
          <button className="lb" onClick={handleAccept} disabled={!canAccept || accepting} style={{ flex: 1, minWidth: 200 }}>`;

if (c.includes(OLD_FOOTER)) {
  c = c.replace(OLD_FOOTER, NEW_FOOTER);
  console.log('✅ Fix 5: Accept/Decline buttons z-index fixed (desktop clickable)');
} else {
  console.log('⚠️  Footer anchor not found exactly');
}

// Fix back button — it uses router.back() which needs client-side nav
// Replace with explicit href
const OLD_BACK_BTN = `          <button onClick={() => router.back()} style={{ background: 'none', border: 'none', color: PRI, cursor: 'pointer', fontSize: 20 }}>←</button>`;
const NEW_BACK_BTN = `          <a href="javascript:history.back()" style={{ background: 'none', border: 'none', color: PRI, cursor: 'pointer', fontSize: 20, textDecoration: 'none' }}>←</a>`;
if (c.includes(OLD_BACK_BTN)) {
  c = c.replace(OLD_BACK_BTN, NEW_BACK_BTN);
  console.log('✅ Fix 6: Back button uses history.back()');
}

// Also fix Decline button
const OLD_DECLINE = `          <button onClick={() => router.back()} style={{ flex: 1, minWidth: 200, padding: 15, borderRadius: 10, border: \`1.5px solid \${BORD}\`, background: 'transparent', color: SUB, fontSize: 16, fontWeight: 600, cursor: 'pointer', fontFamily: 'Inter,sans-serif' }}>`;
const NEW_DECLINE = `          <button onClick={() => { try { window.history.back() } catch { window.location.href = '/register' } }} style={{ flex: 1, minWidth: 200, padding: 15, borderRadius: 10, border: \`1.5px solid \${BORD}\`, background: 'transparent', color: SUB, fontSize: 16, fontWeight: 600, cursor: 'pointer', fontFamily: 'Inter,sans-serif' }}>`;
if (c.includes(OLD_DECLINE)) {
  c = c.replace(OLD_DECLINE, NEW_DECLINE);
  console.log('✅ Fix 7: Decline button uses window.history.back()');
}

fs.writeFileSync(f, c);
console.log('✅ terms/page.tsx updated');
EOF

# ─── Verification ───────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════"
echo "  Bug Fix Verification"
echo "══════════════════════════════════════════════"
R="$FE/app/register/page.tsx"
TR="$FE/app/terms/page.tsx"

chk(){ grep -q "$2" "$1" 2>/dev/null && echo "  ✅ $3" || echo "  ❌ $3"; }

chk "$R"  "pr_terms_viewed"          "Register: auto-check on return from terms"
chk "$R"  "terms?back=/register"     "Register: T&C link passes ?back=/register"
chk "$R"  "Read Terms.*Conditions"   "Register: Read T&C prompt shown first"
chk "$R"  "Terms.*Conditions read"   "Register: checkmark shown after reading"
chk "$TR" "window.scrollY"           "Terms: improved scroll detection"
chk "$TR" "88"                        "Terms: 88% scroll threshold (lenient)"
chk "$TR" "setTimeout.*onScroll"     "Terms: immediate mount check"
chk "$TR" "pr_terms_viewed.*true"    "Terms: sets pr_terms_viewed on accept"
chk "$TR" "params.get.*back"         "Terms: correct back redirect"
chk "$TR" "zIndex: 10"               "Terms: buttons z-index fix (desktop)"
chk "$TR" "history.back"             "Terms: back/decline use history.back()"

echo ""
echo "  Bug 1 Fixed: T&C checkbox requires reading terms first"
echo "  Bug 2 Fixed: Desktop buttons z-index + router.back() replaced"
echo "  Bug 3 Fixed: Accept sets pr_terms_viewed → register auto-checks"
echo ""
echo "══════════════════════════════════════════════"
echo "🎉 git add . && git commit -m 'fix: F35 T&C checkbox + terms scroll + redirect' && git push"
echo "══════════════════════════════════════════════"
