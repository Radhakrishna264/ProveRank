#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# ProveRank — AI Split Modes Fix
# NCERT Mode & Files Mode → Fully Independent Modals
# QsBank page par do alag cards → do alag modals → zero shared state
# ═══════════════════════════════════════════════════════════════

FILE="$HOME/workspace/frontend/app/admin/x7k2p/page.tsx"

if [ ! -f "$FILE" ]; then
  echo "❌ File not found: $FILE"
  exit 1
fi

echo "📂 File found. Creating backup..."
cp "$FILE" "${FILE}.bak_ai_split"
echo "✅ Backup: ${FILE}.bak_ai_split"
echo ""
echo "🔧 Applying patches..."

node << 'NODEEOF'
const fs = require('fs');
const FILE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let code = fs.readFileSync(FILE, 'utf8');
let patches = 0;

function replace(label, oldStr, newStr) {
  if (code.includes(oldStr)) {
    code = code.replace(oldStr, newStr);
    console.log('  ✅ PATCH ' + (++patches) + ': ' + label);
  } else {
    console.log('  ⚠️  SKIP  : ' + label + ' (string not found — may already be applied)');
  }
}

// ── PATCH 1 — Add new independent states ──────────────────────
replace(
  'Add FM + NCERT split states',
  `  const [selMatId,setSelMatId]=useState('')
  const [aiGResult,setAiGResult]=useState([])`,
  `  const [selMatId,setSelMatId]=useState('')
  const [aiGResult,setAiGResult]=useState([])
  const [aiGO_ncert,setAiGO_ncert]=useState(false)
  const [aiGO_files,setAiGO_files]=useState(false)
  const [fmSubj,setFmSubj]=useState('Physics')
  const [fmType,setFmType]=useState('SCQ')
  const [fmResult,setFmResult]=useState([])
  const [fmShowPreview,setFmShowPreview]=useState(false)
  const [fmExamLevel,setFmExamLevel]=useState('NEET')
  const [fmFormats,setFmFormats]=useState(['Random'])
  const [matTitle,setMatTitle]=useState('')`
);

// ── PATCH 2 — Fix fetchMats: silent catch → error toast ────────
replace(
  'fetchMats error handling',
  `  const fetchMats=async()=>{
    setMatLoading(true)
    try{const r=await fetch(API+'/api/materials',{headers:{Authorization:'Bearer '+token}});if(r.ok)setMatList(await r.json())}catch(e){}
    setMatLoading(false)
  }`,
  `  const fetchMats=async()=>{
    setMatLoading(true)
    try{
      const r=await fetch(API+'/api/materials',{headers:{Authorization:'Bearer '+token}})
      if(r.ok)setMatList(await r.json())
      else T('Failed to load materials ('+r.status+')','e')
    }catch(e){T('Network error loading materials','e')}
    setMatLoading(false)
  }`
);

// ── PATCH 3 — Fix deleteMat: no error feedback → proper handling ─
replace(
  'deleteMat error handling',
  `  const deleteMat=async(id)=>{
    if(!confirm('Delete this material?'))return
    const r=await fetch(API+'/api/materials/'+id,{method:'DELETE',headers:{Authorization:'Bearer '+token}})
    if(r.ok){setMatList(function(p){return p.filter(function(m){return m._id!==id})});T('Deleted')}
  }`,
  `  const deleteMat=async(id)=>{
    if(!window.confirm('Delete this material?'))return
    try{
      const r=await fetch(API+'/api/materials/'+id,{method:'DELETE',headers:{Authorization:'Bearer '+token}})
      if(r.ok){setMatList(function(p){return p.filter(function(m){return m._id!==id})});T('🗑️ Material deleted')}
      else T('Delete failed ('+r.status+')','e')
    }catch(e){T(e.message||'Network error','e')}
  }`
);

// ── PATCH 4 — Fix generateFromMat: use fmResult, add subject+type ─
replace(
  'generateFromMat use fmResult + subject + type + r.ok check',
  `  const generateFromMat=async(matId,cnt,diff)=>{
    setMatGenLoading(true)
    try{
      const genRes=await fetch(API+'/api/materials/generate',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({materialId:matId,count:cnt,difficulty:diff,examLevel:aiExamLevel,formats:aiFormats})})
      const qs=await genRes.json()
      if(Array.isArray(qs)&&qs.length>0){setAiGResult(qs);setAiGO(false);setShowAiPreview(true);T('✅ '+qs.length+' Qs from material!')}
      else T('Could not generate questions. Try again.','e')
    }catch(e){T(e.message||'Failed','e')}
    setMatGenLoading(false)
  }`,
  `  const generateFromMat=async(matId,cnt,diff)=>{
    setMatGenLoading(true)
    try{
      const genRes=await fetch(API+'/api/materials/generate',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({materialId:matId,count:cnt,difficulty:diff,examLevel:fmExamLevel,formats:fmFormats,subject:fmSubj,type:fmType})})
      if(!genRes.ok){T('Generation failed ('+genRes.status+')','e');setMatGenLoading(false);return}
      const qs=await genRes.json()
      if(Array.isArray(qs)&&qs.length>0){setFmResult(qs);setFmShowPreview(true);T('✅ '+qs.length+' Qs generated!')}
      else T('No questions generated. Try again.','e')
    }catch(e){T(e.message||'Failed','e')}
    setMatGenLoading(false)
  }`
);

// ── PATCH 5 — Fix handleMatFile: file size check + r.ok on extract ─
replace(
  'handleMatFile size check + extract r.ok',
  `  const handleMatFile=async(file,customTitle)=>{
    if(!file)return
    setMatUploading(true)
    try{
      const ext=(file.name.split('.').pop()||'').toLowerCase()
      let content=''
      if(['txt','csv','md','json','html'].includes(ext)){
        content=await new Promise(function(res,rej){const rd=new FileReader();rd.onload=function(e){res(e.target.result)};rd.onerror=rej;rd.readAsText(file)})
      }else{
        const b64=await new Promise(function(res,rej){const rd=new FileReader();rd.onload=function(e){res(e.target.result.split(',')[1])};rd.onerror=rej;rd.readAsDataURL(file)})
        const extResp=await fetch(API+'/api/materials/extract',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({base64:b64,fileName:file.name,isText:false})})
        const extData=await extResp.json()
        content=extData.content||''
      }
      if(content.trim())await saveMat(customTitle||file.name,content,ext,file.size)
      else T('No content extracted','e')
    }catch(e){T(e.message||'Upload failed','e')}
    setMatUploading(false)
  }`,
  `  const handleMatFile=async(file,customTitle)=>{
    if(!file)return
    if(file.size>10*1024*1024){T('File too large — max 10MB allowed','e');return}
    setMatUploading(true)
    try{
      const ext=(file.name.split('.').pop()||'').toLowerCase()
      let content=''
      if(['txt','csv','md','json','html'].includes(ext)){
        content=await new Promise(function(res,rej){const rd=new FileReader();rd.onload=function(e){res(e.target.result)};rd.onerror=rej;rd.readAsText(file)})
      }else{
        const b64=await new Promise(function(res,rej){const rd=new FileReader();rd.onload=function(e){res(e.target.result.split(',')[1])};rd.onerror=rej;rd.readAsDataURL(file)})
        const extResp=await fetch(API+'/api/materials/extract',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({base64:b64,fileName:file.name,isText:false})})
        if(!extResp.ok){T('Extraction failed ('+extResp.status+') — try TXT format','e');setMatUploading(false);return}
        const extData=await extResp.json()
        content=extData.content||''
      }
      if(content.trim()){await saveMat(customTitle||file.name,content,ext,file.size);setMatTitle('')}
      else T('No content extracted from file','e')
    }catch(e){T(e.message||'Upload failed','e')}
    setMatUploading(false)
  }`
);

// ── PATCH 6 — Fix saveAiQs: setAiGO(false) → setAiGO_ncert(false) ──
replace(
  'saveAiQs close ncert modal',
  `      if(r.ok){T(aiGResult.length+' saved!');setAiGResult([]);setAiGO(false);setTimeout(()=>fetchAll(),400)}`,
  `      if(r.ok){T(aiGResult.length+' saved!');setAiGResult([]);setAiGO_ncert(false);setTimeout(()=>fetchAll(),400)}`
);

// ── PATCH 7 — Add saveFmQs function after saveAiQs ────────────
replace(
  'Add saveFmQs for Files Mode',
  `  const blkDelQs=async()=>{`,
  `  const saveFmQs=async()=>{
    if(!fmResult.length)return
    try{
      const r=await fetch(API+'/api/questions/bulk-save',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({questions:fmResult})})
      if(r.ok){T(fmResult.length+' questions saved!');setFmResult([]);setFmShowPreview(false);setTimeout(()=>fetchAll(),400)}
      else T('Save failed','e')
    }catch(e){T(e.message||'Error saving','e')}
  }
  const blkDelQs=async()=>{`
);

// ── PATCH 8 — Replace single "Upload Via AI" button with 2 cards ─
replace(
  'Replace single AI button with two split cards',
  `                  <div style={{display:'flex',justifyContent:'center',marginTop:18}}>
                    <div onClick={function(){setAiGO(true)}} style={{display:'flex',alignItems:'center',gap:10,background:'linear-gradient(135deg,rgba(77,159,255,0.15),rgba(168,85,247,0.2))',border:'1.5px solid rgba(168,85,247,0.45)',borderRadius:50,padding:'10px 22px',cursor:'pointer',boxShadow:'0 0 20px rgba(168,85,247,0.4)',animation:'qbpulse 2s infinite'}}>
                      <div style={{width:38,height:38,borderRadius:'50%',background:'linear-gradient(135deg,#4D9FFF,#A855F7)',display:'flex',alignItems:'center',justifyContent:'center',boxShadow:'0 0 12px rgba(168,85,247,0.6)',fontSize:18,flexShrink:0}}>🤖</div>
                      <div><div style={{fontSize:13,fontWeight:800,color:'#E2E8F0'}}>Upload Via AI</div><div style={{fontSize:10,color:'#A78BFA'}}>Auto-generate NCERT questions</div></div>
                      <div style={{fontSize:16,color:'#A78BFA'}}>✨</div>
                    </div>
                  </div>
                  <style dangerouslySetInnerHTML={{__html:'@keyframes qbpulse{0%,100%{box-shadow:0 0 20px rgba(168,85,247,0.4)}50%{box-shadow:0 0 35px rgba(168,85,247,0.7),0 0 55px rgba(77,159,255,0.3)}}'}}/>\n                </div>`,
  `                  <div style={{marginTop:18}}>
                    <div style={{textAlign:'center',fontSize:9,fontWeight:700,color:'#475569',letterSpacing:2,marginBottom:10,textTransform:'uppercase'}}>⚡ AI Question Generator — Choose Mode</div>
                    <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                      {/* ── LEFT: NCERT Mode ── */}
                      <div onClick={function(){setAiGO_ncert(true)}} style={{background:'linear-gradient(160deg,rgba(168,85,247,0.12),rgba(77,159,255,0.08))',border:'1.5px solid rgba(168,85,247,0.4)',borderRadius:16,padding:'14px 12px',cursor:'pointer',textAlign:'center',transition:'all 0.25s',animation:'ncertpulse 2.5s infinite'}}>
                        <div style={{width:40,height:40,borderRadius:'50%',background:'linear-gradient(135deg,#7C3AED,#4D9FFF)',display:'flex',alignItems:'center',justifyContent:'center',margin:'0 auto 8px',boxShadow:'0 0 14px rgba(168,85,247,0.5)',fontSize:18}}>🤖</div>
                        <div style={{fontSize:12,fontWeight:800,color:'#E2E8F0',marginBottom:3}}>NCERT Mode</div>
                        <div style={{fontSize:9,color:'#A78BFA',marginBottom:8}}>NEET · JEE · CUET</div>
                        <div style={{textAlign:'left'}}>
                          <div style={{fontSize:9,color:'#64748B',marginBottom:2}}>✦ Subject → Chapter → Topic</div>
                          <div style={{fontSize:9,color:'#64748B',marginBottom:2}}>✦ Auto answers & explanations</div>
                          <div style={{fontSize:9,color:'#64748B'}}>✦ 11 question formats</div>
                        </div>
                      </div>
                      {/* ── RIGHT: Files Mode ── */}
                      <div onClick={function(){setAiGO_files(true);fetchMats()}} style={{background:'linear-gradient(160deg,rgba(0,200,100,0.1),rgba(0,150,200,0.07))',border:'1.5px solid rgba(0,200,100,0.35)',borderRadius:16,padding:'14px 12px',cursor:'pointer',textAlign:'center',transition:'all 0.25s',animation:'filespulse 2.5s infinite'}}>
                        <div style={{width:40,height:40,borderRadius:'50%',background:'linear-gradient(135deg,#059669,#0EA5E9)',display:'flex',alignItems:'center',justifyContent:'center',margin:'0 auto 8px',boxShadow:'0 0 14px rgba(0,200,100,0.4)',fontSize:18}}>📁</div>
                        <div style={{fontSize:12,fontWeight:800,color:'#E2E8F0',marginBottom:3}}>From Files</div>
                        <div style={{fontSize:9,color:'#00C864',marginBottom:8}}>PDF · DOCX · TXT · Notes</div>
                        <div style={{textAlign:'left'}}>
                          <div style={{fontSize:9,color:'#64748B',marginBottom:2}}>✦ Upload your own material</div>
                          <div style={{fontSize:9,color:'#64748B',marginBottom:2}}>✦ AI extracts & generates Qs</div>
                          <div style={{fontSize:9,color:'#64748B'}}>✦ Paste text also supported</div>
                        </div>
                      </div>
                    </div>
                  </div>
                  <style dangerouslySetInnerHTML={{__html:'@keyframes ncertpulse{0%,100%{box-shadow:0 0 0 rgba(168,85,247,0.3)}50%{box-shadow:0 0 18px rgba(168,85,247,0.45),0 0 30px rgba(77,159,255,0.2)}}@keyframes filespulse{0%,100%{box-shadow:0 0 0 rgba(0,200,100,0.3)}50%{box-shadow:0 0 18px rgba(0,200,100,0.4),0 0 30px rgba(0,150,200,0.2)}}@keyframes qbpulse{0%,100%{box-shadow:0 0 20px rgba(168,85,247,0.4)}50%{box-shadow:0 0 35px rgba(168,85,247,0.7),0 0 55px rgba(77,159,255,0.3)}}'}}/>\n                </div>`
);

// ── PATCH 9 — Replace single combined aiGO modal with 2 independent ─
// Find start and end markers
const MODAL_START = '\n              {/* AI GENERATE MODAL — Single Form */}\n              {aiGO&&(function(){';
const MODAL_END = '\n              {/* QUESTION PREVIEW MODAL */}';

const startIdx = code.indexOf(MODAL_START);
const endIdx = code.indexOf(MODAL_END);

if (startIdx === -1 || endIdx === -1) {
  console.log('  ⚠️  SKIP  : Split modals (markers not found — may already be applied)');
} else {
  // Extract the NCERT object from old code to reuse it
  const ncertObjStart = code.indexOf('const NCERT={"Physics"', startIdx);
  const ncertObjEndMarker = '\n                const subj=aiGSub';
  const ncertObjEndIdx = code.indexOf(ncertObjEndMarker, ncertObjStart);
  const NCERT_OBJ = code.slice(ncertObjStart, ncertObjEndIdx + 1);

  const NEW_MODALS = `
              {/* ════════════════════════════════════════════════════ */}
              {/* NCERT MODE MODAL — Fully Independent               */}
              {/* ════════════════════════════════════════════════════ */}
              {aiGO_ncert&&(function(){
                ${NCERT_OBJ}
                const subj=aiGSub
                const chapters=subj&&NCERT[subj]?Object.keys(NCERT[subj]):[]
                const topics=aiSelChap&&NCERT[subj]&&NCERT[subj][aiSelChap]?NCERT[subj][aiSelChap]:[]
                return(
                  <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.88)',zIndex:1000,display:'flex',alignItems:'center',justifyContent:'center',padding:14,overflowY:'auto'}}>
                    <div style={{background:'linear-gradient(160deg,#0D1B2A,#0F1E30)',border:'1px solid rgba(168,85,247,0.35)',borderRadius:20,padding:20,width:'100%',maxWidth:480,maxHeight:'95vh',overflowY:'auto',boxShadow:'0 20px 60px rgba(0,0,0,0.6)'}}>
                      {/* Header */}
                      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
                        <div>
                          <div style={{fontSize:14,fontWeight:800,color:'#E2E8F0'}}>🤖 NCERT AI Generator</div>
                          <div style={{fontSize:10,color:'#A78BFA',marginTop:2}}>NCERT Based · Auto answers & explanations</div>
                        </div>
                        <button onClick={function(){setAiGO_ncert(false);setAiGResult([])}} style={{...bg_,padding:'4px 10px',fontSize:12}}>✕</button>
                      </div>
                      {/* Subject */}
                      <div style={{marginBottom:12}}>
                        <label style={lbl}>📚 Subject *</label>
                        <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:6}}>
                          {['Physics','Chemistry','Biology','Math'].map(function(s){return(
                            <div key={s} onClick={function(){setAiGSub(s);aiChR.current='';aiTopR.current='';setAiSelChap('')}} style={{padding:'8px 4px',borderRadius:8,border:'1.5px solid '+(aiGSub===s?'rgba(168,85,247,0.5)':'rgba(255,255,255,0.08)'),background:aiGSub===s?'rgba(168,85,247,0.12)':'rgba(255,255,255,0.02)',cursor:'pointer',textAlign:'center'}}>
                              <div style={{fontSize:11,fontWeight:700,color:aiGSub===s?'#A78BFA':'#94A3B8'}}>{s}</div>
                            </div>
                          )})}
                        </div>
                      </div>
                      {/* Chapter */}
                      <div style={{marginBottom:10}}>
                        <label style={lbl}>📖 Chapter * <span style={{color:'#475569',fontSize:9}}>(select or type)</span></label>
                        <select onChange={function(e){if(e.target.value){aiChR.current=e.target.value;setAiSelChap(e.target.value)}}} style={{...inp,width:'100%',marginBottom:5}}>
                          <option value=''>— Select NCERT Chapter —</option>
                          {chapters.map(function(c){const dn=c.includes(' - ')?c.split(' - ').slice(1).join(' - '):c;return <option key={c} value={c}>{dn}</option>})}
                        </select>
                        <input defaultValue='' placeholder='Or type custom chapter…' onChange={function(e){aiChR.current=e.target.value;setAiSelChap(e.target.value)}} style={{...inp,width:'100%',fontSize:11}}/>
                      </div>
                      {/* Topic */}
                      <div style={{marginBottom:10}}>
                        <label style={lbl}>📌 Topic * <span style={{color:'#475569',fontSize:9}}>(select or type)</span></label>
                        <select onChange={function(e){if(e.target.value)aiTopR.current=e.target.value}} style={{...inp,width:'100%',marginBottom:5}}>
                          <option value=''>— Select NCERT Topic —</option>
                          {topics.map(function(tp){return <option key={tp} value={tp}>{tp}</option>})}
                        </select>
                        <input defaultValue='' placeholder='Or type custom topic…' onChange={function(e){aiTopR.current=e.target.value}} style={{...inp,width:'100%',fontSize:11}}/>
                      </div>
                      {/* Count + Difficulty */}
                      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:10}}>
                        <div>
                          <label style={lbl}>🔢 Count (1–30)</label>
                          <input type='number' min='1' max='30' defaultValue='10' onChange={function(e){setAiGCnt(e.target.value)}} style={{...inp,width:'100%'}}/>
                        </div>
                        <div>
                          <label style={lbl}>🎯 Difficulty</label>
                          <select value={aiGDiff} onChange={function(e){setAiGDiff(e.target.value)}} style={{...inp,width:'100%'}}>
                            <option value='easy'>🟢 Easy</option>
                            <option value='medium'>🟡 Medium</option>
                            <option value='hard'>🔴 Hard</option>
                          </select>
                        </div>
                      </div>
                      {/* Question Type */}
                      <div style={{marginBottom:10}}>
                        <label style={lbl}>📋 Question Type</label>
                        <div style={{display:'flex',gap:6}}>
                          {['SCQ','MSQ','Integer'].map(function(tp){return(
                            <button key={tp} style={{...bg_,fontSize:10,padding:'4px 10px',flex:1,background:aiType===tp?'rgba(168,85,247,0.25)':'transparent',border:aiType===tp?'1px solid rgba(168,85,247,0.8)':'1px solid rgba(255,255,255,0.1)',color:aiType===tp?'#fff':'#94a3b8'}} onClick={function(){setAiType(tp)}}>{tp}</button>
                          )})}
                        </div>
                      </div>
                      {/* Exam Level */}
                      <div style={{marginBottom:10}}>
                        <div style={{fontSize:11,fontWeight:700,color:'#A78BFA',letterSpacing:1,marginBottom:6}}>🎯 EXAM LEVEL</div>
                        <div style={{display:'flex',flexWrap:'wrap',gap:5}}>
                          {(['NEET','JEE_MAINS','JEE_ADVANCED','CUET','BOARD','OTHER'] as const).map(lvl=>(
                            <button key={lvl} onClick={()=>setAiExamLevel(lvl)} style={{padding:'4px 10px',borderRadius:6,fontSize:11,fontWeight:600,border:'none',cursor:'pointer',background:aiExamLevel===lvl?'#7C3AED':'rgba(124,58,237,0.15)',color:aiExamLevel===lvl?'#fff':'#C4B5FD',transition:'all 0.2s'}}>{lvl.replace(/_/g,' ')}</button>
                          ))}
                        </div>
                      </div>
                      {/* Format */}
                      <div style={{marginBottom:10}}>
                        <div style={{fontSize:11,fontWeight:700,color:'#A78BFA',letterSpacing:1,marginBottom:4}}>📋 FORMAT <span style={{fontWeight:400,color:'#888'}}>(multi-select)</span></div>
                        <div style={{display:'flex',flexWrap:'wrap',gap:4}}>
                          {(['Random','Statement_Based','Assertion_Reason','True_False','Numerical','Fill_Blanks','Match_Column','Passage_Based','Sequence_Based','Graph_Data_Based','Diagram_Based'] as const).map(fmt=>{
                            const sel=aiFormats.includes(fmt);
                            return(<button key={fmt} onClick={()=>setAiFormats((p:string[])=>{if(fmt==='Random')return['Random'];const filtered=p.filter((x:string)=>x!=='Random');const already=filtered.includes(fmt);const next=already?filtered.filter((x:string)=>x!==fmt):[...filtered,fmt];return next.length===0?['Random']:next;})} style={{padding:'3px 8px',borderRadius:5,fontSize:10,fontWeight:600,border:'none',cursor:'pointer',background:sel?'#059669':'rgba(5,150,105,0.15)',color:sel?'#fff':'#6EE7B7',transition:'all 0.2s'}}>{fmt.replace(/_/g,' ')}</button>);
                          })}
                        </div>
                      </div>
                      {/* Diagram URL */}
                      {aiFormats.includes('Diagram_Based')&&(
                        <div style={{marginBottom:10}}>
                          <div style={{fontSize:11,fontWeight:700,color:'#F59E0B',marginBottom:4}}>🖼️ DIAGRAM IMAGE URL <span style={{fontWeight:400,color:'#888'}}>(optional)</span></div>
                          <input value={aiImageUrl} onChange={(e:React.ChangeEvent<HTMLInputElement>)=>setAiImageUrl(e.target.value)} placeholder="Paste image URL…" style={{width:'100%',padding:'6px 10px',background:'rgba(245,158,11,0.08)',border:'1px solid rgba(245,158,11,0.3)',borderRadius:6,color:'#fff',fontSize:11,outline:'none',boxSizing:'border-box'}}/>
                        </div>
                      )}
                      {/* Result preview */}
                      {aiGResult.length>0&&(
                        <div style={{marginBottom:12}}>
                          <div style={{fontSize:11,fontWeight:700,color:'#00C864',marginBottom:6}}>✅ {aiGResult.length} Questions Generated!</div>
                          <div style={{maxHeight:100,overflowY:'auto',display:'flex',flexDirection:'column',gap:3,marginBottom:8}}>
                            {aiGResult.map(function(q:any,i:number){return(<div key={i} style={{padding:'4px 8px',background:'rgba(0,200,100,0.05)',borderRadius:5,fontSize:10,color:'#CBD5E1'}}>Q{i+1}: {(q.text||'').slice(0,65)}…</div>)})}
                          </div>
                          <button onClick={()=>setShowAiPreview(true)} style={{...bp,width:'100%',fontSize:11,marginBottom:8}}>💾 Review & Save All {aiGResult.length} Questions</button>
                        </div>
                      )}
                      {/* Generate Button */}
                      <button onClick={aiGF} disabled={aiGLoading} style={{...bp,width:'100%',opacity:aiGLoading?0.7:1}}>
                        {aiGLoading?'⟳ Generating NCERT Questions…':'🤖 Generate Questions'}
                      </button>
                      <div style={{fontSize:9,color:'#475569',textAlign:'center',marginTop:6}}>NCERT-based questions · auto answers & explanations</div>
                    </div>
                  </div>
                )
              })()}

              {/* ════════════════════════════════════════════════════ */}
              {/* FILES MODE MODAL — Fully Independent               */}
              {/* ════════════════════════════════════════════════════ */}
              {aiGO_files&&(function(){
                return(
                  <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.88)',zIndex:1000,display:'flex',alignItems:'center',justifyContent:'center',padding:14,overflowY:'auto'}}>
                    <div style={{background:'linear-gradient(160deg,#071A12,#0A1E18)',border:'1px solid rgba(0,200,100,0.3)',borderRadius:20,padding:20,width:'100%',maxWidth:480,maxHeight:'95vh',overflowY:'auto',boxShadow:'0 20px 60px rgba(0,0,0,0.6)'}}>
                      {/* Header */}
                      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
                        <div>
                          <div style={{fontSize:14,fontWeight:800,color:'#E2E8F0'}}>📁 AI from Files</div>
                          <div style={{fontSize:10,color:'#00C864',marginTop:2}}>Upload PDF/DOCX/TXT → AI generates questions</div>
                        </div>
                        <button onClick={function(){setAiGO_files(false);setFmResult([]);setSelMatId('');setMatTitle('')}} style={{...bg_,padding:'4px 10px',fontSize:12}}>✕</button>
                      </div>
                      {/* Upload section */}
                      <div style={{background:'rgba(0,200,100,0.05)',border:'1px dashed rgba(0,200,100,0.3)',borderRadius:12,padding:'12px 14px',marginBottom:12}}>
                        <div style={{fontSize:11,fontWeight:700,color:'#00C864',marginBottom:5}}>📤 Upload Material</div>
                        <div style={{fontSize:10,color:'#64748B',marginBottom:8}}>PDF, DOCX, TXT, CSV, MD — max 10MB</div>
                        <input
                          type='text'
                          value={matTitle}
                          onChange={function(e){setMatTitle(e.target.value)}}
                          placeholder='📝 Title (e.g. Chapter 5 Notes)'
                          disabled={matUploading}
                          style={{...inp,width:'100%',marginBottom:6,fontSize:11,opacity:matUploading?0.5:1}}
                        />
                        <div style={{display:'flex',gap:6}}>
                          <label style={{flex:1,padding:'7px 12px',borderRadius:8,border:'1px solid rgba(0,200,100,0.3)',background:'rgba(0,200,100,0.08)',color:'#00C864',fontSize:10,cursor:matUploading?'not-allowed':'pointer',textAlign:'center',fontWeight:600,opacity:matUploading?0.6:1}}>
                            {matUploading?'⟳ Extracting…':'📁 Choose File'}
                            <input type='file' accept='.pdf,.docx,.txt,.csv,.md,.html,.json' style={{display:'none'}} disabled={matUploading} onChange={function(e){const f=e.target.files?.[0];if(f)handleMatFile(f,matTitle||f.name);e.target.value=''}}/>
                          </label>
                          <button
                            disabled={matUploading}
                            onClick={function(){const t=prompt('📋 Paste your notes/content:');if(t&&t.trim()){const ttl=matTitle||'Pasted Notes';setMatTitle('');saveMat(ttl,t,'txt',t.length)}}}
                            style={{...bg_,fontSize:10,padding:'7px 10px',flexShrink:0,opacity:matUploading?0.5:1}}>📋 Paste</button>
                        </div>
                      </div>
                      {/* Materials list */}
                      <div style={{marginBottom:12}}>
                        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:8}}>
                          <div style={{fontSize:11,fontWeight:700,color:'#E2E8F0'}}>📚 Saved Materials ({matList.length})</div>
                          <button onClick={fetchMats} style={{...bg_,fontSize:9,padding:'2px 7px'}}>{matLoading?'⟳':'↻ Refresh'}</button>
                        </div>
                        {matLoading&&<div style={{textAlign:'center',padding:'16px',color:'#475569',fontSize:11}}>⟳ Loading…</div>}
                        {!matLoading&&matList.length===0&&<div style={{textAlign:'center',padding:'20px',color:'#475569',fontSize:11,background:'rgba(255,255,255,0.02)',borderRadius:8}}>No materials yet — upload a file above!</div>}
                        {matList.map(function(m:any){
                          const isS=selMatId===m._id
                          const icons:any={pdf:'📄',docx:'📝',txt:'📃',csv:'📊',md:'📋'}
                          return(
                            <div key={m._id} onClick={function(){setSelMatId(isS?'':m._id)}} style={{padding:'9px 12px',borderRadius:10,border:'1.5px solid '+(isS?'rgba(0,200,100,0.5)':'rgba(255,255,255,0.07)'),background:isS?'rgba(0,200,100,0.08)':'rgba(255,255,255,0.02)',cursor:'pointer',marginBottom:6,transition:'all 0.2s'}}>
                              <div style={{display:'flex',justifyContent:'space-between',alignItems:'center'}}>
                                <div style={{display:'flex',alignItems:'center',gap:7,flex:1,minWidth:0}}>
                                  <span style={{fontSize:16,flexShrink:0}}>{icons[m.fileType]||'📄'}</span>
                                  <div style={{flex:1,minWidth:0}}>
                                    <div style={{fontSize:11,fontWeight:600,color:isS?'#00C864':'#E2E8F0',overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{m.title}</div>
                                    <div style={{fontSize:9,color:'#475569',marginTop:1}}>{m.fileType.toUpperCase()} · {m.fileSize>1024?(Math.round(m.fileSize/1024)+'KB'):(m.fileSize+'B')} · {new Date(m.createdAt).toLocaleDateString()}</div>
                                  </div>
                                </div>
                                <button onClick={function(e){e.stopPropagation();deleteMat(m._id)}} style={{...bg_,fontSize:10,padding:'2px 6px',color:'#F87171',flexShrink:0,marginLeft:6}}>🗑️</button>
                              </div>
                              {isS&&<div style={{fontSize:9,color:'#00C864',marginTop:4}}>✓ Selected — configure below ↓</div>}
                            </div>
                          )
                        })}
                      </div>
                      {/* Generation config — only when material selected */}
                      {selMatId&&(
                        <div style={{background:'rgba(0,200,100,0.04)',border:'1px solid rgba(0,200,100,0.2)',borderRadius:12,padding:'14px'}}>
                          <div style={{fontSize:11,fontWeight:700,color:'#00C864',marginBottom:10}}>⚡ Configure Generation</div>
                          {/* Subject */}
                          <div style={{marginBottom:10}}>
                            <label style={lbl}>📚 Subject (for tagging)</label>
                            <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:5}}>
                              {['Physics','Chemistry','Biology','Math'].map(function(s){return(
                                <div key={s} onClick={function(){setFmSubj(s)}} style={{padding:'6px 4px',borderRadius:7,border:'1.5px solid '+(fmSubj===s?'rgba(0,200,100,0.5)':'rgba(255,255,255,0.08)'),background:fmSubj===s?'rgba(0,200,100,0.12)':'rgba(255,255,255,0.02)',cursor:'pointer',textAlign:'center'}}>
                                  <div style={{fontSize:10,fontWeight:700,color:fmSubj===s?'#00C864':'#94A3B8'}}>{s}</div>
                                </div>
                              )})}
                            </div>
                          </div>
                          {/* Count + Difficulty */}
                          <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:10}}>
                            <div>
                              <label style={lbl}>🔢 Count (1-30)</label>
                              <input type='number' min='1' max='30' value={matGenCnt} onChange={function(e){setMatGenCnt(e.target.value)}} style={{...inp,width:'100%'}}/>
                            </div>
                            <div>
                              <label style={lbl}>🎯 Difficulty</label>
                              <select value={matGenDiff} onChange={function(e){setMatGenDiff(e.target.value)}} style={{...inp,width:'100%'}}>
                                <option value='easy'>🟢 Easy</option>
                                <option value='medium'>🟡 Medium</option>
                                <option value='hard'>🔴 Hard</option>
                              </select>
                            </div>
                          </div>
                          {/* Question Type */}
                          <div style={{marginBottom:10}}>
                            <label style={lbl}>📋 Question Type</label>
                            <div style={{display:'flex',gap:6}}>
                              {['SCQ','MSQ','Integer'].map(function(tp){return(
                                <button key={tp} onClick={function(){setFmType(tp)}} style={{...bg_,fontSize:10,padding:'4px 10px',flex:1,background:fmType===tp?'rgba(0,200,100,0.2)':'transparent',border:fmType===tp?'1px solid rgba(0,200,100,0.6)':'1px solid rgba(255,255,255,0.1)',color:fmType===tp?'#00C864':'#94a3b8'}}>{tp}</button>
                              )})}
                            </div>
                          </div>
                          {/* Exam Level */}
                          <div style={{marginBottom:10}}>
                            <div style={{fontSize:11,fontWeight:700,color:'#00C864',letterSpacing:1,marginBottom:6}}>🎯 EXAM LEVEL</div>
                            <div style={{display:'flex',flexWrap:'wrap',gap:5}}>
                              {(['NEET','JEE_MAINS','JEE_ADVANCED','CUET','BOARD','OTHER'] as const).map(lvl=>(
                                <button key={lvl} onClick={()=>setFmExamLevel(lvl)} style={{padding:'4px 10px',borderRadius:6,fontSize:10,fontWeight:600,border:'none',cursor:'pointer',background:fmExamLevel===lvl?'#059669':'rgba(5,150,105,0.15)',color:fmExamLevel===lvl?'#fff':'#6EE7B7',transition:'all 0.2s'}}>{lvl.replace(/_/g,' ')}</button>
                              ))}
                            </div>
                          </div>
                          {/* Formats */}
                          <div style={{marginBottom:12}}>
                            <div style={{fontSize:11,fontWeight:700,color:'#00C864',letterSpacing:1,marginBottom:4}}>📋 FORMAT <span style={{fontWeight:400,color:'#888'}}>(multi-select)</span></div>
                            <div style={{display:'flex',flexWrap:'wrap',gap:4}}>
                              {(['Random','Statement_Based','Assertion_Reason','True_False','Numerical','Fill_Blanks','Match_Column','Passage_Based','Sequence_Based','Graph_Data_Based','Diagram_Based'] as const).map(fmt=>{
                                const sel=fmFormats.includes(fmt);
                                return(<button key={fmt} onClick={()=>setFmFormats((p:string[])=>{if(fmt==='Random')return['Random'];const filtered=p.filter((x:string)=>x!=='Random');const already=filtered.includes(fmt);const next=already?filtered.filter((x:string)=>x!==fmt):[...filtered,fmt];return next.length===0?['Random']:next;})} style={{padding:'3px 8px',borderRadius:5,fontSize:10,fontWeight:600,border:'none',cursor:'pointer',background:sel?'#059669':'rgba(5,150,105,0.15)',color:sel?'#fff':'#6EE7B7',transition:'all 0.2s'}}>{fmt.replace(/_/g,' ')}</button>);
                              })}
                            </div>
                          </div>
                          {/* Generate Button */}
                          <button onClick={function(){generateFromMat(selMatId,parseInt(matGenCnt)||10,matGenDiff)}} disabled={matGenLoading} style={{...bp,width:'100%',opacity:matGenLoading?0.7:1,background:'linear-gradient(135deg,#059669,#10b981)',border:'none'}}>
                            {matGenLoading?'⟳ AI generating from material…':'🚀 Generate '+matGenCnt+' Questions from File'}
                          </button>
                        </div>
                      )}
                      {/* No material hint */}
                      {!selMatId&&matList.length>0&&(
                        <div style={{textAlign:'center',padding:'14px',color:'#475569',fontSize:11,background:'rgba(0,200,100,0.03)',borderRadius:8,border:'1px solid rgba(0,200,100,0.1)'}}>
                          ☝️ Select a material above to configure generation
                        </div>
                      )}
                    </div>
                    {/* Files Mode — Question Preview Modal */}
                    {fmShowPreview&&(
                      <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.95)',zIndex:10000,display:'flex',alignItems:'center',justifyContent:'center',padding:'12px'}} onClick={function(){setFmShowPreview(false)}}>
                        <div style={{background:'#0d1117',border:'1px solid rgba(0,200,100,0.4)',borderRadius:16,padding:'20px',maxWidth:640,width:'100%',maxHeight:'92vh',overflowY:'auto'}} onClick={function(e){e.stopPropagation()}}>
                          <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
                            <span style={{color:'#00C864',fontWeight:700,fontSize:15}}>📁 Questions Preview ({fmResult.length})</span>
                            <button onClick={function(){setFmShowPreview(false)}} style={{background:'none',border:'none',color:'#666',fontSize:22,cursor:'pointer'}}>✕</button>
                          </div>
                          {fmResult.map(function(q:any,i:number){return(
                            <div key={i} style={{background:'rgba(0,200,100,0.04)',border:'1px solid rgba(0,200,100,0.15)',borderRadius:12,padding:'14px',marginBottom:10}}>
                              <div style={{fontSize:12,color:'#E2E8F0',marginBottom:8,lineHeight:1.6}}><span style={{color:'#00C864',fontWeight:700,marginRight:6}}>Q{i+1}.</span>{q.text||'No text'}</div>
                              {(q.options||[]).map(function(o:string,j:number){const isCorr=q.correctAnswer===('Option '+String.fromCharCode(65+j))||q.correct===j||q.correctAnswer===o;return(
                                <div key={j} style={{padding:'4px 10px',borderRadius:6,marginBottom:3,background:isCorr?'rgba(0,200,100,0.1)':'rgba(255,255,255,0.03)',border:isCorr?'1px solid rgba(0,200,100,0.4)':'1px solid transparent',fontSize:11,color:isCorr?'#00C864':'#CBD5E1'}}>{String.fromCharCode(65+j)}. {o}{isCorr&&' ✓'}</div>
                              )})}
                              <button onClick={function(){setFmResult(function(p:any[]){return p.filter(function(_:any,idx:number){return idx!==i})})}} style={{...bg_,fontSize:9,padding:'2px 7px',marginTop:6,color:'#F87171'}}>🗑️ Remove</button>
                            </div>
                          )})}
                          {fmResult.length===0&&<div style={{color:'#f87171',textAlign:'center',padding:'20px'}}>All questions removed!</div>}
                          <div style={{display:'flex',gap:10,justifyContent:'flex-end',marginTop:12}}>
                            <button onClick={function(){setFmShowPreview(false)}} style={{padding:'10px 20px',borderRadius:8,background:'rgba(255,255,255,0.05)',border:'1px solid rgba(255,255,255,0.15)',color:'#94a3b8',cursor:'pointer',fontSize:13}}>Cancel</button>
                            <button onClick={function(){setFmShowPreview(false);saveFmQs()}} disabled={fmResult.length===0} style={{padding:'10px 24px',borderRadius:8,background:'linear-gradient(135deg,#059669,#10b981)',border:'none',color:'#fff',cursor:'pointer',fontSize:13,fontWeight:700,opacity:fmResult.length===0?0.5:1}}>✅ Save All ({fmResult.length})</button>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                )
              })()}
`;

  code = code.slice(0, startIdx) + NEW_MODALS + code.slice(endIdx);
  console.log('  ✅ PATCH ' + (++patches) + ': Split modals — NCERT & Files independent');
}

fs.writeFileSync(FILE, code, 'utf8');
console.log('');
console.log('═══════════════════════════════════════════');
console.log('✅ All patches applied! Total: ' + patches);
console.log('═══════════════════════════════════════════');
NODEEOF

echo ""
echo "🔍 Verifying build..."
cd $HOME/workspace/frontend
pkill -f "next" 2>/dev/null; sleep 1
npm run build 2>&1 | tail -20
echo ""
echo "═══════════════════════════════════════════"
echo "✅ DONE — Upload script to Replit & run:"
echo "   bash proverank_ai_split_fix.sh"
echo "═══════════════════════════════════════════"
