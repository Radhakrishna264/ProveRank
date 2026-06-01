#!/bin/bash
echo "=== ProveRank: Chapter Field + Preview Modal + AI Edit ==="

node << 'NODEOF'
const fs = require('fs')
const FILE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx'
let c = fs.readFileSync(FILE, 'utf8')

// ══════════════════════════════════════════════════
// CHANGE 1: Add states after existing states
// ══════════════════════════════════════════════════
const stateTarget = `const [draftKey,setDraftKey]=useState(0)`
const stateReplace = `const [draftKey,setDraftKey]=useState(0)
const [confirmQ,setConfirmQ]=useState<any>(null)
const [aiEditIdx,setAiEditIdx]=useState<number|null>(null)
const [aiEditQ,setAiEditQ]=useState<any>(null)`

if(c.includes('const [confirmQ,setConfirmQ]')){
  console.log('⏭  states already exist')
} else if(c.includes(stateTarget)){
  c=c.replace(stateTarget,stateReplace)
  console.log('✅ C1: confirmQ/aiEdit states added')
} else {
  console.log('❌ C1 FAILED: draftKey state not found')
}

// ══════════════════════════════════════════════════
// CHANGE 2: Intercept addQ to show preview first
// ══════════════════════════════════════════════════
const addQStart = `const addQ=useCallback(async()=>{`
const addQIntercept = `const confirmAndAdd=async()=>{`

if(c.includes('const confirmAndAdd=async()=>{')){
  console.log('⏭  addQ intercept already done')
} else if(c.includes(addQStart)){
  // Rename original addQ to confirmAndAdd, then create new addQ that shows preview
  c = c.replace(addQStart, addQIntercept)
  
  // Now add new addQ before confirmAndAdd
  const newAddQ = `const addQ=useCallback(()=>{
const text=qTxtR.current
if(!text){T('Question text is required.','e');return}
setConfirmQ({
  text,
  hindi:qHindiR.current||undefined,
  subject:qSubj||'General',
  chapter:qChapR.current||undefined,
  topic:qTopicR.current||undefined,
  difficulty:qDiff,
  type:qType,
  ans:qAns,
  options:['SCQ','MSQ'].includes(qType)?[qA.current,qB.current,qC.current,qD.current].filter(Boolean):[],
  exp:qExpR.current||undefined,
  img:qImgR.current||undefined,
})
},[qSubj,qDiff,qType,qAns])
`
  c = c.replace(`const confirmAndAdd=async()=>{`, newAddQ + `const confirmAndAdd=async()=>{`)
  console.log('✅ C2: addQ intercept added')
} else {
  console.log('❌ C2 FAILED: addQ not found')
}

// ══════════════════════════════════════════════════
// CHANGE 3: Add Chapter input in form (after Topic)
// ══════════════════════════════════════════════════
const topicField = `<label style={lbl}>📌 Topic</label>
                <input value={qTopicR.current} onChange={e=>{qTopicR.current=e.target.value;setQTopic(e.target.value)}} placeholder='e.g. Coulombs Law' style={{...inp}}/>`

const topicWithChapter = `<label style={lbl}>📌 Topic</label>
                <input value={qTopicR.current} onChange={e=>{qTopicR.current=e.target.value;setQTopic(e.target.value)}} placeholder='e.g. Coulombs Law' style={{...inp}}/>
</div>
<div>
                <label style={lbl}>📖 Chapter</label>
                <input value={qChapR.current} onChange={e=>{qChapR.current=e.target.value;setQChap(e.target.value)}} placeholder='e.g. Laws of Motion' style={{...inp}}/>`

if(c.includes('📖 Chapter')){
  console.log('⏭  Chapter field already exists')
} else if(c.includes(topicField)){
  c=c.replace(topicField, topicWithChapter)
  console.log('✅ C3: Chapter field added after Topic')
} else {
  // Try simpler match
  const simpleMatch = `placeholder='e.g. Coulombs Law' style={{...inp}}/>`
  if(c.includes(simpleMatch)){
    c=c.replace(simpleMatch, `placeholder='e.g. Coulombs Law' style={{...inp}}/>
</div><div><label style={lbl}>📖 Chapter</label><input value={qChapR.current} onChange={e=>{qChapR.current=e.target.value;setQChap(e.target.value)}} placeholder='e.g. Laws of Motion' style={{...inp}}/>`)
    console.log('✅ C3 (simple): Chapter field added')
  } else {
    console.log('❌ C3 FAILED: Topic field pattern not found')
  }
}

// ══════════════════════════════════════════════════
// CHANGE 4: Add Preview Confirm Modal + AI Edit Modal JSX
// before closing of component return
// ══════════════════════════════════════════════════
const modalAnchor = `{/* PREVIEW ALL */}`
const modals = `{/* CONFIRM PREVIEW MODAL */}
{confirmQ&&<div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.85)',zIndex:9999,display:'flex',alignItems:'center',justifyContent:'center',padding:'16px'}} onClick={()=>setConfirmQ(null)}>
<div style={{background:'#0d1117',border:'1px solid rgba(168,85,247,0.4)',borderRadius:16,padding:'20px',maxWidth:600,width:'100%',maxHeight:'90vh',overflowY:'auto'}} onClick={e=>e.stopPropagation()}>
<div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
<span style={{color:'#A788BF',fontWeight:700,fontSize:16}}>📋 Question Preview</span>
<button onClick={()=>setConfirmQ(null)} style={{background:'none',border:'none',color:'#888',fontSize:20,cursor:'pointer'}}>✕</button>
</div>
<div style={{background:'rgba(168,85,247,0.07)',borderRadius:10,padding:'14px',marginBottom:14}}>
<div style={{color:'#E2E8F0',fontSize:14,marginBottom:8}} dangerouslySetInnerHTML={{__html:_html.renderLatex(confirmQ.text)}}/>
{confirmQ.hindi&&<div style={{color:'#94a3b8',fontSize:12,marginTop:6}} dangerouslySetInnerHTML={{__html:_html.renderLatex(confirmQ.hindi)}}/>}
{confirmQ.img&&<img src={confirmQ.img} style={{maxWidth:'100%',borderRadius:8,marginTop:8}} onError={e=>{(e.target as HTMLImageElement).style.display='none'}}/>}
</div>
{confirmQ.options&&confirmQ.options.length>0&&<div style={{marginBottom:14}}>
{confirmQ.options.map((opt:string,i:number)=>{
const letters=['A','B','C','D']
const isAns=confirmQ.ans===('Option '+letters[i])
return <div key={i} style={{padding:'8px 12px',borderRadius:8,marginBottom:6,background:isAns?'rgba(34,197,94,0.15)':'rgba(255,255,255,0.04)',border:isAns?'1px solid rgba(34,197,94,0.5)':'1px solid rgba(255,255,255,0.1)',color:isAns?'#4ade80':'#E2E8F0',fontSize:13}}>
<span style={{fontWeight:700,marginRight:8}}>{letters[i]}.</span>
<span dangerouslySetInnerHTML={{__html:_html.renderLatex(opt)}}/>
{isAns&&<span style={{marginLeft:8,fontSize:11,color:'#4ade80'}}>✓ Correct</span>}
</div>
})}
</div>}
{confirmQ.exp&&<div style={{background:'rgba(252,211,77,0.08)',borderRadius:8,padding:'10px',marginBottom:14,fontSize:12,color:'#fcd34d'}} dangerouslySetInnerHTML={{__html:'💡 '+_html.renderLatex(confirmQ.exp)}}/>}
<div style={{display:'flex',gap:8,flexWrap:'wrap',marginBottom:12}}>
{confirmQ.subject&&<span style={{background:'rgba(168,85,247,0.2)',color:'#c084fc',padding:'3px 10px',borderRadius:20,fontSize:11}}>{confirmQ.subject}</span>}
{confirmQ.chapter&&<span style={{background:'rgba(59,130,246,0.2)',color:'#60a5fa',padding:'3px 10px',borderRadius:20,fontSize:11}}>{confirmQ.chapter}</span>}
{confirmQ.topic&&<span style={{background:'rgba(20,184,166,0.2)',color:'#2dd4bf',padding:'3px 10px',borderRadius:20,fontSize:11}}>{confirmQ.topic}</span>}
{confirmQ.difficulty&&<span style={{background:'rgba(245,158,11,0.2)',color:'#fbbf24',padding:'3px 10px',borderRadius:20,fontSize:11}}>{confirmQ.difficulty}</span>}
</div>
<div style={{display:'flex',gap:10,justifyContent:'flex-end'}}>
<button onClick={()=>setConfirmQ(null)} style={{padding:'10px 20px',borderRadius:8,background:'rgba(255,255,255,0.05)',border:'1px solid rgba(255,255,255,0.15)',color:'#94a3b8',cursor:'pointer',fontSize:13}}>✏️ Edit</button>
<button onClick={()=>{setConfirmQ(null);confirmAndAdd()}} style={{padding:'10px 24px',borderRadius:8,background:'linear-gradient(135deg,#7c3aed,#4f46e5)',border:'none',color:'#fff',cursor:'pointer',fontSize:13,fontWeight:700}}>✅ Confirm & Add</button>
</div>
</div>
</div>}

{/* AI EDIT MODAL */}
{aiEditQ&&<div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.85)',zIndex:9999,display:'flex',alignItems:'center',justifyContent:'center',padding:'16px'}} onClick={()=>setAiEditQ(null)}>
<div style={{background:'#0d1117',border:'1px solid rgba(168,85,247,0.4)',borderRadius:16,padding:'20px',maxWidth:600,width:'100%',maxHeight:'90vh',overflowY:'auto'}} onClick={e=>e.stopPropagation()}>
<div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
<span style={{color:'#A788BF',fontWeight:700,fontSize:16}}>✏️ Edit AI Question {aiEditIdx!==null?(aiEditIdx+1):''}</span>
<button onClick={()=>setAiEditQ(null)} style={{background:'none',border:'none',color:'#888',fontSize:20,cursor:'pointer'}}>✕</button>
</div>
<div style={{marginBottom:10}}><label style={{...lbl}}>Question Text</label><textarea value={aiEditQ.text||''} onChange={e=>setAiEditQ((p:any)=>({...p,text:e.target.value}))} rows={3} style={{...inp,resize:'vertical'}}/></div>
<div style={{marginBottom:10}}><label style={{...lbl}}>Option A</label><input value={aiEditQ.options?.[0]||''} onChange={e=>setAiEditQ((p:any)=>{const o=[...(p.options||[])];o[0]=e.target.value;return{...p,options:o}})} style={{...inp}}/></div>
<div style={{marginBottom:10}}><label style={{...lbl}}>Option B</label><input value={aiEditQ.options?.[1]||''} onChange={e=>setAiEditQ((p:any)=>{const o=[...(p.options||[])];o[1]=e.target.value;return{...p,options:o}})} style={{...inp}}/></div>
<div style={{marginBottom:10}}><label style={{...lbl}}>Option C</label><input value={aiEditQ.options?.[2]||''} onChange={e=>setAiEditQ((p:any)=>{const o=[...(p.options||[])];o[2]=e.target.value;return{...p,options:o}})} style={{...inp}}/></div>
<div style={{marginBottom:10}}><label style={{...lbl}}>Option D</label><input value={aiEditQ.options?.[3]||''} onChange={e=>setAiEditQ((p:any)=>{const o=[...(p.options||[])];o[3]=e.target.value;return{...p,options:o}})} style={{...inp}}/></div>
<div style={{marginBottom:10}}><label style={{...lbl}}>Correct Answer</label>
<select value={aiEditQ.correctAnswer||''} onChange={e=>setAiEditQ((p:any)=>({...p,correctAnswer:e.target.value}))} style={{...inp,width:'100%'}}>
<option value=''>Select</option><option value='Option A'>Option A</option><option value='Option B'>Option B</option><option value='Option C'>Option C</option><option value='Option D'>Option D</option>
</select></div>
<div style={{marginBottom:10}}><label style={{...lbl}}>Explanation</label><textarea value={aiEditQ.explanation||''} onChange={e=>setAiEditQ((p:any)=>({...p,explanation:e.target.value}))} rows={2} style={{...inp,resize:'vertical'}}/></div>
<div style={{display:'flex',gap:10,justifyContent:'flex-end',marginTop:16}}>
<button onClick={()=>setAiEditQ(null)} style={{padding:'10px 20px',borderRadius:8,background:'rgba(255,255,255,0.05)',border:'1px solid rgba(255,255,255,0.15)',color:'#94a3b8',cursor:'pointer'}}>Cancel</button>
<button onClick={()=>{if(aiEditIdx!==null){setPyqData((p:any[])=>{const a=[...p];a[aiEditIdx]=aiEditQ;return a})};setAiEditQ(null)}} style={{padding:'10px 24px',borderRadius:8,background:'linear-gradient(135deg,#7c3aed,#4f46e5)',border:'none',color:'#fff',cursor:'pointer',fontWeight:700}}>💾 Save Changes</button>
</div>
</div>
</div>}

{/* PREVIEW ALL */}`

if(c.includes('const confirmAndAdd=async()=>{')){
  if(c.includes('{/* CONFIRM PREVIEW MODAL */}')){
    console.log('⏭  Modals already exist')
  } else if(c.includes(modalAnchor)){
    c=c.replace(modalAnchor, modals)
    console.log('✅ C4: Preview + AI Edit modals added')
  } else {
    console.log('❌ C4 FAILED: PREVIEW ALL anchor not found')
  }
} else {
  console.log('⏭  C4: Skipped (addQ not intercepted yet)')
}

// ══════════════════════════════════════════════════
// CHANGE 5: Add Edit button in AI questions list
// ══════════════════════════════════════════════════
// Find the AI questions map and add edit button
const aiQCard = `<div key={i} style={{...cs,marginBottom:8}}>`
const aiQCardWithEdit = `<div key={i} style={{...cs,marginBottom:8,position:'relative'}}><button onClick={()=>{setAiEditIdx(i);setAiEditQ(q)}} style={{position:'absolute',top:6,right:6,background:'rgba(168,85,247,0.2)',border:'1px solid rgba(168,85,247,0.4)',color:'#c084fc',borderRadius:6,padding:'3px 8px',fontSize:11,cursor:'pointer',zIndex:1}}>✏️ Edit</button>`

if(c.includes('setAiEditIdx(i)')){
  console.log('⏭  AI edit button already exists')
} else if(c.includes(aiQCard)){
  c=c.replace(aiQCard, aiQCardWithEdit)
  console.log('✅ C5: AI edit button added')
} else {
  console.log('❌ C5 FAILED: AI card pattern not found')
}

fs.writeFileSync(FILE, c)
console.log('\n✅ File saved!')
NODEOF

echo ""
echo "=== Verify ==="
grep -n "confirmQ\|Chapter\|confirmAndAdd\|aiEditQ\|CONFIRM PREVIEW" ~/workspace/frontend/app/admin/x7k2p/page.tsx | head -15

echo "=== Done ==="
