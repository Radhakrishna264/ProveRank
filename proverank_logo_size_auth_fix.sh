#!/bin/bash
# ProveRank — Fix Landing + Login Logo Issues

FE="$HOME/workspace/frontend"
echo "📁 Using: $FE"

# ════════════════════════════════════════
# FIX 1: Landing page — PRLogo size bigger
# Line 164: <PRLogo/> → <PRLogo size={52}/>
# ════════════════════════════════════════
node << 'EOF'
const fs = require('fs')
const path = require('path')
const FE = process.env.HOME + '/workspace/frontend'

// ── FIX 1: app/page.tsx ──
const landingFile = FE + '/app/page.tsx'
let c = fs.readFileSync(landingFile, 'utf8')
const orig1 = c

// Fix PRLogo size — make it bigger
c = c.replace(/<PRLogo\s*\/>/g, '<PRLogo size={56}/>')
c = c.replace(/<PRLogo\s+size=\{[0-9]+\}\s*\/>/g, '<PRLogo size={56}/>')

if (c !== orig1) {
  fs.writeFileSync(landingFile, c, 'utf8')
  console.log('✅ Fix 1: Landing page PRLogo size → 56')
} else {
  console.log('⚠️  Fix 1: No PRLogo tag found in landing page')
}

// ── FIX 2: app/login/page.tsx — Add PRLogo import + replace text logo ──
const loginFile = FE + '/app/login/page.tsx'
let l = fs.readFileSync(loginFile, 'utf8')
const orig2 = l

// Add PRLogo import if not present
if (!l.includes("import PRLogo")) {
  l = l.replace(
    "'use client'",
    "'use client'\nimport PRLogo from '@/components/PRLogo'"
  )
  console.log('✅ Fix 2a: Added PRLogo import to login')
}

// Replace text "ProveRank" logo div with actual PRLogo component
// Pattern: the ProveRank title text in login page
const oldLogoPattern = /<div style=\{\{fontFamily:'Playfair Display,serif',fontSize:2[0-9],fontWeight:700[^}]*\}\}>ProveRank<\/div>/g
const newLogoJSX = `<div style={{display:'flex',alignItems:'center',justifyContent:'center',gap:10,marginBottom:4}}>
              <PRLogo size={44}/>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>ProveRank</div>
            </div>`

if (oldLogoPattern.test(l)) {
  l = l.replace(oldLogoPattern, newLogoJSX)
  console.log('✅ Fix 2b: Login logo replaced with PRLogo + text')
} else {
  // Try simpler pattern
  const idx = l.indexOf('>ProveRank</div>')
  if (idx > -1) {
    // Find start of this div
    const divStart = l.lastIndexOf('<div', idx)
    const divEnd = idx + '>ProveRank</div>'.length
    l = l.slice(0, divStart) + newLogoJSX + l.slice(divEnd)
    console.log('✅ Fix 2b: Login logo replaced (fallback method)')
  } else {
    console.log('⚠️  Fix 2b: Could not find ProveRank text div in login')
  }
}

if (l !== orig2) {
  fs.writeFileSync(loginFile, l, 'utf8')
  console.log('💾 Login page saved!')
}

// ── FIX 3: app/register/page.tsx — Same logo fix ──
const regFile = FE + '/app/register/page.tsx'
if (fs.existsSync(regFile)) {
  let r = fs.readFileSync(regFile, 'utf8')
  const orig3 = r

  if (!r.includes("import PRLogo")) {
    r = r.replace("'use client'", "'use client'\nimport PRLogo from '@/components/PRLogo'")
    console.log('✅ Fix 3a: Added PRLogo import to register')
  }

  const idx = r.indexOf('>ProveRank</div>')
  if (idx > -1) {
    const divStart = r.lastIndexOf('<div', idx)
    const divEnd = idx + '>ProveRank</div>'.length
    const newLogoReg = `<div style={{display:'flex',alignItems:'center',justifyContent:'center',gap:10,marginBottom:4}}>
              <PRLogo size={44}/>
              <div style={{fontFamily:'Playfair Display,serif',fontSize:26,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent'}}>ProveRank</div>
            </div>`
    r = r.slice(0, divStart) + newLogoReg + r.slice(divEnd)
    console.log('✅ Fix 3b: Register logo replaced')
  }

  if (r !== orig3) {
    fs.writeFileSync(regFile, r, 'utf8')
    console.log('💾 Register page saved!')
  }
}

console.log('\n✅ All fixes applied!')
EOF

echo ""
echo "🚀 Now run:"
echo "   git add ."
echo "   git commit -m 'Fix logo size and auth pages logo'"
echo "   git push origin main"
