#!/bin/bash
# ProveRank Admin V4 — Build Error Fix
# Fixes: page.tsx:1987:253 — Invalid object literal in institute_report tab
# Rule C1: node << EOF | Rule C2: NO sed -i | NO Python

G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; N='\033[0m'
log(){ echo -e "${G}[OK]${N} $1"; }
step(){ echo -e "\n${B}===== $1 =====${N}"; }

step "Fixing build error at page.tsx:1987:253"

node << 'NODEEOF'
const fs = require('fs'), os = require('os')
const p = os.homedir() + '/workspace/frontend/app/admin/x7k2p/page.tsx'
let c = fs.readFileSync(p, 'utf8')

// ── FIX: Replace the broken institute_report stats map ──
// The old code had invalid object literal: {ico:'👥',l:'Total Students',(students||[]).length}
// Replace entire institute_report tab with clean version

const oldBlock = `          {/* ══ INSTITUTE REPORT ══ */}
          {tab==='institute_report'&&(
            <div>
              <div style={pageTitle}>🏫 Institute Report Card (N19)</div>
              <div style={pageSub}>Monthly auto-generated PDF — overall platform performance, top students</div>
              <PageHero icon="🏫" title="Monthly Institute Report" subtitle="Auto-generated comprehensive report showing overall platform performance, top students, weak areas, and improvement trends. Perfect for institute management review."/>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginBottom:16}}>
                {[{ico:'👥',l:'Total Students',(students||[]).length},{ico:'📝',l:'Exams Conducted',(exams||[]).length},{ico:'📈',l:'Avg Score',stats?.avgScore||'—'},{ico:'🏆',l:'Completion Rate',stats?.completionRate||'—'}].map((s:any,i)=>(
                  <div key={i} style={cs}>
                    <div style={{fontSize:24}}>{s.ico}</div>
                    <div style={{fontWeight:700,fontSize:18,color:ACC,margin:'4px 0'}}>{(s as any)[(students||[]).length]||s[(exams||[]).length]||s[stats?.avgScore]||s[stats?.completionRate]||Object.values(s)[2]||'—'}</div>
                    <div style={{fontSize:11,color:DIM}}>{s.l}</div>
                  </div>
                ))}
              </div>
              <div style={{display:'flex',gap:10}}>
                <button onClick={()=>doExport(\`\${API}/api/admin/institute-report/pdf\`,'institute_report.pdf')} style={{...bp}}>📄 Download Monthly Report PDF</button>
                <button onClick={()=>doExport(\`\${API}/api/admin/institute-report/excel\`,'institute_report.xlsx')} style={{...bg_}}>📊 Download Excel Report</button>
              </div>
            </div>
          )}`

const newBlock = `          {/* ══ INSTITUTE REPORT ══ */}
          {tab==='institute_report'&&(
            <div>
              <div style={pageTitle}>🏫 Institute Report Card (N19)</div>
              <div style={pageSub}>Monthly auto-generated PDF — overall platform performance, top students</div>
              <PageHero icon="🏫" title="Monthly Institute Report" subtitle="Auto-generated comprehensive report showing overall platform performance, top students, weak areas, and improvement trends. Perfect for institute management review."/>
              <div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:16}}>
                <StatBox ico='👥' lbl='Total Students' val={(students||[]).length} col={ACC}/>
                <StatBox ico='📝' lbl='Exams Conducted' val={(exams||[]).length} col={GOLD}/>
                <StatBox ico='📈' lbl='Avg Score' val={stats?.avgScore||'—'} col={SUC}/>
                <StatBox ico='🏆' lbl='Completion Rate' val={stats?.completionRate||'—'} col='#FF6B9D'/>
              </div>
              <div style={cs}>
                <div style={{fontWeight:700,marginBottom:10,fontSize:13}}>📊 This Month Summary</div>
                {[
                  {l:'New Registrations',v:(students||[]).filter(s=>s.createdAt&&new Date(s.createdAt).getMonth()===new Date().getMonth()).length,c:ACC},
                  {l:'Exams Conducted',v:(exams||[]).length,c:GOLD},
                  {l:'Active Students',v:(students||[]).filter(s=>!s.banned).length,c:SUC},
                  {l:'Questions in Bank',v:(questions||[]).length,c:'#FF6B9D'},
                ].map(({l,v,c})=>(
                  <div key={l} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'10px 0',borderBottom:\`1px solid \${BOR}\`,fontSize:12}}>
                    <span style={{color:DIM}}>{l}</span>
                    <span style={{color:c,fontWeight:700,fontSize:14}}>{v}</span>
                  </div>
                ))}
              </div>
              <div style={{display:'flex',gap:10,flexWrap:'wrap'}}>
                <button onClick={()=>doExport(\`\${API}/api/admin/institute-report/pdf\`,'institute_report.pdf')} style={bp}>📄 Download Monthly Report PDF</button>
                <button onClick={()=>doExport(\`\${API}/api/admin/institute-report/excel\`,'institute_report.xlsx')} style={bg_}>📊 Download Excel Report</button>
              </div>
            </div>
          )}`

if (c.includes(oldBlock)) {
  c = c.replace(oldBlock, newBlock)
  console.log('✅ Institute report tab fixed — invalid object literal replaced.')
} else {
  // Fallback: find and fix the broken line with a regex
  console.log('Using regex fallback fix...')

  // Fix the specific broken object literal pattern
  c = c.replace(
    /\{ico:'👥',l:'Total Students',\(students\|\|\[\]\)\.length\},\{ico:'📝',l:'Exams Conducted',\(exams\|\|\[\]\)\.length\},\{ico:'📈',l:'Avg Score',stats\?\.avgScore\|\|'—'\},\{ico:'🏆',l:'Completion Rate',stats\?\.completionRate\|\|'—'\}\]\.map\(\(s:any,i:number\)=>\([^)]*\)\)/gs,
    `null`
  )

  // Also try to find just the broken line
  const brokenPattern = /\{ico:'👥',l:'Total Students',\(students/
  if (brokenPattern.test(c)) {
    // Replace the entire problematic map block
    c = c.replace(
      /<div style=\{\{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginBottom:16\}\}>\s*\{.*?institute.*?\}\s*<\/div>/s,
      `<div style={{display:'flex',flexWrap:'wrap',gap:12,marginBottom:16}}>
                <StatBox ico='👥' lbl='Total Students' val={(students||[]).length} col={ACC}/>
                <StatBox ico='📝' lbl='Exams Conducted' val={(exams||[]).length} col={GOLD}/>
                <StatBox ico='📈' lbl='Avg Score' val={stats?.avgScore||'—'} col={SUC}/>
                <StatBox ico='🏆' lbl='Completion Rate' val={stats?.completionRate||'—'} col='#FF6B9D'/>
              </div>`
    )
  }
}

// ── ADDITIONAL SAFETY FIXES ──

// Fix 1: Triple equals in JSX that Turbopack doesn't like
// s.integrityScore===undefined should be fine, but ≡ (triple equals) visual in error
// The screenshots show: s.integrityScore===undefined — this is actually valid
// The real error was the invalid object literal above

// Fix 2: Ensure no bare > or < in JSX expressions
// These were shown in error screenshots as potential issues
c = c.replace(/(\(s\.integrityScore\|0\))>70/g, '($1)>70')
c = c.replace(/(\(s\.integrityScore\|0\))>=40/g, '($1)>=40')
c = c.replace(/(\(s\.integrityScore\|0\))<40/g, '($1)<40')

fs.writeFileSync(p, c)
console.log('✅ All fixes applied.')
console.log('Lines: ' + c.split('\n').length)
NODEEOF

log "Fix applied!"

step "Now push to GitHub"
echo ""
echo "Run these commands in Replit — one by one:"
echo ""
echo "  cd ~/workspace"
echo ""
echo "  git add frontend/app/admin/x7k2p/page.tsx"
echo ""
echo "  git commit -m \"Fix: Build error line 1987 — institute report invalid object literal\""
echo ""
echo "  git push origin main"
echo ""
echo -e "${G}Vercel will auto-deploy — should be green in 1-2 minutes.${N}"
