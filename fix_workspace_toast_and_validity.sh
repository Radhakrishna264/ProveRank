#!/bin/bash
set -e
cd ~/workspace

mkdir -p /tmp/wsfix

cp src/routes/myBatches.js src/routes/myBatches.js.bak_validity_fix
cp frontend/app/dashboard/test-series/page.tsx frontend/app/dashboard/test-series/page.tsx.bak_workspace_toast
cp frontend/app/dashboard/my-batches/page.tsx frontend/app/dashboard/my-batches/page.tsx.bak_workspace_toast

# ══════════════════════════════════════════════════
# 1. BACKEND: myBatches.js — fix expiresAt to use actual endDate before falling back to validity days
# ══════════════════════════════════════════════════
cat > /tmp/wsfix/be1_old.txt << 'EOF'
  const expiresAt=m.expiresAt?new Date(m.expiresAt):new Date(enrolledAt.getTime()+validityDays*86400000);
EOF
cat > /tmp/wsfix/be1_new.txt << 'EOF'
  const expiresAt=m.expiresAt?new Date(m.expiresAt):(b.endDate?new Date(b.endDate):new Date(enrolledAt.getTime()+validityDays*86400000));
EOF

# ══════════════════════════════════════════════════
# 2. FRONTEND: test-series/page.tsx
# ══════════════════════════════════════════════════

# 2a. Batch type — add _kind field
cat > /tmp/wsfix/fe1_old.txt << 'EOF'
  teacherAssigned?: string; seatLimit?: number;
}
EOF
cat > /tmp/wsfix/fe1_new.txt << 'EOF'
  teacherAssigned?: string; seatLimit?: number; _kind?: string;
}
EOF

# 2b. BatchCard state — add wsMsg toast state + workspace label helper
cat > /tmp/wsfix/fe2_old.txt << 'EOF'
  const [loading,setLoading]=useState(false)
  const [hov,setHov]=useState(false)
EOF
cat > /tmp/wsfix/fe2_new.txt << 'EOF'
  const [loading,setLoading]=useState(false)
  const [hov,setHov]=useState(false)
  const [wsMsg,setWsMsg]=useState<string|null>(null)
  const workspaceLabel=b._kind==='series'?'Test Series':'Batch'
  const showWorkspaceComingSoon=()=>{setWsMsg(`📚 ${workspaceLabel} Workspace is coming soon!`);setTimeout(()=>setWsMsg(null),3000)}
EOF

# 2c. Toast render inside BatchCard root div
cat > /tmp/wsfix/fe3_old.txt << 'EOF'
    <div onMouseEnter={()=>setHov(true)} onMouseLeave={()=>setHov(false)} onClick={()=>onPreview&&onPreview(b)}
      style={{ background:'rgba(var(--pr-card-rgb),0.95)',border:`1px solid ${hov?ec+'50':ec+'18'}`,borderRadius:20,overflow:'hidden',backdropFilter:'blur(22px)',position:'relative',transition:'all 0.3s',transform:hov?'translateY(-5px)':'none',boxShadow:hov?`0 20px 50px ${ec}18`:'0 4px 18px rgba(0,10,40,0.4)',cursor:onPreview?'pointer':'default' }}>
      <div style={{ position:'absolute',top:10,left:10,zIndex:5,display:'flex',flexDirection:'column',gap:4 }}>
EOF
cat > /tmp/wsfix/fe3_new.txt << 'EOF'
    <div onMouseEnter={()=>setHov(true)} onMouseLeave={()=>setHov(false)} onClick={()=>onPreview&&onPreview(b)}
      style={{ background:'rgba(var(--pr-card-rgb),0.95)',border:`1px solid ${hov?ec+'50':ec+'18'}`,borderRadius:20,overflow:'hidden',backdropFilter:'blur(22px)',position:'relative',transition:'all 0.3s',transform:hov?'translateY(-5px)':'none',boxShadow:hov?`0 20px 50px ${ec}18`:'0 4px 18px rgba(0,10,40,0.4)',cursor:onPreview?'pointer':'default' }}>
      {wsMsg&&<div style={{ position:'absolute',bottom:8,left:8,right:8,zIndex:30,background:'rgba(10,10,20,0.95)',border:`1px solid ${ec}40`,borderRadius:10,padding:'8px 10px',fontSize:10,color:'#fff',textAlign:'center',fontWeight:600,boxShadow:'0 8px 20px rgba(0,0,0,0.4)' }}>{wsMsg}</div>}
      <div style={{ position:'absolute',top:10,left:10,zIndex:5,display:'flex',flexDirection:'column',gap:4 }}>
EOF

# 2d. Banner overlay CTA label — dynamic Batch/Test Series
cat > /tmp/wsfix/fe4_old.txt << 'EOF'
        ctaLabel={b.isEnrolled?'Go to Batch':b.isFree?(loading?'Enrolling...':'Enroll Free'):b.allowFreeTrial?(loading?'Starting...':'Free Trial'):(`Buy ₹${finalPrice}`)}
EOF
cat > /tmp/wsfix/fe4_new.txt << 'EOF'
        ctaLabel={b.isEnrolled?`Go to ${workspaceLabel}`:b.isFree?(loading?'Enrolling...':'Enroll Free'):b.allowFreeTrial?(loading?'Starting...':'Free Trial'):(`Buy ₹${finalPrice}`)}
EOF

# 2e. Compact "Go to Batch" button
cat > /tmp/wsfix/fe5_old.txt << 'EOF'
            <button onClick={e=>{e.stopPropagation();alert('📚 Batch Workspace is coming soon!')}} style={{ flex:1,padding:'10px',background:`linear-gradient(135deg,${ec}20,${ec}10)`,border:`1px solid ${ec}40`,borderRadius:11,color:ec,fontWeight:700,cursor:'pointer',fontSize:11 }}>Go to Batch →</button>
EOF
cat > /tmp/wsfix/fe5_new.txt << 'EOF'
            <button onClick={e=>{e.stopPropagation();showWorkspaceComingSoon()}} style={{ flex:1,padding:'10px',background:`linear-gradient(135deg,${ec}20,${ec}10)`,border:`1px solid ${ec}40`,borderRadius:11,color:ec,fontWeight:700,cursor:'pointer',fontSize:11 }}>Go to {workspaceLabel} →</button>
EOF

# 2f. Wide "Go to Batch" button
cat > /tmp/wsfix/fe6_old.txt << 'EOF'
            <button onClick={e=>{e.stopPropagation();alert('📚 Batch Workspace is coming soon!')}} style={{ flex:1,padding:'11px',background:`linear-gradient(135deg,${ec}30,${ec}15)`,border:`1px solid ${ec}50`,borderRadius:12,color:ec,fontWeight:700,cursor:'pointer',fontSize:12 }}>Go to Batch →</button>
EOF
cat > /tmp/wsfix/fe6_new.txt << 'EOF'
            <button onClick={e=>{e.stopPropagation();showWorkspaceComingSoon()}} style={{ flex:1,padding:'11px',background:`linear-gradient(135deg,${ec}30,${ec}15)`,border:`1px solid ${ec}50`,borderRadius:12,color:ec,fontWeight:700,cursor:'pointer',fontSize:12 }}>Go to {workspaceLabel} →</button>
EOF

# ══════════════════════════════════════════════════
# 3. FRONTEND: my-batches/page.tsx
# ══════════════════════════════════════════════════

# 3a. BatchMeta type — add _kind field
cat > /tmp/wsfix/mb1_old.txt << 'EOF'
type BatchMeta = {
  _id: string; name: string; examType: string; thumbnail: string;
  enrolledAt: string; expiresAt: string; daysLeft: number;
  testsCompleted: number; totalTests: number; progress: number;
  lastAccessedAt: string; daysSinceAccess: number; streak: number;
  isExpired: boolean; isCompleted: boolean; isWishlisted?: boolean;
  isFree: boolean; rating: number; language: string; difficulty: string;
}
EOF
cat > /tmp/wsfix/mb1_new.txt << 'EOF'
type BatchMeta = {
  _id: string; name: string; examType: string; thumbnail: string;
  enrolledAt: string; expiresAt: string; daysLeft: number;
  testsCompleted: number; totalTests: number; progress: number;
  lastAccessedAt: string; daysSinceAccess: number; streak: number;
  isExpired: boolean; isCompleted: boolean; isWishlisted?: boolean;
  isFree: boolean; rating: number; language: string; difficulty: string;
  _kind?: string;
}
EOF

# 3b. Page state — add wsMsg toast state
cat > /tmp/wsfix/mb2_old.txt << 'EOF'
  const [loading,setLoading]=useState(true)
EOF
cat > /tmp/wsfix/mb2_new.txt << 'EOF'
  const [loading,setLoading]=useState(true)
  const [wsMsg,setWsMsg]=useState<string|null>(null)
EOF

# 3c. "Resume →" button (Continue Where You Left Off)
cat > /tmp/wsfix/mb3_old.txt << 'EOF'
              <button onClick={()=>{accessBatch(lastAccessed._id);alert('📚 Batch Workspace is coming soon!')}}
                style={{background:`linear-gradient(135deg,${ECOLS[lastAccessed.examType]||'#4D9FFF'},${ECOLS[lastAccessed.examType]||'#4D9FFF'}BB)`,border:'none',borderRadius:12,padding:'10px 16px',color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12,flexShrink:0,boxShadow:`0 4px 14px ${ECOLS[lastAccessed.examType]||'#4D9FFF'}30`}}>Resume →</button>
EOF
cat > /tmp/wsfix/mb3_new.txt << 'EOF'
              <button onClick={()=>{accessBatch(lastAccessed._id);setWsMsg(`📚 ${lastAccessed._kind==='series'?'Test Series':'Batch'} Workspace is coming soon!`);setTimeout(()=>setWsMsg(null),3000)}}
                style={{background:`linear-gradient(135deg,${ECOLS[lastAccessed.examType]||'#4D9FFF'},${ECOLS[lastAccessed.examType]||'#4D9FFF'}BB)`,border:'none',borderRadius:12,padding:'10px 16px',color:'#fff',fontWeight:700,cursor:'pointer',fontSize:12,flexShrink:0,boxShadow:`0 4px 14px ${ECOLS[lastAccessed.examType]||'#4D9FFF'}30`}}>Resume →</button>
EOF

# 3d. "▶️ Continue" button (batch card)
cat > /tmp/wsfix/mb4_old.txt << 'EOF'
                        <button onClick={()=>{accessBatch(b._id);alert('📚 Batch Workspace is coming soon!')}}
                          style={{flex:1,padding:'9px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11,boxShadow:`0 4px 12px ${ec}25`}}>▶️ Continue</button>
EOF
cat > /tmp/wsfix/mb4_new.txt << 'EOF'
                        <button onClick={()=>{accessBatch(b._id);setWsMsg(`📚 ${b._kind==='series'?'Test Series':'Batch'} Workspace is coming soon!`);setTimeout(()=>setWsMsg(null),3000)}}
                          style={{flex:1,padding:'9px',background:`linear-gradient(135deg,${ec},${ec}BB)`,border:'none',borderRadius:11,color:'#fff',fontWeight:700,cursor:'pointer',fontSize:11,boxShadow:`0 4px 12px ${ec}25`}}>▶️ Continue</button>
EOF

# 3e. Toast render — end of page
cat > /tmp/wsfix/mb5_old.txt << 'EOF'
      </div>
    </div>
    </StudentShell>
  )
}
EOF
cat > /tmp/wsfix/mb5_new.txt << 'EOF'
      </div>
    </div>
    {wsMsg&&<div style={{position:'fixed',bottom:24,left:'50%',transform:'translateX(-50%)',zIndex:2000,background:'rgba(20,20,35,0.95)',border:'1px solid rgba(77,159,255,0.35)',borderRadius:12,padding:'10px 18px',fontSize:12,color:'#fff',fontWeight:600,boxShadow:'0 10px 30px rgba(0,0,0,0.4)',whiteSpace:'nowrap'}}>{wsMsg}</div>}
    </StudentShell>
  )
}
EOF

# ══════════════════════════════════════════════════
# APPLY ALL PATCHES (safe: skip on 0 or >1 matches, never corrupt)
# ══════════════════════════════════════════════════
cat > /tmp/wsfix/apply.js << 'NODEEOF'
const fs = require('fs');
function readTrim(p) { let c = fs.readFileSync(p, 'utf8'); return c.endsWith('\n') ? c.slice(0, -1) : c; }
function patch(targetPath, oldFile, newFile, label) {
  let content = fs.readFileSync(targetPath, 'utf8');
  const oldStr = readTrim(oldFile), newStr = readTrim(newFile);
  const count = content.split(oldStr).length - 1;
  if (count === 0) { console.log('❌ [' + label + '] Pattern NOT FOUND — skipped. NOTHING was changed.'); return; }
  if (count > 1) { console.log('⚠️  [' + label + '] Pattern found ' + count + ' times (expected 1) — skipped for safety.'); return; }
  content = content.replace(oldStr, newStr);
  fs.writeFileSync(targetPath, content, 'utf8');
  console.log('✅ [' + label + '] patched.');
}

patch('src/routes/myBatches.js', '/tmp/wsfix/be1_old.txt', '/tmp/wsfix/be1_new.txt', 'backend: expiresAt uses real endDate');

patch('frontend/app/dashboard/test-series/page.tsx', '/tmp/wsfix/fe1_old.txt', '/tmp/wsfix/fe1_new.txt', 'test-series: Batch type _kind field');
patch('frontend/app/dashboard/test-series/page.tsx', '/tmp/wsfix/fe2_old.txt', '/tmp/wsfix/fe2_new.txt', 'test-series: BatchCard toast state');
patch('frontend/app/dashboard/test-series/page.tsx', '/tmp/wsfix/fe3_old.txt', '/tmp/wsfix/fe3_new.txt', 'test-series: toast render');
patch('frontend/app/dashboard/test-series/page.tsx', '/tmp/wsfix/fe4_old.txt', '/tmp/wsfix/fe4_new.txt', 'test-series: banner CTA label');
patch('frontend/app/dashboard/test-series/page.tsx', '/tmp/wsfix/fe5_old.txt', '/tmp/wsfix/fe5_new.txt', 'test-series: compact Go to X button');
patch('frontend/app/dashboard/test-series/page.tsx', '/tmp/wsfix/fe6_old.txt', '/tmp/wsfix/fe6_new.txt', 'test-series: wide Go to X button');

patch('frontend/app/dashboard/my-batches/page.tsx', '/tmp/wsfix/mb1_old.txt', '/tmp/wsfix/mb1_new.txt', 'my-batches: BatchMeta _kind field');
patch('frontend/app/dashboard/my-batches/page.tsx', '/tmp/wsfix/mb2_old.txt', '/tmp/wsfix/mb2_new.txt', 'my-batches: toast state');
patch('frontend/app/dashboard/my-batches/page.tsx', '/tmp/wsfix/mb3_old.txt', '/tmp/wsfix/mb3_new.txt', 'my-batches: Resume button');
patch('frontend/app/dashboard/my-batches/page.tsx', '/tmp/wsfix/mb4_old.txt', '/tmp/wsfix/mb4_new.txt', 'my-batches: Continue button');
patch('frontend/app/dashboard/my-batches/page.tsx', '/tmp/wsfix/mb5_old.txt', '/tmp/wsfix/mb5_new.txt', 'my-batches: toast render');
NODEEOF

node /tmp/wsfix/apply.js
