#!/bin/bash
set -e
echo "═══════════════════════════════════════════"
echo "  Bug Fix — Backend (auth.js)"
echo "  Bug1: Login slow | Bug2: Email check"
echo "═══════════════════════════════════════════"

AUTH="routes/auth.js"
if [ ! -f "$AUTH" ]; then echo "❌ Run from src/ directory"; exit 1; fi

cp "$AUTH" "${AUTH}.bak_fix3"
echo "✅ Backup: auth.js.bak_fix3"

node << 'JSEOF'
const fs = require('fs')
let code = fs.readFileSync('routes/auth.js', 'utf8')
let fixed = 0

// ── BUG 1A: Add 1.5s timeout to geo lookup ──────────────
const geoOld = "const geoRes = await fetch(`http://ip-api.com/json/${realIp}?fields=city,country,status`)"
const geoNew = "const _ac=new AbortController();const _gt=setTimeout(()=>_ac.abort(),1500);const geoRes=await fetch(`http://ip-api.com/json/${realIp}?fields=city,country,status`,{signal:_ac.signal});clearTimeout(_gt)"
if (code.includes(geoOld)) {
  code = code.replace(geoOld, geoNew)
  fixed++; console.log('✅ Bug1-A: Geo lookup timeout added (1.5s)')
} else console.log('⚠️  Bug1-A: pattern not found')

// ── BUG 1B: Make login history update fire-and-forget ───
const histOld = `    await User.collection.updateOne({ _id: user._id },\n      { $set: { loginHistory: history.slice(-50) }, $inc: { loginCount: 1 } })`
const histNew = `    User.collection.updateOne({ _id: user._id },\n      { $set: { loginHistory: history.slice(-50) }, $inc: { loginCount: 1 } }).catch(()=>{})`
if (code.includes(histOld)) {
  code = code.replace(histOld, histNew)
  fixed++; console.log('✅ Bug1-B: History update is now fire-and-forget')
} else console.log('⚠️  Bug1-B: pattern not found')

// ── BUG 2: Email check — deleted users show as available ─
const emailOld = "const taken = !!(existing && (existing.emailVerified || existing.verified) && !existing.archived)"
const emailNew = "const taken = !!(existing && (existing.emailVerified || existing.verified) && !existing.archived && existing.deleted !== true)"
if (code.includes(emailOld)) {
  code = code.replace(emailOld, emailNew)
  fixed++; console.log('✅ Bug2: Deleted user email now shows as available')
} else console.log('⚠️  Bug2: pattern not found')

fs.writeFileSync('routes/auth.js', code)
console.log(`\n✅ Done — ${fixed}/3 fixes applied`)
JSEOF

echo ""
echo "═══════════════════════════════════════════"
echo "  ✅ BACKEND DONE — Restart backend server"
echo "═══════════════════════════════════════════"
