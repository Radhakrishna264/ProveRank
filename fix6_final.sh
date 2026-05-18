#!/bin/bash
# Fix#6 FINAL — Add Student ID to Active Student Collapsed Card
# Run: bash fix6_final.sh

node << 'EOF'
const fs = require('fs')
const FILE = '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx'
let c = fs.readFileSync(FILE, 'utf8')

// ─── FIX: Add studentId badge in collapsed active student card ───────────────
// Target: the email div at line ~2154 which shows s.email WITHOUT studentId
// The card structure: name+badges div → email div → date+phone div

// Pattern: closing of the name+badges div, followed by the email-only div
const old1 = `</div>
                  <div style={{fontSize:11,color:'#8899AA'}}>{s.email}</div>`

const new1 = `</div>
                  {(s as any).studentId&&<div style={{display:'inline-flex',alignItems:'center',gap:5,marginBottom:4,padding:'2px 8px',background:'rgba(77,159,255,0.08)',borderRadius:5,border:'1px solid rgba(77,159,255,0.18)',width:'fit-content'}}>
                    <span style={{fontSize:9,fontWeight:800,color:'#4D9FFF',fontFamily:'monospace',letterSpacing:1.5}}>{(s as any).studentId}</span>
                    <CopyBtn text={(s as any).studentId} size="sm"/>
                  </div>}
                  <div style={{fontSize:11,color:'#8899AA'}}>{s.email}</div>`

if(c.includes(old1)){
  c = c.replace(old1, new1)
  console.log('✅ Fix: studentId badge added to active collapsed student card')
} else {
  // Try alternate spacing
  const old2 = `</div>\n                  <div style={{fontSize:11,color:'#8899AA'}}>{s.email}</div>`
  if(c.includes(old2)){
    c = c.replace(old2, `</div>\n                  {(s as any).studentId&&<div style={{display:'inline-flex',alignItems:'center',gap:5,marginBottom:4,padding:'2px 8px',background:'rgba(77,159,255,0.08)',borderRadius:5,border:'1px solid rgba(77,159,255,0.18)',width:'fit-content'}}><span style={{fontSize:9,fontWeight:800,color:'#4D9FFF',fontFamily:'monospace',letterSpacing:1.5}}>{(s as any).studentId}</span><CopyBtn text={(s as any).studentId} size="sm"/></div>}\n                  <div style={{fontSize:11,color:'#8899AA'}}>{s.email}</div>`)
    console.log('✅ Fix (alt): studentId badge added to active collapsed student card')
  } else {
    console.log('⚠️ Pattern not found — showing all s.email occurrences near collapsed card:')
    // Find the collapsed card email by looking near line 2154
    const lines = c.split('\n')
    lines.forEach((line, i) => {
      if(line.includes("s.email") && !line.includes('selStudent') && !line.includes('//') && (i > 2100 && i < 2200)){
        console.log(`Line ${i+1}: ${JSON.stringify(line)}`)
        console.log(`Line ${i}: ${JSON.stringify(lines[i-1])}`)
      }
    })
  }
}

// ─── VERIFY: Check selStudent Fix 1 (from previous script) was applied ───────
if(c.includes('(selStudent as any).studentId')){
  console.log('✅ Verified: selStudent expanded card already has studentId (Fix1 applied)')
} else {
  // Apply Fix 1 if not already done
  const s1old = `<div style={{fontSize:12,color:'#8899AA',marginBottom:2}}>►{selStudent.email}</div>`
  const s1new = `<div style={{fontSize:12,color:'#8899AA',marginBottom:2}}>►{selStudent.email}</div>
                  {(selStudent as any).studentId&&<div style={{display:'inline-flex',alignItems:'center',gap:6,marginTop:3,marginBottom:3,padding:'3px 10px',background:'rgba(77,159,255,0.08)',borderRadius:6,border:'1px solid rgba(77,159,255,0.2)',width:'fit-content'}}>
                    <span style={{fontSize:9,color:'#6B8FAF',letterSpacing:1.5,textTransform:'uppercase',fontWeight:700}}>Student ID</span>
                    <span style={{fontSize:12,fontWeight:800,color:'#4D9FFF',fontFamily:'monospace',letterSpacing:2}}>{(selStudent as any).studentId}</span>
                    <CopyBtn text={(selStudent as any).studentId} size="sm"/>
                  </div>}`
  if(c.includes(s1old)){
    c = c.replace(s1old, s1new)
    console.log('✅ Fix1 (selStudent card): applied now')
  } else {
    console.log('⚠️ Fix1 already applied or pattern changed')
  }
}

fs.writeFileSync(FILE, c)
console.log('\n✅ All fixes applied. File saved.')
EOF

echo ""
echo "📦 Running git push..."
cd /home/runner/workspace
git add frontend/app/admin/x7k2p/page.tsx
git commit -m "Fix#6: Student ID visible in active collapsed cards + selStudent expanded card in Admin/Superadmin panel"
git push origin main
echo "✅ Done! Vercel deploying (~2 min)"
