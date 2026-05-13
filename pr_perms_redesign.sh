#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# ProveRank — Admin Permissions Ultra Premium Redesign + Real API
# Fix 1: perms useState → 26 comprehensive permissions
# Fix 2: savePerms → PUT /api/admin/manage/permissions/:id (real API)
# Fix 3: JSX → Premium redesign with admin selector + grouped perms
# ═══════════════════════════════════════════════════════════════
set -e
export FILE="$HOME/workspace/frontend/app/admin/x7k2p/page.tsx"
export JSXFILE="/tmp/pr_perms_v1.jsx"

if [ ! -f "$FILE" ]; then echo "❌ File not found: $FILE"; exit 1; fi
cp "$FILE" "${FILE}.bak5.$(date +%s)"
echo "✅ Backup created"

# ── Write new JSX to temp file ──────────────────────────────────
cat > "$JSXFILE" << 'JSXEOF'
          {/* ══ PERMISSIONS ══ */}
          {tab==='permissions'&&(
            <div>

              {/* ─── PREMIUM HEADER ─── */}
              <div style={{background:'linear-gradient(135deg,rgba(4,30,60,0.97),rgba(0,18,42,0.99))',border:'1px solid rgba(77,159,255,0.22)',borderRadius:20,padding:'22px 22px 18px',marginBottom:20,position:'relative',overflow:'hidden'}}>
                <div style={{position:'absolute',top:-50,right:-50,width:200,height:200,borderRadius:'50%',background:'radial-gradient(circle,rgba(77,159,255,0.09),transparent 70%)',pointerEvents:'none'}}></div>
                <div style={{display:'flex',alignItems:'center',gap:16,position:'relative',zIndex:1}}>
                  <div style={{width:54,height:54,background:'linear-gradient(135deg,rgba(77,159,255,0.2),rgba(0,212,255,0.1))',border:'1.5px solid rgba(77,159,255,0.4)',borderRadius:16,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0,boxShadow:'0 6px 24px rgba(77,159,255,0.18)'}}>
                    <svg width="26" height="26" viewBox="0 0 24 24" fill="none"><path d="M12 2L3 7v5c0 5.25 3.75 10.15 9 11.35C17.25 22.15 21 17.25 21 12V7L12 2z" fill="rgba(77,159,255,0.15)" stroke="#4D9FFF" strokeWidth="1.6" strokeLinejoin="round"/><path d="M9 12l2 2 4-4" stroke="#4D9FFF" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/></svg>
                  </div>
                  <div>
                    <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1.3}}>Admin Permissions</div>
                    <div style={{display:'flex',alignItems:'center',gap:8,marginTop:5,flexWrap:'wrap'}}>
                      <span style={{background:'rgba(77,159,255,0.15)',color:'#4D9FFF',borderRadius:20,padding:'2px 10px',fontSize:10,fontWeight:700,border:'1px solid rgba(77,159,255,0.3)'}}>S72</span>
                      <span style={{fontSize:11,color:'#6B8FAF'}}>26 granular toggles · 6 categories · Real API · Per-admin control</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* ─── ADMIN SELECTOR ─── */}
              <div style={{background:'rgba(0,20,44,0.94)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:16,marginBottom:20,overflow:'hidden'}}>
                <div style={{background:'rgba(77,159,255,0.07)',borderBottom:'1px solid rgba(77,159,255,0.12)',padding:'13px 18px',display:'flex',alignItems:'center',gap:10,flexWrap:'wrap'}}>
                  <div style={{width:32,height:32,background:'rgba(77,159,255,0.12)',borderRadius:9,display:'flex',alignItems:'center',justifyContent:'center',fontSize:16,border:'1px solid rgba(77,159,255,0.22)',flexShrink:0}}>👤</div>
                  <div style={{fontWeight:700,fontSize:13,color:'#E8F4FF',flex:1}}>Select Admin to Configure</div>
                  {selectedPermAdmin&&<span style={{fontSize:10,background:'rgba(0,196,140,0.12)',color:'#00C48C',borderRadius:20,padding:'2px 10px',border:'1px solid rgba(0,196,140,0.22)',fontWeight:600}}>✅ Editing: {selectedPermAdmin.name}</span>}
                </div>
                <div style={{padding:'14px 18px'}}>
                  {(adminUsers||[]).length===0
                    ?<div style={{textAlign:'center',padding:'20px 0',color:'#445566',fontSize:12}}>No active admins found. Create an admin first from the Admins tab.</div>
                    :<div style={{display:'flex',flexDirection:'column',gap:8}}>
                      {(adminUsers||[]).map(au=>(
                        <div key={au._id} onClick={async()=>{
                          setSelectedPermAdmin(au);
                          try{
                            const r=await fetch(API+'/api/admin/manage/profile/'+au._id,{headers:{Authorization:'Bearer '+token}});
                            const d=await r.json();
                            if(d.success&&d.admin){
                              const loaded=d.admin.permissions||{};
                              setPerms(prev=>Object.fromEntries(Object.keys(prev).map(k=>[k,loaded[k]===true])));
                              T('Permissions loaded for '+au.name+' — toggle as needed');
                            }else{
                              setPerms(prev=>Object.fromEntries(Object.keys(prev).map(k=>[k,false])));
                              T('No permissions set yet for '+au.name,'e');
                            }
                          }catch(e){T('Failed to load permissions — check connection','e');}
                        }} style={{background:selectedPermAdmin&&selectedPermAdmin._id===au._id?'rgba(77,159,255,0.1)':'rgba(0,10,28,0.5)',border:'1px solid '+(selectedPermAdmin&&selectedPermAdmin._id===au._id?'rgba(77,159,255,0.35)':'rgba(77,159,255,0.09)'),borderRadius:12,padding:'12px 14px',cursor:'pointer',display:'flex',alignItems:'center',gap:12,transition:'all 0.2s'}}>
                          <div style={{width:38,height:38,background:'rgba(77,159,255,0.15)',border:'1.5px solid rgba(77,159,255,0.28)',borderRadius:11,display:'flex',alignItems:'center',justifyContent:'center',fontSize:16,fontWeight:900,color:'#4D9FFF',flexShrink:0}}>{(au.name||'A')[0].toUpperCase()}</div>
                          <div style={{flex:1,minWidth:0}}>
                            <div style={{fontWeight:600,fontSize:13,color:'#E8F4FF'}}>{au.name}</div>
                            <div style={{fontSize:11,color:'#6B8FAF',marginTop:2}}>{au.email}</div>
                          </div>
                          <div style={{display:'flex',alignItems:'center',gap:6,flexShrink:0}}>
                            <span style={{fontSize:10,background:'rgba(77,159,255,0.12)',color:'#4D9FFF',borderRadius:20,padding:'2px 8px',fontWeight:600}}>{(au.role||'admin').toUpperCase()}</span>
                            {selectedPermAdmin&&selectedPermAdmin._id===au._id&&<span style={{fontSize:14}}>✅</span>}
                          </div>
                        </div>
                      ))}
                    </div>
                  }
                </div>
              </div>

              {/* ─── PERMISSIONS GRID ─── */}
              {selectedPermAdmin
                ?<div style={{display:'flex',flexDirection:'column',gap:14,marginBottom:80}}>
                  {[
                    {g:'📝 Exam Management',c:'#4D9FFF',bg:'rgba(77,159,255,0.06)',brd:'rgba(77,159,255,0.16)',p:[
                      {k:'create_exam',l:'Create Exam',d:'Create and publish new exams'},
                      {k:'edit_exam',l:'Edit Exam',d:'Modify existing exam settings and questions'},
                      {k:'delete_exam',l:'Delete Exam',d:'Permanently delete exams from platform'},
                      {k:'clone_exam',l:'Clone / Duplicate Exam',d:'Copy existing exams as template (S39)'},
                      {k:'bulk_exam',l:'Bulk Exam Creator',d:'Create multiple exams at once (N8)'},
                    ]},
                    {g:'📚 Question Bank',c:'#A080FF',bg:'rgba(160,80,255,0.06)',brd:'rgba(160,80,255,0.16)',p:[
                      {k:'manage_questions',l:'Manage Questions',d:'Add, edit, delete questions from bank'},
                      {k:'bulk_upload',l:'Bulk Upload Questions',d:'Upload via Excel / PDF / Copy-paste (Phase 2)'},
                      {k:'ai_questions',l:'AI Question Generator',d:'Generate questions using AI (S101)'},
                      {k:'pyq_access',l:'PYQ Bank Access',d:'Access Previous Year Questions bank (S104)'},
                    ]},
                    {g:'👥 Student Management',c:'#00C48C',bg:'rgba(0,196,140,0.06)',brd:'rgba(0,196,140,0.16)',p:[
                      {k:'view_students',l:'View Students',d:'Access student list, profiles and details'},
                      {k:'ban_student',l:'Ban / Unban Student',d:'Restrict or restore student account access (M1)'},
                      {k:'impersonate',l:'Impersonate Student',d:'Login as any student for debugging (M4)'},
                      {k:'export_data',l:'Export Data (CSV)',d:'Download student and results data reports (S67)'},
                      {k:'batch_transfer',l:'Batch Transfer',d:'Move students between batches (M3)'},
                    ]},
                    {g:'📊 Results & Analytics',c:'#FFB84D',bg:'rgba(255,184,77,0.06)',brd:'rgba(255,184,77,0.16)',p:[
                      {k:'view_results',l:'View Results',d:'Access exam results, scores and AIR rankings'},
                      {k:'view_analytics',l:'View Analytics',d:'Access analytics dashboard and KPIs (S13/S108)'},
                      {k:'view_leaderboard',l:'View Leaderboard',d:'See all-India student rankings (S15/S60)'},
                      {k:'download_reports',l:'Download Reports',d:'Export PDF / CSV performance reports (S14)'},
                    ]},
                    {g:'📢 Communication',c:'#FF6B6B',bg:'rgba(255,107,107,0.06)',brd:'rgba(255,107,107,0.16)',p:[
                      {k:'send_announcements',l:'Send Announcements',d:'Broadcast notices to all students (S47)'},
                      {k:'manage_doubts',l:'Manage Doubts & Queries',d:'Reply to student questions (S63)'},
                      {k:'manage_grievances',l:'Manage Grievances / Tickets',d:'Handle complaints and support tickets (S92)'},
                      {k:'answer_key_challenge',l:'Answer Key Challenge',d:'Accept or reject answer key challenges (S69)'},
                    ]},
                    {g:'⚙️ System & Admin',c:'#00D4FF',bg:'rgba(0,212,255,0.06)',brd:'rgba(0,212,255,0.16)',p:[
                      {k:'manage_features',l:'Feature Flags',d:'Toggle platform features ON/OFF (N21)'},
                      {k:'manage_branding',l:'Manage Branding',d:'Change platform name, tagline and logo (S56)'},
                      {k:'view_audit_logs',l:'View Audit Logs',d:'See all admin activity history (S93/S38)'},
                      {k:'view_snapshots',l:'View Webcam Snapshots',d:'Access proctoring image captures (Phase 5.2)'},
                      {k:'manage_backup',l:'Manage Backup & Export',d:'Trigger backups and full data export (S50)'},
                      {k:'manage_admins',l:'Manage Admins',d:'Create and manage admin accounts (S37)'},
                    ]},
                  ].map((grp,gi)=>(
                    <div key={gi} style={{background:'rgba(0,8,20,0.85)',border:'1.5px solid '+grp.brd,borderRadius:16,overflow:'hidden'}}>
                      <div style={{background:grp.bg,borderBottom:'1px solid '+grp.brd,padding:'12px 16px',display:'flex',alignItems:'center',gap:10}}>
                        <span style={{fontSize:16}}>{grp.g.split(' ')[0]}</span>
                        <span style={{fontWeight:700,fontSize:13,color:grp.c}}>{grp.g.slice(grp.g.indexOf(' ')+1)}</span>
                        <span style={{marginLeft:'auto',fontSize:10,background:'rgba(0,0,0,0.25)',color:grp.c,borderRadius:20,padding:'2px 9px',border:'1px solid '+grp.brd,fontWeight:700}}>{grp.p.filter(pm=>perms[pm.k]).length}/{grp.p.length} Active</span>
                      </div>
                      <div style={{padding:'12px 14px',display:'flex',flexDirection:'column',gap:7}}>
                        {grp.p.map((pm,pi)=>(
                          <div key={pi} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'10px 13px',background:perms[pm.k]?'rgba(0,196,140,0.05)':'rgba(0,0,0,0.18)',borderRadius:10,border:'1px solid '+(perms[pm.k]?'rgba(0,196,140,0.18)':'rgba(255,255,255,0.03)'),transition:'all 0.2s'}}>
                            <div style={{flex:1,minWidth:0,marginRight:14}}>
                              <div style={{fontWeight:600,fontSize:12,color:perms[pm.k]?'#E0F0FF':'#7A8FA0'}}>{pm.l}</div>
                              <div style={{fontSize:10,color:'#3A5060',marginTop:2}}>{pm.d}</div>
                            </div>
                            <button onClick={()=>setPerms(p=>({...p,[pm.k]:!p[pm.k]}))} style={{width:46,height:26,borderRadius:13,border:'none',background:perms[pm.k]?'linear-gradient(90deg,#00C48C,#00a87a)':'rgba(80,100,120,0.25)',cursor:'pointer',position:'relative',transition:'all 0.3s',flexShrink:0}}>
                              <span style={{position:'absolute',top:3,left:perms[pm.k]?23:3,width:20,height:20,borderRadius:'50%',background:'#fff',transition:'left 0.3s',display:'block',boxShadow:'0 1px 5px rgba(0,0,0,0.4)'}}></span>
                            </button>
                          </div>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
                :<div style={{background:'rgba(0,10,28,0.7)',border:'1px dashed rgba(77,159,255,0.14)',borderRadius:16,padding:'44px 20px',textAlign:'center',marginBottom:20}}>
                  <svg width="52" height="52" viewBox="0 0 24 24" fill="none" style={{margin:'0 auto 14px',display:'block',opacity:0.3}}><path d="M12 2L3 7v5c0 5.25 3.75 10.15 9 11.35C17.25 22.15 21 17.25 21 12V7L12 2z" fill="rgba(77,159,255,0.2)" stroke="#4D9FFF" strokeWidth="1.5" strokeLinejoin="round"/><path d="M9 12l2 2 4-4" stroke="#4D9FFF" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/></svg>
                  <div style={{fontSize:14,color:'#3D5A7A',fontWeight:600}}>Select an admin above to manage their permissions</div>
                  <div style={{fontSize:11,color:'#263040',marginTop:6}}>Grant or restrict 26 individual capabilities per admin account</div>
                </div>
              }

              {/* ─── STICKY SAVE BUTTON ─── */}
              {selectedPermAdmin&&(
                <div style={{position:'sticky',bottom:12,zIndex:100,padding:'0 2px'}}>
                  <button onClick={savePerms} style={{...bp,width:'100%',padding:'14px',fontSize:13,fontWeight:700,display:'flex',alignItems:'center',justifyContent:'center',gap:8,boxShadow:'0 8px 32px rgba(0,100,255,0.28)',borderRadius:14}}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z" stroke="#fff" strokeWidth="2" strokeLinejoin="round"/><polyline points="17,21 17,13 7,13 7,21" stroke="#fff" strokeWidth="2" strokeLinejoin="round"/><polyline points="7,3 7,8 15,8" stroke="#fff" strokeWidth="2" strokeLinejoin="round"/></svg>
                    Save Permissions for {selectedPermAdmin.name}
                  </button>
                </div>
              )}

            </div>
          )}

          {/* ══ RESULTS ══ */}
JSXEOF

echo "✅ JSX written ($(wc -l < $JSXFILE) lines)"

# ── Node.js: 3 fixes ────────────────────────────────────────────
node << 'NODEEOF'
const fs=require('fs');
const FILE=process.env.FILE;
const JSXFILE=process.env.JSXFILE;
let c=fs.readFileSync(FILE,'utf8');
const newJSX=fs.readFileSync(JSXFILE,'utf8');

// ══ FIX 1 — Replace perms useState → 26 perms + add selectedPermAdmin ══
const PERMS_MARKER='const [perms,setPerms]=useState({';
const pi=c.indexOf(PERMS_MARKER);
if(pi!==-1){
  // Find balanced closing }
  let depth=0,i=pi+PERMS_MARKER.length-1;
  while(i<c.length){
    if(c[i]==='{') depth++;
    else if(c[i]==='}'){depth--;if(depth===0)break;}
    i++;
  }
  // Advance past }) and ;
  let endPI=i+1;
  if(endPI<c.length&&c[endPI]===')') endPI++;
  if(endPI<c.length&&c[endPI]===';') endPI++;

  const NEW_PERMS=`const [perms,setPerms]=useState({
  create_exam:false,edit_exam:false,delete_exam:false,clone_exam:false,bulk_exam:false,
  manage_questions:false,bulk_upload:false,ai_questions:false,pyq_access:false,
  view_students:false,ban_student:false,impersonate:false,export_data:false,batch_transfer:false,
  view_results:false,view_analytics:false,view_leaderboard:false,download_reports:false,
  send_announcements:false,manage_doubts:false,manage_grievances:false,answer_key_challenge:false,
  manage_features:false,manage_branding:false,view_audit_logs:false,view_snapshots:false,manage_backup:false,manage_admins:false,
});
const [selectedPermAdmin,setSelectedPermAdmin]=useState(null);`;
  c=c.slice(0,pi)+NEW_PERMS+c.slice(endPI);
  console.log('\u2705 Fix 1: perms useState \u2192 26 permissions + selectedPermAdmin added');
}else{
  console.warn('\u26A0\uFE0F Fix 1: perms useState not found');
}

// ══ FIX 2 — Fix savePerms: wrong endpoint → PUT /permissions/:id ══
const SAVE_MARKER='api/admin/permissions';
const si2=c.indexOf(SAVE_MARKER);
if(si2!==-1){
  const callbackStart=c.lastIndexOf('const savePerms',si2);
  if(callbackStart!==-1){
    // Find dependency array end ]); or ])
    const depArrStart=c.indexOf('},[',si2);
    let depArrEnd=c.indexOf(')',depArrStart)+1;
    if(c[depArrEnd]===';') depArrEnd++;
    const NEW_SAVE=`const savePerms=useCallback(async()=>{
  if(!selectedPermAdmin){T('Pehle koi admin select karo','e');return;}
  try{
    const r=await fetch(API+'/api/admin/manage/permissions/'+selectedPermAdmin._id,{method:'PUT',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({permissions:perms})});
    const d=await r.json();
    if(d.success) T('Permissions saved for '+selectedPermAdmin.name+' \u2705');
    else T(d.message||'Failed to save permissions','e');
  }catch(e){T('Network error \u2014 check connection','e');}
},[perms,token,T,selectedPermAdmin]);`;
    c=c.slice(0,callbackStart)+NEW_SAVE+c.slice(depArrEnd);
    console.log('\u2705 Fix 2: savePerms \u2192 PUT /api/admin/manage/permissions/:id');
  }
}else{
  console.warn('\u26A0\uFE0F Fix 2: savePerms marker not found \u2014 might already be fixed');
}

// ══ FIX 3 — Replace JSX section ══
const START='{/* \u2550\u2550 PERMISSIONS \u2550\u2550 */}';
const END='{/* \u2550\u2550 RESULTS \u2550\u2550 */}';
const si3=c.indexOf(START);
const ei3=c.indexOf(END);
if(si3===-1||ei3===-1){
  console.error('\u274C Markers not found  START:'+si3+' END:'+ei3);
  process.exit(1);
}
const endLineEnd=c.indexOf('\n',ei3)+1;
c=c.slice(0,si3)+newJSX+c.slice(endLineEnd);
console.log('\u2705 Fix 3: Permissions JSX \u2192 Ultra Premium design applied');

fs.writeFileSync(FILE,c,'utf8');
console.log('\n\u2705 ALL 3 FIXES APPLIED!');
NODEEOF

rm -f "$JSXFILE"
echo ""
echo "══════════════════════════════════════════════════════"
echo "✅ Done! Now run:"
echo "   git add -A && git commit -m 'Permissions Ultra Premium + Real API (S72)' && git push"
echo "══════════════════════════════════════════════════════"
