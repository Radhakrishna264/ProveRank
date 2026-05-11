const fs = require('fs');
const fp = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let c = fs.readFileSync(fp, 'utf8');
let n = 0;

// C1: Add new states
if(!c.includes('archivedAdmins')){
  const m = c.match(/const \[adminUsers[^\]]*\]\s*=\s*useState[^;]+;/);
  if(m){
    c = c.replace(m[0], m[0]+'\n  const [archivedAdmins,setArchivedAdmins]=useState([] as any[]);\n  const [profileAdmin,setProfileAdmin]=useState(null as any);\n  const [profileLogs,setProfileLogs]=useState([] as any[]);\n  const [showProfileModal,setShowProfileModal]=useState(false);\n  const [profileLoading,setProfileLoading]=useState(false);');
    n++; console.log('C1 PASS: States added');
  } else console.log('C1 WARN: adminUsers state not matched');
} else console.log('C1 INFO: States exist');

// C2: Add 3 new functions
if(!c.includes('fetchArchivedAdmins')){
  const fam = c.match(/const fetchAdmins\s*=\s*async[^{]*\{[\s\S]*?\n\s*\};/);
  const target = fam ? fam[0] : null;
  if(target){
    c = c.replace(target, target + `

  const fetchArchivedAdmins=async()=>{
    try{const r=await fetch(API+'/api/admin/manage/archived',{headers:{Authorization:'Bearer '+token}});const d=await r.json();if(d.success)setArchivedAdmins(d.admins||d.data||[]);else setArchivedAdmins([]);}catch(e){setArchivedAdmins([]);}
  };
  const viewAdminProfile=async(adminId:string)=>{
    setProfileLoading(true);setShowProfileModal(true);setProfileAdmin(null);setProfileLogs([]);
    try{const r=await fetch(API+'/api/admin/manage/profile/'+adminId,{headers:{Authorization:'Bearer '+token}});const d=await r.json();if(d.success){setProfileAdmin(d.admin);setProfileLogs(d.activityLogs||[]);}}catch(e){}
    setProfileLoading(false);
  };
  const restoreAdmin=async(adminId:string)=>{
    if(!confirm('Restore this admin? They will be able to login again.'))return;
    try{const r=await fetch(API+'/api/admin/manage/restore/'+adminId,{method:'PUT',headers:{Authorization:'Bearer '+token}});const d=await r.json();if(d.success){T('Admin restored! ✅','s');fetchArchivedAdmins();fetchAdmins();}else T(d.message||'Restore failed','e');}catch(e){T('Network error','e');}
  };`);
    n++; console.log('C2 PASS: 3 functions added');
  } else {
    // fallback before fetchAll
    const ff = c.indexOf('const fetchAll=') > -1 ? c.indexOf('const fetchAll=') : c.indexOf('const fetchAll ');
    if(ff > -1){
      const ins = `  const fetchArchivedAdmins=async()=>{try{const r=await fetch(API+'/api/admin/manage/archived',{headers:{Authorization:'Bearer '+token}});const d=await r.json();if(d.success)setArchivedAdmins(d.admins||d.data||[]);else setArchivedAdmins([]);}catch(e){}};
  const viewAdminProfile=async(adminId:string)=>{setProfileLoading(true);setShowProfileModal(true);setProfileAdmin(null);setProfileLogs([]);try{const r=await fetch(API+'/api/admin/manage/profile/'+adminId,{headers:{Authorization:'Bearer '+token}});const d=await r.json();if(d.success){setProfileAdmin(d.admin);setProfileLogs(d.activityLogs||[]);}}catch(e){}setProfileLoading(false);};
  const restoreAdmin=async(adminId:string)=>{if(!confirm('Restore admin?'))return;try{const r=await fetch(API+'/api/admin/manage/restore/'+adminId,{method:'PUT',headers:{Authorization:'Bearer '+token}});const d=await r.json();if(d.success){T('Restored! ✅','s');fetchArchivedAdmins();fetchAdmins();}else T(d.message||'Failed','e');}catch(e){}};
  `;
      c = c.substring(0,ff) + ins + c.substring(ff);
      n++; console.log('C2 PASS(alt): Functions added before fetchAll');
    } else console.log('C2 WARN: No insertion point found');
  }
} else console.log('C2 INFO: Functions exist');

// C3: Auto-load archived when admin tab opens
if(c.includes('fetchArchivedAdmins') && !c.includes('fetchArchivedAdmins()')){
  if(c.indexOf('fetchAdmins();\n') > -1){
    c = c.replace('fetchAdmins();\n','fetchAdmins();\n    fetchArchivedAdmins();\n');
    n++; console.log('C3 PASS: auto-load call added');
  } else console.log('C3 WARN: fetchAdmins() call not found');
} else console.log('C3 INFO: Already set up');

// C4: Fix archive action — remove from active list + refresh archived
const archMsg = "T('Admin archived successfully.')";
if(c.includes(archMsg)){
  const idx = c.indexOf(archMsg);
  const setIdx = c.indexOf('setAdminUsers(p=>p.map',idx);
  if(setIdx>-1){
    const endIdx = c.indexOf(':a))',setIdx);
    if(endIdx>-1){
      const oldCall = c.substring(setIdx, endIdx+':a))'.length);
      c = c.replace(oldCall,'setAdminUsers(p=>p.filter(a=>a._id!==au._id));fetchArchivedAdmins();');
      n++; console.log('C4 PASS: Archive action fixed');
    } else console.log('C4 WARN: end marker :a)) not found');
  } else console.log('C4 WARN: setAdminUsers not found after archive msg');
} else console.log('C4 WARN: Archive success msg pattern not found');

// C5: Profile button in admin card
if(!c.includes('viewAdminProfile(au._id)')){
  const archTxt = "'Archive this admin? They will not be able to login.'";
  if(c.includes(archTxt)){
    const idx = c.indexOf(archTxt);
    const bi = c.lastIndexOf('<button',idx);
    if(bi>-1){
      const pb = `<button onClick={()=>viewAdminProfile(au._id)} style={{background:'rgba(0,180,255,0.1)',border:'1px solid rgba(0,180,255,0.2)',color:'#00B4FF',borderRadius:7,padding:'5px 11px',fontSize:10,cursor:'pointer',fontWeight:600,marginRight:4}}>👁️ Profile</button>`;
      c = c.substring(0,bi)+pb+c.substring(bi);
      n++; console.log('C5 PASS: Profile button added');
    } else console.log('C5 WARN: button tag not found');
  } else console.log('C5 WARN: Archive confirm text not matched');
} else console.log('C5 INFO: Profile button exists');

// C6+C7: Archived Section + Profile Modal
if(!c.includes('archivedAdmins.map')){
  if(c.includes('Granular Permission Control')){
    const gcIdx = c.indexOf('Granular Permission Control');
    const phIdx = c.lastIndexOf('<PageHero',gcIdx);
    const insertAt = phIdx>-1 ? phIdx : c.lastIndexOf('<div',gcIdx);

    const newUI = `
{/* ===== ARCHIVED ADMINS SECTION ===== */}
<div style={{marginTop:24,marginBottom:20,background:'linear-gradient(135deg,rgba(255,55,55,0.05),rgba(0,0,0,0.22))',border:'1px solid rgba(255,55,55,0.14)',borderRadius:18,padding:22}}>
  <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:16}}>
    <div style={{display:'flex',alignItems:'center',gap:12}}>
      <div style={{width:42,height:42,background:'linear-gradient(135deg,rgba(255,55,55,0.14),rgba(200,35,0,0.1))',borderRadius:12,display:'flex',alignItems:'center',justifyContent:'center',fontSize:22,border:'1px solid rgba(255,55,55,0.16)'}}>🗃️</div>
      <div>
        <div style={{color:'#FF5050',fontWeight:700,fontSize:15}}>Archived Admins</div>
        <div style={{color:'#667788',fontSize:12,marginTop:1}}>SuperAdmin can restore any archived admin anytime</div>
      </div>
    </div>
    <div style={{display:'flex',gap:8,alignItems:'center'}}>
      <span style={{background:'rgba(255,55,55,0.12)',color:'#FF5050',borderRadius:20,padding:'3px 12px',fontSize:12,fontWeight:700}}>{archivedAdmins.length}</span>
      <button onClick={fetchArchivedAdmins} style={{background:'rgba(0,180,255,0.09)',border:'1px solid rgba(0,180,255,0.18)',color:'#00B4FF',borderRadius:8,padding:'5px 11px',fontSize:11,cursor:'pointer'}}>🔄</button>
    </div>
  </div>
  {archivedAdmins.length===0
    ?<div style={{textAlign:'center',padding:'20px 0',borderTop:'1px solid rgba(255,55,55,0.07)'}}>
        <div style={{fontSize:28,marginBottom:6,opacity:0.35}}>✅</div>
        <div style={{color:'#445566',fontSize:13}}>No archived admins — All admins are active</div>
      </div>
    :<div style={{borderTop:'1px solid rgba(255,55,55,0.07)',paddingTop:14}}>
        {archivedAdmins.map((aa)=>(
          <div key={aa._id} style={{background:'rgba(0,0,0,0.3)',border:'1px solid rgba(255,55,55,0.09)',borderRadius:13,padding:14,marginBottom:10,display:'flex',alignItems:'center',justifyContent:'space-between',flexWrap:'wrap',gap:10}}>
            <div style={{display:'flex',alignItems:'center',gap:11,flex:1,minWidth:0}}>
              <div style={{width:38,height:38,background:'linear-gradient(135deg,rgba(255,55,55,0.16),rgba(180,35,0,0.1))',borderRadius:10,display:'flex',alignItems:'center',justifyContent:'center',color:'#FF6060',fontWeight:700,fontSize:15,flexShrink:0}}>{(aa.name||'A')[0].toUpperCase()}</div>
              <div style={{minWidth:0}}>
                <div style={{color:'#D4E8F8',fontWeight:600,fontSize:14}}>{aa.name||'Unknown'}</div>
                <div style={{color:'#778899',fontSize:12,marginTop:1}}>{aa.email}</div>
                <div style={{display:'flex',gap:6,marginTop:5,flexWrap:'wrap'}}>
                  <span style={{background:'rgba(160,80,255,0.13)',color:'#B080FF',borderRadius:20,padding:'2px 8px',fontSize:10,fontWeight:600}}>{(aa.role||'admin').toUpperCase()}</span>
                  <span style={{background:'rgba(255,55,55,0.13)',color:'#FF5050',borderRadius:20,padding:'2px 8px',fontSize:10,fontWeight:600}}>🗄️ ARCHIVED</span>
                  {aa.archivedAt&&<span style={{color:'#556677',fontSize:10}}>📅 {new Date(aa.archivedAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'})}</span>}
                  {aa.archivedBy&&<span style={{color:'#445566',fontSize:10}}>by {aa.archivedBy}</span>}
                </div>
              </div>
            </div>
            <div style={{display:'flex',gap:8,flexShrink:0}}>
              <button onClick={()=>viewAdminProfile(aa._id)} style={{background:'rgba(0,180,255,0.09)',border:'1px solid rgba(0,180,255,0.18)',color:'#00B4FF',borderRadius:8,padding:'7px 13px',fontSize:11,cursor:'pointer',fontWeight:600}}>👁️ Profile</button>
              <button onClick={()=>restoreAdmin(aa._id)} style={{background:'rgba(0,200,80,0.09)',border:'1px solid rgba(0,200,80,0.18)',color:'#00C850',borderRadius:8,padding:'7px 13px',fontSize:11,cursor:'pointer',fontWeight:600}}>🔄 Restore</button>
            </div>
          </div>
        ))}
      </div>
  }
</div>

{/* ===== ADMIN PROFILE MODAL ===== */}
{showProfileModal&&(
  <div onClick={(e:any)=>{if(e.target===e.currentTarget){setShowProfileModal(false);setProfileAdmin(null);setProfileLogs([]);}}} style={{position:'fixed',inset:0,background:'rgba(0,0,10,0.9)',zIndex:10000,display:'flex',alignItems:'center',justifyContent:'center',padding:16}}>
    <div style={{background:'linear-gradient(160deg,#060F1C,#0A1726,#0D1C2E)',border:'1px solid rgba(0,180,255,0.2)',borderRadius:22,width:'100%',maxWidth:580,maxHeight:'90vh',display:'flex',flexDirection:'column',boxShadow:'0 0 60px rgba(0,100,255,0.1)'}}>
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'17px 22px 13px',borderBottom:'1px solid rgba(0,180,255,0.09)',flexShrink:0}}>
        <div style={{display:'flex',alignItems:'center',gap:11}}>
          <div style={{width:36,height:36,background:'linear-gradient(135deg,rgba(0,120,255,0.24),rgba(80,50,255,0.18))',borderRadius:10,display:'flex',alignItems:'center',justifyContent:'center',fontSize:18,border:'1px solid rgba(0,180,255,0.16)'}}>👤</div>
          <div>
            <div style={{color:'#00B4FF',fontWeight:700,fontSize:15}}>Admin Profile</div>
            <div style={{color:'#445566',fontSize:11}}>Full details · login history · activity logs</div>
          </div>
        </div>
        <button onClick={()=>{setShowProfileModal(false);setProfileAdmin(null);setProfileLogs([]);}} style={{background:'rgba(255,55,55,0.12)',border:'1px solid rgba(255,55,55,0.2)',color:'#FF5050',borderRadius:8,padding:'5px 13px',cursor:'pointer',fontSize:12,fontWeight:600}}>✕ Close</button>
      </div>
      <div style={{overflowY:'auto',padding:'18px 22px',flex:1}}>
        {profileLoading
          ?<div style={{textAlign:'center',padding:'48px 0',color:'#778899'}}><div style={{fontSize:32,marginBottom:10}}>⟳</div><div>Loading profile...</div></div>
          :profileAdmin
            ?<>
              <div style={{background:'rgba(0,120,255,0.05)',border:'1px solid rgba(0,180,255,0.1)',borderRadius:14,padding:17,marginBottom:14}}>
                <div style={{display:'flex',alignItems:'center',gap:13,marginBottom:13}}>
                  <div style={{width:52,height:52,background:'linear-gradient(135deg,#002E7A,#0052A0)',borderRadius:13,display:'flex',alignItems:'center',justifyContent:'center',fontSize:23,fontWeight:700,color:'#fff',flexShrink:0,border:'2px solid rgba(0,180,255,0.2)'}}>{(profileAdmin.name||'A')[0].toUpperCase()}</div>
                  <div style={{flex:1}}>
                    <div style={{color:'#E0F0FF',fontWeight:700,fontSize:17,marginBottom:2}}>{profileAdmin.name||'Unknown'}</div>
                    <div style={{color:'#8899AA',fontSize:13}}>{profileAdmin.email}</div>
                    {profileAdmin.phone&&<div style={{color:'#667788',fontSize:12,marginTop:2}}>📱 {profileAdmin.phone}</div>}
                  </div>
                </div>
                <div style={{display:'flex',gap:7,flexWrap:'wrap'}}>
                  <span style={{background:'rgba(0,180,255,0.14)',color:'#00B4FF',borderRadius:20,padding:'3px 12px',fontSize:11,fontWeight:700}}>{(profileAdmin.role||'admin').toUpperCase()}</span>
                  <span style={{background:profileAdmin.frozen?'rgba(255,55,55,0.14)':'rgba(0,200,80,0.14)',color:profileAdmin.frozen?'#FF5050':'#00C850',borderRadius:20,padding:'3px 12px',fontSize:11,fontWeight:700}}>{profileAdmin.frozen?'🔒 FROZEN':'✅ ACTIVE'}</span>
                  {profileAdmin.archived&&<span style={{background:'rgba(255,140,0,0.14)',color:'#FFA030',borderRadius:20,padding:'3px 12px',fontSize:11,fontWeight:700}}>🗃️ ARCHIVED</span>}
                  <span style={{background:'rgba(160,80,255,0.12)',color:'#B888FF',borderRadius:20,padding:'3px 12px',fontSize:11}}>📅 {profileAdmin.createdAt?new Date(profileAdmin.createdAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'}):'N/A'}</span>
                </div>
              </div>
              <div style={{background:'rgba(0,0,0,0.15)',border:'1px solid rgba(255,255,255,0.05)',borderRadius:12,padding:15,marginBottom:12}}>
                <div style={{color:'#9AB0C4',fontWeight:600,fontSize:12,marginBottom:10,display:'flex',alignItems:'center',gap:7}}>🕐 Login History<span style={{background:'rgba(0,180,255,0.1)',color:'#00B4FF',borderRadius:10,padding:'1px 7px',fontSize:10,marginLeft:'auto'}}>{(profileAdmin.loginHistory||[]).length}</span></div>
                {(profileAdmin.loginHistory||[]).length===0
                  ?<div style={{color:'#334455',fontSize:12,textAlign:'center',padding:'8px 0'}}>No login history available</div>
                  :((profileAdmin.loginHistory||[]) as any[]).slice(0,5).map((lh:any,i:number)=>(
                    <div key={i} style={{background:'rgba(0,180,255,0.03)',border:'1px solid rgba(0,180,255,0.06)',borderRadius:7,padding:'7px 11px',marginBottom:5}}>
                      <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:3}}>
                        <span style={{color:'#D0E8F8',fontSize:12}}>📍 {lh.city||lh.location||'Unknown'}</span>
                        <span style={{color:'#445566',fontSize:11}}>{lh.time?new Date(lh.time).toLocaleString('en-IN',{day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'}):lh.loginAt?new Date(lh.loginAt).toLocaleString('en-IN',{day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'}):''}</span>
                      </div>
                      {lh.device&&<div style={{color:'#667788',marginTop:2,fontSize:11}}>💻 {lh.device}</div>}
                    </div>
                  ))
                }
              </div>
              <div style={{background:'rgba(0,0,0,0.15)',border:'1px solid rgba(255,255,255,0.05)',borderRadius:12,padding:15}}>
                <div style={{color:'#9AB0C4',fontWeight:600,fontSize:12,marginBottom:10,display:'flex',alignItems:'center',gap:7}}>📋 Activity Log<span style={{background:'rgba(0,180,255,0.1)',color:'#00B4FF',borderRadius:10,padding:'1px 7px',fontSize:10,marginLeft:'auto'}}>{profileLogs.length}</span></div>
                {profileLogs.length===0
                  ?<div style={{color:'#334455',fontSize:12,textAlign:'center',padding:'8px 0'}}>No activity logs found</div>
                  :profileLogs.slice(0,15).map((log:any,i:number)=>(
                    <div key={i} style={{background:'rgba(0,0,0,0.18)',border:'1px solid rgba(255,255,255,0.04)',borderRadius:7,padding:'8px 11px',marginBottom:6}}>
                      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',flexWrap:'wrap',gap:5,marginBottom:3}}>
                        <span style={{background:'rgba(0,180,255,0.12)',color:'#00B4FF',borderRadius:5,padding:'2px 8px',fontSize:10,fontWeight:700}}>{log.action||'ACTION'}</span>
                        <span style={{color:'#445566',fontSize:10}}>{log.createdAt?new Date(log.createdAt).toLocaleString('en-IN',{day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'}):''}</span>
                      </div>
                      {log.details&&<div style={{color:'#8899AA',fontSize:11}}>{log.details}</div>}
                      {log.module&&<div style={{color:'#445566',fontSize:10,marginTop:2}}>📦 {log.module}</div>}
                    </div>
                  ))
                }
              </div>
            </>
            :<div style={{textAlign:'center',padding:'48px 0',color:'#778899'}}><div style={{fontSize:24,marginBottom:8}}>⚠️</div><div>Could not load profile.</div></div>
        }
      </div>
    </div>
  </div>
)}

`;
    c = c.substring(0,insertAt)+newUI+c.substring(insertAt);
    n++; console.log('C6+C7 PASS: Archived Section + Profile Modal added');
  } else console.log('C6 WARN: Granular Permission Control not found');
} else console.log('C6 INFO: Archived section exists');

fs.writeFileSync(fp,c);
console.log('\nFRONTEND PATCH DONE — '+n+' changes applied');
