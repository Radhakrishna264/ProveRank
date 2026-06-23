#!/bin/bash
# ╔══════════════════════════════════════════════════════════╗
# ║  ProveRank — Question Card Ultra Premium Redesign       ║
# ╚══════════════════════════════════════════════════════════╝
set -e
FILE=/home/runner/workspace/frontend/app/admin/x7k2p/PreviewAllQuestions.tsx
echo "🎨 Ultra Premium Card Redesign..."

node << 'ENDOFSCRIPT'
const fs = require('fs');
const file = '/home/runner/workspace/frontend/app/admin/x7k2p/PreviewAllQuestions.tsx';
let c = fs.readFileSync(file, 'utf8');

// ── Find exact start and end of the card map block ───────────────────────────
const CARD_START = `            {pagedQs.map((q:any,qi:number)=>{`;
const CARD_END   = `          </div>\n        )}\n\n        {/* ══════════ PAGINATION BOTTOM`;

const si = c.indexOf(CARD_START);
const ei = c.indexOf(CARD_END);
if (si === -1 || ei === -1) {
  console.log('❌ Could not find card boundaries');
  console.log('Start:', si, 'End:', ei);
  process.exit(1);
}

// ── New ultra premium card code ───────────────────────────────────────────────
const NEW_CARDS = `            {/* ══ CSS for card animations ══ */}
            <style dangerouslySetInnerHTML={{__html:\`
              .qcard{transition:all 0.22s cubic-bezier(0.4,0,0.2,1);}
              .qcard:hover{transform:translateY(-1px);}
              .qact-btn{transition:all 0.18s ease;}
              .qact-btn:hover{transform:scale(1.12);}
              .del-btn{opacity:0;transition:all 0.18s ease;}
              .qcard:hover .del-btn,.del-btn:focus{opacity:1;}
              @keyframes fadeSlideIn{from{opacity:0;transform:translateY(6px)}to{opacity:1;transform:translateY(0)}}
              .qcard{animation:fadeSlideIn 0.25s ease both;}
            \`}}/>

            {pagedQs.map((q:any,qi:number)=>{
              const isChk = bulkSel.includes(q._id)
              const usedIn = (exams||[]).filter((e:any)=>(e.questionIds||e.questions||[]).includes(q._id)).length
              const sc = sColor(q.subject||'')
              const dc = dColor(q.difficulty||'')
              const qNum = _fQsSorted.length-((_qPg-1)*25+qi)
              const qText = qLang==='hi'&&q.hindiText?q.hindiText:q.text||''
              const isPending = q.approvalStatus==='pending'||!q.approvalStatus
              const isRejected = q.approvalStatus==='rejected'
              const ltrs=['A','B','C','D']
              const ci = Array.isArray(q.correct)&&q.correct.length>0?q.correct[0]:(q.correctAnswer?ltrs.indexOf(q.correctAnswer):0)

              return(
                <div key={q._id||qi} className="qcard" style={{
                  position:'relative',
                  background: isChk
                    ? \`linear-gradient(135deg,\${sc}08,rgba(0,18,40,0.95))\`
                    : 'linear-gradient(135deg,rgba(5,18,40,0.92),rgba(2,12,32,0.97))',
                  border: \`1px solid \${isChk?sc+'55':sc+'18'}\`,
                  borderRadius:16,
                  overflow:'hidden',
                  boxShadow: isChk
                    ? \`0 0 0 2px \${sc}33, 0 6px 24px \${sc}14\`
                    : \`0 2px 12px rgba(0,0,0,0.3)\`,
                  animationDelay:\`\${qi*0.04}s\`
                }}>

                  {/* ── Left subject glow strip ────────────────────────── */}
                  <div style={{
                    position:'absolute',top:0,left:0,bottom:0,width:4,
                    background:\`linear-gradient(180deg,\${sc},\${sc}44)\`,
                    borderRadius:'16px 0 0 16px'
                  }}/>

                  {/* ── Top accent line (selected) ─────────────────────── */}
                  {isChk&&<div style={{position:'absolute',top:0,left:4,right:0,height:2,background:\`linear-gradient(90deg,\${sc}88,transparent)\`}}/>}

                  {/* ── CARD BODY ──────────────────────────────────────── */}
                  <div style={{padding:'13px 12px 11px 16px'}}>

                    {/* ── ROW 1: Checkbox · Q# · Badges · Status ────────── */}
                    <div style={{display:'flex',alignItems:'center',gap:7,marginBottom:9,flexWrap:'wrap' as any}}>

                      {/* Checkbox */}
                      <input type='checkbox' checked={isChk}
                        onChange={e=>{if(e.target.checked)setBulkSel((p:string[])=>[...p,q._id]);else setBulkSel((p:string[])=>p.filter((x:string)=>x!==q._id))}}
                        style={{cursor:'pointer',accentColor:sc,width:14,height:14,flexShrink:0,marginRight:2}}/>

                      {/* Q Number badge */}
                      <div style={{
                        background:\`linear-gradient(135deg,\${sc},\${sc}88)\`,
                        color:'#fff',fontSize:10,fontWeight:900,
                        borderRadius:8,padding:'3px 9px',flexShrink:0,letterSpacing:0.3,
                        boxShadow:\`0 2px 8px \${sc}44\`
                      }}>#{qNum}</div>

                      {/* Subject */}
                      <span style={{background:\`\${sc}12\`,border:\`1px solid \${sc}30\`,color:sc,borderRadius:8,padding:'2px 8px',fontSize:10,fontWeight:700,letterSpacing:0.2}}>{q.subject||'General'}</span>

                      {/* Difficulty */}
                      <span style={{background:\`\${dc}10\`,border:\`1px solid \${dc}30\`,color:dc,borderRadius:8,padding:'2px 8px',fontSize:10,fontWeight:600}}>{q.difficulty||'?'}</span>

                      {/* Type */}
                      <span style={{background:'rgba(148,163,184,0.08)',border:'1px solid rgba(148,163,184,0.2)',color:'#94A3B8',borderRadius:8,padding:'2px 8px',fontSize:10,fontWeight:500}}>{q.type||'SCQ'}</span>

                      {/* Used in exams */}
                      {usedIn>0&&(
                        <span style={{background:'rgba(96,165,250,0.1)',border:'1px solid rgba(96,165,250,0.25)',color:'#60A5FA',borderRadius:8,padding:'2px 8px',fontSize:10,fontWeight:600,display:'flex',alignItems:'center',gap:3}}>
                          <span style={{width:5,height:5,borderRadius:'50%',background:'#60A5FA',display:'inline-block'}}/>
                          {usedIn} exam{usedIn>1?'s':''}
                        </span>
                      )}

                      {/* Approval status */}
                      {isPending&&(
                        <span style={{background:'rgba(251,191,36,0.08)',border:'1px solid rgba(251,191,36,0.25)',color:'#FBBF24',borderRadius:8,padding:'2px 8px',fontSize:9,fontWeight:700,letterSpacing:0.3,textTransform:'uppercase' as any}}>⏳ pending</span>
                      )}
                      {isRejected&&(
                        <span style={{background:'rgba(255,77,77,0.08)',border:'1px solid rgba(255,77,77,0.25)',color:'#FF4D4D',borderRadius:8,padding:'2px 8px',fontSize:9,fontWeight:700,letterSpacing:0.3,textTransform:'uppercase' as any}}>✕ rejected</span>
                      )}
                    </div>

                    {/* ── ROW 2: Question Text ───────────────────────────── */}
                    <div
                      onClick={()=>{if(longPressFiredRef.current){longPressFiredRef.current=false;return}setSelQId(q._id)}}
                      onTouchStart={()=>{longPressFiredRef.current=false;longPressTimerRef.current=setTimeout(()=>{longPressFiredRef.current=true;setBulkSel((p:string[])=>p.includes(q._id)?p.filter((x:string)=>x!==q._id):[...p,q._id]);if(navigator.vibrate)navigator.vibrate(30)},500)}}
                      onTouchEnd={()=>clearTimeout(longPressTimerRef.current)}
                      onTouchMove={()=>clearTimeout(longPressTimerRef.current)}
                      onContextMenu={e=>{e.preventDefault();setBulkSel((p:string[])=>p.includes(q._id)?p.filter((x:string)=>x!==q._id):[...p,q._id])}}
                      style={{
                        cursor:'pointer',
                        fontSize:13.5,
                        color:'#D1E0F5',
                        lineHeight:1.65,
                        fontFamily:'Inter,sans-serif',
                        fontWeight:450,
                        letterSpacing:0.1,
                        marginBottom:8,
                        display:'-webkit-box' as any,
                        WebkitLineClamp:3,
                        WebkitBoxOrient:'vertical' as any,
                        overflow:'hidden',
                        WebkitUserSelect:'none' as any,
                        userSelect:'none' as any,
                      }}>
                      {qText}
                    </div>

                    {/* Hindi pending indicator */}
                    {qLang==='hi'&&!q.hindiText&&(
                      <div style={{display:'flex',alignItems:'center',gap:5,marginBottom:6}}>
                        <div style={{width:4,height:4,borderRadius:'50%',background:'#818CF8',animation:'pulse 1.5s ease infinite'}}/>
                        <span style={{fontSize:9,color:'#818CF8',fontWeight:500}}>हिंदी अनुवाद प्रतीक्षा में...</span>
                      </div>
                    )}

                    {/* ── ROW 3: Chapter breadcrumb ──────────────────────── */}
                    {(q.chapter||q.topic)&&(
                      <div style={{display:'flex',alignItems:'center',gap:4,marginBottom:9}}>
                        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#6B8FAF" strokeWidth="2"><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/></svg>
                        <span style={{fontSize:10,color:'#6B8FAF',letterSpacing:0.2}}>
                          {[q.chapter,q.topic].filter(Boolean).join(' › ')}
                        </span>
                      </div>
                    )}

                    {/* ── Options (student preview mode) ────────────────── */}
                    {stdPrv&&(q.options||[]).length>0&&(
                      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:5,marginBottom:10}}>
                        {(q.options||[]).map((opt:string,oi:number)=>{
                          const ltr=String.fromCharCode(65+oi)
                          const cIdx=Array.isArray(q.correct)?q.correct:q.correct!==undefined?[q.correct]:[]
                          const isC=cIdx.includes(oi)||(q.correctAnswer&&q.correctAnswer===ltr)
                          const optText=((qLang==='hi'&&(q.hindiOptions||[])[oi])?q.hindiOptions[oi]:opt||'').replace(/^[A-Da-d][\\.\\)\\:]\\s*/,'').trim()
                          return(
                            <div key={oi} style={{
                              padding:'5px 8px',borderRadius:8,fontSize:10,
                              border:\`1px solid \${isC?'rgba(0,196,140,0.4)':'rgba(255,255,255,0.05)'}\`,
                              background:isC?'rgba(0,196,140,0.08)':'rgba(255,255,255,0.02)',
                              color:isC?'#00C48C':'#7B8FA8',
                              display:'flex',alignItems:'flex-start',gap:5
                            }}>
                              <span style={{fontWeight:800,color:isC?'#00C48C':'#4D9FFF',flexShrink:0,fontSize:9,marginTop:1}}>{ltr}</span>
                              <span style={{lineHeight:1.4}}>{optText.slice(0,40)}{optText.length>40?'…':''}</span>
                              {isC&&<span style={{marginLeft:'auto',flexShrink:0}}>✓</span>}
                            </div>
                          )
                        })}
                      </div>
                    )}

                    {/* ── ROW 4: Bottom action bar ───────────────────────── */}
                    <div style={{
                      display:'flex',alignItems:'center',gap:5,
                      paddingTop:8,
                      borderTop:'1px solid rgba(255,255,255,0.04)',
                      marginTop:2
                    }}>
                      {/* Left: quick info */}
                      <div style={{flex:1,display:'flex',gap:6,alignItems:'center'}}>
                        {q.level&&<span style={{fontSize:9,color:'#475569',background:'rgba(255,255,255,0.03)',border:'1px solid rgba(255,255,255,0.06)',borderRadius:5,padding:'1px 6px'}}>{q.level}</span>}
                        {q.format&&<span style={{fontSize:9,color:'#475569',background:'rgba(255,255,255,0.03)',border:'1px solid rgba(255,255,255,0.06)',borderRadius:5,padding:'1px 6px'}}>{q.format}</span>}
                      </div>

                      {/* Right: action buttons */}
                      <div style={{display:'flex',gap:4,alignItems:'center'}}>
                        {[
                          {ico:'👁',fn:()=>setSelQId(q._id),title:'Preview',col:'#4D9FFF'},
                          {ico:'📊',fn:()=>fetchUsageStats(q),title:'Usage',col:'#A78BFA'},
                          {ico:'✏️',fn:()=>setEditQD({...q,correctLetter:ltrs[ci>=0?ci:0]||'A'}),title:'Edit',col:'#34D399'},
                          {ico:'📋',fn:()=>copyToAddForm(q),title:'Copy',col:'#FBBF24'},
                        ].map(btn=>(
                          <button key={btn.title} onClick={btn.fn} title={btn.title} className="qact-btn"
                            style={{
                              background:'rgba(255,255,255,0.03)',
                              border:'1px solid rgba(255,255,255,0.07)',
                              color:'#475569',borderRadius:7,
                              width:28,height:26,cursor:'pointer',fontSize:13,
                              display:'flex',alignItems:'center',justifyContent:'center',
                              flexShrink:0
                            }}
                            onMouseEnter={e=>{const b=e.currentTarget as HTMLElement;b.style.background=\`\${btn.col}12\`;b.style.color=btn.col;b.style.borderColor=\`\${btn.col}30\`}}
                            onMouseLeave={e=>{const b=e.currentTarget as HTMLElement;b.style.background='rgba(255,255,255,0.03)';b.style.color='#475569';b.style.borderColor='rgba(255,255,255,0.07)'}}>
                            {btn.ico}
                          </button>
                        ))}

                        {/* Delete — appears on hover via CSS class */}
                        <button onClick={()=>openDeleteModal(q)} title='Delete' className="qact-btn del-btn"
                          style={{
                            background:'rgba(255,77,77,0.05)',
                            border:'1px solid rgba(255,77,77,0.15)',
                            color:'#FF4D4D',borderRadius:7,
                            width:28,height:26,cursor:'pointer',fontSize:13,
                            display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0
                          }}
                          onMouseEnter={e=>{const b=e.currentTarget as HTMLElement;b.style.background='linear-gradient(135deg,#FF4D4D,#aa0000)';b.style.color='#fff';b.style.borderColor='transparent';b.style.boxShadow='0 2px 10px rgba(255,77,77,0.4)'}}
                          onMouseLeave={e=>{const b=e.currentTarget as HTMLElement;b.style.background='rgba(255,77,77,0.05)';b.style.color='#FF4D4D';b.style.borderColor='rgba(255,77,77,0.15)';b.style.boxShadow='none'}}>
                          🗑️
                        </button>
                      </div>
                    </div>

                  </div>
                </div>
              )
            })}
          </div>
        )}

        {/* ══════════ PAGINATION BOTTOM`;

c = c.substring(0, si) + NEW_CARDS + c.substring(ei + CARD_END.length);
fs.writeFileSync(file, c);
console.log('✅ Ultra Premium card design applied!');
ENDOFSCRIPT

# ── Verification ──────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════"
echo "  Question Card Redesign — Verification"
echo "═══════════════════════════════════════════════"
chk(){ grep -q "$2" "$FILE" 2>/dev/null && echo "  ✅ $3" || echo "  ❌ $3"; }

chk "fadeSlideIn"         "Card entrance animation"
chk "del-btn"             "Delete button CSS class (hover reveal)"
chk "qcard:hover"         "Card hover lift effect"
chk "Left subject glow"   "Left colored subject strip"
chk "Top accent line"     "Selected card top accent"
chk "cubic-bezier"        "Smooth transition timing"
chk "Bottom action bar"   "Bottom inline action bar"
chk "openDeleteModal"     "Delete → modal"
chk "setSelQId"           "Preview click"
chk "fetchUsageStats"     "Usage stats"
chk "setEditQD"           "Edit button"
chk "copyToAddForm"       "Copy button"
chk "longPressTimerRef"   "Long press bulk select"
chk "hindiText"           "Hindi text support"
chk "stdPrv"              "Student preview options"
chk "approvalStatus"      "Approval status badge"
chk "usedIn"              "Used in exams badge"
chk "chapter.*topic"      "Chapter/topic breadcrumb"
chk "animate.*delay\|animationDelay" "Staggered animation"

echo ""
echo "═══════════════════════════════════════════════"
echo "🎉 git add . && git commit -m 'feat: Premium Qs card redesign' && git push"
echo "═══════════════════════════════════════════════"
