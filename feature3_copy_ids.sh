#!/bin/bash
# ProveRank — Feature 3: Universal Copy Button for all IDs in Admin/Student panels
# Run: bash feature3_copy_ids.sh

echo "=== FEATURE 3: Copy Button for all IDs ==="

node << 'EOF'
const fs=require('fs'),path=require('path');
const WS=process.env.HOME+'/workspace';
const FE=WS+'/frontend';

// ── Universal CopyBtn inline (no import needed, self-contained) ──
// We'll inject a CopyBtn function where needed, or patch key files

const COPY_FN=`
const CopyBtn=({text,label=''}:{text:string,label?:string})=>{
  const[cp,setCp]=useState(false)
  return <button onClick={e=>{e.stopPropagation();navigator.clipboard.writeText(text).then(()=>{setCp(true);setTimeout(()=>setCp(false),2000)}).catch(()=>{const el=document.createElement('textarea');el.value=text;document.body.appendChild(el);el.select();document.execCommand('copy');document.body.removeChild(el);setCp(true);setTimeout(()=>setCp(false),2000)})}} title={'Copy: '+text} style={{background:cp?'rgba(0,196,140,0.15)':'rgba(77,159,255,0.08)',color:cp?'#00C48C':'#6B8FAF',border:'1px solid '+(cp?'rgba(0,196,140,0.3)':'rgba(77,159,255,0.2)'),borderRadius:6,cursor:'pointer',display:'inline-flex',alignItems:'center',gap:3,fontSize:10,padding:'2px 7px',transition:'all 0.2s',flexShrink:0,fontFamily:'monospace',fontWeight:600}}>{cp?'✅ Copied':'📋 '+label}</button>
}
`;

// Find admin page (main large file)
const adminPage=FE+'/app/admin/x7k2p/page.tsx';
if(fs.existsSync(adminPage)){
  let c=fs.readFileSync(adminPage,'utf8');
  
  // Add CopyBtn function before BatchDetailOverlay
  if(!c.includes('const CopyBtn=')){
    c=c.replace('// ═══════════════════════════════════════════════════\n// BATCH_IMPROVEMENTS_V2',COPY_FN+'\n// ═══════════════════════════════════════════════════\n// BATCH_IMPROVEMENTS_V2');
    console.log('CopyBtn added to admin page');
  }
  
  // ── Patch Batch ID display to add copy button ──
  // In batch cards
  c=c.replace(
    '<div style={{fontSize:9,color:\'rgba(148,163,184,0.4)\',marginBottom:8,fontFamily:\'monospace\',letterSpacing:0.5}}>ID: {b._id}</div>',
    '<div style={{display:\'flex\',alignItems:\'center\',gap:6,marginBottom:8}}><div style={{fontSize:9,color:\'rgba(148,163,184,0.4)\',fontFamily:\'monospace\',letterSpacing:0.5}}>ID: {b._id?.slice(-8)}</div><CopyBtn text={b._id} label="ID"/></div>'
  );
  
  // In BatchDetailOverlay header - batch ID
  c=c.replace(
    '<div style={{fontSize:10,color:DIM,marginTop:1,overflow:\'hidden\',textOverflow:\'ellipsis\',whiteSpace:\'nowrap\'}}>ID: {batch._id} · {batch.createdAt?new Date(batch.createdAt).toLocaleDateString():\'-\'}</div>',
    '<div style={{display:\'flex\',alignItems:\'center\',gap:6,marginTop:1,flexWrap:\'wrap\'}}><span style={{fontSize:10,color:DIM,fontFamily:\'monospace\'}}>ID: {batch._id?.slice(-12)}...</span><CopyBtn text={batch._id} label="Batch ID"/><span style={{fontSize:10,color:DIM}}>· {batch.createdAt?new Date(batch.createdAt).toLocaleDateString():\'-\'}</span></div>'
  );
  
  // In batch info settings tab
  c=c.replace(
    "(['Batch ID',batch._id],",
    "(['Batch ID',batch._id?.slice(-8)+'... '],// ID display"
  );
  
  // ── Patch Student list in BatchDetailOverlay to show studentId with copy ──
  // In students table - add Student ID column
  c=c.replace(
    "{['#','Name','Email','Joined','Status','Action'].map(h=><th key={h}",
    "{['#','Student ID','Name','Email','Joined','Status','Action'].map(h=><th key={h}"
  );
  c=c.replace(
    "<td style={{padding:'9px 8px',color:DIM}}>{i+1}</td>\n                      <td style={{padding:'9px 8px'}}>",
    `<td style={{padding:'9px 8px',color:DIM}}>{i+1}</td>
                      <td style={{padding:'9px 8px'}}><div style={{display:'flex',alignItems:'center',gap:4}}><span style={{fontSize:11,color:'#4D9FFF',fontFamily:'monospace',fontWeight:700}}>{s.studentId||'—'}</span>{s.studentId&&<CopyBtn text={s.studentId}/>}</div></td>
                      <td style={{padding:'9px 8px'}}>` 
  );
  
  // Also add student ID in recent students list (overview tab)
  c=c.replace(
    '<div style={{fontSize:10,color:DIM}}>{s.email}</div>\n                </div>\n                <div style={{fontSize:10,color:DIM,flexShrink:0}}>{s.createdAt?new Date(s.createdAt).toLocaleDateString():\'-\'}</div>',
    '<div style={{display:\'flex\',alignItems:\'center\',gap:4}}><span style={{fontSize:10,color:DIM}}>{s.email}</span></div>\n                  {s.studentId&&<div style={{display:\'flex\',alignItems:\'center\',gap:3}}><span style={{fontSize:9,color:\'#4D9FFF\',fontFamily:\'monospace\'}}>{s.studentId}</span><CopyBtn text={s.studentId}/></div>}\n                </div>\n                <div style={{fontSize:10,color:DIM,flexShrink:0}}>{s.createdAt?new Date(s.createdAt).toLocaleDateString():\'-\'}</div>'
  );

  fs.writeFileSync(adminPage,c);
  console.log('Admin page patched with copy buttons. Size:',fs.statSync(adminPage).size);
}

// ── Find Students section in admin panel ──
// Look for students page/section in admin
function findAdminStudentFiles(dir,depth=0){
  if(depth>6||!fs.existsSync(dir))return[];
  const results=[];
  for(const item of fs.readdirSync(dir)){
    if(item==='node_modules'||item.startsWith('.'))continue;
    const fp=path.join(dir,item);
    const stat=fs.statSync(fp);
    if(stat.isDirectory()&&(item.includes('student')||item.includes('admin'))){
      results.push(...findAdminStudentFiles(fp,depth+1));
    } else if(/\.(jsx?|tsx?)$/.test(item)){
      try{
        const c=fs.readFileSync(fp,'utf8');
        if(c.includes('studentId')||c.includes('student_id')||(c.includes('Student ID')&&c.includes('table'))){
          results.push(fp);
        }
      }catch(e){}
    }
  }
  return results;
}

const studentFiles=findAdminStudentFiles(FE);
console.log('Student admin files with ID:',studentFiles);

// ── Patch admin students section (separate page if exists) ──
// Check for students page under admin
const studentsPage=FE+'/app/admin/x7k2p/students/page.tsx';
if(fs.existsSync(studentsPage)){
  let c=fs.readFileSync(studentsPage,'utf8');
  if(!c.includes('CopyBtn')&&!c.includes('studentId')){
    // Add CopyBtn inline function
    c=c.replace("'use client'","'use client'\n// Feature 3: Copy buttons for IDs");
    // Add studentId column and copy button
    console.log('Students page found, patching...');
    // Generic patch: add studentId where email is shown
    c=c.replace('{s.email}','{s.studentId&&<span style={{fontSize:11,color:\'#4D9FFF\',fontFamily:\'monospace\',fontWeight:700,marginRight:6}}>{s.studentId}</span>}{s.email}');
    fs.writeFileSync(studentsPage,c);
  }
}

// ── Patch student profile page for self-view of ID ──
function findFiles(dir,pred,depth=0){
  if(depth>7||!fs.existsSync(dir))return[];
  const results=[];
  for(const item of fs.readdirSync(dir)){
    if(item==='node_modules'||item.startsWith('.'))continue;
    const fp=path.join(dir,item);
    try{
      const stat=fs.statSync(fp);
      if(stat.isDirectory())results.push(...findFiles(fp,pred,depth+1));
      else if(pred(fp,item))results.push(fp);
    }catch(e){}
  }
  return results;
}

const profileFiles=findFiles(FE,(fp,name)=>/\.(tsx|jsx)$/.test(name)&&(name.includes('profile')||fp.includes('/profile')));
console.log('Profile files:',profileFiles);

for(const pf of profileFiles.slice(0,3)){
  let c=fs.readFileSync(pf,'utf8');
  if(c.includes('studentId'))continue;
  if(c.length<1000)continue;
  
  // Add studentId display near where user info is shown
  // Find email display and add ID before it
  const emailDisplays=['{user.email}','{user?.email}','{userData?.email}','{profile?.email}'];
  for(const ed of emailDisplays){
    if(c.includes(ed)){
      c=c.replace(ed,`<div style={{marginTop:6,marginBottom:4,display:'flex',alignItems:'center',gap:8,flexWrap:'wrap'}}>
          <span style={{fontSize:11,fontWeight:600,color:'#6B8FAF'}}>Student ID:</span>
          <span style={{fontSize:13,fontWeight:800,color:'#4D9FFF',fontFamily:'monospace',letterSpacing:1.5}}>{user?.studentId||userData?.studentId||'—'}</span>
          <button onClick={()=>{navigator.clipboard.writeText(user?.studentId||userData?.studentId||'');}} style={{fontSize:10,background:'rgba(77,159,255,0.1)',color:'#4D9FFF',border:'1px solid rgba(77,159,255,0.3)',borderRadius:5,padding:'2px 7px',cursor:'pointer'}}>📋 Copy</button>
        </div>
        `+ed);
      console.log('Profile patched for studentId display:',pf);
      fs.writeFileSync(pf,c);
      break;
    }
  }
}

// ── Patch student dashboard to show ID in header/card ──
const studentDashFiles=findFiles(FE,(fp,name)=>/\.(tsx|jsx)$/.test(name)&&fp.includes('/student')&&!fp.includes('admin')&&!fp.includes('node_modules'));
console.log('Student dash files:',studentDashFiles.slice(0,3));

for(const sf of studentDashFiles.slice(0,3)){
  let c=fs.readFileSync(sf,'utf8');
  if(c.includes('studentId')||c.length<3000)continue;
  
  // Look for where student name is displayed in header
  const namePatterns=['{user?.name}','{student?.name}','{userData?.name}'];
  for(const np of namePatterns){
    if(c.includes(np)){
      c=c.replace(np,np+`
        {user?.studentId&&<div style={{fontSize:11,color:'#4D9FFF',fontFamily:'monospace',fontWeight:700,letterSpacing:1}}>{user.studentId}<button onClick={()=>navigator.clipboard.writeText(user.studentId)} style={{marginLeft:4,fontSize:10,background:'none',border:'none',cursor:'pointer',color:'#6B8FAF'}}>📋</button></div>}`);
      console.log('Dashboard patched for studentId:',sf);
      fs.writeFileSync(sf,c);
      break;
    }
  }
}

console.log('\n✅ Feature 3 complete!');
EOF

cd ~/workspace && git add . && git commit -m "feat: Universal CopyBtn for all IDs - studentId, batchId everywhere" && git push
echo ""
echo "=== ALL 3 FEATURES DONE ==="
echo "Feature 1: PRxxABCD Student ID generation on registration"
echo "Feature 2: Welcome Banner with Student ID + CopyBtn component"  
echo "Feature 3: Copy buttons for all IDs in admin/student panels"
echo ""
echo "IMPORTANT: Run migration for existing students:"
echo "  node ~/workspace/migrate_student_ids.js"
