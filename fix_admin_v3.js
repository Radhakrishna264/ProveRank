const fs = require('fs');
const fp = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let c = fs.readFileSync(fp, 'utf8');
let n = 0;

// DIAGNOSE
console.log('Has FIXED sections:', c.includes('ARCHIVED ADMINS SECTION (FIXED)'));
console.log('Has old sections:', c.includes('ARCHIVED ADMINS SECTION ===== */}'));

// Find permissions tab with multiple patterns
let permIdx = -1, foundM = '';
const markers = [
  '{/* == PERMISSIONS == */}',"{/* ==PERMISSIONS== */}","tab==='permissions'&&(",
  "tab === 'permissions' && (","tab==='permissions' &&(","'permissions'&&(",
  "==PERMISSIONS==","== PERMISSIONS =="
];
for(const m of markers){
  const i = c.indexOf(m);
  if(i > -1){ permIdx = i; foundM = m; break; }
}

// Regex fallback
if(permIdx === -1){
  const rm = c.match(/tab\s*===\s*['"]permissions['"]/);
  if(rm){ permIdx = c.indexOf(rm[0]); foundM = rm[0]; }
}

console.log('Permissions marker found:', foundM || 'NOT FOUND', 'at:', permIdx);

// Insert sections before permissions tab
if(permIdx > -1 && !c.includes('ARCHIVED ADMINS SECTION (FIXED)')){
  const ns = `
{/* ===== ARCHIVED ADMINS SECTION (FIXED) ===== */}
<div style={{marginTop:24,marginBottom:20,background:'rgba(28,5,5,0.9)',border:'2px solid rgba(255,80,80,0.45)',borderRadius:18,padding:22}}>
  <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:16}}>
    <div style={{display:'flex',alignItems:'center',gap:12}}>
      <div style={{width:42,height:42,background:'rgba(255,60,60,0.22)',borderRadius:12,display:'flex',alignItems:'center',justifyContent:'center',fontSize:22,border:'1px solid rgba(255,60,60,0.4)'}}>🗃️</div>
      <div>
        <div style={{color:'#FF7070',fontWeight:700,fontSize:15}}>Archived Admins</div>
        <div style={{color:'#CC9999',fontSize:12,marginTop:1}}>SuperAdmin can restore any archived admin anytime</div>
      </div>
    </div>
    <div style={{display:'flex',gap:8,alignItems:'center'}}>
      <span style={{background:'rgba(255,60,60,0.22)',color:'#FF7070',borderRadius:20,padding:'3px 12px',fontSize:12,fontWeight:700,border:'1px solid rgba(255,60,60,0.35)'}}>{archivedAdmins.length}</span>
      <button onClick={fetchArchivedAdmins} style={{background:'rgba(0,180,255,0.12)',border:'1px solid rgba(0,180,255,0.28)',color:'#00B4FF',borderRadius:8,padding:'5px 12px',fontSize:11,cursor:'pointer',fontWeight:600}}>🔄 Refresh</button>
    </div>
  </div>
  {archivedAdmins.length===0
    ?<div style={{textAlign:'center',padding:'22px 0',borderTop:'1px solid rgba(255,60,60,0.12)'}}>
        <div style={{fontSize:28,marginBottom:8}}>✅</div>
        <div style={{color:'#FF8888',fontSize:13,fontWeight:600}}>No archived admins — All admins are active</div>
      </div>
    :<div style={{borderTop:'1px solid rgba(255,60,60,0.1)',paddingTop:14}}>
        {archivedAdmins.map((aa)=>(
          <div key={aa._id} style={{background:'rgba(0,0,0,0.4)',border:'1px solid rgba(255,60,60,0.18)',borderRadius:13,padding:14,marginBottom:10,display:'flex',alignItems:'center',justifyContent:'space-between',flexWrap:'wrap',gap:10}}>
            <div style={{display:'flex',alignItems:'center',gap:11,flex:1,minWidth:0}}>
              <div style={{width:38,height:38,background:'rgba(255,60,60,0.22)',borderRadius:10,display:'flex',alignItems:'center',justifyContent:'center',color:'#FF7070',fontWeight:700,fontSize:15,flexShrink:0}}>{(aa.name||'A')[0].toUpperCase()}</div>
              <div style={{minWidth:0}}>
                <div style={{color:'#E0E8F4',fontWeight:600,fontSize:14}}>{aa.name||'Unknown'}</div>
                <div style={{color:'#8899AA',fontSize:12,marginTop:1}}>{aa.email}</div>
                <div style={{display:'flex',gap:6,marginTop:5,flexWrap:'wrap'}}>
                  <span style={{background:'rgba(160,80,255,0.2)',color:'#C090FF',borderRadius:20,padding:'2px 8px',fontSize:10,fontWeight:600}}>{(aa.role||'admin').toUpperCase()}</span>
                  <span style={{background:'rgba(255,60,60,0.2)',color:'#FF7070',borderRadius:20,padding:'2px 8px',fontSize:10,fontWeight:600}}>🗄️ ARCHIVED</span>
                  {aa.archivedAt&&<span style={{color:'#CC7777',fontSize:10}}>📅 {new Date(aa.archivedAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'})}</span>}
                </div>
              </div>
            </div>
            <div style={{display:'flex',gap:8,flexShrink:0}}>
              <button onClick={()=>viewAdminProfile(aa._id)} style={{background:'rgba(0,180,255,0.12)',border:'1px solid rgba(0,180,255,0.28)',color:'#00B4FF',borderRadius:8,padding:'7px 13px',fontSize:11,cursor:'pointer',fontWeight:600}}>👁️ Profile</button>
              <button onClick={()=>restoreAdmin(aa._id)} style={{background:'rgba(0,200,80,0.12)',border:'1px solid rgba(0,200,80,0.28)',color:'#00C850',borderRadius:8,padding:'7px 13px',fontSize:11,cursor:'pointer',fontWeight:600}}>🔄 Restore</button>
            </div>
          </div>
        ))}
      </div>
  }
</div>

{/* ===== ADMIN PROFILE MODAL (FIXED) ===== */}
{showProfileModal&&(
  <div onClick={(e)=>{if(e.target===e.currentTarget){setShowProfileModal(false);setProfileAdmin(null);setProfileLogs([]);}}} style={{position:'fixed',top:0,left:0,right:0,bottom:0,background:'rgba(0,0,0,0.93)',zIndex:99999,display:'flex',alignItems:'center',justifyContent:'center',padding:16}}>
    <div style={{background:'#081420',border:'1px solid rgba(0,180,255,0.28)',borderRadius:20,width:'100%',maxWidth:560,maxHeight:'88vh',display:'flex',flexDirection:'column',boxShadow:'0 0 80px rgba(0,100,255,0.15)'}}>
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'18px 20px',borderBottom:'1px solid rgba(0,180,255,0.1)',flexShrink:0}}>
        <div style={{color:'#00B4FF',fontWeight:700,fontSize:16}}>👤 Admin Profile</div>
        <button onClick={()=>{setShowProfileModal(false);setProfileAdmin(null);setProfileLogs([]);}} style={{background:'rgba(255,60,60,0.15)',border:'1px solid rgba(255,60,60,0.28)',color:'#FF6060',borderRadius:8,padding:'5px 14px',cursor:'pointer',fontSize:12,fontWeight:600}}>✕ Close</button>
      </div>
      <div style={{overflowY:'auto',padding:'18px 20px',flex:1}}>
        {profileLoading&&<div style={{textAlign:'center',padding:'40px 0',color:'#AABBCC',fontSize:15}}>⟳ Loading profile...</div>}
        {!profileLoading&&!profileAdmin&&<div style={{textAlign:'center',padding:'40px 0',color:'#778899',fontSize:14}}>⚠️ Could not load profile. Try again.</div>}
        {!profileLoading&&profileAdmin&&(
          <div>
            <div style={{background:'rgba(0,100,255,0.07)',border:'1px solid rgba(0,180,255,0.12)',borderRadius:14,padding:16,marginBottom:14}}>
              <div style={{display:'flex',alignItems:'center',gap:14,marginBottom:12}}>
                <div style={{width:50,height:50,background:'linear-gradient(135deg,#002870,#0048A0)',borderRadius:12,display:'flex',alignItems:'center',justifyContent:'center',fontSize:22,fontWeight:700,color:'#fff',flexShrink:0}}>{(profileAdmin.name||'A')[0].toUpperCase()}</div>
                <div>
                  <div style={{color:'#E0F0FF',fontWeight:700,fontSize:17}}>{profileAdmin.name}</div>
                  <div style={{color:'#8899AA',fontSize:13,marginTop:2}}>{profileAdmin.email}</div>
                </div>
              </div>
              <div style={{display:'flex',gap:7,flexWrap:'wrap'}}>
                <span style={{background:'rgba(0,180,255,0.16)',color:'#00B4FF',borderRadius:20,padding:'3px 12px',fontSize:11,fontWeight:700}}>{(profileAdmin.role||'admin').toUpperCase()}</span>
                <span style={{background:profileAdmin.frozen?'rgba(255,60,60,0.16)':'rgba(0,200,80,0.16)',color:profileAdmin.frozen?'#FF6060':'#00C850',borderRadius:20,padding:'3px 12px',fontSize:11,fontWeight:700}}>{profileAdmin.frozen?'🔒 FROZEN':'✅ ACTIVE'}</span>
                {profileAdmin.archived&&<span style={{background:'rgba(255,140,0,0.16)',color:'#FFA030',borderRadius:20,padding:'3px 12px',fontSize:11}}>🗃️ ARCHIVED</span>}
              </div>
            </div>
            <div style={{background:'rgba(0,0,0,0.2)',border:'1px solid rgba(255,255,255,0.06)',borderRadius:12,padding:14,marginBottom:12}}>
              <div style={{color:'#9AB0C4',fontWeight:600,fontSize:12,marginBottom:10}}>🕐 Login History ({(profileAdmin.loginHistory||[]).length})</div>
              {(profileAdmin.loginHistory||[]).length===0&&<div style={{color:'#556677',fontSize:12}}>No login history available</div>}
              {((profileAdmin.loginHistory||[]) as any[]).slice(0,5).map((lh:any,i:number)=>(
                <div key={i} style={{background:'rgba(0,180,255,0.04)',border:'1px solid rgba(0,180,255,0.08)',borderRadius:7,padding:'7px 11px',marginBottom:5}}>
                  <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:3}}>
                    <span style={{color:'#D0E8F8',fontSize:12}}>📍 {lh.city||lh.location||'Unknown'}</span>
                    <span style={{color:'#445566',fontSize:11}}>{lh.time?new Date(lh.time).toLocaleString('en-IN',{day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'}):''}</span>
                  </div>
                  {lh.device&&<div style={{color:'#667788',marginTop:2,fontSize:11}}>💻 {lh.device}</div>}
                </div>
              ))}
            </div>
            <div style={{background:'rgba(0,0,0,0.2)',border:'1px solid rgba(255,255,255,0.06)',borderRadius:12,padding:14}}>
              <div style={{color:'#9AB0C4',fontWeight:600,fontSize:12,marginBottom:10}}>📋 Activity Logs ({profileLogs.length})</div>
              {profileLogs.length===0&&<div style={{color:'#556677',fontSize:12}}>No activity logs found</div>}
              {(profileLogs as any[]).slice(0,10).map((log:any,i:number)=>(
                <div key={i} style={{background:'rgba(0,0,0,0.2)',border:'1px solid rgba(255,255,255,0.04)',borderRadius:7,padding:'8px 11px',marginBottom:6}}>
                  <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',gap:6,flexWrap:'wrap',marginBottom:3}}>
                    <span style={{background:'rgba(0,180,255,0.13)',color:'#00B4FF',borderRadius:5,padding:'1px 7px',fontSize:10,fontWeight:700}}>{log.action||'ACTION'}</span>
                    <span style={{color:'#445566',fontSize:10}}>{log.createdAt?new Date(log.createdAt).toLocaleString('en-IN',{day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'}):''}</span>
                  </div>
                  {log.details&&<div style={{color:'#8899AA',fontSize:11}}>{log.details}</div>}
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  </div>
)}

`;
  c = c.substring(0,permIdx) + ns + c.substring(permIdx);
  n++; console.log('S2 PASS: Inserted before: ' + foundM);
} else if(c.includes('ARCHIVED ADMINS SECTION (FIXED)')){
  console.log('S2 INFO: Fixed sections already exist');
} else {
  console.log('S2 FAIL: permIdx='+permIdx+' — Cannot insert');
}

// S3: fetchArchivedAdmins on initial load
if(!c.includes('fetchArchivedAdmins();fetchAdmins') && !c.includes('fetchAdmins();fetchArchivedAdmins')){
  const pats=['fetchAdmins();\n','fetchAdmins();\r\n','fetchAdmins() ','fetchAdmins()'];
  let done=false;
  for(const p of pats){
    if(c.includes(p)&&!done){
      c=c.replace(p,p.trimEnd()+';fetchArchivedAdmins();'+(p.endsWith('\n')?'\n':' '));
      n++;console.log('S3 PASS: wired via pattern: '+JSON.stringify(p));done=true;
    }
  }
  if(!done)console.log('S3 WARN: no fetchAdmins pattern matched');
} else console.log('S3 INFO: already wired');

fs.writeFileSync(fp,c);
console.log('\nFIX V3 DONE — '+n+' changes');
