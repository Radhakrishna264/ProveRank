'use client';
import { useState, useEffect, useRef } from 'react';

interface Props { token: string; role: string; API: string; }

export default function AdminProfilePage({ token, role, API }: Props) {
  const [pd, setPd] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState('personal');
  const [edit, setEdit] = useState(false);
  const [stats, setStats] = useState<any>(null);
  const [form, setForm] = useState({name:'',phone:'',city:'',bio:''});
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState('');
  const [pw, setPw] = useState({cur:'',nw:'',cf:''});
  const [pwMsg, setPwMsg] = useState('');
  const fileRef = useRef<HTMLInputElement>(null);
  const isSA = role === 'superadmin';
  const ac = isSA ? '#00B4FF' : '#FFB800';
  const ac2 = isSA ? '#7B2FFF' : '#FF6B35';

  const fetchAll = async () => {
    setLoading(true);
    try {
      const r = await fetch(`${API}/api/admin/manage/profile/me`, { headers: { Authorization: `Bearer ${token}` } });
      const d = await r.json();
      if (d.success) { setPd(d.admin); setForm({ name: d.admin.name||'', phone: d.admin.phone||'', city: d.admin.city||'', bio: d.admin.bio||'' }); }
    } catch(e) {} finally { setLoading(false); }
    try {
      const r2 = await fetch(`${API}/api/admin/manage/profile/stats`, { headers: { Authorization: `Bearer ${token}` } });
      const d2 = await r2.json();
      if (d2.success) setStats(d2.stats);
    } catch(e) {}
  };

  useEffect(() => { fetchAll(); }, []);

  const completion = (() => {
    if (!pd) return 0;
    const f = [pd.name, pd.phone, pd.city, pd.bio, pd.profilePhoto];
    return Math.round((f.filter(x=>x&&String(x).trim()).length / f.length) * 100);
  })();

  const nm = pd?.name || '';
  const initials = nm.split(' ').map((w:string)=>w[0]||'').join('').toUpperCase().slice(0,2) || 'A';
  const adminId = pd?.adminId || '—';
  const lh = pd?.loginHistory || [];
  const lastL = lh[lh.length-1] || {};

  const saveProfile = async () => {
    setSaving(true); setMsg('');
    try {
      const r = await fetch(`${API}/api/admin/manage/profile/me`, { method:'PUT', headers:{'Content-Type':'application/json', Authorization:`Bearer ${token}`}, body: JSON.stringify(form) });
      const d = await r.json();
      setMsg(d.success ? '✅ Saved successfully!' : '❌ '+(d.message||'Failed'));
      if (d.success) { setEdit(false); fetchAll(); setTimeout(()=>setMsg(''),3000); }
    } catch(e) { setMsg('❌ Network error'); } finally { setSaving(false); }
  };

  const changePw = async () => {
    if (pw.nw !== pw.cf) { setPwMsg('❌ Passwords do not match'); return; }
    if (pw.nw.length < 6) { setPwMsg('❌ Min 6 characters'); return; }
    try {
      const r = await fetch(`${API}/api/auth/change-password`, { method:'PUT', headers:{'Content-Type':'application/json', Authorization:`Bearer ${token}`}, body: JSON.stringify({ currentPassword: pw.cur, newPassword: pw.nw }) });
      const d = await r.json();
      const ok = d.success || (d.message&&d.message.toLowerCase().includes('updat'));
      setPwMsg(ok ? '✅ Password updated!' : '❌ '+(d.message||'Failed'));
      if (ok) setPw({ cur:'', nw:'', cf:'' });
    } catch(e) { setPwMsg('❌ Error'); }
    setTimeout(() => setPwMsg(''), 4000);
  };

  const uploadPhoto = async (file: File) => {
    const reader = new FileReader();
    reader.onload = async (e) => {
      const b64 = e.target?.result as string;
      try {
        const r = await fetch(`${API}/api/admin/manage/profile/photo`, { method:'POST', headers:{'Content-Type':'application/json', Authorization:`Bearer ${token}`}, body: JSON.stringify({ photoBase64: b64 }) });
        const d = await r.json();
        if (d.success) fetchAll();
      } catch(er) {}
    };
    reader.readAsDataURL(file);
  };

  const glassCard = (extra?: object) => ({
    background: 'rgba(10,15,35,0.6)',
    backdropFilter: 'blur(16px)',
    WebkitBackdropFilter: 'blur(16px)',
    border: `1px solid rgba(${isSA?'0,180,255':'255,184,0'},0.18)`,
    borderRadius: 20,
    ...extra
  });

  const inp = { width:'100%', background:'rgba(255,255,255,0.06)', border:'1px solid rgba(255,255,255,0.12)', borderRadius:10, padding:'10px 14px', color:'#E8F4FF', fontSize:13, outline:'none', boxSizing:'border-box' as const, transition:'border 0.2s' };

  // ── Praveen Signature SVG ──
  const PraveenSVG = () => (
    <svg viewBox="0 0 320 175" style={{width:'100%',height:'100%',filter:`drop-shadow(0 0 10px ${ac}99)`}} xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="psg" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#00B4FF"/><stop offset="100%" stopColor="#7B2FFF"/>
        </linearGradient>
      </defs>
      {/* P — tall vertical stroke */}
      <path d="M108,18 L108,158 Q107,168 103,174" stroke="url(#psg)" strokeWidth="2.8" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
      {/* P — left decorative oval loop */}
      <path d="M108,82 Q60,58 62,98 Q63,135 108,118" stroke="url(#psg)" strokeWidth="2.2" fill="none" strokeLinecap="round"/>
      {/* Outer encircling ellipse around 'raveen' */}
      <ellipse cx="205" cy="97" rx="80" ry="31" stroke="url(#psg)" strokeWidth="1.8" fill="none" transform="rotate(-4 205 97)" opacity="0.85"/>
      {/* raveen in cursive */}
      <text x="138" y="106" fontFamily="'Dancing Script','Brush Script MT',cursive" fontSize="36" fill="url(#psg)" transform="rotate(-3 138 106)" letterSpacing="1.5">raveen</text>
      {/* Double diagonal strokes after ellipse */}
      <line x1="282" y1="87" x2="298" y2="81" stroke="url(#psg)" strokeWidth="2.2" strokeLinecap="round"/>
      <line x1="283" y1="94" x2="296" y2="89" stroke="url(#psg)" strokeWidth="1.8" strokeLinecap="round"/>
      {/* Two dots */}
      <circle cx="302" cy="80" r="2.8" fill="#00B4FF"/>
      <circle cx="300" cy="90" r="2.8" fill="#7B2FFF"/>
      {/* Bottom tail curl from P */}
      <path d="M105,145 Q110,158 125,163 Q138,167 133,175" stroke="url(#psg)" strokeWidth="2" fill="none" strokeLinecap="round"/>
    </svg>
  );

  // ── Dynamic Admin Signature ──
  const AdminSVG = ({ name }: { name: string }) => (
    <svg viewBox="0 0 320 120" style={{width:'100%',height:'100%',filter:`drop-shadow(0 0 8px ${ac}88)`}} xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="asg" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stopColor="#FFB800"/><stop offset="100%" stopColor="#FF6B35"/>
        </linearGradient>
      </defs>
      <ellipse cx="160" cy="62" rx="120" ry="36" stroke="url(#asg)" strokeWidth="1.6" fill="none" opacity="0.7"/>
      <text x="160" y="72" fontFamily="'Dancing Script','Brush Script MT',cursive" fontSize="42" fill="url(#asg)" textAnchor="middle" letterSpacing="2">{name}</text>
      <line x1="55" y1="86" x2="265" y2="86" stroke="url(#asg)" strokeWidth="1.5" opacity="0.5"/>
      <line x1="75" y1="92" x2="245" y2="92" stroke="url(#asg)" strokeWidth="1" opacity="0.3"/>
      {/* Decorative dots */}
      <circle cx="270" cy="86" r="2.5" fill="#FFB800" opacity="0.8"/>
      <circle cx="278" cy="89" r="2" fill="#FF6B35" opacity="0.7"/>
    </svg>
  );

  if (loading) return (
    <div style={{display:'flex',alignItems:'center',justifyContent:'center',height:400,flexDirection:'column',gap:16}}>
      <div style={{width:48,height:48,borderRadius:'50%',border:`3px solid ${ac}`,borderTopColor:'transparent',animation:'spin 0.8s linear infinite'}}/>
      <div style={{color:ac,fontSize:14,fontWeight:600,letterSpacing:1}}>Loading Profile...</div>
      <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
    </div>
  );

  return (
    <div style={{paddingBottom:40}}>
      {/* ── SIGNATURE BANNER ── */}
      <div style={{...glassCard({padding:'20px 24px 18px',marginBottom:28,textAlign:'center' as const})}}>
        <div style={{color:`${ac}66`,fontSize:10,letterSpacing:3,textTransform:'uppercase' as const,marginBottom:10,fontWeight:700}}>
          {isSA ? '— SuperAdmin Signature —' : '— Admin Signature —'}
        </div>
        <div style={{height:130,maxWidth:340,margin:'0 auto'}}>
          {isSA ? <PraveenSVG/> : <AdminSVG name={nm.split(' ')[0]||'Admin'}/>}
        </div>
      </div>

      {/* ── SPLIT LAYOUT ── */}
      <div style={{display:'grid',gridTemplateColumns:'clamp(240px,28%,300px) 1fr',gap:20}}>

        {/* ═══ LEFT PANEL ═══ */}
        <div style={{display:'flex',flexDirection:'column' as const,gap:14}}>

          {/* Avatar Card */}
          <div style={{...glassCard({padding:'28px 18px 22px',textAlign:'center' as const})}}>
            {/* Avatar with glow ring */}
            <div style={{position:'relative' as const,display:'inline-block',marginBottom:18}}>
              <div style={{
                width:98,height:98,borderRadius:'50%',padding:3,
                background:`linear-gradient(135deg,${ac},${ac2})`,
                boxShadow:`0 0 25px ${ac}55`,
                animation:'ringGlow 2s ease-in-out infinite alternate'
              }}>
                <div style={{width:'100%',height:'100%',borderRadius:'50%',background:'rgba(8,12,28,0.92)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:34,fontWeight:900,color:ac,overflow:'hidden'}}>
                  {pd?.profilePhoto
                    ? <img src={pd.profilePhoto} alt="" style={{width:'100%',height:'100%',objectFit:'cover' as const,borderRadius:'50%'}}/>
                    : initials}
                </div>
              </div>
              <button onClick={()=>fileRef.current?.click()} title="Upload Photo" style={{position:'absolute' as const,bottom:2,right:2,width:28,height:28,borderRadius:'50%',border:'none',cursor:'pointer',background:ac,display:'flex',alignItems:'center',justifyContent:'center',fontSize:13,boxShadow:'0 2px 8px rgba(0,0,0,0.5)'}}>📷</button>
              <input ref={fileRef} type="file" accept="image/*" style={{display:'none'}} onChange={e=>{const f=e.target.files?.[0];if(f)uploadPhoto(f);}}/>
            </div>

            {/* Name */}
            <div style={{color:'#ECF4FF',fontSize:18,fontWeight:700,marginBottom:8,letterSpacing:0.5}}>{nm||'Admin'}</div>

            {/* Admin ID — neon pulsing badge */}
            <div style={{display:'inline-block',background:`rgba(${isSA?'0,180,255':'255,184,0'},0.1)`,border:`1px solid ${ac}66`,borderRadius:20,padding:'4px 15px',fontSize:12,color:ac,fontWeight:700,letterSpacing:1.2,marginBottom:8,animation:'idPulse 2.5s ease-in-out infinite'}}>
              🪪 {adminId}
            </div>

            {/* Role chip */}
            <div style={{display:'block',marginBottom:10}}>
              <span style={{background:`rgba(${isSA?'123,47,255':'0,196,140'},0.15)`,border:`1px solid ${ac2}55`,borderRadius:20,padding:'3px 14px',fontSize:11,color:ac2,fontWeight:700,letterSpacing:1}}>
                {isSA?'👑 SUPERADMIN':'⚡ ADMIN'}
              </span>
            </div>

            {/* Status dot */}
            <div style={{fontSize:12,color:pd?.adminFrozen?'#FF6B35':'#00C48C',display:'flex',alignItems:'center',justifyContent:'center',gap:5,marginBottom:16}}>
              <span style={{width:7,height:7,borderRadius:'50%',background:pd?.adminFrozen?'#FF6B35':'#00C48C',display:'inline-block',animation:'blink 1.5s infinite'}}/>
              {pd?.adminFrozen ? '🔒 Account Frozen' : '● Active'}
            </div>

            {/* Profile Completion */}
            <div style={{textAlign:'left' as const}}>
              <div style={{display:'flex',justifyContent:'space-between',fontSize:11,color:'rgba(255,255,255,0.45)',marginBottom:5}}>
                <span>Profile Completion</span>
                <span style={{color:ac,fontWeight:700}}>{completion}%</span>
              </div>
              <div style={{background:'rgba(255,255,255,0.08)',borderRadius:10,height:7,overflow:'hidden'}}>
                <div style={{width:`${completion}%`,height:'100%',borderRadius:10,background:`linear-gradient(90deg,${ac},${ac2})`,transition:'width 1s ease',boxShadow:`0 0 8px ${ac}66`}}/>
              </div>
            </div>
          </div>

          {/* Stats Card */}
          <div style={glassCard({padding:'16px 15px'})}>
            <div style={{color:'rgba(255,255,255,0.4)',fontSize:10,letterSpacing:2.5,fontWeight:700,marginBottom:12,textTransform:'uppercase' as const}}>📊 Overview</div>
            {[
              {label:'Exams Created',val:stats?.examsCreated??'—',icon:'📝',c:'#4D9FFF'},
              {label:'Total Students',val:stats?.studentsCount??'—',icon:'👥',c:'#00C48C'},
              {label:'Days Active',val:stats?.daysActive??'—',icon:'📅',c:'#FFB800'},
              {label:'Total Logins',val:stats?.totalLogins??lh.length,icon:'🔑',c:'#B97FFF'},
            ].map(s=>(
              <div key={s.label} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'8px 0',borderBottom:'1px solid rgba(255,255,255,0.05)'}}>
                <span style={{color:'rgba(255,255,255,0.5)',fontSize:12}}>{s.icon} {s.label}</span>
                <span style={{color:s.c,fontSize:14,fontWeight:700}}>{s.val}</span>
              </div>
            ))}
          </div>

          {/* Quick Info */}
          <div style={glassCard({padding:'14px 15px'})}>
            {[
              {icon:'📧',val:pd?.email||'—'},
              {icon:'📞',val:pd?.phone||'Not set'},
              {icon:'🏙️',val:pd?.city||'Not set'},
              {icon:'📅',val:pd?.createdAt?new Date(pd.createdAt).toLocaleDateString('en-IN'):'—'},
              {icon:'🔐',val:pd?.twoFactorEnabled?'2FA: ON':'2FA: OFF'},
            ].map((c,i)=>(
              <div key={i} style={{display:'flex',gap:10,padding:'6px 0',borderBottom:i<4?'1px solid rgba(255,255,255,0.05)':'none',alignItems:'center'}}>
                <span style={{fontSize:14,flexShrink:0}}>{c.icon}</span>
                <span style={{color:'rgba(255,255,255,0.6)',fontSize:12,wordBreak:'break-all' as const}}>{c.val}</span>
              </div>
            ))}
          </div>
        </div>

        {/* ═══ RIGHT PANEL ═══ */}
        <div style={{...glassCard({overflow:'hidden',padding:0})}}>
          {/* Tab Header */}
          <div style={{display:'flex',borderBottom:'1px solid rgba(255,255,255,0.07)',background:'rgba(0,0,0,0.25)',overflowX:'auto' as const}}>
            {[
              {k:'personal',l:'👤 Personal'},
              {k:'security',l:'🔐 Security'},
              {k:'activity',l:'📊 Activity'},
              {k:'permissions',l:'🔑 Permissions'},
            ].map(t=>(
              <button key={t.k} onClick={()=>setTab(t.k)} style={{
                background:'none',border:'none',cursor:'pointer',whiteSpace:'nowrap' as const,
                padding:'15px 20px',fontSize:13,fontWeight:600,letterSpacing:0.4,
                color:tab===t.k?ac:'rgba(255,255,255,0.38)',
                borderBottom:tab===t.k?`2px solid ${ac}`:'2px solid transparent',
                transition:'all 0.25s',flexShrink:0
              }}>{t.l}</button>
            ))}
          </div>

          <div style={{padding:24}}>

            {/* ── PERSONAL TAB ── */}
            {tab==='personal'&&(
              <div>
                <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:22}}>
                  <div style={{color:'#ECF4FF',fontSize:16,fontWeight:700}}>Personal Information</div>
                  <button onClick={()=>{setEdit(!edit);setMsg('');}} style={{background:edit?'rgba(255,77,77,0.12)':'rgba(0,180,255,0.1)',border:`1px solid ${edit?'rgba(255,77,77,0.35)':ac+'44'}`,borderRadius:10,padding:'7px 18px',color:edit?'#FF6B6B':ac,cursor:'pointer',fontSize:12,fontWeight:700,transition:'all 0.2s'}}>
                    {edit?'✕ Cancel':'✏️ Edit Profile'}
                  </button>
                </div>

                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:16,marginBottom:16}}>
                  {[
                    {label:'Full Name',key:'name',icon:'👤'},
                    {label:'Phone',key:'phone',icon:'📞'},
                    {label:'City',key:'city',icon:'🏙️'},
                    {label:'Bio',key:'bio',icon:'📝',full:true},
                  ].map(f=>(
                    <div key={f.key} style={{gridColumn:f.full?'1 / -1':'auto'}}>
                      <div style={{color:'rgba(255,255,255,0.4)',fontSize:11,marginBottom:6,letterSpacing:1.2,textTransform:'uppercase' as const}}>{f.icon} {f.label}</div>
                      {edit
                        ? f.key==='bio'
                          ? <textarea value={(form as any)[f.key]} onChange={e=>setForm({...form,[f.key]:e.target.value})} rows={3} style={{...inp,resize:'none' as const,fontFamily:'inherit'}}/>
                          : <input value={(form as any)[f.key]} onChange={e=>setForm({...form,[f.key]:e.target.value})} style={inp}/>
                        : <div style={{background:'rgba(255,255,255,0.04)',borderRadius:10,padding:'10px 14px',color:'#E2ECFF',fontSize:13,minHeight:40,display:'flex',alignItems:'center'}}>
                            {(pd as any)?.[f.key]||<span style={{color:'rgba(255,255,255,0.22)'}}>Not set</span>}
                          </div>
                      }
                    </div>
                  ))}
                </div>

                {/* Read-only info grid */}
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12}}>
                  {[
                    {l:'Email',v:pd?.email||'—',i:'📧'},
                    {l:'Admin ID',v:adminId,i:'🪪'},
                    {l:'Role',v:(pd?.role||'').toUpperCase(),i:'🎭'},
                    {l:'Joined',v:pd?.createdAt?new Date(pd.createdAt).toLocaleDateString('en-IN'):'—',i:'📅'},
                    {l:'2FA',v:pd?.twoFactorEnabled?'✅ Enabled':'❌ Disabled',i:'🛡️'},
                    {l:'Login Count',v:`${lh.length} sessions`,i:'🔥'},
                  ].map(f=>(
                    <div key={f.l}>
                      <div style={{color:'rgba(255,255,255,0.35)',fontSize:10,marginBottom:5,letterSpacing:1.2,textTransform:'uppercase' as const}}>{f.i} {f.l}</div>
                      <div style={{background:'rgba(255,255,255,0.04)',borderRadius:10,padding:'9px 13px',color:'rgba(230,240,255,0.7)',fontSize:12,fontWeight:500}}>{f.v}</div>
                    </div>
                  ))}
                </div>

                {edit&&(
                  <div style={{marginTop:22,display:'flex',gap:12,alignItems:'center',flexWrap:'wrap' as const}}>
                    <button onClick={saveProfile} disabled={saving} style={{background:`linear-gradient(135deg,${ac},${ac2})`,border:'none',borderRadius:12,padding:'11px 30px',color:'#fff',cursor:saving?'not-allowed':'pointer',fontWeight:700,fontSize:14,boxShadow:`0 4px 18px ${ac}44`,opacity:saving?0.7:1,transition:'all 0.2s'}}>
                      {saving?'💾 Saving...':'💾 Save Changes'}
                    </button>
                    {msg&&<span style={{fontSize:13,fontWeight:600,color:msg.includes('✅')?'#00C48C':'#FF6B6B'}}>{msg}</span>}
                  </div>
                )}
              </div>
            )}

            {/* ── SECURITY TAB ── */}
{tab==='security'&&(
              <div>
                <div style={{color:'#ECF4FF',fontSize:16,fontWeight:700,marginBottom:20}}>🔐 Security Settings</div>
                
                <div style={{background:'rgba(255,255,255,0.03)',borderRadius:16,padding:20,border:'1px solid rgba(255,255,255,0.07)',marginBottom:18}}>
                  <div style={{color:ac,fontSize:14,fontWeight:700,marginBottom:16}}>🔑 Change Password</div>
                  {[['cur','Current Password'],['nw','New Password'],['cf','Confirm New Password']].map(([k,lbl])=>(
                    <div key={k} style={{marginBottom:13}}>
                      <div style={{color:'rgba(255,255,255,0.4)',fontSize:11,marginBottom:5,textTransform:'uppercase' as const,letterSpacing:1}}>{lbl}</div>
                      <input type="password" value={(pw as any)[k]} onChange={e=>setPw({...pw,[k]:e.target.value})} style={inp} placeholder="••••••••"/>
                    </div>
                  ))}
                  <button onClick={changePw} style={{background:`rgba(${isSA?'0,180,255':'255,184,0'},0.12)`,border:`1px solid ${ac}44`,borderRadius:10,padding:'10px 24px',color:ac,cursor:'pointer',fontWeight:700,fontSize:13,transition:'all 0.2s'}}>🔑 Update Password</button>
                  {pwMsg&&<div style={{marginTop:10,fontSize:13,fontWeight:600,color:pwMsg.includes('✅')?'#00C48C':'#FF6B6B'}}>{pwMsg}</div>}
                </div>

                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12}}>
                  {[
                    {title:'2FA Status',val:pd?.twoFactorEnabled?'✅ Enabled':'❌ Disabled',icon:'🛡️',c:pd?.twoFactorEnabled?'#00C48C':'#FF6B35'},
                    {title:'Active Sessions',val:`${lh.length} recorded`,icon:'💻',c:'#4D9FFF'},
                    {title:'Last Login City',val:lastL.city||'—',icon:'📍',c:'#FFB800'},
                    {title:'Last Device',val:lastL.device||'Unknown',icon:'📱',c:'#B97FFF'},
                    {title:'Last Login IP',val:lastL.ip||'—',icon:'🌐',c:'#00C48C'},
                    {title:'Account Status',val:pd?.adminFrozen?'🔒 Frozen':'✅ Active',icon:'🔰',c:pd?.adminFrozen?'#FF6B35':'#00C48C'},
                  ].map(s=>(
                    <div key={s.title} style={{background:'rgba(255,255,255,0.03)',borderRadius:14,padding:'15px 14px',border:'1px solid rgba(255,255,255,0.06)',transition:'border 0.2s'}}>
                      <div style={{fontSize:22,marginBottom:6}}>{s.icon}</div>
                      <div style={{color:'rgba(255,255,255,0.4)',fontSize:10,marginBottom:4,textTransform:'uppercase' as const,letterSpacing:1}}>{s.title}</div>
                      <div style={{color:s.c,fontSize:13,fontWeight:700}}>{s.val}</div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* ── ACTIVITY TAB ── */}
            {tab==='activity'&&(
              <div>
                <div style={{color:'#ECF4FF',fontSize:16,fontWeight:700,marginBottom:20}}>📊 Activity Overview</div>
                <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:12,marginBottom:20}}>
                  {[
                    {label:'Total Logins',val:stats?.totalLogins??lh.length,icon:'🔑',c:ac},
                    {label:'Days Active',val:stats?.daysActive??'—',icon:'📅',c:'#FFB800'},
                    {label:'Exams Created',val:stats?.examsCreated??'—',icon:'📝',c:'#00C48C'},
                  ].map(s=>(
                    <div key={s.label} style={{background:'rgba(255,255,255,0.04)',borderRadius:16,padding:'18px 12px',textAlign:'center' as const,border:'1px solid rgba(255,255,255,0.06)'}}>
                      <div style={{fontSize:26,marginBottom:8}}>{s.icon}</div>
                      <div style={{color:s.c,fontSize:26,fontWeight:800,lineHeight:1}}>{s.val}</div>
                      <div style={{color:'rgba(255,255,255,0.38)',fontSize:11,marginTop:5,letterSpacing:0.5}}>{s.label}</div>
                    </div>
                  ))}
                </div>
                <div style={{background:'rgba(255,255,255,0.03)',borderRadius:16,padding:18,border:'1px solid rgba(255,255,255,0.06)'}}>
                  <div style={{color:'rgba(255,255,255,0.55)',fontSize:13,fontWeight:700,marginBottom:14}}>🕐 Login History</div>
                  {lh.length===0
                    ? <div style={{color:'rgba(255,255,255,0.25)',textAlign:'center' as const,padding:'24px 0',fontSize:13}}>No login history yet</div>
                    : [...lh].reverse().slice(0,8).map((l:any,i:number)=>(
                      <div key={i} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'9px 0',borderBottom:i<7?'1px solid rgba(255,255,255,0.04)':'none'}}>
                        <div>
                          <div style={{color:'#E2ECFF',fontSize:13,fontWeight:500}}>{l.city||'Unknown Location'}</div>
                          <div style={{color:'rgba(255,255,255,0.3)',fontSize:11,marginTop:2}}>{l.device||'Unknown Device'} {l.ip?`• ${l.ip}`:''}</div>
                        </div>
                        <div style={{color:'rgba(255,255,255,0.35)',fontSize:11,textAlign:'right' as const,flexShrink:0,marginLeft:12}}>
                          {l.loginAt?new Date(l.loginAt).toLocaleDateString('en-IN'):l.timestamp?new Date(l.timestamp).toLocaleDateString('en-IN'):'—'}
                        </div>
                      </div>
                    ))
                  }
                </div>
              </div>
            )}

            {/* ── PERMISSIONS TAB ── */}
            {tab==='permissions'&&(
              <div>
                <div style={{color:'#ECF4FF',fontSize:16,fontWeight:700,marginBottom:20}}>🔑 Permissions & Access</div>
                {isSA?(
                  <div style={{background:`linear-gradient(135deg,rgba(0,180,255,0.08),rgba(123,47,255,0.08))`,border:'1px solid rgba(0,180,255,0.25)',borderRadius:18,padding:'28px 24px',textAlign:'center' as const}}>
                    <div style={{fontSize:52,marginBottom:14}}>👑</div>
                    <div style={{color:'#00B4FF',fontSize:17,fontWeight:800,marginBottom:8}}>SuperAdmin — Unrestricted Access</div>
                    <div style={{color:'rgba(255,255,255,0.45)',fontSize:13,marginBottom:20,lineHeight:1.6}}>All platform permissions are permanently enabled. You have complete control.</div>
                    <div style={{display:'flex',flexWrap:'wrap' as const,gap:8,justifyContent:'center' as const}}>
                      {['Exam Management','Question Bank','Student Mgmt','Result Control','Analytics','Communication','System Admin','Branding & SEO','Backup & Restore','Feature Flags','Audit Logs','SuperAdmin Panel'].map(p=>(
                        <span key={p} style={{background:'rgba(0,180,255,0.08)',border:'1px solid rgba(0,180,255,0.22)',borderRadius:20,padding:'5px 14px',color:'#00B4FF',fontSize:11,fontWeight:600}}>✅ {p}</span>
                      ))}
                    </div>
                  </div>
                ):(
                  <div>
                    <div style={{marginBottom:14,color:'rgba(255,255,255,0.45)',fontSize:13}}>Permissions assigned by SuperAdmin:</div>
                    {pd?.permissions&&Object.keys(pd.permissions).length>0
                      ? <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                          {Object.entries(pd.permissions).map(([k,v])=>(
                            <div key={k} style={{background:v?'rgba(0,196,140,0.07)':'rgba(255,77,77,0.05)',border:`1px solid ${v?'rgba(0,196,140,0.2)':'rgba(255,77,77,0.15)'}`,borderRadius:10,padding:'10px 14px',display:'flex',alignItems:'center',gap:8}}>
                              <span style={{fontSize:16}}>{v?'✅':'❌'}</span>
                              <span style={{color:v?'rgba(255,255,255,0.7)':'rgba(255,255,255,0.35)',fontSize:12,fontWeight:500}}>{k.replace(/_/g,' ').replace(/\b\w/g,(c:string)=>c.toUpperCase())}</span>
                            </div>
                          ))}
                        </div>
                      : <div style={{color:'rgba(255,255,255,0.28)',textAlign:'center' as const,padding:'32px 0',fontSize:13}}>No permissions assigned. Contact SuperAdmin.</div>
                    }
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>

      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Dancing+Script:wght@700&display=swap');
        @keyframes ringGlow { from{box-shadow:0 0 15px ${ac}44} to{box-shadow:0 0 30px ${ac}88,0 0 50px ${ac}33} }
        @keyframes idPulse { 0%,100%{box-shadow:0 0 6px ${ac}44} 50%{box-shadow:0 0 18px ${ac}88,0 0 30px ${ac}44} }
        @keyframes blink { 0%,100%{opacity:1} 50%{opacity:0.3} }
      `}</style>
    </div>
  );
}
