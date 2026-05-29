#!/bin/bash
# ProveRank Fix: Question Bank — fetch on mount + click detail modal
echo "=================================================="
echo " Question Bank Fix: Load on refresh + Click Detail"
echo "=================================================="

PAGE="$HOME/workspace/frontend/app/admin/x7k2p/page.tsx"
cp "$PAGE" "${PAGE}.bak_qfix"
echo "✅ Backup done"

node << 'NODEEOF'
const fs = require('fs');
const PAGE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let c = fs.readFileSync(PAGE, 'utf8');
let fixes = 0;

// ─────────────────────────────────────────────────────────────────────────
// FIX 1: Add selectedQuestion state for detail modal
// ─────────────────────────────────────────────────────────────────────────
if (!c.includes('selectedQuestion,setSelectedQuestion')) {
  c = c.replace(
    'const [qPreview,setQPreview]=useState(false)',
    'const [qPreview,setQPreview]=useState(false);\n  const [selectedQuestion,setSelectedQuestion]=useState<any>(null);'
  );
  console.log('✅ Fix 1: selectedQuestion state added');
  fixes++;
} else {
  console.log('✅ Fix 1: selectedQuestion already exists');
}

// ─────────────────────────────────────────────────────────────────────────
// FIX 2: Add useEffect to fetch questions on mount + when qPreview opens
// ─────────────────────────────────────────────────────────────────────────
if (!c.includes('fetchQuestionsOnMount') && !c.includes('qPreview&&loadQ')) {
  // Find loadQ function or the questions fetch
  const loadQMatch = c.match(/const loadQ[^=]*=\s*useCallback\(async\(\)/);
  if (loadQMatch) {
    // loadQ exists — add useEffect after it
    const insertAfter = 'const uploadQs=useCallback(async()=>{';
    const insertPos = c.indexOf(insertAfter);
    if (insertPos > -1) {
      const useEffectCode = `
  // Fetch questions on mount and when preview opens
  useEffect(()=>{
    const tk=getToken();
    if(!tk)return;
    fetch(\`\${API}/api/questions\`,{headers:{Authorization:\`Bearer \${tk}\`}})
      .then(r=>r.json())
      .then(d=>{if(d.questions)setQuestions(d.questions);else if(Array.isArray(d))setQuestions(d);})
      .catch(()=>{});
  },[]);

`;
      c = c.slice(0, insertPos) + useEffectCode + c.slice(insertPos);
      console.log('✅ Fix 2: useEffect to fetch questions on mount added');
      fixes++;
    }
  } else {
    // Find GET questions fetch and wrap in useEffect
    const getQFetch = "get(`${API}/api/questions`,";
    const getQPos = c.indexOf(getQFetch);
    if (getQPos > -1) {
      // Find the useEffect area
      const uploadQs = 'const uploadQs=useCallback(async()=>{';
      const pos = c.indexOf(uploadQs);
      if (pos > -1) {
        const useEffectCode = `
  // Fetch questions on mount
  useEffect(()=>{
    const tk=getToken();
    if(!tk)return;
    fetch(\`\${API}/api/questions\`,{headers:{Authorization:\`Bearer \${tk}\`}})
      .then(r=>r.json())
      .then(d=>{if(d.questions)setQuestions(d.questions);else if(Array.isArray(d))setQuestions(d);})
      .catch(()=>{});
  },[]);

`;
        c = c.slice(0, pos) + useEffectCode + c.slice(pos);
        console.log('✅ Fix 2b: useEffect added before uploadQs');
        fixes++;
      }
    }
  }
} else {
  console.log('✅ Fix 2: fetch on mount already present');
}

// ─────────────────────────────────────────────────────────────────────────
// FIX 3: Add onClick to question cards in preview mode
// Find: div Key={q._id||i} className="card-hover"
// Add: onClick={()=>setSelectedQuestion(q)}
// ─────────────────────────────────────────────────────────────────────────
const cardPattern = /(<div Key=\{q\._id\|\|i\}\s+className="card-hover")/g;
if (cardPattern.test(c)) {
  c = c.replace(
    /(<div Key=\{q\._id\|\|i\}\s+className="card-hover")/g,
    '$1 onClick={()=>setSelectedQuestion(q)} style={{cursor:"pointer"}}'
  );
  console.log('✅ Fix 3: onClick added to question cards');
  fixes++;
} else {
  // Try lowercase key
  const cardPattern2 = /(<div key=\{q\._id\|\|[^}]+\}[^>]*className="card-hover")/g;
  if (cardPattern2.test(c)) {
    c = c.replace(cardPattern2, '$1 onClick={()=>setSelectedQuestion(q)}');
    console.log('✅ Fix 3b: onClick added (lowercase key)');
    fixes++;
  } else {
    // Find card-hover in question list context
    const lines = c.split('\n');
    let found = false;
    for (let i = 0; i < lines.length; i++) {
      if (lines[i].includes('card-hover') && 
          (lines[i].includes('q._id') || lines[i-1]?.includes('q._id') || lines[i+1]?.includes('q._id'))) {
        if (!lines[i].includes('onClick')) {
          lines[i] = lines[i].replace('card-hover"', 'card-hover" onClick={()=>setSelectedQuestion(q)} style={{cursor:"pointer"}}');
          found = true;
          console.log('✅ Fix 3c: onClick added at line ' + (i+1));
          fixes++;
          break;
        }
      }
    }
    if (found) c = lines.join('\n');
    else console.log('⚠️  Fix 3: card-hover pattern not found — check manually');
  }
}

// ─────────────────────────────────────────────────────────────────────────
// FIX 4: Add Question Detail Modal JSX
// ─────────────────────────────────────────────────────────────────────────
if (!c.includes('Question Detail Modal') && !c.includes('selectedQuestion&&')) {
  const detailModal = `
      {/* Question Detail Modal */}
      {selectedQuestion&&(
        <div onClick={()=>setSelectedQuestion(null)} style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.8)',zIndex:10000,display:'flex',alignItems:'center',justifyContent:'center',padding:16,overflowY:'auto'}}>
          <div onClick={(e)=>e.stopPropagation()} style={{background:'#0d1b2e',border:'1px solid #1e3a5f',borderRadius:14,padding:24,maxWidth:520,width:'100%',boxShadow:'0 16px 48px rgba(0,0,0,0.8)',maxHeight:'90vh',overflowY:'auto'}}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:16}}>
              <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>
                {selectedQuestion.subject&&<span style={{fontSize:10,background:'#1e3a5f',color:'#60a5fa',borderRadius:6,padding:'2px 8px'}}>{selectedQuestion.subject}</span>}
                {selectedQuestion.difficulty&&<span style={{fontSize:10,background:'rgba(245,158,11,0.2)',color:'#f59e0b',borderRadius:6,padding:'2px 8px'}}>{selectedQuestion.difficulty}</span>}
                {selectedQuestion.type&&<span style={{fontSize:10,background:'rgba(168,85,247,0.2)',color:'#a855f7',borderRadius:6,padding:'2px 8px'}}>{selectedQuestion.type}</span>}
              </div>
              <button onClick={()=>setSelectedQuestion(null)} style={{background:'none',border:'none',color:'#64748b',fontSize:20,cursor:'pointer',lineHeight:1,flexShrink:0}}>×</button>
            </div>
            <div style={{fontSize:14,fontWeight:600,color:'#e2e8f0',marginBottom:16,lineHeight:1.6}}>{selectedQuestion.text||selectedQuestion.question}</div>
            {selectedQuestion.textHindi&&<div style={{fontSize:13,color:'#94a3b8',marginBottom:16,lineHeight:1.5}}>{selectedQuestion.textHindi}</div>}
            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:16}}>
              {['A','B','C','D'].map((opt,i)=>{
                const val=selectedQuestion[`option${opt}`]||selectedQuestion.options?.[i];
                const isCorrect=selectedQuestion.correctAnswer===`Option ${opt}`||selectedQuestion.answer===opt||selectedQuestion.correctAnswer===opt;
                return val?(
                  <div key={opt} style={{padding:'8px 12px',borderRadius:8,border:`1px solid ${isCorrect?'#22c55e':'#1e3a5f'}`,background:isCorrect?'rgba(34,197,94,0.1)':'transparent',fontSize:12,color:isCorrect?'#22c55e':'#94a3b8'}}>
                    <span style={{fontWeight:700,marginRight:6}}>{opt}.</span>{val}
                    {isCorrect&&<span style={{marginLeft:6}}>✅</span>}
                  </div>
                ):null;
              })}
            </div>
            {(selectedQuestion.explanation||selectedQuestion.solution)&&(
              <div style={{padding:'10px 14px',background:'rgba(59,130,246,0.08)',borderRadius:8,border:'1px solid rgba(59,130,246,0.2)',marginBottom:12}}>
                <div style={{fontSize:11,color:'#60a5fa',fontWeight:600,marginBottom:4}}>💡 Explanation</div>
                <div style={{fontSize:12,color:'#94a3b8',lineHeight:1.5}}>{selectedQuestion.explanation||selectedQuestion.solution}</div>
              </div>
            )}
            {(selectedQuestion.chapter||selectedQuestion.topic)&&(
              <div style={{fontSize:11,color:'#475569'}}>
                {selectedQuestion.chapter&&<span>📚 {selectedQuestion.chapter}</span>}
                {selectedQuestion.topic&&<span style={{marginLeft:8}}>🏷️ {selectedQuestion.topic}</span>}
              </div>
            )}
            <button onClick={()=>setSelectedQuestion(null)} style={{width:'100%',marginTop:16,padding:'10px',background:'#1e3a5f',border:'none',borderRadius:8,color:'#e2e8f0',cursor:'pointer',fontSize:13,fontWeight:600}}>Close</button>
          </div>
        </div>
      )}`;

  // Insert before last </div> of return
  const lastDiv = c.lastIndexOf('    </div>\n  )\n}');
  if (lastDiv > -1) {
    c = c.slice(0, lastDiv) + detailModal + '\n' + c.slice(lastDiv);
    console.log('✅ Fix 4: Question detail modal added');
    fixes++;
  } else {
    const altEnd = c.lastIndexOf('\n  );\n}');
    if (altEnd > -1) {
      c = c.slice(0, altEnd) + detailModal + c.slice(altEnd);
      console.log('✅ Fix 4b: Modal added (alt)');
      fixes++;
    }
  }
} else {
  console.log('✅ Fix 4: Detail modal already exists');
}

fs.writeFileSync(PAGE, c);
console.log('\n✅ Total fixes: ' + fixes);
NODEEOF

echo ""
echo "--- Verify ---"
grep -n "selectedQuestion\|fetchQuestionsOnMount\|useEffect.*questions\|Questions on mount" "$PAGE" | head -8

echo ""
echo "--- Git Push ---"
cd ~/workspace
git add frontend/app/admin/x7k2p/page.tsx
git commit -m "fix(F15/F16): question bank fetch on mount + click detail modal"
git push origin main

echo ""
echo "=================================================="
echo "✅ DONE — Deploy ~2 min"
echo "Test:"
echo "  1. Refresh page → questions load ho"
echo "  2. Preview Mode → question click → detail modal"
echo "=================================================="
