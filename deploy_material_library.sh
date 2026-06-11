#!/bin/bash
# Feature: Material Library for AI Question Generator
# Creates: Material model + routes + registers in backend + updates frontend

WORKSPACE="/home/runner/workspace"
SRC="$WORKSPACE/src"
FRONTEND="$WORKSPACE/frontend/app/admin/x7k2p"

echo "🚀 Deploying Material Library Feature..."
echo ""

# ── 1. Create Material Model ────────────────────────────────────
cat > "$SRC/models/Material.js" << 'MODEL_EOF'
const mongoose = require('mongoose');

const MaterialSchema = new mongoose.Schema({
  title:     { type: String, required: true, trim: true },
  content:   { type: String, required: true },
  fileType:  { type: String, default: 'txt' },
  fileSize:  { type: Number, default: 0 },
  adminId:   { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Material', MaterialSchema);
MODEL_EOF
echo "✅ 1. Material model created"

# ── 2. Create Material Routes ───────────────────────────────────
cat > "$SRC/routes/materialRoutes.js" << 'ROUTE_EOF'
const express  = require('express');
const router   = express.Router();
const jwt      = require('jsonwebtoken');
const Material = require('../models/Material');

function getAdmin(req) {
  try {
    const tok = (req.headers.authorization || '').replace('Bearer ', '');
    if (!tok) return null;
    return jwt.verify(tok, process.env.JWT_SECRET);
  } catch { return null; }
}

// GET all materials (list, no content)
router.get('/', async (req, res) => {
  const user = getAdmin(req);
  if (!user) return res.status(401).json({ message: 'Unauthorized' });
  try {
    const mats = await Material.find({ adminId: user.id || user._id })
      .sort({ createdAt: -1 })
      .select('_id title fileType fileSize createdAt');
    res.json(mats);
  } catch(e) { res.status(500).json({ message: e.message }); }
});

// GET single material with content
router.get('/:id', async (req, res) => {
  const user = getAdmin(req);
  if (!user) return res.status(401).json({ message: 'Unauthorized' });
  try {
    const mat = await Material.findOne({ _id: req.params.id, adminId: user.id || user._id });
    if (!mat) return res.status(404).json({ message: 'Not found' });
    res.json(mat);
  } catch(e) { res.status(500).json({ message: e.message }); }
});

// POST save new material
router.post('/', async (req, res) => {
  const user = getAdmin(req);
  if (!user) return res.status(401).json({ message: 'Unauthorized' });
  try {
    const { title, content, fileType, fileSize } = req.body;
    if (!title || !content) return res.status(400).json({ message: 'title and content required' });
    const mat = await Material.create({
      title: title.trim(), content,
      fileType: fileType || 'txt',
      fileSize: fileSize || 0,
      adminId: user.id || user._id
    });
    res.json({ _id: mat._id, title: mat.title, fileType: mat.fileType, fileSize: mat.fileSize, createdAt: mat.createdAt });
  } catch(e) { res.status(500).json({ message: e.message }); }
});

// DELETE material
router.delete('/:id', async (req, res) => {
  const user = getAdmin(req);
  if (!user) return res.status(401).json({ message: 'Unauthorized' });
  try {
    const result = await Material.findOneAndDelete({ _id: req.params.id, adminId: user.id || user._id });
    if (!result) return res.status(404).json({ message: 'Not found' });
    res.json({ success: true });
  } catch(e) { res.status(500).json({ message: e.message }); }
});

module.exports = router;
ROUTE_EOF
echo "✅ 2. Material routes created"

# ── 3. Register route in index.js ───────────────────────────────
INDEX="$SRC/index.js"
# Check if already registered
if grep -q "materialRoutes" "$INDEX"; then
  echo "⚠️  3. Route already registered in index.js"
else
  # Add after questionFeaturesRoutes line
  node -e "
const fs=require('fs');
let c=fs.readFileSync('$INDEX','utf8');
const OLD=\"const questionFeaturesRoutes = require('./routes/questionFeatures');\";
const NEW=OLD+\"\nconst materialRoutes = require('./routes/materialRoutes');\";
if(c.includes(OLD)){
  c=c.replace(OLD,NEW);
  // Also register the route
  const OLD2=\"app.use('/api/questions', questionFeaturesRoutes);\";
  const NEW2=\"app.use('/api/materials', materialRoutes);\n\"+OLD2;
  c=c.replace(OLD2,NEW2);
  fs.writeFileSync('$INDEX',c);
  console.log('Route registered');
} else { console.log('Pattern not found'); }
"
  echo "✅ 3. Route registered in index.js"
fi

# ── 4. Apply frontend changes ───────────────────────────────────
PAGE="$FRONTEND/page.tsx"
cp "$PAGE" "$PAGE.bak_matlib_$(date +%Y%m%d_%H%M%S)"

cat > /tmp/fix_material_library.js << 'JSEOF'
const fs = require('fs');
const file = process.argv[2];
let code = fs.readFileSync(file, 'utf8');
let changed = 0;

const OLD_ST = "  const [aiGLoading,setAiGLoading]=useState(false)";
const NEW_ST  = "  const [aiGLoading,setAiGLoading]=useState(false)\n"
  + "  const [matMode,setMatMode]=useState('ncert')\n"
  + "  const [matList,setMatList]=useState([])\n"
  + "  const [matLoading,setMatLoading]=useState(false)\n"
  + "  const [matUploading,setMatUploading]=useState(false)\n"
  + "  const [matGenLoading,setMatGenLoading]=useState(false)\n"
  + "  const [matGenCnt,setMatGenCnt]=useState('10')\n"
  + "  const [matGenDiff,setMatGenDiff]=useState('medium')\n"
  + "  const [selMatId,setSelMatId]=useState('')";
if(code.includes(OLD_ST)){code=code.replace(OLD_ST,NEW_ST);console.log('✅ States');changed++;}
else console.log('❌ States');

const OLD_FN = "  const saveAiQs=async()=>{";
const NEW_FN  = "  const fetchMats=async()=>{\n"
  + "    setMatLoading(true)\n"
  + "    try{const r=await fetch(API+'/api/materials',{headers:{Authorization:'Bearer '+token}});if(r.ok)setMatList(await r.json())}catch(e){}\n"
  + "    setMatLoading(false)\n"
  + "  }\n"
  + "  const saveMat=async(title,content,fileType,fileSize)=>{\n"
  + "    try{\n"
  + "      const r=await fetch(API+'/api/materials',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({title,content,fileType:fileType||'txt',fileSize:fileSize||0})})\n"
  + "      if(r.ok){await fetchMats();T('📚 Material saved!')}\n"
  + "      else T('Save failed','e')\n"
  + "    }catch(e){T(e.message||'Error','e')}\n"
  + "  }\n"
  + "  const deleteMat=async(id)=>{\n"
  + "    if(!confirm('Delete this material?'))return\n"
  + "    const r=await fetch(API+'/api/materials/'+id,{method:'DELETE',headers:{Authorization:'Bearer '+token}})\n"
  + "    if(r.ok){setMatList(function(p){return p.filter(function(m){return m._id!==id})});T('Deleted')}\n"
  + "  }\n"
  + "  const generateFromMat=async(matId,cnt,diff)=>{\n"
  + "    setMatGenLoading(true)\n"
  + "    try{\n"
  + "      const mr=await fetch(API+'/api/materials/'+matId,{headers:{Authorization:'Bearer '+token}})\n"
  + "      const mat=await mr.json()\n"
  + "      const prompt='You are a NEET question generator. Based on the following educational content, generate '+cnt+' high-quality NEET-style multiple choice questions.\\n\\nEDUCATIONAL CONTENT:\\n'+mat.content.substring(0,8000)+'\\n\\nINSTRUCTIONS:\\n- Generate exactly '+cnt+' questions\\n- Difficulty: '+diff+'\\n- Each question has exactly 4 options (A,B,C,D)\\n- Return ONLY valid JSON array:\\n[{\"text\":\"question\",\"options\":[\"A\",\"B\",\"C\",\"D\"],\"correctAnswer\":\"A\",\"explanation\":\"reason\",\"difficulty\":\"'+diff+'\",\"type\":\"SCQ\",\"chapter\":\"'+mat.title+'\"}]'\n"
  + "      const res=await fetch('https://api.anthropic.com/v1/messages',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({model:'claude-sonnet-4-20250514',max_tokens:4000,messages:[{role:'user',content:prompt}]})})\n"
  + "      const data=await res.json()\n"
  + "      const txt=data.content?.[0]?.text||''\n"
  + "      const m=txt.match(/\\[[\\s\\S]*\\]/)\n"
  + "      if(m){const qs=JSON.parse(m[0]);setAiGResult(qs);setAiGO(false);setShowAiPreview(true);T('✅ '+qs.length+' Qs from material!')}\n"
  + "      else T('Could not parse questions','e')\n"
  + "    }catch(e){T(e.message||'Failed','e')}\n"
  + "    setMatGenLoading(false)\n"
  + "  }\n"
  + "  const handleMatFile=async(file,customTitle)=>{\n"
  + "    if(!file)return\n"
  + "    setMatUploading(true)\n"
  + "    try{\n"
  + "      const ext=(file.name.split('.').pop()||'').toLowerCase()\n"
  + "      let content=''\n"
  + "      if(['txt','csv','md','json','html'].includes(ext)){\n"
  + "        content=await new Promise(function(res,rej){const rd=new FileReader();rd.onload=function(e){res(e.target.result)};rd.onerror=rej;rd.readAsText(file)})\n"
  + "      }else{\n"
  + "        const b64=await new Promise(function(res,rej){const rd=new FileReader();rd.onload=function(e){res(e.target.result.split(',')[1])};rd.onerror=rej;rd.readAsDataURL(file)})\n"
  + "        const mt=ext==='pdf'?'application/pdf':'application/octet-stream'\n"
  + "        const resp=await fetch('https://api.anthropic.com/v1/messages',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({model:'claude-sonnet-4-20250514',max_tokens:4000,messages:[{role:'user',content:[{type:'document',source:{type:'base64',media_type:mt,data:b64}},{type:'text',text:'Extract ALL educational content from this document as clean readable text. Include every concept, definition, formula, theorem, and important point. Do not summarize.'}]}]})})\n"
  + "        const d=await resp.json()\n"
  + "        content=d.content?.[0]?.text||''\n"
  + "      }\n"
  + "      if(content.trim())await saveMat(customTitle||file.name,content,ext,file.size)\n"
  + "      else T('No content extracted','e')\n"
  + "    }catch(e){T(e.message||'Upload failed','e')}\n"
  + "    setMatUploading(false)\n"
  + "  }\n"
  + "  const saveAiQs=async()=>{";
if(code.includes(OLD_FN)){code=code.replace(OLD_FN,NEW_FN);console.log('✅ Functions');changed++;}
else console.log('❌ Functions');

const OLD_HEADER = "                          <div style={{fontSize:14,fontWeight:800,color:'#E2E8F0'}}>🤖 AI Question Generator</div>\n"
  + "                          <div style={{fontSize:10,color:'#64748B',marginTop:2}}>NCERT Based · Auto answers & explanations</div>\n"
  + "                        </div>\n"
  + "                        <button onClick={function(){setAiGO(false);setAiGResult([])}} style={{...bg_,padding:'3px 8px',fontSize:11}}>✕</button>\n"
  + "                      </div>\n"
  + "                      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:12}}>";
const NEW_HEADER = "                          <div style={{fontSize:14,fontWeight:800,color:'#E2E8F0'}}>🤖 AI Question Generator</div>\n"
  + "                          <div style={{fontSize:10,color:'#64748B',marginTop:2}}>{matMode==='ncert'?'NCERT Based · Auto answers & explanations':'📁 Generate from your uploaded files & notes'}</div>\n"
  + "                        </div>\n"
  + "                        <button onClick={function(){setAiGO(false);setAiGResult([])}} style={{...bg_,padding:'3px 8px',fontSize:11}}>✕</button>\n"
  + "                      </div>\n"
  + "                      <div style={{display:'flex',gap:6,marginBottom:14,background:'rgba(255,255,255,0.04)',borderRadius:10,padding:3}}>\n"
  + "                        {[{k:'ncert',l:'🤖 NCERT Mode'},{k:'files',l:'📁 From Files'}].map(function(m){return(\n"
  + "                          <button key={m.k} onClick={function(){setMatMode(m.k);if(m.k==='files')fetchMats()}} style={{flex:1,padding:'6px 8px',borderRadius:8,border:'none',background:matMode===m.k?'rgba(77,159,255,0.25)':'transparent',color:matMode===m.k?'#60A5FA':'#64748B',fontSize:10,fontWeight:matMode===m.k?700:400,cursor:'pointer'}}>{m.l}</button>\n"
  + "                        )})}\n"
  + "                      </div>\n"
  + "                      {matMode==='files'&&(function(){\n"
  + "                        return(<div>\n"
  + "                          <div style={{background:'rgba(77,159,255,0.07)',border:'1px dashed rgba(77,159,255,0.3)',borderRadius:12,padding:'12px 14px',marginBottom:12}}>\n"
  + "                            <div style={{fontSize:11,fontWeight:700,color:'#60A5FA',marginBottom:6}}>📤 Upload New Material</div>\n"
  + "                            <div style={{fontSize:10,color:'#64748B',marginBottom:8}}>PDF, DOCX, TXT, CSV, MD — AI extracts content automatically</div>\n"
  + "                            <input id='mat-title-inp' defaultValue='' placeholder='📝 Title (e.g. Chapter 5 Notes)' style={{...inp,width:'100%',marginBottom:6,fontSize:11}} onChange={function(e){if(typeof window!=='undefined')window.__matTitle=e.target.value}}/>\n"
  + "                            <div style={{display:'flex',gap:6}}>\n"
  + "                              <label style={{flex:1,padding:'7px 12px',borderRadius:8,border:'1px solid rgba(77,159,255,0.3)',background:'rgba(77,159,255,0.08)',color:'#60A5FA',fontSize:10,cursor:'pointer',textAlign:'center',fontWeight:600}}>\n"
  + "                                {matUploading?'⟳ Extracting…':'📁 Choose File'}\n"
  + "                                <input type='file' accept='.pdf,.docx,.txt,.csv,.md,.html,.json' style={{display:'none'}} disabled={matUploading} onChange={function(e){const f=e.target.files?.[0];if(f)handleMatFile(f,typeof window!=='undefined'?window.__matTitle||f.name:f.name);e.target.value=''}}/>\n"
  + "                              </label>\n"
  + "                              <button onClick={function(){const t=prompt('📋 Paste your notes/content:');if(t&&t.trim()){const ttl=typeof window!=='undefined'?window.__matTitle||'Pasted Notes':'Pasted Notes';saveMat(ttl,t,'txt',t.length)}}} style={{...bg_,fontSize:10,padding:'7px 10px',flexShrink:0}}>📋 Paste Text</button>\n"
  + "                            </div>\n"
  + "                          </div>\n"
  + "                          <div style={{marginBottom:10}}>\n"
  + "                            <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:8}}>\n"
  + "                              <div style={{fontSize:11,fontWeight:700,color:'#E2E8F0'}}>📚 Saved Materials ({matList.length})</div>\n"
  + "                              <button onClick={fetchMats} style={{...bg_,fontSize:9,padding:'2px 7px'}}>{matLoading?'⟳':'↻ Refresh'}</button>\n"
  + "                            </div>\n"
  + "                            {matLoading&&<div style={{textAlign:'center',padding:'16px',color:'#475569',fontSize:11}}>⟳ Loading…</div>}\n"
  + "                            {!matLoading&&matList.length===0&&<div style={{textAlign:'center',padding:'20px',color:'#475569',fontSize:11}}>No materials yet. Upload a file above!</div>}\n"
  + "                            {matList.map(function(m){\n"
  + "                              const isS=selMatId===m._id\n"
  + "                              const icons={pdf:'📄',docx:'📝',txt:'📃',csv:'📊',md:'📋'}\n"
  + "                              return(<div key={m._id} onClick={function(){setSelMatId(isS?'':m._id)}} style={{padding:'9px 12px',borderRadius:10,border:'1.5px solid '+(isS?'rgba(77,159,255,0.5)':'rgba(255,255,255,0.07)'),background:isS?'rgba(77,159,255,0.1)':'rgba(255,255,255,0.02)',cursor:'pointer',marginBottom:6}}>\n"
  + "                                <div style={{display:'flex',justifyContent:'space-between',alignItems:'center'}}>\n"
  + "                                  <div style={{display:'flex',alignItems:'center',gap:7,flex:1,minWidth:0}}>\n"
  + "                                    <span style={{fontSize:16,flexShrink:0}}>{icons[m.fileType]||'📄'}</span>\n"
  + "                                    <div style={{flex:1,minWidth:0}}>\n"
  + "                                      <div style={{fontSize:11,fontWeight:600,color:isS?'#60A5FA':'#E2E8F0',overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{m.title}</div>\n"
  + "                                      <div style={{fontSize:9,color:'#475569',marginTop:1}}>{m.fileType.toUpperCase()} · {m.fileSize>1024?(Math.round(m.fileSize/1024)+'KB'):(m.fileSize+'B')} · {new Date(m.createdAt).toLocaleDateString()}</div>\n"
  + "                                    </div>\n"
  + "                                  </div>\n"
  + "                                  <button onClick={function(e){e.stopPropagation();deleteMat(m._id)}} style={{...bg_,fontSize:10,padding:'2px 6px',color:'#F87171',flexShrink:0,marginLeft:6}}>🗑️</button>\n"
  + "                                </div>\n"
  + "                                {isS&&<div style={{fontSize:9,color:'#60A5FA',marginTop:4}}>✓ Selected — configure generation below</div>}\n"
  + "                              </div>)\n"
  + "                            })}\n"
  + "                          </div>\n"
  + "                          {selMatId&&(<div style={{background:'rgba(0,200,100,0.06)',border:'1px solid rgba(0,200,100,0.2)',borderRadius:10,padding:'12px 14px'}}>\n"
  + "                            <div style={{fontSize:11,fontWeight:700,color:'#00C864',marginBottom:8}}>⚡ Generate from Selected Material</div>\n"
  + "                            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8,marginBottom:10}}>\n"
  + "                              <div><label style={lbl}>🔢 Count (1-30)</label><input type='number' min='1' max='30' defaultValue='10' onChange={function(e){setMatGenCnt(e.target.value)}} style={{...inp,width:'100%'}}/></div>\n"
  + "                              <div><label style={lbl}>🎯 Difficulty</label><select value={matGenDiff} onChange={function(e){setMatGenDiff(e.target.value)}} style={{...inp,width:'100%'}}><option value='easy'>🟢 Easy</option><option value='medium'>🟡 Medium</option><option value='hard'>🔴 Hard</option></select></div>\n"
  + "                            </div>\n"
  + "                            <button onClick={function(){generateFromMat(selMatId,parseInt(matGenCnt)||10,matGenDiff)}} disabled={matGenLoading} style={{...bp,width:'100%',opacity:matGenLoading?0.7:1}}>\n"
  + "                              {matGenLoading?'⟳ AI generating questions from material…':'🚀 Generate '+matGenCnt+' Questions'}\n"
  + "                            </button>\n"
  + "                          </div>)}\n"
  + "                        </div>)\n"
  + "                      })()}\n"
  + "                      {matMode==='ncert'&&<div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:12}}>";
if(code.includes(OLD_HEADER)){code=code.replace(OLD_HEADER,NEW_HEADER);console.log('✅ UI');changed++;}
else console.log('❌ UI');

const OLD_GENBTN = "                        {aiGLoading?'⟳ Generating NCERT Questions…':'🤖 Generate Questions'}\n"
  + "                      </button>";
const NEW_GENBTN = "                        {aiGLoading?'⟳ Generating NCERT Questions…':'🤖 Generate Questions'}\n"
  + "                      </button>\n"
  + "                      </div>}";
if(code.includes(OLD_GENBTN)){code=code.replace(OLD_GENBTN,NEW_GENBTN);console.log('✅ NCERT close');changed++;}
else console.log('❌ NCERT close');

fs.writeFileSync(file,code);
console.log('Frontend changes: '+changed+'/4');
JSEOF

node /tmp/fix_material_library.js "$PAGE"

echo ""
echo "--- Verify ---"
grep -c "matMode\|fetchMats\|materialRoutes\|Material.js" "$SRC/index.js" && echo "✅ Backend registered"
grep -c "matMode\|fetchMats\|handleMatFile" "$PAGE" && echo "✅ Frontend updated"
echo ""
echo "✅ Deploy complete! Now run: cd /home/runner/workspace && git add -A && git commit -m 'feat: Material Library for AI generation' && git push"
