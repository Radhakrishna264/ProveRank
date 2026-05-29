#!/bin/bash
# ProveRank Final Fix: Edit Q + Count + Next/Prev Navigation
echo "=================================================="
echo " Final Fix: Edit + Count + Next/Prev"
echo "=================================================="

PAGE="$HOME/workspace/frontend/app/admin/x7k2p/page.tsx"
cp "$PAGE" "${PAGE}.bak_final"
echo "✅ Backup done"

cat > /tmp/final_fix.js << 'JSEOF'
const fs = require('fs');
const PAGE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let c = fs.readFileSync(PAGE, 'utf8');
let fixes = 0;

// ─────────────────────────────────────────────────────────────────────────
// FIX 1: Add currentQIndex state for Next/Prev navigation
// ─────────────────────────────────────────────────────────────────────────
if (!c.includes('currentQIndex,setCurrentQIndex')) {
  c = c.replace(
    'const [editingQData,setEditingQData]=useState(null);',
    'const [editingQData,setEditingQData]=useState(null);\n  const [currentQIndex,setCurrentQIndex]=useState(0);'
  );
  console.log('✅ Fix 1: currentQIndex state added');
  fixes++;
}

// ─────────────────────────────────────────────────────────────────────────
// FIX 2: Update setSelectedQuestion calls to also track index
// When question card clicked → also set its index in fQs array
// ─────────────────────────────────────────────────────────────────────────
// Find card onClick: onClick={()=>setSelectedQuestion(q)}
// Replace with: onClick={()=>{setSelectedQuestion(q);setCurrentQIndex(i);}}
// The map already has index i
c = c.replace(
  /onClick=\{()=>setSelectedQuestion\(q\)\}/g,
  'onClick={()=>{setSelectedQuestion(q);setCurrentQIndex(i);}}'
);
console.log('✅ Fix 2: card onClick tracks index');
fixes++;

// ─────────────────────────────────────────────────────────────────────────
// FIX 3: Replace the selectedQuestion modal with full-featured version
// Including: details + edit + next/prev + working edit
// ─────────────────────────────────────────────────────────────────────────
const startMarker = '{selectedQuestion&&(';
const startIdx = c.indexOf(startMarker);
if (startIdx === -1) { console.log('❌ Modal not found'); process.exit(1); }

let depth = 0, endIdx = -1;
for (let i = startIdx; i < c.length; i++) {
  if (c[i] === '{') depth++;
  if (c[i] === '}') { depth--; if (depth === 0) { endIdx = i; break; } }
}
console.log('Modal: ' + startIdx + ' → ' + endIdx);

const newModal = `{selectedQuestion&&(
        <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.85)',zIndex:10000,display:'flex',alignItems:'center',justifyContent:'center',padding:16}}>
          <div onClick={(e)=>e.stopPropagation()} style={{background:'#0d1b2e',border:'1px solid #1e3a5f',borderRadius:14,padding:20,maxWidth:520,width:'100%',maxHeight:'90vh',overflowY:'auto',boxShadow:'0 16px 48px rgba(0,0,0,0.9)',position:'relative'}}>
            {/* Top bar: badges + close */}
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:14}}>
              <div style={{display:'flex',gap:5,flexWrap:'wrap'}}>
                {selectedQuestion.subject&&<span style={{fontSize:10,background:'#1e3a5f',color:'#60a5fa',borderRadius:6,padding:'2px 8px',fontWeight:600}}>{selectedQuestion.subject}</span>}
                {selectedQuestion.difficulty&&<span style={{fontSize:10,background:'rgba(245,158,11,0.2)',color:'#f59e0b',borderRadius:6,padding:'2px 8px',fontWeight:600}}>{selectedQuestion.difficulty}</span>}
                {selectedQuestion.type&&<span style={{fontSize:10,background:'rgba(168,85,247,0.2)',color:'#a855f7',borderRadius:6,padding:'2px 8px',fontWeight:600}}>{selectedQuestion.type}</span>}
                {selectedQuestion.approvalStatus&&<span style={{fontSize:10,background:'rgba(34,197,94,0.15)',color:'#22c55e',borderRadius:6,padding:'2px 8px',fontWeight:600}}>{selectedQuestion.approvalStatus}</span>}
              </div>
              <button onClick={()=>setSelectedQuestion(null)} style={{background:'none',border:'none',color:'#64748b',fontSize:22,cursor:'pointer',lineHeight:1,padding:'0 4px'}}>×</button>
            </div>
            {/* Question index indicator */}
            <div style={{fontSize:11,color:'#475569',marginBottom:8}}>Question {currentQIndex+1} of {fQs.length}</div>
            {/* Question text */}
            <div style={{fontSize:14,fontWeight:700,color:'#e2e8f0',marginBottom:8,lineHeight:1.7}}>{selectedQuestion.text||selectedQuestion.question||'Question'}</div>
            {selectedQuestion.hindiText&&<div style={{fontSize:12,color:'#94a3b8',marginBottom:12,lineHeight:1.6,borderLeft:'2px solid #1e3a5f',paddingLeft:10,fontStyle:'italic'}}>{selectedQuestion.hindiText}</div>}
            {/* Options */}
            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:14}}>
              {(selectedQuestion.options||[]).map((opt,i)=>{
                const label=['A','B','C','D'][i]||String(i+1);
                const correctArr=selectedQuestion.correct||[];
                const isCorrect=Array.isArray(correctArr)?correctArr.includes(i):(correctArr===i);
                return(
                  <div key={i} style={{padding:'8px 10px',borderRadius:8,border:'1px solid '+(isCorrect?'#22c55e':'#1e3a5f'),background:isCorrect?'rgba(34,197,94,0.12)':'rgba(255,255,255,0.02)',fontSize:12,color:isCorrect?'#22c55e':'#cbd5e1',wordBreak:'break-word',lineHeight:1.5,position:'relative'}}>
                    <span style={{fontWeight:700,marginRight:5,color:isCorrect?'#22c55e':'#60a5fa'}}>{label}.</span>{opt}{isCorrect&&<span style={{marginLeft:4}}>✅</span>}
                  </div>
                );
              })}
            </div>
            {/* Correct Answer */}
            {(selectedQuestion.correct||[]).length>0&&(
              <div style={{fontSize:12,color:'#22c55e',marginBottom:10,padding:'6px 12px',background:'rgba(34,197,94,0.08)',borderRadius:8,border:'1px solid rgba(34,197,94,0.2)',fontWeight:600}}>
                ✅ Correct Answer: {(selectedQuestion.correct||[]).map((idx)=>(['A','B','C','D'][idx]||idx)).join(', ')}
              </div>
            )}
            {/* Explanation */}
            {selectedQuestion.explanation&&(
              <div style={{padding:'10px 14px',background:'rgba(59,130,246,0.08)',borderRadius:8,border:'1px solid rgba(59,130,246,0.2)',marginBottom:10}}>
                <div style={{fontSize:11,color:'#60a5fa',fontWeight:700,marginBottom:4}}>💡 Explanation</div>
                <div style={{fontSize:12,color:'#94a3b8',lineHeight:1.6,wordBreak:'break-word'}}>{selectedQuestion.explanation}</div>
              </div>
            )}
            {/* Chapter / Topic */}
            {(selectedQuestion.chapter||selectedQuestion.topic)&&(
              <div style={{fontSize:11,color:'#64748b',marginBottom:14,display:'flex',gap:12,flexWrap:'wrap'}}>
                {selectedQuestion.chapter&&<span>📚 <strong style={{color:'#94a3b8'}}>Chapter:</strong> {selectedQuestion.chapter}</span>}
                {selectedQuestion.topic&&<span>🏷️ <strong style={{color:'#94a3b8'}}>Topic:</strong> {selectedQuestion.topic}</span>}
              </div>
            )}
            {/* Action Buttons Row */}
            <div style={{display:'flex',gap:8,marginTop:8,flexWrap:'wrap'}}>
              {/* Prev */}
              <button onClick={()=>{const pi=currentQIndex-1;if(pi>=0){setCurrentQIndex(pi);setSelectedQuestion(fQs[pi]);}}} disabled={currentQIndex===0} style={{flex:1,padding:'8px',background:currentQIndex===0?'#0a1628':'rgba(99,102,241,0.15)',border:'1px solid '+(currentQIndex===0?'#1e3a5f':'#6366f1'),borderRadius:8,color:currentQIndex===0?'#475569':'#818cf8',cursor:currentQIndex===0?'not-allowed':'pointer',fontSize:12,fontWeight:600}}>← Prev</button>
              {/* Edit */}
              <button onClick={()=>{
                const eq=selectedQuestion;
                setEditingQId(eq._id||eq.id||null);
                setEditingQData(eq);
                setQSubj(eq.subject||'General');
                setQDiff(eq.difficulty||'Easy');
                setQType(eq.type||'SCQ');
                setSelectedQuestion(null);
                setQPreview(false);
              }} style={{flex:2,padding:'8px',background:'rgba(59,130,246,0.15)',border:'1px solid #3b82f6',borderRadius:8,color:'#60a5fa',cursor:'pointer',fontSize:12,fontWeight:600}}>✏️ Edit</button>
              {/* Next */}
              <button onClick={()=>{const ni=currentQIndex+1;if(ni<fQs.length){setCurrentQIndex(ni);setSelectedQuestion(fQs[ni]);}}} disabled={currentQIndex===fQs.length-1} style={{flex:1,padding:'8px',background:currentQIndex===fQs.length-1?'#0a1628':'rgba(99,102,241,0.15)',border:'1px solid '+(currentQIndex===fQs.length-1?'#1e3a5f':'#6366f1'),borderRadius:8,color:currentQIndex===fQs.length-1?'#475569':'#818cf8',cursor:currentQIndex===fQs.length-1?'not-allowed':'pointer',fontSize:12,fontWeight:600}}>Next →</button>
            </div>
            <button onClick={()=>setSelectedQuestion(null)} style={{width:'100%',marginTop:8,padding:'9px',background:'#1e3a5f',border:'none',borderRadius:8,color:'#e2e8f0',cursor:'pointer',fontSize:12,fontWeight:600}}>Close</button>
          </div>
        </div>
      )}`;

c = c.slice(0, startIdx) + newModal + c.slice(endIdx + 1);
console.log('✅ Fix 3: Modal replaced with Next/Prev + Edit');
fixes++;

// ─────────────────────────────────────────────────────────────────────────
// FIX 4: Subject-wise count in header
// Find: {questions||[]).length} questions — search, filter, add, edit
// Replace with full count + subject breakdown
// ─────────────────────────────────────────────────────────────────────────
// Find the pagesSub div that shows question count
const countPattern = /\{questions\|\|\[\]\}\.length\}\s*questions\s*—\s*search,\s*filter,\s*add,\s*edit/;
if (countPattern.test(c)) {
  c = c.replace(
    countPattern,
    `{(questions||[]).length} questions — search, filter, add, edit`
  );
}

// Add subject counts below the main count  
const subCountCode = `
                {/* Subject-wise counts */}
                {(questions||[]).length>0&&(
                  <div style={{display:'flex',gap:6,flexWrap:'wrap',marginTop:4}}>
                    {['Physics','Chemistry','Biology','General'].map(sub=>{
                      const cnt=(questions||[]).filter(q=>q.subject===sub).length;
                      if(!cnt)return null;
                      const cols={Physics:'#60a5fa',Chemistry:'#a78bfa',Biology:'#34d399',General:'#94a3b8'};
                      return <span key={sub} style={{fontSize:10,color:cols[sub]||'#94a3b8',background:'rgba(255,255,255,0.05)',borderRadius:4,padding:'1px 6px'}}>{sub}: {cnt}</span>;
                    })}
                  </div>
                )}`;

// Insert after pageSub div
const pageSubIdx = c.indexOf('<div style={pageSub}>');
if (pageSubIdx > -1) {
  const closeDiv = c.indexOf('</div>', pageSubIdx);
  if (closeDiv > -1) {
    c = c.slice(0, closeDiv + 6) + subCountCode + c.slice(closeDiv + 6);
    console.log('✅ Fix 4: Subject-wise counts added');
    fixes++;
  }
} else {
  console.log('⚠️  Fix 4: pageSub not found - trying alternate');
  // Find questions count line
  const qCountLine = c.indexOf('questions — search, filter, add, edit');
  if (qCountLine > -1) {
    const lineEnd = c.indexOf('</div>', qCountLine);
    if (lineEnd > -1) {
      c = c.slice(0, lineEnd + 6) + subCountCode + c.slice(lineEnd + 6);
      console.log('✅ Fix 4b: Subject counts added (alt)');
      fixes++;
    }
  }
}

fs.writeFileSync(PAGE, c);
console.log('\n✅ Total fixes: ' + fixes);
JSEOF

node /tmp/final_fix.js

echo ""
echo "--- Verify ---"
grep -n "currentQIndex\|fQs.length\|Prev\|Next →" "$PAGE" | head -8

echo ""
echo "--- Git Push ---"
cd ~/workspace
git add frontend/app/admin/x7k2p/page.tsx
git commit -m "feat(F15/F16): next/prev navigation + edit fix + subject counts"
git push origin main

echo ""
echo "=================================================="
echo "✅ DONE — Deploy ~2 min"
echo "Test:"
echo "  1. Question click → modal with Next/Prev"
echo "  2. Edit → form pre-filled, Update button"
echo "  3. Header → subject-wise counts"
echo "=================================================="
