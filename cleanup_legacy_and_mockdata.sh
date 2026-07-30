#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# PART A — DELETE legacy/dead code (100% verified safe):
#   1. frontend/app/exam/demo/          — old demo attempt+result flow.
#      Confirmed no active file references it (checked earlier).
#   2. frontend/app/admin/{students,exams,questions,results,
#      announcements,settings,panel}/   — old duplicate admin panel.
#      Confirmed no active file imports/links to these (checked
#      earlier). middleware.ts blocks the exact '/admin' path anyway,
#      so frontend/app/admin/page.tsx (the redirect stub) is dead too
#      — deleted as well.
#   KEPT: frontend/app/admin/layout.tsx — minimal pass-through
#      wrapper that also wraps /admin/x7k2p (your CURRENT admin
#      panel). Deleting it is unnecessary and carries route-render
#      risk for zero benefit, so it's left untouched.
#   KEPT: frontend/app/admin/x7k2p/     — your current, active
#      Admin Panel V4. NOT touched.
#
# PART B — Clean fake/mock DEFAULT data from 4 REAL, currently-used
# dashboard pages (results, results/history, exams, admit-card).
# These are NOT legacy — they're part of the current Student
# Dashboard (Phase 7.2) — but their real API calls either don't
# exist yet on the backend or return empty, and they were silently
# falling back to hardcoded fake numbers instead of an honest empty
# state. This patch removes the fake data only; nothing else changes.
#
# NOTE: dashboard/results/[attemptId]/page.tsx (367 lines, complex —
# has Subjects/Answers/Trend tabs) is intentionally NOT touched in
# this script — it needs a separate, more careful pass since parts
# of its UI depend on fields the real API doesn't return yet. Will
# do that as its own next step.
#
# Node.js exact-string patcher — NOT sed -i, NOT python.
# ══════════════════════════════════════════════════════════════════
set -e
cd ~/workspace

echo "=== PART A: Deleting legacy/dead code ==="

rm -rf frontend/app/exam/demo
echo "✅ Deleted: frontend/app/exam/demo/"

rm -rf frontend/app/admin/students
rm -rf frontend/app/admin/exams
rm -rf frontend/app/admin/questions
rm -rf frontend/app/admin/results
rm -rf frontend/app/admin/announcements
rm -rf frontend/app/admin/settings
rm -rf frontend/app/admin/panel
rm -f  frontend/app/admin/page.tsx
echo "✅ Deleted: old duplicate admin panel (students/exams/questions/results/announcements/settings/panel + page.tsx)"
echo "✅ KEPT (untouched): frontend/app/admin/layout.tsx, frontend/app/admin/x7k2p/"

echo ""
echo "=== PART B: Removing fake/mock data from active dashboard pages ==="

cat > /tmp/patch_mockdata.js << 'NODEEOF'
const fs = require('fs');

function patchFile(path, replacements) {
  if (!fs.existsSync(path)) {
    console.error('❌ File not found: ' + path);
    process.exit(1);
  }
  let src = fs.readFileSync(path, 'utf8');
  for (const [label, oldStr, newStr] of replacements) {
    if (!src.includes(oldStr)) {
      console.error('❌ FAILED — anchor not found for "' + label + '" in ' + path + '. ABORTING (no changes written to this file).');
      process.exit(1);
    }
    const count = src.split(oldStr).length - 1;
    if (count > 1) {
      console.error('❌ FAILED — anchor for "' + label + '" not unique (' + count + ' matches) in ' + path + '. ABORTING.');
      process.exit(1);
    }
    src = src.replace(oldStr, newStr);
  }
  fs.writeFileSync(path, src, 'utf8');
  console.log('✅ Patched: ' + path);
}

// ── 1. dashboard/results/page.tsx ──────────────────────────────
patchFile('frontend/app/dashboard/results/page.tsx', [
  [
    'remove mockResults array + default state',
`const mockResults = [
  { id:'r1', exam:'NEET Full Mock #12', date:'Feb 28, 2026', score:610, max:720, rank:234, percentile:96.8, correct:152, incorrect:18, skipped:10, status:'Completed' },
  { id:'r2', exam:'NEET Full Mock #11', date:'Feb 21, 2026', score:587, max:720, rank:412, percentile:94.1, correct:146, incorrect:22, skipped:12, status:'Completed' },
  { id:'r3', exam:'NEET Full Mock #10', date:'Feb 14, 2026', score:632, max:720, rank:189, percentile:97.3, correct:158, incorrect:16, skipped:6,  status:'Completed' },
  { id:'r4', exam:'NEET Full Mock #9',  date:'Feb 7, 2026',  score:601, max:720, rank:290, percentile:95.6, correct:150, incorrect:20, skipped:10, status:'Completed' },
]

export default function Results() {
  const { user } = useAuth('student')
  const router   = useRouter()
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [results, setResults] = useState(mockResults)`,
`export default function Results() {
  const { user } = useAuth('student')
  const router   = useRouter()
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [results, setResults] = useState<any[]>([])`
  ],
  [
    'fix dangling /exam/demo link + add empty state',
`        {results.map((r,i)=>{
          const pct = Math.round((r.score/(r.max||720))*100)
          return (
            <div key={i} style={{padding:'18px 22px',borderBottom:i<results.length-1?\`1px solid \${v.bord}\`:'none',display:'flex',flexWrap:'wrap',gap:16,alignItems:'center',transition:'background 0.2s'}}
              onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.04)')}
              onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
              <div style={{flex:'1 1 200px'}}>
                <div style={{fontWeight:700,fontSize:15,color:v.tm,marginBottom:4}}>{r.exam}</div>
                <div style={{fontSize:12,color:v.ts}}>{r.date}</div>
              </div>
              <div style={{display:'flex',gap:20,flexWrap:'wrap',alignItems:'center'}}>
                <div style={{textAlign:'center'}}>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:800,color:'#4D9FFF'}}>{r.score}</div>
                  <div style={{fontSize:10,color:v.ts,textTransform:'uppercase',letterSpacing:'0.06em'}}>Score</div>
                </div>
                <div style={{textAlign:'center'}}>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:800,color:'#FFD700'}}>#{r.rank||'—'}</div>
                  <div style={{fontSize:10,color:v.ts,textTransform:'uppercase',letterSpacing:'0.06em'}}>AIR</div>
                </div>
                <div style={{textAlign:'center'}}>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:800,color:'#00C4BC'}}>{r.percentile||0}%</div>
                  <div style={{fontSize:10,color:v.ts,textTransform:'uppercase',letterSpacing:'0.06em'}}>%ile</div>
                </div>
                <button onClick={()=>router.push(r.examId ? \`/exam/\${r.examId}/result?attemptId=\${r.id}\` : \`/dashboard/results/\${r.id}\`)}
                  style={{padding:'9px 18px',borderRadius:10,border:'none',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',fontWeight:700,fontSize:12,cursor:'pointer',fontFamily:'Inter,sans-serif',whiteSpace:'nowrap'}}>
                  {lang==='en'?'View Details →':'विवरण →'}
                </button>
              </div>
            </div>
          )
        })}`,
`        {results.length === 0 && (
          <div style={{padding:'40px 22px',textAlign:'center',color:v.ts}}>
            <div style={{fontSize:32,marginBottom:8}}>📭</div>
            <div>{lang==='en'?'No exam results yet':'अभी तक कोई परिणाम नहीं'}</div>
          </div>
        )}
        {results.map((r,i)=>{
          const pct = Math.round((r.score/(r.max||720))*100)
          return (
            <div key={i} style={{padding:'18px 22px',borderBottom:i<results.length-1?\`1px solid \${v.bord}\`:'none',display:'flex',flexWrap:'wrap',gap:16,alignItems:'center',transition:'background 0.2s'}}
              onMouseEnter={e=>(e.currentTarget.style.background='rgba(77,159,255,0.04)')}
              onMouseLeave={e=>(e.currentTarget.style.background='transparent')}>
              <div style={{flex:'1 1 200px'}}>
                <div style={{fontWeight:700,fontSize:15,color:v.tm,marginBottom:4}}>{r.exam}</div>
                <div style={{fontSize:12,color:v.ts}}>{r.date}</div>
              </div>
              <div style={{display:'flex',gap:20,flexWrap:'wrap',alignItems:'center'}}>
                <div style={{textAlign:'center'}}>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:800,color:'#4D9FFF'}}>{r.score}</div>
                  <div style={{fontSize:10,color:v.ts,textTransform:'uppercase',letterSpacing:'0.06em'}}>Score</div>
                </div>
                <div style={{textAlign:'center'}}>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:800,color:'#FFD700'}}>#{r.rank||'—'}</div>
                  <div style={{fontSize:10,color:v.ts,textTransform:'uppercase',letterSpacing:'0.06em'}}>AIR</div>
                </div>
                <div style={{textAlign:'center'}}>
                  <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:800,color:'#00C4BC'}}>{r.percentile||0}%</div>
                  <div style={{fontSize:10,color:v.ts,textTransform:'uppercase',letterSpacing:'0.06em'}}>%ile</div>
                </div>
                <button onClick={()=>router.push(r.examId ? \`/exam/\${r.examId}/result?attemptId=\${r.id}\` : \`/dashboard/results/\${r.id}\`)}
                  style={{padding:'9px 18px',borderRadius:10,border:'none',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',fontWeight:700,fontSize:12,cursor:'pointer',fontFamily:'Inter,sans-serif',whiteSpace:'nowrap'}}>
                  {lang==='en'?'View Details →':'विवरण →'}
                </button>
              </div>
            </div>
          )
        })}`
  ]
]);

// ── 2. dashboard/results/history/page.tsx ──────────────────────
patchFile('frontend/app/dashboard/results/history/page.tsx', [
  [
    'remove MOCK_HISTORY array + fallback usage',
`const MOCK_HISTORY = [
  { attemptId:'att001', examTitle:'NEET Mock Test — Series 5', date:'2025-01-15', score:540, maxScore:720, rank:42, percentile:96.6, correct:135, wrong:30, status:'completed' },
  { attemptId:'att002', examTitle:'NEET Mock Test — Series 4', date:'2025-01-10', score:510, maxScore:720, rank:68, percentile:94.5, correct:128, wrong:32, status:'completed' },
  { attemptId:'att003', examTitle:'NEET Mock Test — Series 3', date:'2025-01-05', score:480, maxScore:720, rank:95, percentile:92.4, correct:120, wrong:36, status:'completed' },
  { attemptId:'att004', examTitle:'NEET Mock Test — Series 2', date:'2024-12-28', score:420, maxScore:720, rank:145, percentile:88.4, correct:105, wrong:42, status:'completed' },
  { attemptId:'att005', examTitle:'NEET Mock Test — Series 1', date:'2024-12-20', score:380, maxScore:720, rank:210, percentile:83.2, correct:95, wrong:48, status:'completed' },
];

export default function ResultHistoryPage() {
  const router = useRouter();
  const [history, setHistory] = useState<typeof MOCK_HISTORY>([]);
  const [loading, setLoading] = useState(true);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    if (!getToken()) { router.push('/login'); return; }
    const fetchHistory = async () => {
      try {
        const res = await fetch(\`\${process.env.NEXT_PUBLIC_API_URL}/api/results/history\`, {
          headers: { Authorization: \`Bearer \${getToken()}\` }
        });
        if (res.ok) { const data = await res.json(); setHistory(data); }
        else setHistory(MOCK_HISTORY);
      } catch { setHistory(MOCK_HISTORY); }
      finally { setLoading(false); }
    };
    fetchHistory();
  }, [router]);`,
`export default function ResultHistoryPage() {
  const router = useRouter();
  const [history, setHistory] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    if (!getToken()) { router.push('/login'); return; }
    const fetchHistory = async () => {
      try {
        const res = await fetch(\`\${process.env.NEXT_PUBLIC_API_URL}/api/results/history\`, {
          headers: { Authorization: \`Bearer \${getToken()}\` }
        });
        if (res.ok) { const data = await res.json(); setHistory(Array.isArray(data) ? data : []); }
        else setHistory([]);
      } catch { setHistory([]); }
      finally { setLoading(false); }
    };
    fetchHistory();
  }, [router]);`
  ],
  [
    'guard avgScore/bestRank math + add empty state',
`  const avgScore = Math.round(history.reduce((s,h)=>s+h.score,0)/history.length);
  const bestRank = Math.min(...history.map(h=>h.rank));
  const trend = history.length>1 ? (history[0].score > history[history.length-1].score ? '📈' : '📉') : '—';`,
`  const avgScore = history.length ? Math.round(history.reduce((s,h)=>s+h.score,0)/history.length) : 0;
  const bestRank = history.length ? Math.min(...history.map(h=>h.rank)) : 0;
  const trend = history.length>1 ? (history[0].score > history[history.length-1].score ? '📈' : '📉') : '—';`
  ],
  [
    'add empty state before history list',
`        {/* History List */}
        <div style={{display:'flex',flexDirection:'column',gap:10}}>
          {history.map((attempt,i)=>{`,
`        {/* History List */}
        {history.length === 0 && (
          <div style={{textAlign:'center',padding:'40px 16px',color:'#6B8FAF'}}>
            <div style={{fontSize:32,marginBottom:8}}>📭</div>
            <div>No exam attempts yet</div>
          </div>
        )}
        <div style={{display:'flex',flexDirection:'column',gap:10}}>
          {history.map((attempt,i)=>{`
  ]
]);

// ── 3. dashboard/exams/page.tsx ─────────────────────────────────
patchFile('frontend/app/dashboard/exams/page.tsx', [
  [
    'remove mockExams array + default state',
`const mockExams = [
  { _id:'demo1', title:'NEET Full Mock Test #13', scheduledAt: new Date(Date.now()+86400000*3).toISOString(), totalDurationSec:12000, totalMarks:720, status:'upcoming' },
  { _id:'demo2', title:'NEET Chapter Test — Biology', scheduledAt: new Date(Date.now()+86400000*6).toISOString(), totalDurationSec:7200, totalMarks:360, status:'upcoming' },
]

export default function Exams() {
  const { user } = useAuth('student')
  const router = useRouter()
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [exams, setExams] = useState(mockExams)`,
`export default function Exams() {
  const { user } = useAuth('student')
  const router = useRouter()
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [exams, setExams] = useState<any[]>([])`
  ],
  [
    'add empty state before exams grid',
`      <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(320px,1fr))',gap:18}}>
        {exams.map((ex,i)=>{`,
`      {exams.length === 0 && (
        <div style={{textAlign:'center',padding:'40px 16px',color:v.ts}}>
          <div style={{fontSize:32,marginBottom:8}}>📭</div>
          <div>{lang==='en'?'No exams scheduled yet':'अभी तक कोई परीक्षा निर्धारित नहीं'}</div>
        </div>
      )}
      <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(320px,1fr))',gap:18}}>
        {exams.map((ex,i)=>{`
  ]
]);

// ── 4. dashboard/admit-card/page.tsx ────────────────────────────
patchFile('frontend/app/dashboard/admit-card/page.tsx', [
  [
    'remove mockExams array + empty-state instead of hardcoded card',
`const mockExams = [
  { id:1, name:'NEET Full Mock Test #13', date:'March 15, 2026', time:'10:00 AM – 1:20 PM', center:'Online (ProveRank Platform)', rollNo:'PR2026-00847', instructions:['Webcam required','Stable internet connection','Quiet environment','Valid ID ready'] },
  { id:2, name:'NEET Chapter Test — Biology', date:'March 18, 2026', time:'2:00 PM – 4:00 PM', center:'Online (ProveRank Platform)', rollNo:'PR2026-00848', instructions:['Webcam required','Stable internet connection'] },
]

export default function AdmitCard() {
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [selected, setSelected] = useState(0)
  const [mounted, setMounted] = useState(false)
  useEffect(()=>{ setMounted(true); const sl=localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl) },[])
  const dark = mounted ? localStorage.getItem('pr_theme')!=='light' : true

  const v = {
    card: dark ? 'rgba(0,18,36,0.9)' : 'rgba(255,255,255,0.95)',
    bord: dark ? 'rgba(77,159,255,0.14)' : 'rgba(77,159,255,0.25)',
    tm: dark ? '#E8F4FF' : '#0F172A',
    ts: dark ? '#6B8BAF' : '#64748B',
  }

  const ex = mockExams[selected]

  return (
    <DashLayout title={lang==='en'?'Admit Card':'प्रवेश पत्र'} subtitle={lang==='en'?'Download admit cards for upcoming exams':'आगामी परीक्षाओं के लिए प्रवेश पत्र'}>
      {/* Exam selector */}
      <div style={{display:'flex',gap:12,marginBottom:24,flexWrap:'wrap'}}>
        {mockExams.map((e,i)=>(
          <button key={e.id} onClick={()=>setSelected(i)} style={{padding:'10px 18px',borderRadius:12,border:\`2px solid \${selected===i?'#4D9FFF':v.bord}\`,background:selected===i?'rgba(77,159,255,0.1)':'transparent',color:selected===i?'#4D9FFF':v.ts,fontWeight:selected===i?700:500,fontSize:13,cursor:'pointer',fontFamily:'Inter,sans-serif',transition:'all 0.2s'}}>
            {e.name}
          </button>
        ))}
      </div>`,
`export default function AdmitCard() {
  const [lang, setLang] = useState<'en'|'hi'>('en')
  const [selected, setSelected] = useState(0)
  const [mounted, setMounted] = useState(false)
  const [exams, setExams] = useState<any[]>([])
  useEffect(()=>{
    setMounted(true)
    const sl=localStorage.getItem('pr_lang') as 'en'|'hi'; if(sl) setLang(sl)
    // TODO: wire to real admit-card API (S106) — kept empty for now,
    // no more fake placeholder admit cards.
  },[])
  const dark = mounted ? localStorage.getItem('pr_theme')!=='light' : true

  const v = {
    card: dark ? 'rgba(0,18,36,0.9)' : 'rgba(255,255,255,0.95)',
    bord: dark ? 'rgba(77,159,255,0.14)' : 'rgba(77,159,255,0.25)',
    tm: dark ? '#E8F4FF' : '#0F172A',
    ts: dark ? '#6B8BAF' : '#64748B',
  }

  const ex = exams[selected]

  if (!exams.length) {
    return (
      <DashLayout title={lang==='en'?'Admit Card':'प्रवेश पत्र'} subtitle={lang==='en'?'Download admit cards for upcoming exams':'आगामी परीक्षाओं के लिए प्रवेश पत्र'}>
        <div style={{textAlign:'center',padding:'60px 16px',color:v.ts}}>
          <div style={{fontSize:40,marginBottom:12}}>🪪</div>
          <div>{lang==='en'?'No admit card available yet':'अभी तक कोई प्रवेश पत्र उपलब्ध नहीं'}</div>
        </div>
      </DashLayout>
    )
  }

  return (
    <DashLayout title={lang==='en'?'Admit Card':'प्रवेश पत्र'} subtitle={lang==='en'?'Download admit cards for upcoming exams':'आगामी परीक्षाओं के लिए प्रवेश पत्र'}>
      {/* Exam selector */}
      <div style={{display:'flex',gap:12,marginBottom:24,flexWrap:'wrap'}}>
        {exams.map((e,i)=>(
          <button key={e.id} onClick={()=>setSelected(i)} style={{padding:'10px 18px',borderRadius:12,border:\`2px solid \${selected===i?'#4D9FFF':v.bord}\`,background:selected===i?'rgba(77,159,255,0.1)':'transparent',color:selected===i?'#4D9FFF':v.ts,fontWeight:selected===i?700:500,fontSize:13,cursor:'pointer',fontFamily:'Inter,sans-serif',transition:'all 0.2s'}}>
            {e.name}
          </button>
        ))}
      </div>`
  ]
]);

console.log('✅ All Part B patches applied.');
NODEEOF

node /tmp/patch_mockdata.js
rm /tmp/patch_mockdata.js

echo ""
echo "=== DONE ==="
echo "git add -A && git commit -m 'Delete legacy old admin panel + exam/demo folder; remove fake mock-data fallbacks from active dashboard pages' && git push"
echo ""
echo "⚠️  NOTE: dashboard/results/[attemptId]/page.tsx (the detailed result view with"
echo "    Subjects/Answers/Trend tabs) still has its own mock fallback — it needs a"
echo "    separate, more careful pass since parts of its UI expect fields the real"
echo "    /api/results/:attemptId endpoint doesn't return yet. Will do that next."
