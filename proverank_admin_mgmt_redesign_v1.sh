#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# ProveRank — Admin Management Tab ULTRA PREMIUM Redesign
# Features: SAME as before. Design: SaaS-grade, SVGs, animations
# NO Python. Pure Bash + Node.js heredoc.
# ═══════════════════════════════════════════════════════════════════

PANEL="$HOME/workspace/frontend/app/admin/x7k2p/page.tsx"

if [ ! -f "$PANEL" ]; then
  echo "❌ File not found: $PANEL"
  echo "Please check path and run again."
  exit 1
fi

echo "✅ File found. Starting Admin Management Ultra Premium Redesign..."
echo "📦 File size before: $(wc -c < "$PANEL") bytes"

node << 'JSEOF'
const fs = require('fs');
const path = require('path');
const filePath = path.join(process.env.HOME, 'workspace/frontend/app/admin/x7k2p/page.tsx');

let content = fs.readFileSync(filePath, 'utf8');

// ── STEP 1: Replace the {tab==='admins'&&( ... )} block ──
const ADMINS_START = `          {/* ══ ADMINS ══ */}\n          {tab==='admins'&&(`;
const PERMISSIONS_COMMENT = `          {/* ══ PERMISSIONS ══ */}`;

const adminsIdx = content.indexOf(ADMINS_START);
if (adminsIdx === -1) { console.error('❌ Admins tab not found'); process.exit(1); }

const permIdx = content.indexOf(PERMISSIONS_COMMENT, adminsIdx);
if (permIdx === -1) { console.error('❌ Permissions comment not found'); process.exit(1); }

// ── STEP 2: Find and remove old Archived+Modal block ──
const ARCHIVED_OLD = `\n{/* ===== ARCHIVED ADMINS SECTION (FIXED) =====`;
const PERM_TAB = `{\n\ntab==='permissions'`;

const archivedOldIdx = content.indexOf(ARCHIVED_OLD, permIdx);
const permTabIdx = content.indexOf(PERM_TAB, permIdx);

// ── NEW ADMINS TAB ──
const NEW_ADMINS = `          {/* ══ ADMINS ══ */}
          {tab==='admins'&&(
            <div style={{animation:'fadeIn 0.4s ease'}}>

              {/* ── PAGE HERO HEADER ── */}
              <div style={{background:'linear-gradient(135deg,rgba(0,40,100,0.55),rgba(77,159,255,0.10))',border:'1px solid rgba(77,159,255,0.22)',borderRadius:20,padding:'26px 22px 22px',marginBottom:24,position:'relative',overflow:'hidden'}}>
                <div style={{position:'absolute',right:-18,top:-18,fontSize:160,opacity:0.035,lineHeight:1,pointerEvents:'none'}}>🛡️</div>
                {/* Circuit Board SVG */}
                <svg style={{position:'absolute',right:20,bottom:10,opacity:0.08}} width="100" height="65" viewBox="0 0 100 65">
                  <rect x="8" y="8" width="84" height="49" rx="5" fill="none" stroke="#4D9FFF" strokeWidth="1.5"/>
                  <rect x="18" y="18" width="18" height="12" rx="3" fill="none" stroke="#4D9FFF" strokeWidth="1.2"/>
                  <rect x="64" y="18" width="18" height="12" rx="3" fill="none" stroke="#00D4FF" strokeWidth="1.2"/>
                  <rect x="41" y="38" width="18" height="10" rx="3" fill="none" stroke="#4D9FFF" strokeWidth="1.2"/>
                  <circle cx="27" cy="44" r="4" fill="none" stroke="#4D9FFF" strokeWidth="1.2"/>
                  <circle cx="73" cy="44" r="4" fill="none" stroke="#00D4FF" strokeWidth="1.2"/>
                  <line x1="36" y1="24" x2="64" y2="24" stroke="#4D9FFF" strokeWidth="1"/>
                  <line x1="50" y1="30" x2="50" y2="38" stroke="#4D9FFF" strokeWidth="1"/>
                  <line x1="27" y1="30" x2="27" y2="40" stroke="#4D9FFF" strokeWidth="1"/>
                  <line x1="73" y1="30" x2="73" y2="40" stroke="#00D4FF" strokeWidth="1"/>
                  <rect x="22" y="3" width="10" height="5" rx="1.5" fill="#4D9FFF" opacity="0.7"/>
                  <rect x="68" y="3" width="10" height="5" rx="1.5" fill="#4D9FFF" opacity="0.7"/>
                </svg>
                <div style={{display:'flex',alignItems:'flex-start',justifyContent:'space-between',flexWrap:'wrap',gap:14}}>
                  <div style={{display:'flex',alignItems:'center',gap:14}}>
                    <div style={{width:50,height:50,background:'linear-gradient(135deg,#1a3a80,#4D9FFF)',borderRadius:15,display:'flex',alignItems:'center',justifyContent:'center',fontSize:24,boxShadow:'0 6px 22px rgba(77,159,255,0.40)',flexShrink:0}}>🛡️</div>
                    <div>
                      <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,background:'linear-gradient(90deg,#4D9FFF,#E8F4FF)',WebkitBackgroundClip:'text',WebkitTextFillColor:'transparent',lineHeight:1.2}}>Admin Management</div>
                      <div style={{fontSize:11,color:'#6B8FAF',marginTop:3,lineHeight:1.5}}>Multi-Admin System (S37) · Permission Control (S72) · SuperAdmin Full Control</div>
                    </div>
                  </div>
                  {/* Stats Pills */}
                  <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
                    {[
                      {ico:'✅',val:(adminUsers||[]).filter((a:any)=>!a.archived&&!a.frozen).length,lbl:'Active',col:'#00C48C',bg:'rgba(0,196,140,0.12)',bdr:'rgba(0,196,140,0.28)'},
                      {ico:'🔒',val:(adminUsers||[]).filter((a:any)=>a.frozen).length,lbl:'Frozen',col:'#FFB84D',bg:'rgba(255,184,77,0.12)',bdr:'rgba(255,184,77,0.28)'},
                      {ico:'🗃️',val:archivedAdmins.length,lbl:'Archived',col:'#FF7070',bg:'rgba(255,60,60,0.12)',bdr:'rgba(255,60,60,0.28)'},
                    ].map((s:any)=>(
                      <div key={s.lbl} style={{background:s.bg,border:\`1px solid \${s.bdr}\`,borderRadius:12,padding:'10px 14px',textAlign:'center',minWidth:64}}>
                        <div style={{fontSize:18,marginBottom:3}}>{s.ico}</div>
                        <div style={{fontWeight:800,fontSize:20,color:s.col,lineHeight:1}}>{s.val}</div>
                        <div style={{fontSize:10,color:'#6B8FAF',marginTop:2}}>{s.lbl}</div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              {/* ── CREATE NEW ADMIN CARD ── */}
              <div style={{background:'linear-gradient(135deg,rgba(0,22,40,0.92),rgba(0,36,72,0.88))',border:'1.5px solid rgba(77,159,255,0.22)',borderRadius:18,padding:'22px 20px',marginBottom:20,backdropFilter:'blur(14px)',boxShadow:'0 8px 32px rgba(0,0,0,0.3)'}}>
                <div style={{display:'flex',alignItems:'center',gap:10,marginBottom:18}}>
                  <div style={{width:38,height:38,background:'linear-gradient(135deg,rgba(77,159,255,0.25),rgba(0,85,204,0.22))',borderRadius:11,display:'flex',alignItems:'center',justifyContent:'center',fontSize:18,border:'1px solid rgba(77,159,255,0.30)',flexShrink:0}}>➕</div>
                  <div>
                    <div style={{fontWeight:700,fontSize:15,color:'#E8F4FF',fontFamily:'Playfair Display,serif'}}>Create New Admin</div>
                    <div style={{fontSize:11,color:'#6B8FAF',marginTop:1}}>Add sub-admins and moderators with custom permissions</div>
                  </div>
                </div>
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12}}>
                  <div>
                    <label style={{display:'block',fontSize:10,color:'#6B8FAF',marginBottom:5,fontWeight:700,letterSpacing:0.8,textTransform:'uppercase'}}>Full Name *</label>
                    <SInput init='' onSet={v=>{admNameR.current=v}} ph='Admin full name' style={{width:'100%',padding:'11px 14px',background:'rgba(0,22,40,0.85)',border:'1.5px solid rgba(77,159,255,0.22)',borderRadius:10,color:'#E8F4FF',fontSize:13,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box'}}/>
                  </div>
                  <div>
                    <label style={{display:'block',fontSize:10,color:'#6B8FAF',marginBottom:5,fontWeight:700,letterSpacing:0.8,textTransform:'uppercase'}}>Email *</label>
                    <SInput init='' onSet={v=>{admEmailR.current=v}} ph='admin@proverank.com' type='email' style={{width:'100%',padding:'11px 14px',background:'rgba(0,22,40,0.85)',border:'1.5px solid rgba(77,159,255,0.22)',borderRadius:10,color:'#E8F4FF',fontSize:13,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box'}}/>
                  </div>
                  <div>
                    <label style={{display:'block',fontSize:10,color:'#6B8FAF',marginBottom:5,fontWeight:700,letterSpacing:0.8,textTransform:'uppercase'}}>Password *</label>
                    <SInput init='' onSet={v=>{admPassR.current=v}} ph='Strong password' type='password' style={{width:'100%',padding:'11px 14px',background:'rgba(0,22,40,0.85)',border:'1.5px solid rgba(77,159,255,0.22)',borderRadius:10,color:'#E8F4FF',fontSize:13,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box'}}/>
                  </div>
                  <div>
                    <label style={{display:'block',fontSize:10,color:'#6B8FAF',marginBottom:5,fontWeight:700,letterSpacing:0.8,textTransform:'uppercase'}}>Role</label>
                    <SSelect val={admRole} onChange={setAdmRole} opts={[{v:'admin',l:'🛡️ Admin'},{v:'moderator',l:'👁️ Moderator'},{v:'superadmin',l:'👑 Super Admin'}]} style={{width:'100%',padding:'11px 14px',background:'rgba(0,22,40,0.85)',border:'1.5px solid rgba(77,159,255,0.22)',borderRadius:10,color:'#E8F4FF',fontSize:13,fontFamily:'Inter,sans-serif',outline:'none',boxSizing:'border-box'}}/>
                  </div>
                </div>
                <button onClick={createAdmin} disabled={creatingAdm} style={{width:'100%',marginTop:16,padding:'13px',background:creatingAdm?'rgba(77,159,255,0.4)':'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',border:'none',borderRadius:12,cursor:creatingAdm?'not-allowed':'pointer',fontWeight:700,fontSize:14,fontFamily:'Inter,sans-serif',boxShadow:'0 4px 18px rgba(77,159,255,0.35)',transition:'all 0.2s',letterSpacing:0.3}}>
                  {creatingAdm?'⟳ Creating Account…':'🛡️ Create Admin Account'}
                </button>
              </div>

              {/* ── ACTIVE ADMINS LIST ── */}
              <div style={{marginBottom:20}}>
                <div style={{display:'flex',alignItems:'center',gap:10,marginBottom:14}}>
                  <div style={{height:1,flex:1,background:'linear-gradient(90deg,rgba(77,159,255,0.35),transparent)'}}/>
                  <span style={{fontSize:10,color:'#6B8FAF',fontWeight:700,letterSpacing:1.2,textTransform:'uppercase',whiteSpace:'nowrap'}}>Active Admins ({(adminUsers||[]).length})</span>
                  <div style={{height:1,flex:1,background:'linear-gradient(90deg,transparent,rgba(77,159,255,0.35))'}}/>
                </div>
                {(adminUsers||[]).length===0?(
                  <div style={{background:'rgba(0,22,40,0.55)',border:'1px dashed rgba(77,159,255,0.18)',borderRadius:18,padding:'36px 20px',textAlign:'center'}}>
                    <div style={{fontSize:52,marginBottom:12,opacity:0.5}}>🛡️</div>
                    <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:'#E8F4FF',marginBottom:6}}>No Additional Admins Yet</div>
                    <div style={{fontSize:12,color:'#6B8FAF',lineHeight:1.7,maxWidth:380,margin:'0 auto'}}>Create sub-admins and moderators using the form above. SuperAdmin always retains full control.</div>
                  </div>
                ):(
                  <div style={{display:'grid',gap:12}}>
                    {(adminUsers||[]).map((au:any,idx:number)=>(
                      <div key={au._id} style={{background:'linear-gradient(135deg,rgba(0,22,40,0.90),rgba(0,36,65,0.85))',border:\`1.5px solid \${au.frozen?'rgba(255,184,77,0.35)':au.archived?'rgba(255,60,60,0.30)':'rgba(77,159,255,0.18)'}\`,borderRadius:16,padding:'16px 18px',backdropFilter:'blur(12px)',position:'relative',overflow:'hidden',transition:'all 0.2s',boxShadow:'0 4px 20px rgba(0,0,0,0.22)'}}>
                        {au.frozen&&<div style={{position:'absolute',top:0,right:0,background:'rgba(255,184,77,0.16)',borderBottomLeftRadius:10,padding:'4px 14px',fontSize:10,fontWeight:700,color:'#FFB84D',border:'1px solid rgba(255,184,77,0.28)'}}>🔒 FROZEN</div>}
                        <div style={{position:'absolute',right:-10,bottom:-10,fontSize:70,opacity:0.03,pointerEvents:'none'}}>🛡️</div>
                        <div style={{display:'flex',gap:14,alignItems:'flex-start',flexWrap:'wrap'}}>
                          {/* Avatar */}
                          <div style={{width:52,height:52,borderRadius:15,flexShrink:0,background:idx%3===0?'linear-gradient(135deg,#1a3a80,#4D9FFF)':idx%3===1?'linear-gradient(135deg,#200060,#7B2FBE)':'linear-gradient(135deg,#003040,#00A0B4)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:22,fontWeight:800,color:'#fff',boxShadow:'0 4px 16px rgba(77,159,255,0.28)'}}>
                            {(au.name||'A').charAt(0).toUpperCase()}
                          </div>
                          {/* Info */}
                          <div style={{flex:1,minWidth:160}}>
                            <div style={{display:'flex',alignItems:'center',gap:8,flexWrap:'wrap',marginBottom:4}}>
                              <span style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:'#E8F4FF'}}>{au.name}</span>
                              <span style={{fontSize:9,padding:'2px 10px',borderRadius:20,fontWeight:700,background:au.role==='superadmin'?'rgba(255,215,0,0.18)':au.role==='moderator'?'rgba(160,80,255,0.18)':'rgba(77,159,255,0.18)',color:au.role==='superadmin'?'#FFD700':au.role==='moderator'?'#C090FF':'#4D9FFF',border:\`1px solid \${au.role==='superadmin'?'rgba(255,215,0,0.35)':au.role==='moderator'?'rgba(160,80,255,0.35)':'rgba(77,159,255,0.35)'}\`}}>{au.role.toUpperCase()}</span>
                              {au.frozen&&<span style={{fontSize:9,padding:'2px 9px',borderRadius:20,background:'rgba(255,184,77,0.16)',color:'#FFB84D',border:'1px solid rgba(255,184,77,0.32)',fontWeight:700}}>🔒 FROZEN</span>}
                            </div>
                            <div style={{fontSize:12,color:'#6B8FAF',marginBottom:5}}>✉️ {au.email}</div>
                            {au.createdAt&&<div style={{fontSize:10,color:'#6B8FAF'}}>📅 Joined: {new Date(au.createdAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'})}</div>}
                          </div>
                          {/* Action Buttons */}
                          <div style={{display:'flex',flexDirection:'column' as const,gap:7,flexShrink:0,minWidth:110}}>
                            <button onClick={()=>viewAdminProfile(au._id)} style={{background:'rgba(0,212,255,0.10)',border:'1px solid rgba(0,212,255,0.28)',color:'#00D4FF',borderRadius:9,padding:'8px 14px',fontSize:11,cursor:'pointer',fontWeight:700,fontFamily:'Inter,sans-serif',transition:'all 0.2s',textAlign:'center' as const}}>👁️ View Profile</button>
                            <button onClick={async()=>{const r=await fetch(\`\${API}/api/admin/manage/freeze/\${au._id}\`,{method:'PUT',headers:{'Content-Type':'application/json',Authorization:\`Bearer \${token}\`},body:JSON.stringify({frozen:!au.frozen})});const d=await r.json();if(d.success){T(au.frozen?'✅ Admin unfrozen.':'🔒 Admin frozen — login blocked.');setAdminUsers((p:any)=>p.map((a:any)=>a._id===au._id?{...a,frozen:!au.frozen}:a))}else T(d.message||'Failed','e')}} style={{background:au.frozen?'rgba(0,196,140,0.12)':'rgba(255,184,77,0.12)',border:\`1px solid \${au.frozen?'rgba(0,196,140,0.35)':'rgba(255,184,77,0.35)'}\`,color:au.frozen?'#00C48C':'#FFB84D',borderRadius:9,padding:'8px 14px',fontSize:11,cursor:'pointer',fontWeight:700,fontFamily:'Inter,sans-serif',transition:'all 0.2s',textAlign:'center' as const}}>{au.frozen?'🔓 Unfreeze':'🔒 Freeze'}</button>
                            <button onClick={async()=>{if(confirm('Archive this admin? They cannot login. SuperAdmin can restore anytime.')){const r=await fetch(\`\${API}/api/admin/manage/archive/\${au._id}\`,{method:'PUT',headers:{Authorization:\`Bearer \${token}\`}});const d=await r.json();if(d.success){T('🗃️ Admin archived. Restore from Archived section anytime.');setAdminUsers((p:any)=>p.filter((a:any)=>a._id!==au._id));fetchArchivedAdmins();}else T(d.message||'Failed','e')}}} style={{background:'rgba(255,60,60,0.08)',border:'1px solid rgba(255,60,60,0.28)',color:'#FF7070',borderRadius:9,padding:'8px 14px',fontSize:11,cursor:'pointer',fontWeight:700,fontFamily:'Inter,sans-serif',transition:'all 0.2s',textAlign:'center' as const}}>🗑️ Archive</button>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* ── ARCHIVED ADMINS — ULTRA PREMIUM SECTION ── */}
              <div style={{background:'linear-gradient(135deg,rgba(18,3,3,0.95),rgba(36,6,6,0.92))',border:'1.5px solid rgba(255,60,60,0.28)',borderRadius:20,padding:'22px 20px',backdropFilter:'blur(14px)',boxShadow:'0 8px 30px rgba(255,30,30,0.06)',position:'relative',overflow:'hidden',marginBottom:20}}>
                {/* DNA Helix SVG — Biology decoration */}
                <svg style={{position:'absolute',left:10,bottom:8,opacity:0.065}} width="55" height="85" viewBox="0 0 55 85">
                  <path d="M8 5 Q47 22 8 42 Q47 62 8 80" fill="none" stroke="#FF7070" strokeWidth="2"/>
                  <path d="M47 5 Q8 22 47 42 Q8 62 47 80" fill="none" stroke="#FF9090" strokeWidth="1.5"/>
                  <line x1="16" y1="13" x2="39" y2="17" stroke="#FF7070" strokeWidth="1.2"/>
                  <line x1="11" y1="27" x2="44" y2="27" stroke="#FF7070" strokeWidth="1.2"/>
                  <line x1="11" y1="57" x2="44" y2="57" stroke="#FF7070" strokeWidth="1.2"/>
                  <line x1="16" y1="72" x2="39" y2="68" stroke="#FF7070" strokeWidth="1.2"/>
                  <circle cx="8" cy="5" r="2.5" fill="#FF7070"/>
                  <circle cx="47" cy="5" r="2.5" fill="#FF9090"/>
                  <circle cx="8" cy="80" r="2.5" fill="#FF7070"/>
                  <circle cx="47" cy="80" r="2.5" fill="#FF9090"/>
                </svg>
                <div style={{position:'absolute',right:-15,top:-15,fontSize:150,opacity:0.03,pointerEvents:'none',lineHeight:1}}>🗃️</div>
                {/* Header */}
                <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:18,flexWrap:'wrap',gap:10}}>
                  <div style={{display:'flex',alignItems:'center',gap:12}}>
                    <div style={{width:44,height:44,background:'rgba(255,60,60,0.18)',borderRadius:13,display:'flex',alignItems:'center',justifyContent:'center',fontSize:20,border:'1px solid rgba(255,60,60,0.35)',flexShrink:0}}>🗃️</div>
                    <div>
                      <div style={{color:'#FF8585',fontWeight:700,fontSize:17,fontFamily:'Playfair Display,serif'}}>Archived Admins</div>
                      <div style={{color:'#AA7070',fontSize:11,marginTop:2}}>SuperAdmin can restore any archived admin anytime</div>
                    </div>
                  </div>
                  <div style={{display:'flex',gap:8,alignItems:'center'}}>
                    <span style={{background:'rgba(255,60,60,0.18)',color:'#FF7070',borderRadius:20,padding:'5px 16px',fontSize:13,fontWeight:800,border:'1px solid rgba(255,60,60,0.32)'}}>{archivedAdmins.length}</span>
                    <button onClick={fetchArchivedAdmins} style={{background:'rgba(0,180,255,0.12)',border:'1px solid rgba(0,180,255,0.28)',color:'#00B4FF',borderRadius:9,padding:'8px 14px',fontSize:11,cursor:'pointer',fontWeight:700,fontFamily:'Inter,sans-serif',transition:'all 0.2s'}}>🔄 Refresh</button>
                  </div>
                </div>
                {archivedAdmins.length===0?(
                  <div style={{textAlign:'center',padding:'28px 0',borderTop:'1px solid rgba(255,60,60,0.10)'}}>
                    <div style={{fontSize:38,marginBottom:10,opacity:0.55}}>✅</div>
                    <div style={{color:'#FF9090',fontSize:13,fontWeight:600}}>No Archived Admins</div>
                    <div style={{color:'#775555',fontSize:11,marginTop:4}}>All admin accounts are currently active</div>
                  </div>
                ):(
                  <div style={{borderTop:'1px solid rgba(255,60,60,0.10)',paddingTop:16}}>
                    <div style={{display:'grid',gap:10}}>
                      {archivedAdmins.map((aa:any)=>(
                        <div key={aa._id} style={{background:'rgba(0,0,0,0.45)',border:'1px solid rgba(255,60,60,0.18)',borderRadius:14,padding:'14px 16px',display:'flex',alignItems:'center',justifyContent:'space-between',flexWrap:'wrap' as const,gap:10,backdropFilter:'blur(8px)',transition:'all 0.2s'}}>
                          <div style={{display:'flex',alignItems:'center',gap:12,flex:1,minWidth:0}}>
                            <div style={{width:44,height:44,background:'linear-gradient(135deg,rgba(255,60,60,0.30),rgba(180,30,30,0.42))',borderRadius:12,display:'flex',alignItems:'center',justifyContent:'center',color:'#FF8080',fontWeight:800,fontSize:20,flexShrink:0,border:'1px solid rgba(255,60,60,0.25)'}}>
                              {(aa.name||'A')[0].toUpperCase()}
                            </div>
                            <div style={{minWidth:0}}>
                              <div style={{color:'#E8F0F8',fontWeight:700,fontSize:14}}>{aa.name||'Unknown'}</div>
                              <div style={{color:'#8899AA',fontSize:12,marginTop:1,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{aa.email}</div>
                              <div style={{display:'flex',gap:6,marginTop:6,flexWrap:'wrap' as const}}>
                                <span style={{background:'rgba(160,80,255,0.18)',color:'#C090FF',borderRadius:20,padding:'2px 10px',fontSize:9,fontWeight:700,border:'1px solid rgba(160,80,255,0.28)'}}>{(aa.role||'admin').toUpperCase()}</span>
                                <span style={{background:'rgba(255,60,60,0.16)',color:'#FF8080',borderRadius:20,padding:'2px 10px',fontSize:9,fontWeight:700,border:'1px solid rgba(255,60,60,0.25)'}}>🗄️ ARCHIVED</span>
                                {aa.archivedAt&&<span style={{color:'#886666',fontSize:10}}>📅 {new Date(aa.archivedAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'})}</span>}
                              </div>
                            </div>
                          </div>
                          <div style={{display:'flex',gap:8,flexShrink:0}}>
                            <button onClick={()=>viewAdminProfile(aa._id)} style={{background:'rgba(0,180,255,0.12)',border:'1px solid rgba(0,180,255,0.28)',color:'#00B4FF',borderRadius:9,padding:'8px 14px',fontSize:11,cursor:'pointer',fontWeight:700,fontFamily:'Inter,sans-serif',transition:'all 0.2s'}}>👁️ Profile</button>
                            <button onClick={()=>restoreAdmin(aa._id)} style={{background:'rgba(0,200,80,0.12)',border:'1px solid rgba(0,200,80,0.30)',color:'#00C850',borderRadius:9,padding:'8px 16px',fontSize:11,cursor:'pointer',fontWeight:700,fontFamily:'Inter,sans-serif',transition:'all 0.2s'}}>🔄 Restore</button>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              {/* ── MOTIVATIONAL + SCIENCE FACT ROW ── */}
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12}}>
                <div style={{background:'linear-gradient(135deg,rgba(77,159,255,0.09),rgba(0,212,255,0.04))',border:'1px solid rgba(77,159,255,0.16)',borderRadius:16,padding:'16px 18px',position:'relative',overflow:'hidden'}}>
                  <div style={{position:'absolute',right:-8,top:-6,fontSize:48,opacity:0.07,pointerEvents:'none'}}>💡</div>
                  <div style={{fontSize:10,fontWeight:700,color:'#4D9FFF',letterSpacing:1,textTransform:'uppercase' as const,marginBottom:8}}>Motivational Quote</div>
                  <div style={{fontSize:13,color:'#C8DCF0',fontStyle:'italic',lineHeight:1.7,fontFamily:'Playfair Display,serif'}}>"Great teams are built on trust. Each admin you onboard multiplies your mission."</div>
                  <div style={{fontSize:10,color:'#6B8FAF',marginTop:8}}>— ProveRank Admin Principle</div>
                </div>
                <div style={{background:'linear-gradient(135deg,rgba(0,229,160,0.08),rgba(0,212,255,0.04))',border:'1px solid rgba(0,229,160,0.16)',borderRadius:16,padding:'16px 18px',position:'relative',overflow:'hidden'}}>
                  <div style={{position:'absolute',right:-8,top:-6,fontSize:48,opacity:0.07,pointerEvents:'none'}}>🧬</div>
                  <div style={{fontSize:10,fontWeight:700,color:'#00E5A0',letterSpacing:1,textTransform:'uppercase' as const,marginBottom:8}}>Biology Fact</div>
                  <div style={{fontSize:12,color:'#C8DCF0',lineHeight:1.7}}>The human brain has ~86 billion neurons. Each forms up to 10,000 synaptic connections — more than any computer ever built.</div>
                  <div style={{fontSize:10,color:'#6B8FAF',marginTop:6}}>— Neuroscience</div>
                </div>
              </div>
            </div>
          )}`;

// ── NEW PROFILE MODAL ──
const NEW_MODAL = `{showProfileModal&&(
  <div onClick={(e:any)=>{if(e.target===e.currentTarget){setShowProfileModal(false);setProfileAdmin(null);setProfileLogs([]);}}} style={{position:'fixed',top:0,left:0,right:0,bottom:0,background:'rgba(0,4,12,0.96)',backdropFilter:'blur(8px)',zIndex:99999,display:'flex',alignItems:'center',justifyContent:'center',padding:16,animation:'fadeIn 0.25s ease'}}>
    <div style={{background:'linear-gradient(135deg,#020e1e,#071428)',border:'1.5px solid rgba(0,180,255,0.28)',borderRadius:22,width:'100%',maxWidth:580,maxHeight:'90vh',display:'flex',flexDirection:'column' as const,boxShadow:'0 0 80px rgba(0,100,255,0.18)',overflow:'hidden'}}>
      {/* Modal Header */}
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'18px 22px',borderBottom:'1px solid rgba(0,180,255,0.12)',background:'linear-gradient(135deg,rgba(0,40,100,0.5),rgba(0,30,60,0.40))',flexShrink:0}}>
        <div style={{display:'flex',alignItems:'center',gap:10}}>
          <div style={{width:36,height:36,background:'linear-gradient(135deg,#002870,#0048A0)',borderRadius:10,display:'flex',alignItems:'center',justifyContent:'center',fontSize:17}}>👤</div>
          <div>
            <div style={{color:'#00D4FF',fontWeight:700,fontSize:16,fontFamily:'Playfair Display,serif'}}>Admin Full Profile</div>
            <div style={{color:'#6B8FAF',fontSize:10,marginTop:1}}>Login history · Activity logs · Account status</div>
          </div>
        </div>
        <button onClick={()=>{setShowProfileModal(false);setProfileAdmin(null);setProfileLogs([]);}} style={{background:'rgba(255,60,60,0.15)',border:'1px solid rgba(255,60,60,0.30)',color:'#FF7070',borderRadius:9,padding:'6px 16px',cursor:'pointer',fontSize:12,fontWeight:700,fontFamily:'Inter,sans-serif',transition:'all 0.2s'}}>✕ Close</button>
      </div>
      {/* Modal Body */}
      <div style={{overflowY:'auto',padding:'20px 22px',flex:1}}>
        {profileLoading&&(
          <div style={{textAlign:'center',padding:'50px 0'}}>
            <div style={{fontSize:36,marginBottom:14,animation:'spin 1s linear infinite',display:'inline-block'}}>⟳</div>
            <div style={{color:'#6B8FAF',fontSize:14}}>Loading admin profile...</div>
          </div>
        )}
        {!profileLoading&&!profileAdmin&&(
          <div style={{textAlign:'center',padding:'50px 0'}}>
            <div style={{fontSize:40,marginBottom:12}}>⚠️</div>
            <div style={{color:'#8899AA',fontSize:14}}>Could not load profile. Please try again.</div>
          </div>
        )}
        {!profileLoading&&profileAdmin&&(
          <div>
            {/* Admin Info */}
            <div style={{background:'linear-gradient(135deg,rgba(0,80,200,0.10),rgba(0,40,100,0.08))',border:'1px solid rgba(0,180,255,0.15)',borderRadius:16,padding:'18px 16px',marginBottom:16}}>
              <div style={{display:'flex',alignItems:'center',gap:16,marginBottom:14}}>
                <div style={{width:58,height:58,background:'linear-gradient(135deg,#001e60,#0048A0)',borderRadius:16,display:'flex',alignItems:'center',justifyContent:'center',fontSize:26,fontWeight:800,color:'#fff',flexShrink:0,boxShadow:'0 4px 18px rgba(0,100,255,0.32)'}}>{(profileAdmin.name||'A')[0].toUpperCase()}</div>
                <div>
                  <div style={{color:'#E8F4FF',fontWeight:700,fontSize:18,fontFamily:'Playfair Display,serif'}}>{profileAdmin.name}</div>
                  <div style={{color:'#6B8FAF',fontSize:13,marginTop:2}}>✉️ {profileAdmin.email}</div>
                  {profileAdmin.createdAt&&<div style={{color:'#6B8FAF',fontSize:11,marginTop:2}}>📅 Created: {new Date(profileAdmin.createdAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'})}</div>}
                </div>
              </div>
              <div style={{display:'flex',gap:8,flexWrap:'wrap' as const}}>
                <span style={{background:'rgba(0,180,255,0.16)',color:'#00D4FF',borderRadius:20,padding:'4px 14px',fontSize:11,fontWeight:700,border:'1px solid rgba(0,180,255,0.30)'}}>{(profileAdmin.role||'admin').toUpperCase()}</span>
                <span style={{background:profileAdmin.frozen?'rgba(255,60,60,0.16)':'rgba(0,200,80,0.16)',color:profileAdmin.frozen?'#FF7070':'#00C850',borderRadius:20,padding:'4px 14px',fontSize:11,fontWeight:700,border:\`1px solid \${profileAdmin.frozen?'rgba(255,60,60,0.30)':'rgba(0,200,80,0.30)'}\`}}>{profileAdmin.frozen?'🔒 FROZEN':'✅ ACTIVE'}</span>
                {profileAdmin.archived&&<span style={{background:'rgba(255,140,0,0.16)',color:'#FFA030',borderRadius:20,padding:'4px 14px',fontSize:11,fontWeight:600,border:'1px solid rgba(255,140,0,0.30)'}}>🗃️ ARCHIVED</span>}
              </div>
            </div>
            {/* Login History */}
            <div style={{background:'rgba(0,0,0,0.28)',border:'1px solid rgba(255,255,255,0.06)',borderRadius:14,padding:'16px',marginBottom:14}}>
              <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:12}}>
                <div style={{width:28,height:28,background:'rgba(0,180,255,0.14)',borderRadius:7,display:'flex',alignItems:'center',justifyContent:'center',fontSize:14}}>🕐</div>
                <div style={{color:'#8AAABF',fontWeight:700,fontSize:12,letterSpacing:0.5}}>Login History ({(profileAdmin.loginHistory||[]).length})</div>
              </div>
              {(profileAdmin.loginHistory||[]).length===0&&<div style={{color:'#445566',fontSize:12,textAlign:'center',padding:'14px 0'}}>No login history recorded yet</div>}
              <div style={{display:'grid',gap:7}}>
                {((profileAdmin.loginHistory||[]) as any[]).slice(0,5).map((lh:any,i:number)=>(
                  <div key={i} style={{background:'rgba(0,180,255,0.04)',border:'1px solid rgba(0,180,255,0.09)',borderRadius:9,padding:'9px 13px',display:'flex',justifyContent:'space-between',alignItems:'flex-start',flexWrap:'wrap' as const,gap:4}}>
                    <div>
                      <span style={{color:'#C8E0F0',fontSize:12,fontWeight:600}}>📍 {lh.city||lh.location||'Unknown'}</span>
                      {lh.device&&<div style={{color:'#5577AA',marginTop:2,fontSize:11}}>💻 {lh.device}</div>}
                      {lh.ip&&<div style={{color:'#445566',fontSize:10,marginTop:1}}>🌐 {lh.ip}</div>}
                    </div>
                    <span style={{color:'#3A5A7A',fontSize:11,flexShrink:0}}>{lh.time?new Date(lh.time).toLocaleString('en-IN',{day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'}):''}</span>
                  </div>
                ))}
              </div>
            </div>
            {/* Activity Logs */}
            <div style={{background:'rgba(0,0,0,0.28)',border:'1px solid rgba(255,255,255,0.06)',borderRadius:14,padding:'16px'}}>
              <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:12}}>
                <div style={{width:28,height:28,background:'rgba(77,159,255,0.14)',borderRadius:7,display:'flex',alignItems:'center',justifyContent:'center',fontSize:14}}>📋</div>
                <div style={{color:'#8AAABF',fontWeight:700,fontSize:12,letterSpacing:0.5}}>Activity Logs ({profileLogs.length})</div>
              </div>
              {profileLogs.length===0&&<div style={{color:'#445566',fontSize:12,textAlign:'center',padding:'14px 0'}}>No activity logs recorded yet</div>}
              <div style={{display:'grid',gap:7}}>
                {(profileLogs as any[]).slice(0,10).map((log:any,i:number)=>(
                  <div key={i} style={{background:'rgba(0,0,0,0.25)',border:'1px solid rgba(255,255,255,0.05)',borderRadius:9,padding:'10px 13px'}}>
                    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',gap:6,flexWrap:'wrap' as const,marginBottom:4}}>
                      <span style={{background:'rgba(0,180,255,0.14)',color:'#00D4FF',borderRadius:6,padding:'2px 9px',fontSize:10,fontWeight:700}}>{log.action||'ACTION'}</span>
                      <span style={{color:'#3A5A7A',fontSize:10}}>{log.createdAt?new Date(log.createdAt).toLocaleString('en-IN',{day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'}):''}</span>
                    </div>
                    {log.details&&<div style={{color:'#6B8FAF',fontSize:11,lineHeight:1.5}}>{log.details}</div>}
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  </div>
)}`;

// ── Build new content ──
const beforeAdmins = content.substring(0, adminsIdx);
const afterPermissions = content.substring(permIdx);

// In afterPermissions: find old archived+modal block and remove it
// Old archived section starts with '\n{/* ===== ARCHIVED ADMINS'
// tab==='permissions'&&( is the boundary
const PERM_COMMENT_LOCAL = `{/* ══ PERMISSIONS ══ */}`;
const PERM_TAB_LOCAL = `tab==='permissions'&&(`;
const permCommentLocal = afterPermissions.indexOf(PERM_COMMENT_LOCAL);
const permTabLocal = afterPermissions.indexOf(PERM_TAB_LOCAL, permCommentLocal);

let newContent;
if (permCommentLocal !== -1 && permTabLocal !== -1) {
  const beforePermComment = afterPermissions.substring(0, permCommentLocal + PERM_COMMENT_LOCAL.length);
  const fromPermTab = afterPermissions.substring(permTabLocal - 1);
  newContent = beforeAdmins
    + NEW_ADMINS
    + '\n\n          '
    + PERM_COMMENT_LOCAL
    + '\n          \n'
    + NEW_MODAL
    + '\n{\n\n'
    + PERM_TAB_LOCAL
    + fromPermTab.substring(PERM_TAB_LOCAL.length);
} else {
  console.warn('⚠️ Partial replacement: old modal block markers not found');
  newContent = beforeAdmins + NEW_ADMINS + '\n\n' + afterPermissions;
}

fs.writeFileSync(filePath, newContent, 'utf8');
console.log('✅ Admin Management Ultra Premium Redesign applied!');
console.log('📊 File size after:', Buffer.byteLength(newContent, 'utf8'), 'bytes');
JSEOF

echo ""
echo "📌 NEXT STEP — Git push karein:"
echo "   cd ~/workspace && git add -A && git commit -m 'feat: Admin Management Ultra Premium SaaS Redesign' && git push"
echo ""
echo "✅ Done!"
