#!/bin/bash
# ═══════════════════════════════════════════════════════════
# ProveRank — Admin Management Ultra Premium Redesign v3
# START: {/* ══ ADMINS ══ */}   END: {/* ══ RESULTS ══ */}
# ═══════════════════════════════════════════════════════════
set -e
export FILE="$HOME/workspace/frontend/app/admin/x7k2p/page.tsx"
export JSXFILE="/tmp/pr_admins_v3.jsx"

if [ ! -f "$FILE" ]; then echo "❌ File not found: $FILE"; exit 1; fi

cp "$FILE" "${FILE}.bak3.$(date +%s)"
echo "✅ Backup created"

# ── Write JSX to temp file ──────────────────────────────────
cat > "$JSXFILE" << 'JSXEOF'
          {/* ══ ADMINS ══ */}
          {tab==='admins'&&(
            <div>

              {/* ─── PREMIUM HEADER ─── */}
              <div style={{background:'linear-gradient(135deg,rgba(4,30,60,0.97),rgba(0,18,42,0.99))',border:'1px solid rgba(77,159,255,0.22)',borderRadius:20,padding:'22px 22px 18px',marginBottom:20,position:'relative',overflow:'hidden'}}>
                <div style={{position:'absolute',top:-50,right:-50,width:200,height:200,borderRadius:'50%',background:'radial-gradient(circle,rgba(77,159,255,0.09),transparent 70%)',pointerEvents:'none'}}></div>
                <div style={{display:'flex',alignItems:'center',gap:16,position:'relative',zIndex:1}}>
                  <div style={{width:54,height:54,background:'linear-gradient(135deg,rgba(77,159,255,0.2),rgba(0,212,255,0.1))',border:'1.5px solid rgba(77,159,255,0.4)',borderRadius:16,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0,boxShadow:'0 6px 24px rgba(77,159,255,0.18)'}}>
                    <svg width="26" height="26" viewBox="0 0 24 24" fill="none"><path d="M12 2L3 7v5c0 5.25 3.75 10.15 9 11.35C17.25 22.15 21 17.25 21 12V7L12 2z" fill="rgba(77,159,255,0.22)" stroke="#4D9FFF" strokeWidth="1.6" strokeLinejoin="round"/><circle cx="12" cy="10" r="2.6" fill="#4D9FFF"/><path d="M7.5 16.5c.5-2 2.3-3.5 4.5-3.5s4 1.5 4.5 3.5" stroke="#4D9FFF" strokeWidth="1.5" strokeLinecap="round"/></svg>
                  </div>
                  <div>
                    <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1.3}}>Admin Management</div>
                    <div style={{display:'flex',alignItems:'center',gap:8,marginTop:5,flexWrap:'wrap'}}>
                      <span style={{background:'rgba(77,159,255,0.15)',color:'#4D9FFF',borderRadius:20,padding:'2px 10px',fontSize:10,fontWeight:700,border:'1px solid rgba(77,159,255,0.3)'}}>S37</span>
                      <span style={{fontSize:11,color:'#6B8FAF'}}>Create · Freeze · Archive · Restore sub-admin accounts</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* ─── STATS ROW ─── */}
              <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:10,marginBottom:20}}>
                {[
                  {icon:'👥',label:'Total',val:(adminUsers||[]).length+archivedAdmins.length,col:'#4D9FFF',brd:'rgba(77,159,255,0.22)'},
                  {icon:'✅',label:'Active',val:(adminUsers||[]).filter(a=>!a.frozen).length,col:'#00C48C',brd:'rgba(0,196,140,0.22)'},
                  {icon:'🔒',label:'Frozen',val:(adminUsers||[]).filter(a=>a.frozen).length,col:'#FFB84D',brd:'rgba(255,184,77,0.22)'},
                  {icon:'🗃️',label:'Archived',val:archivedAdmins.length,col:'#FF6B6B',brd:'rgba(255,107,107,0.22)'},
                ].map((s,i)=>(
                  <div key={i} style={{background:'rgba(0,18,36,0.9)',border:`1px solid ${s.brd}`,borderRadius:14,padding:'14px 10px',textAlign:'center'}}>
                    <div style={{fontSize:20,marginBottom:6}}>{s.icon}</div>
                    <div style={{fontSize:20,fontWeight:800,color:s.col,lineHeight:1}}>{s.val}</div>
                    <div style={{fontSize:10,color:'#6B8FAF',marginTop:5,fontWeight:600}}>{s.label}</div>
                  </div>
                ))}
              </div>

              {/* ─── CREATE FORM ─── */}
              <div style={{...cs,marginBottom:20,border:'1px solid rgba(77,159,255,0.22)',padding:'0'}}>
                <div style={{background:'linear-gradient(90deg,rgba(77,159,255,0.1),rgba(0,212,255,0.04))',borderBottom:'1px solid rgba(77,159,255,0.12)',padding:'14px 18px',display:'flex',alignItems:'center',gap:10,flexWrap:'wrap'}}>
                  <div style={{width:32,height:32,background:'rgba(77,159,255,0.15)',borderRadius:9,display:'flex',alignItems:'center',justifyContent:'center',fontSize:15,border:'1px solid rgba(77,159,255,0.25)',flexShrink:0}}>➕</div>
                  <div style={{fontWeight:700,fontSize:13,color:'#E8F4FF',flex:1}}>Create New Admin Account</div>
                  <span style={{fontSize:10,color:'#4D9FFF',background:'rgba(77,159,255,0.1)',borderRadius:20,padding:'2px 10px',border:'1px solid rgba(77,159,255,0.2)',fontWeight:600}}>SuperAdmin Only</span>
                </div>
                <div style={{padding:'16px 18px'}}>
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                    <div><label style={lbl}>Full Name *</label><SInput init='' onSet={v=>{admNameR.current=v}} ph='Admin full name' style={inp}/></div>
                    <div><label style={lbl}>Email *</label><SInput init='' onSet={v=>{admEmailR.current=v}} ph='admin@proverank.com' type='email' style={inp}/></div>
                    <div><label style={lbl}>Password *</label><SInput init='' onSet={v=>{admPassR.current=v}} ph='Strong password' type='password' style={inp}/></div>
                    <div><label style={lbl}>Role</label><SSelect val={admRole} onChange={setAdmRole} opts={[{v:'admin',l:'🛡️ Admin'},{v:'moderator',l:'🔍 Moderator'},{v:'superadmin',l:'👑 Super Admin'}]} style={{...inp}}/></div>
                  </div>
                  <button onClick={createAdmin} disabled={creatingAdm} style={{...bp,width:'100%',marginTop:14,opacity:creatingAdm?0.7:1}}>
                    {creatingAdm?'⟳ Creating…':'🛡️ Create Admin Account'}
                  </button>
                </div>
              </div>

              {/* ─── ACTIVE ADMINS LABEL ─── */}
              <div style={{display:'flex',alignItems:'center',gap:10,marginBottom:12,padding:'0 2px'}}>
                <div style={{width:3,height:20,background:'linear-gradient(180deg,#4D9FFF,#00D4FF)',borderRadius:4,flexShrink:0}}></div>
                <span style={{fontWeight:700,fontSize:13,color:'#E8F4FF'}}>Active Admins</span>
                <span style={{background:'rgba(77,159,255,0.14)',color:'#4D9FFF',borderRadius:20,padding:'2px 10px',fontSize:11,fontWeight:700,border:'1px solid rgba(77,159,255,0.25)'}}>{(adminUsers||[]).length}</span>
              </div>

              {/* ─── ACTIVE ADMINS LIST ─── */}
              {(adminUsers||[]).length===0
                ?<div style={{...cs,textAlign:'center',padding:'32px 20px',marginBottom:20,border:'1px dashed rgba(77,159,255,0.2)'}}>
                  <div style={{fontSize:36,marginBottom:8,opacity:0.4}}>🛡️</div>
                  <div style={{fontSize:12,color:DIM}}>No sub-admins yet. Use the form above to create one.</div>
                </div>
                :<div style={{display:'flex',flexDirection:'column',gap:10,marginBottom:20}}>
                  {(adminUsers||[]).map(au=>(
                    <div key={au._id} style={{background:au.frozen?'rgba(36,18,0,0.9)':'rgba(0,20,42,0.9)',border:`1px solid ${au.frozen?'rgba(255,184,77,0.3)':'rgba(77,159,255,0.18)'}`,borderRadius:16,padding:'14px 16px',position:'relative',overflow:'hidden'}}>
                      <div style={{position:'absolute',top:0,left:0,right:0,height:2,background:au.frozen?'linear-gradient(90deg,#FFB84D,#FF9800)':'linear-gradient(90deg,#4D9FFF,#00D4FF)'}}></div>
                      <div style={{display:'flex',alignItems:'center',gap:12,flexWrap:'wrap'}}>
                        <div style={{width:46,height:46,background:au.frozen?'rgba(80,40,0,0.8)':'rgba(77,159,255,0.15)',border:`2px solid ${au.frozen?'rgba(255,184,77,0.4)':'rgba(77,159,255,0.35)'}`,borderRadius:13,display:'flex',alignItems:'center',justifyContent:'center',fontSize:18,fontWeight:900,color:au.frozen?'#FFB84D':'#4D9FFF',flexShrink:0,fontFamily:'Inter,sans-serif'}}>
                          {(au.name||'A')[0].toUpperCase()}
                        </div>
                        <div style={{flex:1,minWidth:140}}>
                          <div style={{display:'flex',alignItems:'center',gap:8,flexWrap:'wrap',marginBottom:3}}>
                            <span style={{fontWeight:700,fontSize:14,color:'#E8F4FF'}}>{au.name}</span>
                            {au.frozen&&<span style={{fontSize:10,background:'rgba(255,184,77,0.16)',color:'#FFB84D',borderRadius:20,padding:'1px 8px',fontWeight:700,border:'1px solid rgba(255,184,77,0.3)'}}>🔒 FROZEN</span>}
                          </div>
                          <div style={{fontSize:11,color:'#6B8FAF',marginBottom:6}}>{au.email}</div>
                          <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>
                            <span style={{fontSize:10,background:'rgba(77,159,255,0.12)',color:'#4D9FFF',borderRadius:20,padding:'2px 9px',fontWeight:700,border:'1px solid rgba(77,159,255,0.22)'}}>{(au.role||'admin').toUpperCase()}</span>
                            {!au.frozen&&<span style={{fontSize:10,background:'rgba(0,196,140,0.1)',color:'#00C48C',borderRadius:20,padding:'2px 8px',fontWeight:600,border:'1px solid rgba(0,196,140,0.2)'}}>● Active</span>}
                          </div>
                        </div>
                        <div style={{display:'flex',gap:7,flexShrink:0,flexWrap:'wrap'}}>
                          <button onClick={()=>viewAdminProfile(au._id)} style={{background:'rgba(0,180,255,0.09)',border:'1px solid rgba(0,180,255,0.24)',color:'#00B4FF',borderRadius:10,padding:'7px 12px',fontSize:11,cursor:'pointer',fontWeight:600}}>👁️ Profile</button>
                          <button onClick={async()=>{const r=await fetch(`${API}/api/admin/manage/freeze/${au._id}`,{method:'PUT',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({frozen:!au.frozen})});const d=await r.json();if(d.success){T(au.frozen?'Admin unfrozen.':'Admin frozen — cannot login now.');setAdminUsers(p=>p.map(a=>a._id===au._id?{...a,frozen:!au.frozen}:a))}else T(d.message||'Failed','e')}} style={{background:au.frozen?'rgba(0,196,140,0.09)':'rgba(255,184,77,0.09)',border:`1px solid ${au.frozen?'rgba(0,196,140,0.28)':'rgba(255,184,77,0.28)'}`,color:au.frozen?'#00C48C':'#FFB84D',borderRadius:10,padding:'7px 12px',fontSize:11,cursor:'pointer',fontWeight:600}}>{au.frozen?'🔓 Unfreeze':'🔒 Freeze'}</button>
                          <button onClick={async()=>{if(confirm('Archive this admin? They will not be able to login.')){const r=await fetch(`${API}/api/admin/manage/archive/${au._id}`,{method:'PUT',headers:{Authorization:`Bearer ${token}`}});const d=await r.json();if(d.success){T('Admin archived.');setAdminUsers(p=>p.filter(a=>a._id!==au._id));fetchArchivedAdmins();}else T(d.message||'Failed','e')}}} style={{background:'rgba(255,77,77,0.08)',border:'1px solid rgba(255,77,77,0.22)',color:'#FF6B6B',borderRadius:10,padding:'7px 12px',fontSize:11,cursor:'pointer',fontWeight:600}}>🗑️ Archive</button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              }

              {/* ─── ARCHIVED ADMINS (INSIDE TAB) ─── */}
              <div style={{background:'rgba(28,4,4,0.97)',border:'1.5px solid rgba(255,80,80,0.26)',borderRadius:18,overflow:'hidden'}}>
                <div style={{background:'rgba(255,80,80,0.08)',borderBottom:'1px solid rgba(255,80,80,0.14)',padding:'14px 18px',display:'flex',alignItems:'center',justifyContent:'space-between',flexWrap:'wrap',gap:8}}>
                  <div style={{display:'flex',alignItems:'center',gap:10}}>
                    <div style={{width:32,height:32,background:'rgba(255,60,60,0.16)',borderRadius:10,display:'flex',alignItems:'center',justifyContent:'center',fontSize:16,border:'1px solid rgba(255,60,60,0.28)',flexShrink:0}}>🗃️</div>
                    <div>
                      <div style={{fontWeight:700,fontSize:13,color:'#FF7878'}}>Archived Admins</div>
                      <div style={{fontSize:10,color:'#994444',marginTop:1}}>Restore anytime to reactivate login access</div>
                    </div>
                    <span style={{background:'rgba(255,60,60,0.16)',color:'#FF6B6B',borderRadius:20,padding:'2px 10px',fontSize:11,fontWeight:700,border:'1px solid rgba(255,60,60,0.28)'}}>{archivedAdmins.length}</span>
                  </div>
                  <button onClick={fetchArchivedAdmins} style={{background:'rgba(77,159,255,0.09)',border:'1px solid rgba(77,159,255,0.22)',color:'#4D9FFF',borderRadius:9,padding:'7px 13px',fontSize:11,cursor:'pointer',fontWeight:600}}>🔄 Refresh</button>
                </div>
                <div style={{padding:'16px 18px'}}>
                  {archivedAdmins.length===0
                    ?<div style={{textAlign:'center',padding:'24px 0'}}>
                      <div style={{fontSize:28,marginBottom:8,opacity:0.4}}>✅</div>
                      <div style={{color:'#557766',fontSize:12,fontWeight:600}}>No archived admins — All are active</div>
                    </div>
                    :<div style={{display:'flex',flexDirection:'column',gap:10}}>
                      {archivedAdmins.map(aa=>(
                        <div key={aa._id} style={{background:'rgba(0,0,0,0.35)',border:'1px solid rgba(255,60,60,0.15)',borderRadius:13,padding:'13px 15px',display:'flex',alignItems:'center',gap:12,flexWrap:'wrap'}}>
                          <div style={{width:40,height:40,background:'rgba(255,60,60,0.12)',border:'1.5px solid rgba(255,60,60,0.28)',borderRadius:12,display:'flex',alignItems:'center',justifyContent:'center',fontSize:16,fontWeight:900,color:'#FF7878',flexShrink:0}}>
                            {(aa.name||'A')[0].toUpperCase()}
                          </div>
                          <div style={{flex:1,minWidth:130}}>
                            <div style={{fontWeight:600,fontSize:13,color:'#C8D4E0'}}>{aa.name||'Unknown'}</div>
                            <div style={{fontSize:11,color:'#667788',marginTop:2}}>{aa.email}</div>
                            <div style={{display:'flex',gap:5,marginTop:5,flexWrap:'wrap'}}>
                              <span style={{background:'rgba(160,80,255,0.14)',color:'#C090FF',borderRadius:20,padding:'1px 8px',fontSize:10,fontWeight:600}}>{(aa.role||'admin').toUpperCase()}</span>
                              <span style={{background:'rgba(255,60,60,0.13)',color:'#FF6B6B',borderRadius:20,padding:'1px 8px',fontSize:10,fontWeight:600}}>🗃️ ARCHIVED</span>
                              {aa.archivedAt&&<span style={{fontSize:10,color:'#553333'}}>📅 {new Date(aa.archivedAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'})}</span>}
                              {aa.archivedBy&&<span style={{fontSize:10,color:'#445566'}}>by {aa.archivedBy}</span>}
                            </div>
                          </div>
                          <div style={{display:'flex',gap:7,flexShrink:0}}>
                            <button onClick={()=>viewAdminProfile(aa._id)} style={{background:'rgba(0,180,255,0.09)',border:'1px solid rgba(0,180,255,0.24)',color:'#00B4FF',borderRadius:9,padding:'6px 12px',fontSize:11,cursor:'pointer',fontWeight:600}}>👁️ Profile</button>
                            <button onClick={()=>restoreAdmin(aa._id)} style={{background:'rgba(0,196,140,0.09)',border:'1px solid rgba(0,196,140,0.26)',color:'#00C48C',borderRadius:9,padding:'6px 12px',fontSize:11,cursor:'pointer',fontWeight:600}}>🔄 Restore</button>
                          </div>
                        </div>
                      ))}
                    </div>
                  }
                </div>
              </div>

            </div>
          )}

          {/* ══ PERMISSIONS ══ */}
          {tab==='permissions'&&(
            <div>
              <div style={pageTitle}>🔐 Admin Permissions (S72)</div>
              <div style={pageSub}>SuperAdmin can enable or disable individual admin permissions</div>
              <PageHero icon="🔐" title="Granular Permission Control" subtitle="Enable or disable specific actions for sub-admins. SuperAdmin always retains full control and can freeze any permission instantly."/>
              <div style={cs}>
                <div style={{display:'grid',gap:10}}>
                  {Object.entries(perms).map(([key,val])=>(
                    <div key={key} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'10px 14px',background:CRD2,borderRadius:10,border:`1px solid ${val?BOR2:BOR}`}}>
                      <div>
                        <div style={{fontWeight:600,fontSize:12,color:TS}}>{key.replace(/_/g,' ').replace(/\b\w/g,c=>c.toUpperCase())}</div>
                        <div style={{fontSize:10,color:DIM,marginTop:1}}>Admin permission: {key}</div>
                      </div>
                      <button onClick={()=>setPerms(p=>({...p,[key]:!val}))} style={{width:44,height:24,borderRadius:12,border:'none',background:val?`linear-gradient(90deg,${SUC},#00a87a)`:'rgba(107,143,175,0.2)',cursor:'pointer',position:'relative',transition:'all 0.3s'}}>
                        <span style={{position:'absolute',top:2,left:val?22:2,width:20,height:20,borderRadius:'50%',background:'#fff',transition:'left 0.3s',display:'block'}}/>
                      </button>
                    </div>
                  ))}
                </div>
                <button onClick={savePerms} style={{...bp,width:'100%',marginTop:16}}>💾 Save Permissions</button>
              </div>
            </div>
          )}

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

          {/* ══ RESULTS ══ */}
JSXEOF

echo "✅ JSX written to temp file ($(wc -l < $JSXFILE) lines)"

# ── Node.js: replace section ────────────────────────────────
node << 'NODEEOF'
const fs=require('fs');
const FILE=process.env.FILE;
const JSXFILE=process.env.JSXFILE;
const content=fs.readFileSync(FILE,'utf8');
const newSection=fs.readFileSync(JSXFILE,'utf8');

// START = {/* ══ ADMINS ══ */}  END = {/* ══ RESULTS ══ */}
const START='{/* \u2550\u2550 ADMINS \u2550\u2550 */}';
const END='{/* \u2550\u2550 RESULTS \u2550\u2550 */}';

const si=content.indexOf(START);
const ei=content.indexOf(END);

if(si===-1||ei===-1){
  console.error('\u274C Markers not found  START:',si,' END:',ei);
  process.exit(1);
}

// newSection already ends with {/* ══ RESULTS ══ */} line
// so we slice content up to START, append newSection, then continue from AFTER the END marker line
const endLineEnd=content.indexOf('\n',ei)+1;
const result=content.slice(0,si)+newSection+content.slice(endLineEnd);
fs.writeFileSync(FILE,result,'utf8');
console.log('\u2705 Admin Management Ultra Premium v3 applied!');
console.log('   Chars: '+content.length+' \u2192 '+result.length);
NODEEOF

rm -f "$JSXFILE"
echo ""
echo "════════════════════════════════════════════════"
echo "✅ Now run: git add -A && git commit -m 'Admin Mgmt Ultra Premium v3' && git push"
echo "════════════════════════════════════════════════"
