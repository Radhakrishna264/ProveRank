#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# ProveRank — Admin Management Ultra Premium SaaS Redesign
# Features: ZERO changes | Design: Ultra Premium | No Python
# ═══════════════════════════════════════════════════════════════

export FILE="$HOME/workspace/frontend/app/admin/x7k2p/page.tsx"
export TMPFILE="/tmp/pr_admin_mgmt_new.tmp"

# ── VERIFY FILE EXISTS ──
if [ ! -f "$FILE" ]; then
  echo "❌ File not found: $FILE"
  echo "   Check path and try again."
  exit 1
fi

# ── BACKUP ──
BACKUP="${FILE}.bak.$(date +%s)"
cp "$FILE" "$BACKUP"
echo "✅ Backup: $BACKUP"

# ═══════════════════════════════════════════════════════════════
# STEP 1 — Write new JSX section to temp file
# ═══════════════════════════════════════════════════════════════
cat > "$TMPFILE" << 'JSXEOF'
          {/* ══ ADMINS ══ */}
          {tab==='admins'&&(
            <div>

              {/* ─────── PREMIUM PAGE HEADER ─────── */}
              <div style={{background:'linear-gradient(135deg,rgba(4,30,60,0.97),rgba(0,18,42,0.99))',border:'1px solid rgba(77,159,255,0.22)',borderRadius:20,padding:'22px 22px 18px',marginBottom:20,position:'relative',overflow:'hidden'}}>
                <div style={{position:'absolute',top:-50,right:-50,width:200,height:200,borderRadius:'50%',background:'radial-gradient(circle,rgba(77,159,255,0.09),transparent 70%)',pointerEvents:'none'}}/>
                <div style={{position:'absolute',bottom:-40,left:40,width:140,height:140,borderRadius:'50%',background:'radial-gradient(circle,rgba(0,212,255,0.06),transparent 70%)',pointerEvents:'none'}}/>
                <div style={{display:'flex',alignItems:'center',gap:16,position:'relative',zIndex:1}}>
                  <div style={{width:54,height:54,background:'linear-gradient(135deg,rgba(77,159,255,0.2),rgba(0,212,255,0.1))',border:'1.5px solid rgba(77,159,255,0.4)',borderRadius:16,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0,boxShadow:'0 6px 24px rgba(77,159,255,0.2)'}}>
                    <svg width="26" height="26" viewBox="0 0 24 24" fill="none">
                      <path d="M12 2L3 7v5c0 5.25 3.75 10.15 9 11.35C17.25 22.15 21 17.25 21 12V7L12 2z" fill="rgba(77,159,255,0.22)" stroke="#4D9FFF" strokeWidth="1.6" strokeLinejoin="round"/>
                      <circle cx="12" cy="10" r="2.6" fill="#4D9FFF"/>
                      <path d="M7.5 16.5c.5-2 2.3-3.5 4.5-3.5s4 1.5 4.5 3.5" stroke="#4D9FFF" strokeWidth="1.5" strokeLinecap="round"/>
                    </svg>
                  </div>
                  <div style={{flex:1,minWidth:0}}>
                    <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#00D4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1.25}}>Admin Management</div>
                    <div style={{display:'flex',alignItems:'center',gap:8,marginTop:5,flexWrap:'wrap'}}>
                      <span style={{background:'rgba(77,159,255,0.15)',color:'#4D9FFF',borderRadius:20,padding:'2px 10px',fontSize:10,fontWeight:700,border:'1px solid rgba(77,159,255,0.3)'}}>S37</span>
                      <span style={{fontSize:11,color:'#6B8FAF'}}>Create · Freeze · Archive · Restore sub-admin accounts</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* ─────── STATS ROW ─────── */}
              <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:10,marginBottom:22}}>
                {([
                  {icon:'👥',label:'Total Admins',val:(adminUsers||[]).length+archivedAdmins.length,col:'#4D9FFF',bg:'rgba(77,159,255,0.1)',brd:'rgba(77,159,255,0.22)'},
                  {icon:'✅',label:'Active',val:(adminUsers||[]).filter(function(a){return !a.frozen}).length,col:'#00C48C',bg:'rgba(0,196,140,0.1)',brd:'rgba(0,196,140,0.22)'},
                  {icon:'🔒',label:'Frozen',val:(adminUsers||[]).filter(function(a){return a.frozen}).length,col:'#FFB84D',bg:'rgba(255,184,77,0.1)',brd:'rgba(255,184,77,0.22)'},
                  {icon:'🗃️',label:'Archived',val:archivedAdmins.length,col:'#FF6B6B',bg:'rgba(255,107,107,0.1)',brd:'rgba(255,107,107,0.22)'},
                ] as any[]).map(function(s:any,i:number){return(
                  <div key={i} style={{background:'rgba(0,18,36,0.9)',border:`1px solid ${s.brd}`,borderRadius:14,padding:'14px 12px',backdropFilter:'blur(12px)',position:'relative',overflow:'hidden'}}>
                    <div style={{position:'absolute',top:-6,right:-6,fontSize:32,opacity:0.06}}>{s.icon}</div>
                    <div style={{width:34,height:34,background:s.bg,borderRadius:10,display:'flex',alignItems:'center',justifyContent:'center',fontSize:16,marginBottom:9,border:`1px solid ${s.brd}`}}>{s.icon}</div>
                    <div style={{fontSize:24,fontWeight:800,color:s.col,fontFamily:'Inter,sans-serif',lineHeight:1}}>{s.val}</div>
                    <div style={{fontSize:10,color:'#6B8FAF',marginTop:5,fontWeight:600,letterSpacing:0.3}}>{s.label}</div>
                  </div>
                )})}
              </div>

              {/* ─────── CREATE ADMIN FORM ─────── */}
              <div style={{background:'rgba(0,20,44,0.94)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:18,marginBottom:22,overflow:'hidden',boxShadow:'0 4px 32px rgba(0,0,0,0.28)'}}>
                <div style={{background:'linear-gradient(90deg,rgba(77,159,255,0.16),rgba(0,212,255,0.06))',borderBottom:'1px solid rgba(77,159,255,0.14)',padding:'14px 20px',display:'flex',alignItems:'center',gap:10}}>
                  <div style={{width:32,height:32,background:'rgba(77,159,255,0.18)',borderRadius:9,display:'flex',alignItems:'center',justifyContent:'center',border:'1px solid rgba(77,159,255,0.28)'}}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                      <circle cx="10" cy="7" r="4" stroke="#4D9FFF" strokeWidth="1.8"/>
                      <path d="M2 21c0-4 3.58-7 8-7" stroke="#4D9FFF" strokeWidth="1.8" strokeLinecap="round"/>
                      <path d="M19 11v6M22 14h-6" stroke="#4D9FFF" strokeWidth="2" strokeLinecap="round"/>
                    </svg>
                  </div>
                  <div style={{fontWeight:700,fontSize:13,color:'#E8F4FF'}}>Create New Admin Account</div>
                  <div style={{marginLeft:'auto',fontSize:10,color:'#4D9FFF',background:'rgba(77,159,255,0.1)',borderRadius:20,padding:'2px 10px',border:'1px solid rgba(77,159,255,0.2)',fontWeight:600}}>SuperAdmin Only</div>
                </div>
                <div style={{padding:'18px 20px'}}>
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginBottom:14}}>
                    <div>
                      <label style={lbl}>Full Name *</label>
                      <SInput init='' onSet={function(v){admNameR.current=v}} ph='Admin full name' style={inp}/>
                    </div>
                    <div>
                      <label style={lbl}>Email Address *</label>
                      <SInput init='' onSet={function(v){admEmailR.current=v}} ph='admin@proverank.com' type='email' style={inp}/>
                    </div>
                    <div>
                      <label style={lbl}>Password *</label>
                      <SInput init='' onSet={function(v){admPassR.current=v}} ph='Strong password (min 8 chars)' type='password' style={inp}/>
                    </div>
                    <div>
                      <label style={lbl}>Role</label>
                      <SSelect val={admRole} onChange={setAdmRole} opts={[{v:'admin',l:'🛡️ Admin'},{v:'moderator',l:'🔍 Moderator'},{v:'superadmin',l:'👑 Super Admin'}]} style={{...inp}}/>
                    </div>
                  </div>
                  <button onClick={createAdmin} disabled={creatingAdm} style={{...bp,width:'100%',opacity:creatingAdm?0.7:1,display:'flex',alignItems:'center',justifyContent:'center',gap:8}}>
                    {creatingAdm?(
                      <><svg width="15" height="15" viewBox="0 0 24 24" fill="none" style={{animation:'spin 1s linear infinite'}}><circle cx="12" cy="12" r="9" stroke="rgba(255,255,255,0.25)" strokeWidth="2.5"/><path d="M12 3a9 9 0 019 9" stroke="#fff" strokeWidth="2.5" strokeLinecap="round"/></svg>Creating Account…</>
                    ):(
                      <><svg width="15" height="15" viewBox="0 0 24 24" fill="none"><path d="M12 5v14M5 12h14" stroke="#fff" strokeWidth="2.5" strokeLinecap="round"/></svg>Create Admin Account</>
                    )}
                  </button>
                </div>
              </div>

              {/* ─────── ACTIVE ADMINS HEADER ─────── */}
              <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:12,padding:'0 2px'}}>
                <div style={{display:'flex',alignItems:'center',gap:10}}>
                  <div style={{width:3,height:22,background:'linear-gradient(180deg,#4D9FFF,#00D4FF)',borderRadius:4,flexShrink:0}}/>
                  <span style={{fontWeight:700,fontSize:13,color:'#E8F4FF'}}>Active Admin Accounts</span>
                  <span style={{background:'rgba(77,159,255,0.14)',color:'#4D9FFF',borderRadius:20,padding:'2px 10px',fontSize:11,fontWeight:700,border:'1px solid rgba(77,159,255,0.25)'}}>{(adminUsers||[]).length}</span>
                </div>
              </div>

              {/* ─────── ACTIVE ADMINS LIST ─────── */}
              {(adminUsers||[]).length===0
                ?(
                  <div style={{background:'rgba(0,18,36,0.7)',border:'1px dashed rgba(77,159,255,0.2)',borderRadius:16,padding:'36px 20px',textAlign:'center',marginBottom:20}}>
                    <svg width="46" height="46" viewBox="0 0 24 24" fill="none" style={{margin:'0 auto 12px',display:'block'}}>
                      <path d="M12 2L3 7v5c0 5.25 3.75 10.15 9 11.35C17.25 22.15 21 17.25 21 12V7L12 2z" fill="rgba(77,159,255,0.08)" stroke="rgba(77,159,255,0.35)" strokeWidth="1.5" strokeLinejoin="round"/>
                      <circle cx="12" cy="10" r="2.5" stroke="rgba(77,159,255,0.4)" strokeWidth="1.5"/>
                      <path d="M7.5 16.5c.5-2 2.3-3.5 4.5-3.5s4 1.5 4.5 3.5" stroke="rgba(77,159,255,0.4)" strokeWidth="1.4" strokeLinecap="round"/>
                    </svg>
                    <div style={{color:'#6B8FAF',fontSize:13,fontWeight:600}}>No sub-admins yet</div>
                    <div style={{color:'#445566',fontSize:11,marginTop:4}}>Use the form above to create the first admin account</div>
                  </div>
                ):(
                  <div style={{display:'flex',flexDirection:'column',gap:10,marginBottom:22}}>
                    {(adminUsers||[]).map(function(au){return(
                      <div key={au._id} style={{background:au.frozen?'rgba(36,18,0,0.9)':'rgba(0,20,42,0.9)',border:`1px solid ${au.frozen?'rgba(255,184,77,0.3)':'rgba(77,159,255,0.18)'}`,borderRadius:16,padding:'15px 18px',backdropFilter:'blur(12px)',position:'relative',overflow:'hidden',transition:'border-color 0.2s'}}>
                        <div style={{position:'absolute',top:0,left:0,right:0,height:2,background:au.frozen?'linear-gradient(90deg,#FFB84D,#FF9800)':'linear-gradient(90deg,#4D9FFF,#00D4FF)',opacity:au.frozen?1:0.55}}/>
                        <div style={{display:'flex',alignItems:'center',gap:14,flexWrap:'wrap'}}>
                          {/* Avatar */}
                          <div style={{width:48,height:48,background:au.frozen?'linear-gradient(135deg,rgba(80,40,0,0.9),rgba(60,28,0,0.8))':'linear-gradient(135deg,rgba(77,159,255,0.22),rgba(0,100,200,0.28))',border:`2px solid ${au.frozen?'rgba(255,184,77,0.45)':'rgba(77,159,255,0.38)'}`,borderRadius:14,display:'flex',alignItems:'center',justifyContent:'center',fontSize:19,fontWeight:900,color:au.frozen?'#FFB84D':'#4D9FFF',flexShrink:0,fontFamily:'Inter,sans-serif'}}>
                            {(au.name||'A')[0].toUpperCase()}
                          </div>
                          {/* Info */}
                          <div style={{flex:1,minWidth:160}}>
                            <div style={{display:'flex',alignItems:'center',gap:8,flexWrap:'wrap',marginBottom:3}}>
                              <span style={{fontWeight:700,fontSize:14,color:'#E8F4FF'}}>{au.name}</span>
                              {au.frozen&&<span style={{fontSize:10,background:'rgba(255,184,77,0.16)',color:'#FFB84D',borderRadius:20,padding:'1px 8px',fontWeight:700,border:'1px solid rgba(255,184,77,0.32)'}}>🔒 FROZEN</span>}
                            </div>
                            <div style={{fontSize:11,color:'#6B8FAF',marginBottom:7}}>{au.email}</div>
                            <div style={{display:'flex',gap:6,flexWrap:'wrap',alignItems:'center'}}>
                              <span style={{fontSize:10,background:au.role==='superadmin'?'rgba(255,215,0,0.13)':au.role==='moderator'?'rgba(0,196,140,0.12)':'rgba(77,159,255,0.12)',color:au.role==='superadmin'?'#FFD700':au.role==='moderator'?'#00C48C':'#4D9FFF',borderRadius:20,padding:'2px 9px',fontWeight:700,border:`1px solid ${au.role==='superadmin'?'rgba(255,215,0,0.28)':au.role==='moderator'?'rgba(0,196,140,0.24)':'rgba(77,159,255,0.24)'}`}}>
                                {au.role==='superadmin'?'👑':au.role==='moderator'?'🔍':'🛡️'} {(au.role||'admin').toUpperCase()}
                              </span>
                              {!au.frozen&&<span style={{fontSize:10,background:'rgba(0,196,140,0.1)',color:'#00C48C',borderRadius:20,padding:'2px 8px',fontWeight:600,border:'1px solid rgba(0,196,140,0.2)'}}>● Active</span>}
                              {au.createdAt&&<span style={{fontSize:10,color:'#445566'}}>Joined {new Date(au.createdAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'})}</span>}
                            </div>
                          </div>
                          {/* Action Buttons */}
                          <div style={{display:'flex',gap:7,flexShrink:0,flexWrap:'wrap',alignItems:'center'}}>
                            <button onClick={function(){viewAdminProfile(au._id)}} style={{display:'flex',alignItems:'center',gap:5,background:'rgba(0,180,255,0.09)',border:'1px solid rgba(0,180,255,0.24)',color:'#00B4FF',borderRadius:10,padding:'7px 12px',fontSize:11,cursor:'pointer',fontWeight:600,backdropFilter:'blur(8px)'}}>
                              <svg width="13" height="13" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="8" r="4" stroke="#00B4FF" strokeWidth="2"/><path d="M4 20c0-4 3.58-7 8-7s8 3 8 7" stroke="#00B4FF" strokeWidth="2" strokeLinecap="round"/></svg>
                              Profile
                            </button>
                            <button onClick={async function(){
                              const r=await fetch(`${API}/api/admin/manage/freeze/${au._id}`,{method:'PUT',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},body:JSON.stringify({frozen:!au.frozen})})
                              const d=await r.json()
                              if(d.success){T(au.frozen?'Admin unfrozen — access restored.':'Admin frozen — cannot login now.');setAdminUsers(function(p:any){return p.map(function(a:any){return a._id===au._id?{...a,frozen:!au.frozen}:a})})}
                              else T(d.message||'Failed','e')
                            }} style={{display:'flex',alignItems:'center',gap:5,background:au.frozen?'rgba(0,196,140,0.09)':'rgba(255,184,77,0.09)',border:`1px solid ${au.frozen?'rgba(0,196,140,0.28)':'rgba(255,184,77,0.28)'}`,color:au.frozen?'#00C48C':'#FFB84D',borderRadius:10,padding:'7px 12px',fontSize:11,cursor:'pointer',fontWeight:600}}>
                              {au.frozen?(
                                <><svg width="13" height="13" viewBox="0 0 24 24" fill="none"><rect x="5" y="11" width="14" height="10" rx="2" stroke="#00C48C" strokeWidth="1.8"/><path d="M8 11V7a4 4 0 118 0" stroke="#00C48C" strokeWidth="1.8" strokeLinecap="round"/></svg>Unfreeze</>
                              ):(
                                <><svg width="13" height="13" viewBox="0 0 24 24" fill="none"><rect x="5" y="11" width="14" height="10" rx="2" stroke="#FFB84D" strokeWidth="1.8"/><path d="M8 11V7a4 4 0 118 0v4" stroke="#FFB84D" strokeWidth="1.8" strokeLinecap="round"/></svg>Freeze</>
                              )}
                            </button>
                            <button onClick={async function(){if(confirm('Archive this admin? They will not be able to login.')){
                              const r=await fetch(`${API}/api/admin/manage/archive/${au._id}`,{method:'PUT',headers:{Authorization:`Bearer ${token}`}})
                              const d=await r.json()
                              if(d.success){T('Admin archived successfully.');setAdminUsers(function(p:any){return p.filter(function(a:any){return a._id!==au._id})});fetchArchivedAdmins();}
                              else T(d.message||'Failed','e')
                            }}} style={{display:'flex',alignItems:'center',gap:5,background:'rgba(255,77,77,0.08)',border:'1px solid rgba(255,77,77,0.22)',color:'#FF6B6B',borderRadius:10,padding:'7px 12px',fontSize:11,cursor:'pointer',fontWeight:600}}>
                              <svg width="13" height="13" viewBox="0 0 24 24" fill="none"><path d="M5 8h14M5 8a2 2 0 01-2-2V5a2 2 0 012-2h14a2 2 0 012 2v1a2 2 0 01-2 2M5 8l1 10a2 2 0 002 2h8a2 2 0 002-2L19 8" stroke="#FF6B6B" strokeWidth="1.8" strokeLinecap="round"/></svg>
                              Archive
                            </button>
                          </div>
                        </div>
                      </div>
                    )})}
                  </div>
                )
              }

              {/* ─────── ARCHIVED ADMINS SECTION (INSIDE TAB — FIXED) ─────── */}
              <div style={{background:'linear-gradient(135deg,rgba(28,4,4,0.97),rgba(18,0,0,0.99))',border:'1.5px solid rgba(255,80,80,0.26)',borderRadius:18,overflow:'hidden',boxShadow:'0 4px 28px rgba(180,0,0,0.08)'}}>
                {/* Archived Header */}
                <div style={{background:'linear-gradient(90deg,rgba(255,80,80,0.1),rgba(255,40,40,0.04))',borderBottom:'1px solid rgba(255,80,80,0.14)',padding:'14px 18px',display:'flex',alignItems:'center',justifyContent:'space-between',flexWrap:'wrap',gap:8}}>
                  <div style={{display:'flex',alignItems:'center',gap:10}}>
                    <div style={{width:34,height:34,background:'rgba(255,60,60,0.16)',borderRadius:10,display:'flex',alignItems:'center',justifyContent:'center',border:'1px solid rgba(255,60,60,0.28)',flexShrink:0}}>
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                        <path d="M5 8h14M5 8a2 2 0 01-2-2V5a2 2 0 012-2h14a2 2 0 012 2v1a2 2 0 01-2 2M5 8l1 10a2 2 0 002 2h8a2 2 0 002-2L19 8" stroke="#FF6B6B" strokeWidth="1.8" strokeLinecap="round"/>
                      </svg>
                    </div>
                    <div>
                      <div style={{fontWeight:700,fontSize:13,color:'#FF7878'}}>Archived Admins</div>
                      <div style={{fontSize:10,color:'#994444',marginTop:1}}>Restore anytime to reactivate login access</div>
                    </div>
                    <span style={{background:'rgba(255,60,60,0.16)',color:'#FF6B6B',borderRadius:20,padding:'2px 10px',fontSize:11,fontWeight:700,border:'1px solid rgba(255,60,60,0.28)'}}>{archivedAdmins.length}</span>
                  </div>
                  <button onClick={fetchArchivedAdmins} style={{display:'flex',alignItems:'center',gap:5,background:'rgba(77,159,255,0.09)',border:'1px solid rgba(77,159,255,0.22)',color:'#4D9FFF',borderRadius:9,padding:'7px 13px',fontSize:11,cursor:'pointer',fontWeight:600}}>
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none"><path d="M4 4v5h.582M4.582 9A9 9 0 1120 12" stroke="#4D9FFF" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>
                    Refresh
                  </button>
                </div>
                {/* Archived Content */}
                <div style={{padding:'16px 18px'}}>
                  {archivedAdmins.length===0
                    ?(
                      <div style={{textAlign:'center',padding:'26px 0'}}>
                        <svg width="42" height="42" viewBox="0 0 24 24" fill="none" style={{margin:'0 auto 10px',display:'block'}}>
                          <circle cx="12" cy="12" r="9" fill="rgba(0,196,140,0.07)" stroke="rgba(0,196,140,0.28)" strokeWidth="1.5"/>
                          <path d="M7.5 12l3 3 6-6" stroke="#00C48C" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                        </svg>
                        <div style={{color:'#557766',fontSize:12,fontWeight:600}}>No archived admins</div>
                        <div style={{color:'#334455',fontSize:11,marginTop:3}}>All admin accounts are currently active</div>
                      </div>
                    ):(
                      <div style={{display:'flex',flexDirection:'column',gap:10}}>
                        {archivedAdmins.map(function(aa:any){return(
                          <div key={aa._id} style={{background:'rgba(0,0,0,0.35)',border:'1px solid rgba(255,60,60,0.15)',borderRadius:13,padding:'13px 15px',display:'flex',alignItems:'center',gap:12,flexWrap:'wrap'}}>
                            {/* Avatar */}
                            <div style={{width:42,height:42,background:'rgba(255,60,60,0.12)',border:'1.5px solid rgba(255,60,60,0.28)',borderRadius:12,display:'flex',alignItems:'center',justifyContent:'center',fontSize:17,fontWeight:900,color:'#FF7878',flexShrink:0,fontFamily:'Inter,sans-serif'}}>
                              {(aa.name||'A')[0].toUpperCase()}
                            </div>
                            {/* Info */}
                            <div style={{flex:1,minWidth:130}}>
                              <div style={{fontWeight:600,fontSize:13,color:'#C8D4E0'}}>{aa.name||'Unknown'}</div>
                              <div style={{fontSize:11,color:'#667788',marginTop:2}}>{aa.email}</div>
                              <div style={{display:'flex',gap:5,marginTop:6,flexWrap:'wrap',alignItems:'center'}}>
                                <span style={{background:'rgba(160,80,255,0.14)',color:'#C090FF',borderRadius:20,padding:'1px 8px',fontSize:10,fontWeight:600,border:'1px solid rgba(160,80,255,0.24)'}}>{(aa.role||'admin').toUpperCase()}</span>
                                <span style={{background:'rgba(255,60,60,0.13)',color:'#FF6B6B',borderRadius:20,padding:'1px 8px',fontSize:10,fontWeight:600,border:'1px solid rgba(255,60,60,0.24)'}}>🗃️ ARCHIVED</span>
                                {aa.archivedAt&&<span style={{fontSize:10,color:'#553333'}}>📅 {new Date(aa.archivedAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'})}</span>}
                              </div>
                            </div>
                            {/* Buttons */}
                            <div style={{display:'flex',gap:7,flexShrink:0}}>
                              <button onClick={function(){viewAdminProfile(aa._id)}} style={{display:'flex',alignItems:'center',gap:5,background:'rgba(0,180,255,0.09)',border:'1px solid rgba(0,180,255,0.24)',color:'#00B4FF',borderRadius:9,padding:'6px 12px',fontSize:11,cursor:'pointer',fontWeight:600}}>
                                <svg width="12" height="12" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="8" r="4" stroke="#00B4FF" strokeWidth="2"/><path d="M4 20c0-4 3.58-7 8-7s8 3 8 7" stroke="#00B4FF" strokeWidth="2" strokeLinecap="round"/></svg>
                                Profile
                              </button>
                              <button onClick={function(){restoreAdmin(aa._id)}} style={{display:'flex',alignItems:'center',gap:5,background:'rgba(0,196,140,0.09)',border:'1px solid rgba(0,196,140,0.26)',color:'#00C48C',borderRadius:9,padding:'6px 12px',fontSize:11,cursor:'pointer',fontWeight:600}}>
                                <svg width="12" height="12" viewBox="0 0 24 24" fill="none"><path d="M4 4v5h.582M4.582 9A9 9 0 1120 12" stroke="#00C48C" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>
                                Restore
                              </button>
                            </div>
                          </div>
                        )})}
                      </div>
                    )
                  }
                </div>
              </div>

            </div>
          )}

JSXEOF

echo "✅ JSX section written to temp file"

# ═══════════════════════════════════════════════════════════════
# STEP 2 — Node.js replaces the section in original file
# ═══════════════════════════════════════════════════════════════
node << 'NODEEOF'
const fs = require('fs');
const FILE    = process.env.FILE;
const TMPFILE = process.env.TMPFILE;

// Read files
let content    = fs.readFileSync(FILE,    'utf8');
const newSection = fs.readFileSync(TMPFILE, 'utf8');

// Unique markers
const START = '{/* \u2550\u2550 ADMINS \u2550\u2550 */}';
const END   = '{showProfileModal&&(';

const si = content.indexOf(START);
const ei = content.indexOf(END);

if (si === -1 || ei === -1) {
  console.error('❌ Markers not found  START:', si, ' END:', ei);
  console.error('   Restore from backup and check file manually.');
  process.exit(1);
}

// Stitch: everything before START + new section + everything from END onwards
const result = content.slice(0, si) + newSection + content.slice(ei);
fs.writeFileSync(FILE, result, 'utf8');

console.log('✅ Admin Management — Ultra Premium Redesign applied!');
console.log('   Lines replaced: ' + (ei - si) + ' chars → ' + newSection.length + ' chars');
NODEEOF

# ── CLEAN TEMP FILE ──
rm -f "$TMPFILE"
echo ""
echo "═══════════════════════════════════════════════"
echo "✅ DONE! Deploy using:  git add -A && git commit -m 'Admin Mgmt Ultra Premium Redesign' && git push"
echo "═══════════════════════════════════════════════"
