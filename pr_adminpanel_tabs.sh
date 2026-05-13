#!/bin/bash
# ══════════════════════════════════════════════════════════════
# ProveRank — Admin Panel: Rich Content for All Feature Tabs
# Replaces lines 529-713 with premium layouts for each tab
# ══════════════════════════════════════════════════════════════
set -e
export FILE="$HOME/workspace/frontend/app/admin/panel/page.tsx"
export JSXFILE="/tmp/pr_adminpanel_tabs.jsx"

if [ ! -f "$FILE" ]; then echo "❌ File not found"; exit 1; fi
cp "$FILE" "${FILE}.bak6.$(date +%s)"
echo "✅ Backup created"

cat > "$JSXFILE" << 'JSXEOF'
        {/* ══ ALL EXAMS ══ */}
        {tab==='exams'&&(hasPermission('create_exam')||hasPermission('edit_exam')||hasPermission('delete_exam'))&&(
          <div>
            <div style={{...pageTitle,display:'flex',alignItems:'center',justifyContent:'space-between',flexWrap:'wrap',gap:8}}>
              <span>📝 All Exams</span>
              {hasPermission('create_exam')&&<button onClick={()=>setTab('create_exam')} style={{...bp,padding:'8px 16px',fontSize:12}}>➕ Create New</button>}
            </div>
            <div style={pageSub}>{exams.length} exams in system</div>
            <div style={{...cs,marginTop:12,padding:'10px 14px',marginBottom:16,display:'flex',alignItems:'center',gap:10}}>
              <span style={{fontSize:16}}>🔍</span>
              <input placeholder="Search exams by title…" onChange={e=>setExamSearch(e.target.value)} style={{flex:1,background:'transparent',border:'none',outline:'none',color:TS,fontSize:13}} value={examSearch||''}/>
            </div>
            {exams.filter((e:any)=>!examSearch||(e.title||'').toLowerCase().includes((examSearch||'').toLowerCase())).length===0
              ?<div style={{...cs,textAlign:'center',padding:40}}>
                <svg width="52" height="52" viewBox="0 0 24 24" fill="none" style={{margin:'0 auto 12px',display:'block',opacity:0.3}}><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8l-6-6z" stroke="#4D9FFF" strokeWidth="1.6" strokeLinejoin="round"/><polyline points="14,2 14,8 20,8" stroke="#4D9FFF" strokeWidth="1.6" strokeLinejoin="round"/></svg>
                <div style={{color:DIM,fontSize:13,fontWeight:600}}>No exams found</div>
                {hasPermission('create_exam')&&<button onClick={()=>setTab('create_exam')} style={{...bp,marginTop:14,padding:'8px 20px'}}>Create First Exam</button>}
              </div>
              :exams.filter((e:any)=>!examSearch||(e.title||'').toLowerCase().includes((examSearch||'').toLowerCase())).map((e:any)=>(
                <div key={e._id} className="card-hover" style={{...cs,marginBottom:10,padding:'14px 16px',border:'1px solid rgba(77,159,255,0.14)',position:'relative',overflow:'hidden'}}>
                  <div style={{position:'absolute',top:0,left:0,width:3,height:'100%',background:e.status==='active'?'#00C48C':e.status==='completed'?'#778899':'#FFB84D',borderRadius:'3px 0 0 3px'}}></div>
                  <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',flexWrap:'wrap',gap:8,paddingLeft:8}}>
                    <div style={{flex:1,minWidth:160}}>
                      <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:4}}>{e.title}</div>
                      <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
                        <span style={{fontSize:11,color:DIM}}>📅 {e.scheduledAt?new Date(e.scheduledAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'}):'Not scheduled'}</span>
                        <span style={{fontSize:11,color:DIM}}>⏱ {e.duration||200} min</span>
                        <span style={{fontSize:11,color:DIM}}>📊 {e.totalMarks||720} marks</span>
                      </div>
                    </div>
                    <div style={{display:'flex',gap:6,alignItems:'center',flexShrink:0}}>
                      <Badge label={e.status||'draft'} col={e.status==='active'?SUC:e.status==='completed'?DIM:WRN}/>
                      {hasPermission('edit_exam')&&<button style={{...bg_,fontSize:11,padding:'4px 9px',color:ACC,border:`1px solid rgba(77,159,255,0.3)`}}>✏️</button>}
                    </div>
                  </div>
                </div>
              ))
            }
          </div>
        )}

        {/* ══ CREATE EXAM ══ */}
        {tab==='create_exam'&&hasPermission('create_exam')&&(
          <div>
            <div style={pageTitle}>➕ Create Exam — 3-Step Wizard</div>
            <div style={pageSub}>Build a complete NEET exam in 3 simple steps</div>
            <div style={{display:'flex',gap:0,marginBottom:20,marginTop:16,background:'rgba(0,10,28,0.6)',borderRadius:12,padding:4,border:'1px solid rgba(77,159,255,0.14)'}}>
              {(['Exam Details','Add Questions','Review & Publish'] as string[]).map((s,i)=>(
                <div key={i} style={{flex:1,textAlign:'center',padding:'9px 4px',borderRadius:9,background:examStep===i?'rgba(77,159,255,0.18)':'transparent',color:examStep===i?ACC:DIM,fontSize:11,fontWeight:examStep===i?700:400,cursor:'pointer',transition:'all 0.2s'}} onClick={()=>setExamStep(i)}>{i+1}. {s}</div>
              ))}
            </div>
            {examStep===0&&(
              <div style={{...cs,padding:'18px 20px'}}>
                <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:16}}>📋 Step 1 — Exam Details</div>
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12}}>
                  <div style={{gridColumn:'1/-1'}}><label style={lbl}>Exam Title *</label><SInput init='' onSet={v=>{eTitleR.current=v}} ph='e.g. NEET Full Mock Test — May 2026' style={inp}/></div>
                  <div><label style={lbl}>Scheduled Date & Time *</label><SInput init='' onSet={v=>{eDateR.current=v}} type='datetime-local' style={inp}/></div>
                  <div><label style={lbl}>Category</label><SSelect val={eCat} onChange={setECat} opts={[{v:'Full Mock Test',l:'Full Mock Test'},{v:'Chapter Test',l:'Chapter Test'},{v:'Part Test',l:'Part Test'},{v:'Grand Test',l:'Grand Test'}]} style={inp}/></div>
                  <div><label style={lbl}>Total Marks</label><SInput init='720' onSet={v=>{eMarksR.current=v}} type='number' style={inp}/></div>
                  <div><label style={lbl}>Duration (minutes)</label><SInput init='200' onSet={v=>{eDurR.current=v}} type='number' style={inp}/></div>
                  <div style={{gridColumn:'1/-1'}}><div style={{fontSize:11,color:'rgba(77,159,255,0.6)',background:'rgba(77,159,255,0.06)',borderRadius:8,padding:'8px 12px',border:'1px solid rgba(77,159,255,0.12)'}}>📌 NEET defaults: 180 questions · Physics 45 + Chemistry 45 + Biology 90 · +4/-1 marking · 200 minutes</div></div>
                </div>
                <button onClick={()=>setExamStep(1)} style={{...bp,width:'100%',marginTop:16}}>Next: Add Questions →</button>
              </div>
            )}
            {examStep===1&&(
              <div style={{...cs,padding:'18px 20px'}}>
                <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:16}}>❓ Step 2 — Add Questions</div>
                <div style={{background:'rgba(77,159,255,0.06)',border:'1px solid rgba(77,159,255,0.15)',borderRadius:10,padding:'16px',textAlign:'center'}}>
                  <svg width="44" height="44" viewBox="0 0 24 24" fill="none" style={{margin:'0 auto 10px',display:'block',opacity:0.4}}><circle cx="12" cy="12" r="9" stroke="#4D9FFF" strokeWidth="1.6"/><path d="M12 8v4M12 16h.01" stroke="#4D9FFF" strokeWidth="2" strokeLinecap="round"/></svg>
                  <div style={{color:DIM,fontSize:13}}>Questions from your Question Bank will be linked here.</div>
                  <div style={{color:'rgba(77,159,255,0.5)',fontSize:11,marginTop:6}}>Bank has {questions.length} questions available</div>
                </div>
                <div style={{display:'flex',gap:10,marginTop:16}}>
                  <button onClick={()=>setExamStep(0)} style={{...bg_,flex:1,padding:'10px',color:DIM,border:'1px solid rgba(255,255,255,0.08)'}}>← Back</button>
                  <button onClick={()=>setExamStep(2)} style={{...bp,flex:2,padding:'10px'}}>Next: Review & Publish →</button>
                </div>
              </div>
            )}
            {examStep===2&&(
              <div style={{...cs,padding:'18px 20px'}}>
                <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:16}}>✅ Step 3 — Review & Publish</div>
                <div style={{background:'rgba(0,196,140,0.05)',border:'1px solid rgba(0,196,140,0.2)',borderRadius:10,padding:14,marginBottom:14}}>
                  <div style={{fontSize:12,color:'#00C48C',fontWeight:600,marginBottom:6}}>Ready to publish?</div>
                  <div style={{fontSize:11,color:DIM}}>Once published, students with access can see and attempt this exam. You can still edit it before the scheduled time.</div>
                </div>
                <div style={{display:'flex',gap:10,marginTop:12}}>
                  <button onClick={()=>setExamStep(1)} style={{...bg_,flex:1,padding:'10px',color:DIM,border:'1px solid rgba(255,255,255,0.08)'}}>← Back</button>
                  <button onClick={createExam} disabled={creatingE} style={{...bp,flex:2,padding:'10px',opacity:creatingE?0.7:1}}>{creatingE?'⟳ Publishing…':'🚀 Publish Exam'}</button>
                </div>
              </div>
            )}
          </div>
        )}

        {/* ══ EXAM TEMPLATES ══ */}
        {tab==='templates'&&hasPermission('create_exam')&&(
          <div>
            <div style={pageTitle}>📋 Exam Templates</div>
            <div style={pageSub}>Pre-configured exam templates — select and auto-fill settings instantly</div>
            <div style={{...cs,marginBottom:20,padding:'18px 20px',textAlign:'center'}}>
              <div style={{fontSize:36,marginBottom:8}}>📋</div>
              <div style={{fontWeight:700,fontSize:15,color:TS,marginBottom:6}}>Save Time with Templates</div>
              <div style={{color:DIM,fontSize:12}}>One click to apply all settings — title, marks, duration, subjects pre-filled</div>
            </div>
            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginBottom:20}}>
              {([
                {ico:'🎯',name:'NEET Full Mock',desc:'180 Qs · 720 marks · 200 min · Physics+Chemistry+Biology',marks:720,dur:200,qs:180},
                {ico:'📖',name:'NEET Chapter Test',desc:'45 Qs · 180 marks · 60 min · Single chapter focus',marks:180,dur:60,qs:45},
                {ico:'⚡',name:'NEET Part Test',desc:'90 Qs · 360 marks · 100 min · 2 subjects',marks:360,dur:100,qs:90},
                {ico:'🏆',name:'Grand Test',desc:'180 Qs · 720 marks · 200 min · Full syllabus',marks:720,dur:200,qs:180},
                {ico:'📅',name:'PYQ Practice',desc:'50 Qs · 200 marks · 70 min · Previous year questions',marks:200,dur:70,qs:50},
              ] as any[]).map((t:any,i:number)=>(
                <div key={i} style={{...cs,padding:'16px 14px',cursor:'pointer',border:'1px solid rgba(77,159,255,0.14)',transition:'all 0.2s'}} className="card-hover" onClick={()=>{eMarksR.current=String(t.marks);eDurR.current=String(t.dur);setTab('create_exam');T('Template applied: '+t.name+' ✅');}}>
                  <div style={{fontSize:28,marginBottom:8}}>{t.ico}</div>
                  <div style={{fontWeight:700,fontSize:13,color:TS,marginBottom:4}}>{t.name}</div>
                  <div style={{fontSize:10,color:DIM,marginBottom:10}}>{t.desc}</div>
                  <button style={{...bp,width:'100%',fontSize:11,padding:'7px 0'}}>Apply Template →</button>
                </div>
              ))}
            </div>
            <div style={{...cs,padding:'16px 18px'}}>
              <div style={{fontWeight:600,fontSize:13,color:TS,marginBottom:4}}>💾 Save Current Exam as Template</div>
              <div style={{fontSize:11,color:DIM,marginBottom:10}}>Create a reusable template from any exam configuration for future use.</div>
              <div style={{display:'flex',gap:8}}>
                <SInput init='' onSet={v=>{}} ph='Template name…' style={{...inp,flex:1}}/>
                <button style={{...bp,padding:'0 16px',flexShrink:0}}>💾 Save</button>
              </div>
            </div>
          </div>
        )}

        {/* ══ BULK CREATOR ══ */}
        {tab==='bulk_creator'&&hasPermission('bulk_exam')&&(
          <div>
            <div style={pageTitle}>⚡ Bulk Exam Creator</div>
            <div style={pageSub}>Create multiple exams at once using a structured format</div>
            <div style={{...cs,marginTop:16,padding:'22px 20px',textAlign:'center'}}>
              <svg width="52" height="52" viewBox="0 0 24 24" fill="none" style={{margin:'0 auto 14px',display:'block',opacity:0.5}}><rect x="3" y="3" width="7" height="7" rx="1" stroke="#4D9FFF" strokeWidth="1.6"/><rect x="14" y="3" width="7" height="7" rx="1" stroke="#4D9FFF" strokeWidth="1.6"/><rect x="3" y="14" width="7" height="7" rx="1" stroke="#4D9FFF" strokeWidth="1.6"/><rect x="14" y="14" width="7" height="7" rx="1" stroke="#4D9FFF" strokeWidth="1.6"/></svg>
              <div style={{fontWeight:700,fontSize:14,color:TS,marginBottom:8}}>Bulk Exam Creator</div>
              <div style={{color:DIM,fontSize:12,marginBottom:16}}>Upload a CSV / Excel file with exam details<br/>or use the structured format below to create multiple exams at once.</div>
              <div style={{display:'flex',gap:10,justifyContent:'center',flexWrap:'wrap'}}>
                <button style={{...bp,padding:'10px 20px',fontSize:12}}>📤 Upload CSV/Excel</button>
                <button style={{...bg_,padding:'10px 20px',fontSize:12,color:ACC,border:`1px solid rgba(77,159,255,0.25)`}}>📥 Download Template</button>
              </div>
            </div>
            <div style={{...cs,marginTop:14,padding:'14px 16px',border:'1px solid rgba(255,184,77,0.2)'}}>
              <div style={{fontSize:11,color:WRN,fontWeight:600,marginBottom:4}}>⚠️ Feature Note</div>
              <div style={{fontSize:11,color:DIM}}>Bulk creation processes up to 50 exams at once. Each exam follows the same NEET marking scheme unless overridden in the file.</div>
            </div>
          </div>
        )}

        {/* ══ QUESTION BANK ══ */}
        {tab==='questions'&&hasPermission('manage_questions')&&(
          <div>
            <div style={pageTitle}>❓ Question Bank</div>
            <div style={pageSub}>{questions.length} questions in bank</div>
            <div style={{...cs,marginTop:16,border:'1px solid rgba(77,159,255,0.18)'}}>
              <div style={{background:'rgba(77,159,255,0.07)',borderBottom:'1px solid rgba(77,159,255,0.12)',padding:'12px 16px',display:'flex',alignItems:'center',gap:10}}>
                <span style={{fontSize:16}}>➕</span>
                <span style={{fontWeight:700,fontSize:13,color:TS}}>Add Question</span>
              </div>
              <div style={{padding:'16px'}}>
                <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
                  <div style={{gridColumn:'1/-1'}}><label style={lbl}>Question Text *</label><STextarea init='' onSet={v=>{qTxtR.current=v}} ph='Type the full question text…' rows={3} style={{...inp,resize:'vertical'}}/></div>
                  <div><label style={lbl}>Subject</label><SSelect val={qSubj} onChange={setQSubj} opts={[{v:'Physics',l:'⚛️ Physics'},{v:'Chemistry',l:'🧪 Chemistry'},{v:'Biology',l:'🧬 Biology'}]} style={inp}/></div>
                  <div><label style={lbl}>Difficulty</label><SSelect val={qDiff} onChange={setQDiff} opts={[{v:'easy',l:'🟢 Easy'},{v:'medium',l:'🟡 Medium'},{v:'hard',l:'🔴 Hard'}]} style={inp}/></div>
                  <div><label style={lbl}>Type</label><SSelect val={qType} onChange={setQType} opts={[{v:'SCQ',l:'SCQ — Single Correct'},{v:'MSQ',l:'MSQ — Multiple Correct'},{v:'Integer',l:'Integer Type'}]} style={inp}/></div>
                  <div><label style={lbl}>Chapter</label><SInput init='' onSet={v=>{qChapR.current=v}} ph='e.g. Electrostatics' style={inp}/></div>
                  {['SCQ','MSQ'].includes(qType)&&<>
                    <div><label style={lbl}>Option A</label><SInput init='' onSet={v=>{qA.current=v}} ph='Option A' style={inp}/></div>
                    <div><label style={lbl}>Option B</label><SInput init='' onSet={v=>{qB.current=v}} ph='Option B' style={inp}/></div>
                    <div><label style={lbl}>Option C</label><SInput init='' onSet={v=>{qC.current=v}} ph='Option C' style={inp}/></div>
                    <div><label style={lbl}>Option D</label><SInput init='' onSet={v=>{qD.current=v}} ph='Option D' style={inp}/></div>
                    <div><label style={lbl}>Correct Answer</label><SSelect val={qAnsR.current||'A'} onChange={v=>{qAnsR.current=v}} opts={[{v:'A',l:'A'},{v:'B',l:'B'},{v:'C',l:'C'},{v:'D',l:'D'}]} style={inp}/></div>
                  </>}
                </div>
                <button onClick={addQ} disabled={savingQ} style={{...bp,width:'100%',marginTop:14,opacity:savingQ?0.7:1}}>{savingQ?'⟳ Saving…':'➕ Add to Bank'}</button>
              </div>
            </div>
            <div style={{marginTop:16,display:'flex',flexDirection:'column',gap:8}}>
              {questions.slice(0,20).map((q:any,i:number)=>(
                <div key={q._id||i} className="card-hover" style={{...cs,padding:'12px 14px',border:'1px solid rgba(77,159,255,0.1)'}}>
                  <div style={{fontWeight:600,fontSize:13,color:TS,marginBottom:6}}>{q.text?.substring(0,140)}{(q.text?.length||0)>140?'…':''}</div>
                  <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>
                    <Badge label={q.subject} col={q.subject==='Physics'?ACC:q.subject==='Chemistry'?'#FF6B9D':SUC}/>
                    <Badge label={q.difficulty||'medium'} col={q.difficulty==='hard'?DNG:q.difficulty==='easy'?SUC:WRN}/>
                    <Badge label={q.type||'SCQ'} col={ACC}/>
                    {q.chapter&&<Badge label={q.chapter} col={DIM}/>}
                  </div>
                </div>
              ))}
              {questions.length===0&&<div style={{...cs,textAlign:'center',padding:32,color:DIM}}>
                <div style={{fontSize:32,marginBottom:8,opacity:0.4}}>❓</div>
                <div>No questions yet. Add your first question above.</div>
              </div>}
            </div>
          </div>
        )}

        {/* ══ SMART GENERATOR ══ */}
        {tab==='smart_gen'&&hasPermission('ai_questions')&&(
          <div>
            <div style={pageTitle}>🤖 AI Smart Generator</div>
            <div style={pageSub}>Generate NEET questions using AI in seconds</div>
            <div style={{...cs,marginTop:16,padding:'24px 20px',textAlign:'center'}}>
              <div style={{fontSize:48,marginBottom:12}}>🤖</div>
              <div style={{fontWeight:700,fontSize:15,color:TS,marginBottom:8}}>Generate Questions with AI</div>
              <div style={{color:DIM,fontSize:12,marginBottom:20,maxWidth:320,margin:'0 auto 20px'}}>Select subject, chapter and difficulty — AI will generate high-quality NEET-pattern questions instantly.</div>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,textAlign:'left',marginBottom:14}}>
                <div><label style={lbl}>Subject</label><SSelect val={qSubj} onChange={setQSubj} opts={[{v:'Physics',l:'⚛️ Physics'},{v:'Chemistry',l:'🧪 Chemistry'},{v:'Biology',l:'🧬 Biology'}]} style={inp}/></div>
                <div><label style={lbl}>Count</label><SSelect val='10' onChange={()=>{}} opts={[{v:'5',l:'5 Questions'},{v:'10',l:'10 Questions'},{v:'20',l:'20 Questions'},{v:'45',l:'45 Questions'}]} style={inp}/></div>
                <div style={{gridColumn:'1/-1'}}><label style={lbl}>Chapter / Topic</label><SInput init='' onSet={()=>{}} ph='e.g. Laws of Motion, Cell Division…' style={inp}/></div>
              </div>
              <button style={{...bp,width:'100%',padding:'12px'}}>✨ Generate Questions</button>
            </div>
          </div>
        )}

        {/* ══ PYQ BANK ══ */}
        {tab==='pyq_bank'&&hasPermission('pyq_access')&&(
          <div>
            <div style={pageTitle}>📚 PYQ Bank</div>
            <div style={pageSub}>Previous Year Questions — NEET 2015 to 2025</div>
            <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:10,marginTop:16,marginBottom:16}}>
              {(['2025','2024','2023','2022','2021','2020'] as string[]).map((yr:string)=>(
                <div key={yr} style={{...cs,textAlign:'center',padding:'14px 8px',cursor:'pointer',border:'1px solid rgba(77,159,255,0.14)'}} className="card-hover">
                  <div style={{fontSize:20,marginBottom:4}}>📄</div>
                  <div style={{fontWeight:700,color:TS,fontSize:13}}>NEET {yr}</div>
                  <div style={{fontSize:10,color:DIM,marginTop:2}}>180 Qs</div>
                </div>
              ))}
            </div>
            <div style={{...cs,padding:'14px 16px',border:'1px solid rgba(77,159,255,0.14)'}}>
              <div style={{fontWeight:600,fontSize:13,color:TS,marginBottom:4}}>🔍 Search PYQ</div>
              <SInput init='' onSet={()=>{}} ph='Search by topic, keyword or year…' style={{...inp,marginTop:8}}/>
            </div>
          </div>
        )}

        {/* ══ STUDENTS ══ */}
        {tab==='students'&&hasPermission('ban_student')&&(
          <div>
            <div style={pageTitle}>👥 Students</div>
            <div style={pageSub}>{students.length} registered students</div>
            <div style={{...cs,marginTop:12,padding:'10px 14px',marginBottom:14,display:'flex',alignItems:'center',gap:10}}>
              <span style={{fontSize:16}}>🔍</span>
              <input placeholder="Search students by name or email…" onChange={e=>setStudentSearch(e.target.value)} style={{flex:1,background:'transparent',border:'none',outline:'none',color:TS,fontSize:13}} value={studentSearch||''}/>
            </div>
            <div style={{display:'flex',flexDirection:'column',gap:8}}>
              {students.filter((s:any)=>!studentSearch||(s.name||'').toLowerCase().includes((studentSearch||'').toLowerCase())||(s.email||'').toLowerCase().includes((studentSearch||'').toLowerCase())).slice(0,25).map((s:any)=>(
                <div key={s._id} className="card-hover" style={{...cs,padding:'12px 14px',border:`1px solid ${s.banned?'rgba(255,77,77,0.2)':'rgba(77,159,255,0.1)'}`}}>
                  <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',flexWrap:'wrap',gap:8}}>
                    <div style={{display:'flex',alignItems:'center',gap:10,flex:1,minWidth:140}}>
                      <div style={{width:36,height:36,background:'rgba(77,159,255,0.15)',borderRadius:10,display:'flex',alignItems:'center',justifyContent:'center',fontSize:15,fontWeight:700,color:ACC,flexShrink:0}}>{(s.name||'S')[0].toUpperCase()}</div>
                      <div>
                        <div style={{fontWeight:600,fontSize:13,color:TS}}>{s.name}</div>
                        <div style={{fontSize:11,color:DIM}}>{s.email}</div>
                      </div>
                    </div>
                    <div style={{display:'flex',gap:6,alignItems:'center',flexShrink:0}}>
                      {s.banned?<Badge label='Banned' col={DNG}/>:<Badge label='Active' col={SUC}/>}
                      {hasPermission('ban_student')&&(s.banned
                        ?<button onClick={()=>banStudent(s._id,'Unban')} style={{...bg_,fontSize:11,padding:'4px 10px',color:SUC,border:`1px solid rgba(0,196,140,0.3)`}}>Unban</button>
                        :<button onClick={()=>banStudent(s._id,'Admin action')} style={{...bg_,fontSize:11,padding:'4px 10px',color:DNG,border:`1px solid rgba(255,77,77,0.3)`}}>Ban</button>
                      )}
                    </div>
                  </div>
                </div>
              ))}
              {students.length===0&&<div style={{...cs,textAlign:'center',padding:36,color:DIM}}><div style={{fontSize:32,marginBottom:8,opacity:0.3}}>👥</div>No students registered yet.</div>}
            </div>
          </div>
        )}

        {/* ══ RESULTS ══ */}
        {tab==='results'&&hasPermission('view_results')&&(
          <div>
            <div style={pageTitle}>📈 Results</div>
            <div style={pageSub}>{results.length} total results</div>
            <div style={{display:'flex',flexDirection:'column',gap:8,marginTop:16}}>
              {results.slice(0,25).map((r:any,i:number)=>(
                <div key={r._id||i} className="card-hover" style={{...cs,padding:'13px 15px',border:'1px solid rgba(77,159,255,0.1)'}}>
                  <div style={{display:'flex',justifyContent:'space-between',flexWrap:'wrap',gap:8}}>
                    <div style={{flex:1,minWidth:140}}>
                      <div style={{fontWeight:600,fontSize:13,color:TS,marginBottom:3}}>{r.studentName||r.student?.name||'Student'}</div>
                      <div style={{fontSize:11,color:DIM}}>{r.examTitle||r.exam?.title||'Exam'}</div>
                    </div>
                    <div style={{textAlign:'right',flexShrink:0}}>
                      <div style={{fontWeight:800,fontSize:16,color:ACC}}>{r.score||0}<span style={{fontSize:11,color:DIM,fontWeight:400}}>/{r.totalMarks||720}</span></div>
                      <div style={{fontSize:11,color:DIM}}>Rank #{r.rank||'—'}</div>
                    </div>
                  </div>
                </div>
              ))}
              {results.length===0&&<div style={{...cs,textAlign:'center',padding:36,color:DIM}}><div style={{fontSize:32,marginBottom:8,opacity:0.3}}>📈</div>No results yet.</div>}
            </div>
          </div>
        )}

        {/* ══ LEADERBOARD ══ */}
        {tab==='leaderboard'&&hasPermission('view_leaderboard')&&(
          <div>
            <div style={pageTitle}>🏆 Leaderboard</div>
            <div style={pageSub}>Top student rankings across all exams</div>
            <div style={{display:'flex',flexDirection:'column',gap:8,marginTop:16}}>
              {results.slice(0,10).map((r:any,i:number)=>(
                <div key={r._id||i} style={{...cs,padding:'12px 14px',display:'flex',alignItems:'center',gap:12,border:'1px solid rgba(77,159,255,0.1)'}}>
                  <div style={{width:32,height:32,background:i===0?'rgba(255,215,0,0.2)':i===1?'rgba(192,192,192,0.2)':i===2?'rgba(205,127,50,0.2)':'rgba(77,159,255,0.1)',borderRadius:10,display:'flex',alignItems:'center',justifyContent:'center',fontWeight:800,fontSize:14,color:i===0?GOLD:i===1?'#C0C0C0':i===2?'#CD7F32':ACC,flexShrink:0}}>#{i+1}</div>
                  <div style={{flex:1,minWidth:0}}>
                    <div style={{fontWeight:600,fontSize:13,color:TS}}>{r.studentName||'Student'}</div>
                    <div style={{fontSize:11,color:DIM}}>{r.examTitle||'Exam'}</div>
                  </div>
                  <div style={{fontWeight:800,fontSize:15,color:ACC,flexShrink:0}}>{r.score||0}</div>
                </div>
              ))}
              {results.length===0&&<div style={{...cs,textAlign:'center',padding:36,color:DIM}}><div style={{fontSize:32,marginBottom:8,opacity:0.3}}>🏆</div>No ranking data yet.</div>}
            </div>
          </div>
        )}

        {/* ══ ANALYTICS ══ */}
        {tab==='analytics'&&hasPermission('view_analytics')&&(
          <div>
            <div style={pageTitle}>📊 Analytics</div>
            <div style={pageSub}>Platform performance insights</div>
            <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginTop:16,marginBottom:16}}>
              {([
                {ico:'👥',l:'Total Students',v:students.length,col:ACC},
                {ico:'📝',l:'Total Exams',v:exams.length,col:WRN},
                {ico:'📈',l:'Total Results',v:results.length,col:SUC},
                {ico:'❓',l:'Questions',v:questions.length,col:'#A080FF'},
              ] as any[]).map((s:any,i:number)=>(
                <div key={i} style={{...cs,textAlign:'center',padding:'18px 12px',border:`1px solid rgba(77,159,255,0.14)`}}>
                  <div style={{fontSize:24,marginBottom:6}}>{s.ico}</div>
                  <div style={{fontSize:24,fontWeight:800,color:s.col,lineHeight:1}}>{s.v}</div>
                  <div style={{fontSize:10,color:DIM,marginTop:5,fontWeight:600}}>{s.l}</div>
                </div>
              ))}
            </div>
            <div style={{...cs,padding:'14px 16px',textAlign:'center'}}>
              <div style={{fontSize:11,color:DIM}}>📊 Detailed analytics charts and graphs are available in the full analytics dashboard.</div>
            </div>
          </div>
        )}

        {/* ══ ANNOUNCEMENTS ══ */}
        {tab==='announcements'&&hasPermission('send_announcements')&&(
          <div>
            <div style={pageTitle}>📢 Announcements</div>
            <div style={pageSub}>Send notices to all students</div>
            <div style={{...cs,marginTop:16,border:'1px solid rgba(77,159,255,0.18)'}}>
              <div style={{background:'rgba(77,159,255,0.07)',borderBottom:'1px solid rgba(77,159,255,0.12)',padding:'12px 16px',display:'flex',alignItems:'center',gap:10}}>
                <span style={{fontSize:16}}>📤</span>
                <span style={{fontWeight:700,fontSize:13,color:TS}}>New Announcement</span>
              </div>
              <div style={{padding:'16px'}}>
                <div style={{marginBottom:12}}><label style={lbl}>Title *</label><SInput init='' onSet={v=>{annTitleR.current=v}} ph='Announcement title…' style={inp}/></div>
                <div style={{marginBottom:14}}><label style={lbl}>Message *</label><STextarea init={annTxt} onSet={setAnnTxt} ph='Type your announcement…' rows={4} style={{...inp,resize:'vertical'}}/></div>
                <button onClick={sendAnn} disabled={sendingAnn} style={{...bp,width:'100%',opacity:sendingAnn?0.7:1}}>{sendingAnn?'⟳ Sending…':'📢 Send to All Students'}</button>
              </div>
            </div>
            <div style={{marginTop:14,display:'flex',flexDirection:'column',gap:8}}>
              {announcements.slice(0,10).map((a:any,i:number)=>(
                <div key={a._id||i} style={{...cs,padding:'12px 14px',border:'1px solid rgba(77,159,255,0.08)'}}>
                  <div style={{fontWeight:600,fontSize:13,color:TS,marginBottom:3}}>{a.title}</div>
                  <div style={{fontSize:12,color:DIM}}>{a.message?.substring(0,150)}</div>
                  <div style={{fontSize:10,color:'rgba(77,159,255,0.4)',marginTop:4}}>{a.createdAt?new Date(a.createdAt).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'}):''}</div>
                </div>
              ))}
              {announcements.length===0&&<div style={{...cs,textAlign:'center',padding:24,color:DIM}}>No announcements sent yet.</div>}
            </div>
          </div>
        )}

        {/* ══ AUDIT LOGS ══ */}
        {tab==='audit'&&hasPermission('view_audit_logs')&&(
          <div>
            <div style={pageTitle}>📋 Audit Logs</div>
            <div style={pageSub}>All admin actions and activity history</div>
            <div style={{...cs,marginTop:16,padding:'14px 16px',textAlign:'center'}}>
              <svg width="44" height="44" viewBox="0 0 24 24" fill="none" style={{margin:'0 auto 10px',display:'block',opacity:0.4}}><path d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" stroke="#4D9FFF" strokeWidth="1.6" strokeLinejoin="round"/><path d="M9 12h6M9 16h4" stroke="#4D9FFF" strokeWidth="1.6" strokeLinecap="round"/></svg>
              <div style={{color:DIM,fontSize:12}}>Activity logs load from the backend. Showing your recent actions.</div>
            </div>
          </div>
        )}

        {/* ══ COMING SOON SECTIONS ══ */}
        {['reports','cheating','snapshots','integrity','proct_pdf','email_tmpl','features','branding','maintenance','qbank_stats','subj_rank','batches','custom_fields'].includes(tab)&&(
          <div style={{...cs,textAlign:'center',padding:48}}>
            <svg width="56" height="56" viewBox="0 0 24 24" fill="none" style={{margin:'0 auto 16px',display:'block',opacity:0.3}}><circle cx="12" cy="12" r="9" stroke="#4D9FFF" strokeWidth="1.5"/><path d="M12 8v4M12 16h.01" stroke="#4D9FFF" strokeWidth="2" strokeLinecap="round"/></svg>
            <div style={{fontSize:16,fontWeight:700,color:TS,marginBottom:8}}>Coming Soon</div>
            <div style={{fontSize:13,color:DIM,marginBottom:4}}>This section is under active development.</div>
            <div style={{fontSize:11,color:'rgba(77,159,255,0.5)',marginTop:6,background:'rgba(77,159,255,0.06)',borderRadius:8,padding:'6px 12px',display:'inline-block'}}>Permission granted — content loading soon</div>
          </div>
        )}

        {/* ══ NO PERMISSION FALLBACK ══ */}
        {tab!=='dashboard'&&!['exams','create_exam','templates','bulk_creator','questions','smart_gen','pyq_bank','students','batches','custom_fields','results','leaderboard','analytics','reports','cheating','snapshots','integrity','proct_pdf','announcements','email_tmpl','audit','features','branding','maintenance','qbank_stats','subj_rank'].includes(tab)&&(
          <div style={{...cs,textAlign:'center',padding:40}}>
            <div style={{fontSize:40,marginBottom:12}}>🔒</div>
            <div style={{fontSize:16,fontWeight:700,color:TS,marginBottom:8}}>Feature Not Accessible</div>
            <div style={{fontSize:13,color:DIM}}>This section is not enabled for your account.<br/>Contact your SuperAdmin to enable access.</div>
          </div>
        )}
        {tab==='students'&&!hasPermission('ban_student')&&!hasPermission('view_students')&&<div style={{...cs,textAlign:'center',padding:40}}><div style={{fontSize:40}}>🔒</div><div style={{color:DIM,marginTop:8}}>Student management permission not granted.</div></div>}
        {tab==='questions'&&!hasPermission('manage_questions')&&<div style={{...cs,textAlign:'center',padding:40}}><div style={{fontSize:40}}>🔒</div><div style={{color:DIM,marginTop:8}}>Question bank permission not granted.</div></div>}
        {tab==='results'&&!hasPermission('view_results')&&<div style={{...cs,textAlign:'center',padding:40}}><div style={{fontSize:40}}>🔒</div><div style={{color:DIM,marginTop:8}}>Results view permission not granted.</div></div>}
        {tab==='announcements'&&!hasPermission('send_announcements')&&<div style={{...cs,textAlign:'center',padding:40}}><div style={{fontSize:40}}>🔒</div><div style={{color:DIM,marginTop:8}}>Announcements permission not granted.</div></div>}

JSXEOF

echo "✅ JSX written ($(wc -l < $JSXFILE) lines)"

node << 'NODEEOF'
const fs=require('fs');
const FILE=process.env.FILE;
const JSXFILE=process.env.JSXFILE;
const lines=fs.readFileSync(FILE,'utf8').split('\n');
const newContent=fs.readFileSync(JSXFILE,'utf8');

// Find line 529 (index 528) = {/* ══ ALL EXAMS ══ */}
// Find closing section before </div></div>) — lines 715-718 stay
// Replace lines 529-713 (indexes 528-712) with new content

const START_IDX=528; // line 529
const END_IDX=713;   // line 714 onwards stays (blank + </div></div>)

const before=lines.slice(0,START_IDX).join('\n');
const after=lines.slice(END_IDX).join('\n');

// Need to add state vars for new features if not present
let fileContent=before+'\n'+newContent+'\n'+after;

// Add examSearch, studentSearch, examStep, eCat state if not present
if(!fileContent.includes('examSearch')){
  fileContent=fileContent.replace(
    'const [tab,setTab]=useState(',
    'const [examSearch,setExamSearch]=useState(\'\');\n  const [studentSearch,setStudentSearch]=useState(\'\');\n  const [examStep,setExamStep]=useState(0);\n  const [eCat,setECat]=useState(\'Full Mock Test\');\n  const [tab,setTab]=useState('
  );
  console.log('\u2705 New state vars added: examSearch, studentSearch, examStep, eCat');
}

fs.writeFileSync(FILE,fileContent,'utf8');
console.log('\u2705 Admin Panel: Rich content tabs applied!');
console.log('   Total lines: '+fileContent.split('\n').length);
NODEEOF

rm -f "$JSXFILE"
echo ""
echo "════════════════════════════════════════════════════"
echo "✅ Done! Run: git add -A && git commit -m 'Admin Panel: Rich content for all feature tabs' && git push"
echo "════════════════════════════════════════════════════"
