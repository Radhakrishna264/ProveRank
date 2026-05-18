#!/bin/bash
# Fix#6 — Student ID in Admin/Superadmin Panel (all student listing places)
# Upload to Replit root and run: bash fix6_student_id_admin.sh

echo "🔍 Starting Fix#6 diagnosis and fix..."

FILE="/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx"

node << 'NODEOF'
const fs = require('fs')
const FILE = '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx'
let c = fs.readFileSync(FILE, 'utf8')

// ─── FIX 1: selStudent Expanded Card — Add studentId before email ───────────
// Target: the email line in selStudent expanded card (has ► prefix and selStudent.email)
const old1 = `<div style={{fontSize:12,color:'#8899AA',marginBottom:2}}>►{selStudent.email}</div>`
const new1 = `<div style={{fontSize:12,color:'#8899AA',marginBottom:2}}>►{selStudent.email}</div>
                  {(selStudent as any).studentId&&<div style={{display:'inline-flex',alignItems:'center',gap:6,marginTop:4,marginBottom:2,padding:'3px 10px',background:'rgba(77,159,255,0.08)',borderRadius:6,border:'1px solid rgba(77,159,255,0.2)',width:'fit-content'}}>
                    <span style={{fontSize:9,color:'#6B8FAF',letterSpacing:1.5,textTransform:'uppercase',fontFamily:'Inter,sans-serif',fontWeight:700}}>Student ID</span>
                    <span style={{fontSize:12,fontWeight:800,color:'#4D9FFF',fontFamily:'monospace',letterSpacing:2}}>{(selStudent as any).studentId}</span>
                    <CopyBtn text={(selStudent as any).studentId} size="sm"/>
                  </div>}`

if(c.includes(old1)){
  c = c.replace(old1, new1)
  console.log('✅ Fix 1: studentId added to selStudent expanded card')
} else {
  console.log('⚠️ Fix 1: Pattern not found — searching alternatives...')
  // Try alternate pattern (without marginBottom)
  const alt1 = `color:'#8899AA',marginBottom:2}}>►{selStudent.email}`
  const idx = c.indexOf(alt1)
  if(idx !== -1){
    console.log('  Found at index:', idx, '— context:', JSON.stringify(c.substring(idx-20, idx+80)))
  } else {
    // Find any selStudent.email occurrence
    const matches = []
    let i = 0
    while(i < c.length){
      const fi = c.indexOf('selStudent.email', i)
      if(fi === -1) break
      matches.push({idx:fi, ctx: c.substring(fi-50,fi+60)})
      i = fi + 1
    }
    console.log('  selStudent.email occurrences:', matches.length)
    matches.forEach((m,i) => console.log(`  #${i+1}:`, JSON.stringify(m.ctx)))
  }
}

// ─── FIX 2: Find Active Collapsed Student Card & Add studentId ──────────────
// Look for the active student collapsed card — it has name + email + View/Ban buttons
// The card uses 's' variable and setSelStudent(s) for View button

// Strategy: find where the collapsed active cards are rendered
// Search for the pattern of name + email in the collapsed card format

// Common patterns in collapsed cards:
const patterns = [
  // Pattern A: name div then email div in collapsed format
  `{s.name||'-'}</div>`,
  // Pattern B: setSelStudent call (View button)
  `setSelStudent(s)`,
  // Pattern C: student collapsed card
  `setBanId(s._id)`,
]

console.log('\n📍 Locating active collapsed student card...')
patterns.forEach(p => {
  const occurrences = []
  let i = 0
  while(i < c.length){
    const fi = c.indexOf(p, i)
    if(fi === -1) break
    occurrences.push(fi)
    i = fi + 1
  }
  console.log(`Pattern "${p.substring(0,40)}": ${occurrences.length} occurrences at lines:`)
  occurrences.forEach(idx => {
    const lineNum = c.substring(0,idx).split('\n').length
    console.log(`  Line ${lineNum}: ${JSON.stringify(c.substring(idx,idx+100))}`)
  })
})

// ─── FIX 2 Actual: Add studentId to active collapsed card ───────────────────
// The active collapsed card email display won't have ► prefix (that's only in expanded)
// Look for the name+email pattern in the student management list section

// Find the map section that renders active students (not selStudent, not archived)
// The collapsed card for active students likely has this pattern near email:
// fontSize:11 or 12, color something dim, s.email

// Try to find the collapsed card by looking for setSelStudent near s.email
const setSelIdx = c.indexOf('setSelStudent(s)')
if(setSelIdx !== -1){
  const lineNum = c.substring(0, setSelIdx).split('\n').length
  console.log(`\n📍 setSelStudent(s) found at line ${lineNum}`)
  // Look backwards from setSelStudent for the email display
  const surrounding = c.substring(Math.max(0,setSelIdx-800), setSelIdx+200)
  console.log('Surrounding context (800 chars before setSelStudent):')
  console.log(surrounding)
}

// ─── FIX 3: Top Students Widget on Dashboard — Add studentId ────────────────
// The top students widget shows s.name but might not show studentId
const old3 = `<span style={{flex:1,fontWeight:500,color:TS,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{s.name||'-'}</span>`
if(c.includes(old3)){
  const new3 = `<span style={{flex:1,fontWeight:500,color:TS,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{s.name||'-'}</span>
                      {(s as any).studentId&&<span style={{fontSize:8,fontWeight:700,color:'#4D9FFF',fontFamily:'monospace',letterSpacing:1,flexShrink:0}}>{(s as any).studentId}</span>}`
  c = c.replace(old3, new3)
  console.log('✅ Fix 3: studentId added to Top Students dashboard widget')
} else {
  console.log('⚠️ Fix 3: Top Students widget pattern not found')
}

fs.writeFileSync(FILE, c)
console.log('\n📝 File saved. Check above for patterns to complete Fix 2.')
NODEOF

echo ""
echo "📋 Now checking for the active collapsed card pattern..."
echo ""

# Show lines around setSelStudent(s) to find the collapsed card structure
node << 'NODE2'
const fs = require('fs')
const c = fs.readFileSync('/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx', 'utf8')
const lines = c.split('\n')

// Find setSelStudent(s) occurrences
lines.forEach((line, i) => {
  if(line.includes('setSelStudent(s)') && !line.includes('//') && !line.includes('setSelStudent(s._')){
    console.log(`\n--- Line ${i+1} (setSelStudent(s)) ---`)
    // Show 25 lines before and 5 after
    for(let j = Math.max(0, i-25); j <= Math.min(lines.length-1, i+5); j++){
      console.log(`${j+1}: ${lines[j]}`)
    }
  }
})
NODE2
