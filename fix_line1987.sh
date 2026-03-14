#!/bin/bash
# ProveRank Admin V4 — Exact Fix for line 1987:253
# Error: Unexpected token — > and < inside JSX expression causing Turbopack parse fail
G='\033[0;32m'; B='\033[0;34m'; N='\033[0m'
log(){ echo -e "${G}[OK]${N} $1"; }
step(){ echo -e "\n${B}===== $1 =====${N}"; }

step "Fixing line 1987 — integrity score JSX comparison operators"

node << 'NODEEOF'
const fs=require('fs'),os=require('os')
const p=os.homedir()+'/workspace/frontend/app/admin/x7k2p/page.tsx'
let c=fs.readFileSync(p,'utf8')

// ══ THE EXACT BUG ══
// In the integrity tab, these 3 stat boxes use > and < inside JSX {}
// Turbopack 16.1.6 fails on: .filter(s=>...&&(s.integrityScore||0)>70).length
// inside JSX — it treats > as closing tag
//
// FIX: Extract values BEFORE return into variables, then use in JSX

// Replace the entire integrity stats section (3 divs with the filter+comparison)
const broken=`              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr 1fr',gap:10,marginBottom:16}}>
                <div style={{...cs,textAlign:'center'}}><div style={{fontSize:24,color:SUC,fontWeight:700}}>{(students||[]).filter(s=>s.integrityScore!==undefined&&(s.integrityScore||0)>70).length}</div><div style={{fontSize:11,color:DIM}}>High Trust (>70)</div></div>
                <div style={{...cs,textAlign:'center'}}><div style={{fontSize:24,color:WRN,fontWeight:700}}>{(students||[]).filter(s=>s.integrityScore!==undefined&&(s.integrityScore||0)>=40&&(s.integrityScore||0)<=70).length}</div><div style={{fontSize:11,color:DIM}}>Medium Trust</div></div>
                <div style={{...cs,textAlign:'center'}}><div style={{fontSize:24,color:DNG,fontWeight:700}}>{(students||[]).filter(s=>s.integrityScore!==undefined&&(s.integrityScore||0)<40).length}</div><div style={{fontSize:11,color:DIM}}>Low Trust (<40)</div></div>
              </div>`

const fixed=`              {(()=>{
                const hi=(students||[]).filter(s=>s.integrityScore!==undefined&&Number(s.integrityScore||0)>70).length
                const md=(students||[]).filter(s=>s.integrityScore!==undefined&&Number(s.integrityScore||0)>=40&&Number(s.integrityScore||0)<=70).length
                const lo=(students||[]).filter(s=>s.integrityScore!==undefined&&Number(s.integrityScore||0)<40).length
                return(
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr 1fr',gap:10,marginBottom:16}}>
                    <div style={{...cs,textAlign:'center'}}><div style={{fontSize:24,color:SUC,fontWeight:700}}>{hi}</div><div style={{fontSize:11,color:DIM}}>High Trust (70+)</div></div>
                    <div style={{...cs,textAlign:'center'}}><div style={{fontSize:24,color:WRN,fontWeight:700}}>{md}</div><div style={{fontSize:11,color:DIM}}>Medium Trust</div></div>
                    <div style={{...cs,textAlign:'center'}}><div style={{fontSize:24,color:DNG,fontWeight:700}}>{lo}</div><div style={{fontSize:11,color:DIM}}>Low Trust (below 40)</div></div>
                  </div>
                )
              })()}`

if(c.includes(broken)){
  c=c.replace(broken,fixed)
  console.log('✅ FIX 1 applied: integrity stats section fixed (IIFE pattern)')
} else {
  console.log('Pattern not found exactly — trying line-by-line fix...')
  
  // Line by line approach — find and fix each of the 3 broken lines
  const lines=c.split('\n')
  let fixCount=0
  
  const newLines=lines.map((l,i)=>{
    // Line with >70 comparison inside JSX
    if(l.includes('integrityScore||0)>70).length}')&&l.includes('High Trust')){
      fixCount++
      return l.replace(
        '{(students||[]).filter(s=>s.integrityScore!==undefined&&(s.integrityScore||0)>70).length}',
        '{(students||[]).filter(s=>{ const sc=Number(s.integrityScore||0); return s.integrityScore!==undefined && sc>70 }).length}'
      )
    }
    // Line with >=40 and <=70 inside JSX
    if(l.includes('integrityScore||0)>=40')&&l.includes('Medium Trust')){
      fixCount++
      return l.replace(
        '{(students||[]).filter(s=>s.integrityScore!==undefined&&(s.integrityScore||0)>=40&&(s.integrityScore||0)<=70).length}',
        '{(students||[]).filter(s=>{ const sc=Number(s.integrityScore||0); return s.integrityScore!==undefined && sc>=40 && sc<=70 }).length}'
      )
    }
    // Line with <40 comparison inside JSX
    if(l.includes('integrityScore||0)<40').length&&l.includes('Low Trust')){
      fixCount++
      return l.replace(
        '{(students||[]).filter(s=>s.integrityScore!==undefined&&(s.integrityScore||0)<40).length}',
        '{(students||[]).filter(s=>{ const sc=Number(s.integrityScore||0); return s.integrityScore!==undefined && sc<40 }).length}'
      )
    }
    return l
  })
  
  c=newLines.join('\n')
  if(fixCount>0){
    console.log('✅ FIX 1 (line-by-line) applied: '+fixCount+' lines fixed')
  } else {
    console.log('⚠️ Could not find the exact pattern. Applying broad fix...')
    // Broad fix — replace ALL >70 <40 >=40 <=70 filter patterns in JSX
    c=c.replace(
      /\{\(students\|\|\[\]\)\.filter\(s=>s\.integrityScore!==undefined&&\(s\.integrityScore\|\|0\)>70\)\.length\}/g,
      '{(students||[]).filter(s=>{ const sc=Number(s.integrityScore||0); return s.integrityScore!==undefined && sc>70 }).length}'
    )
    c=c.replace(
      /\{\(students\|\|\[\]\)\.filter\(s=>s\.integrityScore!==undefined&&\(s\.integrityScore\|\|0\)>=40&&\(s\.integrityScore\|\|0\)<=70\)\.length\}/g,
      '{(students||[]).filter(s=>{ const sc=Number(s.integrityScore||0); return s.integrityScore!==undefined && sc>=40 && sc<=70 }).length}'
    )
    c=c.replace(
      /\{\(students\|\|\[\]\)\.filter\(s=>s\.integrityScore!==undefined&&\(s\.integrityScore\|\|0\)<40\)\.length\}/g,
      '{(students||[]).filter(s=>{ const sc=Number(s.integrityScore||0); return s.integrityScore!==undefined && sc<40 }).length}'
    )
    console.log('✅ Broad fix applied')
  }
}

// ══ FIX 2: Also fix similar patterns elsewhere in file ══
// Any place where (someVal)>number or (someVal)<number is directly in JSX {}
// These are: integrity score list items
c=c.replace(
  /\(s\.integrityScore\|\|0\)>70\?SUC:\(s\.integrityScore\|\|0\)>40\?WRN:DNG/g,
  '(Number(s.integrityScore||0))>70?SUC:(Number(s.integrityScore||0))>40?WRN:DNG'
)
c=c.replace(
  /\(s\.integrityScore\|\|0\)>70\?SUC:s\.integrityScore>40\?WRN:DNG/g,
  'Number(s.integrityScore||0)>70?SUC:Number(s.integrityScore||0)>40?WRN:DNG'
)

// ══ FIX 3: "High Trust (>70)" text — > in JSX text is fine but wrap to be safe ══
c=c.replace(/>High Trust \(>70\)</g,'>High Trust (70+)<')
c=c.replace(/>Low Trust \(<40\)</g,'>Low Trust (below 40)<')

// ══ FIX 4: institute_report broken object literal (previous fix) ══
// Check if it's still there
if(c.includes("(students||[]).length},{ico:'📝'")){
  console.log('Also fixing institute_report object literal...')
  const brokenObj=c.match(/\[\{ico:'👥',l:'Total Students',\(students.*?\)\.map\([^)]+\)\)/s)
  if(brokenObj){
    c=c.replace(brokenObj[0],
      `null && []`  // temporary null to prevent crash, replaced below
    )
  }
  // Full replacement
  c=c.replace(
    /<div style=\{\{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginBottom:16\}\}>\s*\{null && \[\]\}\s*<\/div>/,
    `<div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:16}}>
                <StatBox ico='👥' lbl='Total Students' val={(students||[]).length} col={ACC}/>
                <StatBox ico='📝' lbl='Exams Conducted' val={(exams||[]).length} col={GOLD}/>
                <StatBox ico='📈' lbl='Avg Score' val={stats?.avgScore||'—'} col={SUC}/>
                <StatBox ico='🏆' lbl='Completion Rate' val={stats?.completionRate||'—'} col='#FF6B9D'/>
              </div>`
  )
  console.log('✅ FIX 4 applied: institute_report also fixed')
}

fs.writeFileSync(p,c)
console.log('\n✅ All fixes done! Lines: '+c.split('\n').length)

// ══ VALIDATION ══
const check=c.split('\n')
const problems=[]
check.forEach((l,i)=>{
  if(l.includes('integrityScore||0)>70).length}')) problems.push('Line '+(i+1)+': >70 still in JSX')
  if(l.includes('integrityScore||0)<40).length}')) problems.push('Line '+(i+1)+': <40 still in JSX')
  if(l.includes(",(students||[]).length}")) problems.push('Line '+(i+1)+': broken object literal')
})

if(problems.length===0){
  console.log('✅ VALIDATION PASSED — No remaining issues detected')
}else{
  console.log('⚠️ Still has issues:')
  problems.forEach(p=>console.log('  '+p))
}
NODEEOF

log "Fix complete!"
echo ""
echo "Now run:"
echo "  cd ~/workspace"
echo "  git add frontend/app/admin/x7k2p/page.tsx"
echo "  git commit -m \"Fix: line 1987 integrity score JSX comparison operators\""
echo "  git push origin main"
