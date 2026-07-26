const fs = require('fs');
const path = require('path');

const CANDIDATES = [
  process.env.APP_DIR,
  '/root/workspace/frontend/app/exam/[examId]/attempt',
  '/home/runner/workspace/frontend/app/exam/[examId]/attempt',
  path.join(process.cwd(), 'frontend/app/exam/[examId]/attempt'),
].filter(Boolean);

let TARGET = null;
for (const dir of CANDIDATES) {
  const p = path.join(dir, 'page.tsx');
  if (fs.existsSync(p)) { TARGET = p; break; }
}
if (!TARGET) {
  console.error('❌ Could not find exam attempt page.tsx automatically.');
  console.error("   Set APP_DIR env var, e.g.:");
  console.error("   APP_DIR='/home/runner/workspace/frontend/app/exam/[examId]/attempt' node patch_attempt_f57_v3.js");
  process.exit(1);
}
console.log('📄 Target file:', TARGET);
fs.copyFileSync(TARGET, TARGET + '.bak_v3_' + Date.now());

let src = fs.readFileSync(TARGET, 'utf8');
let count = 0;

// ── 1) Replace the tab-switch effect (exact block copied from the live file) ──
{
  const anchor = `  // Anti-cheat: tab switch
  useEffect(()=>{
    const onVis = () => {
      if (document.hidden && attempt) {
        setWarnings(w => {
          const next = w+1
          if (next >= 3) { autoSubmit(); return next }
          // Save warning to backend
          if (user && attempt?._id) {
            fetch(\`\${API}/api/attempts/\${attempt._id}/tab-switch\`,{
              method:'POST', headers:{'Content-Type':'application/json','Authorization':\`Bearer \${user.token}\`},
              body:JSON.stringify({count:next})
            }).catch(()=>{})
          }
          return next
        })
      }
    }
    document.addEventListener('visibilitychange', onVis)
    return () => document.removeEventListener('visibilitychange', onVis)
  },[attempt, user])`;

  const replacement = `  // F57 v3 — Anti-cheat: tab switch + window blur + fullscreen enforcement
  // (real /api/anticheat/* routes, attemptId + examId both sent as required by backend)
  useEffect(()=>{
    const logWarning = (type) => setWarningHistory(h => [{ type, at: new Date().toLocaleTimeString() }, ...h].slice(0, 15))

    const onVis = () => {
      if (document.hidden && attempt) {
        logWarning('Tab Switch')
        if (user && attempt?._id) {
          fetch(\`\${API}/api/anticheat/tab-switch\`,{
            method:'POST', headers:{'Content-Type':'application/json','Authorization':\`Bearer \${user.token}\`},
            body:JSON.stringify({attemptId: attempt._id, examId})
          }).then(r=>r.json()).then(d=>{
            if (typeof d?.warningCount === 'number') setWarnings(d.warningCount)
            if (d?.autoSubmitted) autoSubmit()
          }).catch(()=>{
            setWarnings(w => { const next = w+1; if (next >= 3) autoSubmit(); return next })
          })
        }
      }
    }

    const onBlur = () => {
      if (attempt) {
        logWarning('Window Blur')
        if (user && attempt?._id) {
          fetch(\`\${API}/api/anticheat/window-blur\`,{
            method:'POST', headers:{'Content-Type':'application/json','Authorization':\`Bearer \${user.token}\`},
            body:JSON.stringify({attemptId: attempt._id, examId})
          }).then(r=>r.json()).then(d=>{
            if (typeof d?.warningCount === 'number') setWarnings(d.warningCount)
            if (d?.autoSubmitted) autoSubmit()
          }).catch(()=>{})
        }
      }
    }

    const requestFS = () => { try { document.documentElement.requestFullscreen?.() } catch(e){} }
    const onFsChange = () => {
      const isFs = !!document.fullscreenElement
      setFsCompliant(isFs)
      setFocusLocked(isFs)
      if (!isFs && attempt) {
        setShowFSWarning(true)
        logWarning('Fullscreen Exit')
        fsExitTimerRef.current = setTimeout(() => {
          if (user && attempt?._id) {
            fetch(\`\${API}/api/anticheat/fullscreen-exit\`,{
              method:'POST', headers:{'Content-Type':'application/json','Authorization':\`Bearer \${user.token}\`},
              body:JSON.stringify({attemptId: attempt._id, examId})
            }).then(r=>r.json()).then(d=>{
              if (typeof d?.warningCount === 'number') setWarnings(d.warningCount)
              if (d?.autoSubmitted) autoSubmit()
            }).catch(()=>{})
          }
        }, 5000) // 5-second grace period before warning counted
      } else {
        setShowFSWarning(false)
        if (fsExitTimerRef.current) { clearTimeout(fsExitTimerRef.current); fsExitTimerRef.current = null }
      }
    }

    requestFS()
    document.addEventListener('fullscreenchange', onFsChange)
    window.addEventListener('blur', onBlur)
    document.addEventListener('visibilitychange', onVis)
    return () => {
      document.removeEventListener('visibilitychange', onVis)
      document.removeEventListener('fullscreenchange', onFsChange)
      window.removeEventListener('blur', onBlur)
      if (fsExitTimerRef.current) clearTimeout(fsExitTimerRef.current)
    }
  },[attempt, user, examId])`;

  if (src.includes(anchor)) {
    src = src.replace(anchor, replacement);
    count++;
    console.log('✅ Patched: tab-switch/window-blur/fullscreen effect rewritten (real endpoints + examId + warning history)');
  } else if (src.includes('/api/anticheat/tab-switch')) {
    console.log('⚠️  Anti-cheat effect already patched — skipping');
  } else {
    console.log('❌ tab-switch effect anchor not found — patch NOT applied for this block.');
  }
}

// ── 2) Focus-lock + integrity-impact badges next to the existing warnings badge ──
{
  const anchor = `{warnings>0 && <span className="badge badge-red">⚠️ {warnings}/3</span>}`;
  const replacement = `{warnings>0 && <span className="badge badge-red">⚠️ {warnings}/3</span>}
            <span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background:focusLocked?'#123b1e':'#3a1414',color:focusLocked?'#7CFC9C':'#ff8080'}}>
              {focusLocked ? '🔒 Focus Locked' : '🔓 Focus Lost'}
            </span>
            <span style={{fontSize:10,padding:'2px 8px',borderRadius:20,background: integrityImpact==='none'?'#123b1e':integrityImpact==='low'?'#3a2a00':integrityImpact==='medium'?'#3a2200':'#3a1414', color: integrityImpact==='none'?'#7CFC9C':integrityImpact==='low'?'#f2d38a':integrityImpact==='medium'?'#ffb066':'#ff8080'}}>
              🛡️ {integrityImpact}
            </span>`;
  if (src.includes(anchor) && !src.includes('Focus Locked')) {
    src = src.replace(anchor, replacement);
    count++;
    console.log('✅ Patched: added focus-lock + integrity-impact badges next to Warnings counter');
  } else if (src.includes('Focus Locked')) {
    console.log('⚠️  Badges already present — skipping');
  } else {
    console.log('❌ Warnings badge anchor not found — badges NOT added.');
  }
}

// ── 3) Fullscreen warning modal — inserted before the Feature 32 notification block ──
{
  const anchor = `{/* ── Feature 32: Time Extension Notification ── */}`;
  const modal = `{/* ── F57 v3: Fullscreen Exit Warning Modal ── */}
      {showFSWarning && (
        <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.75)',display:'flex',alignItems:'center',justifyContent:'center',zIndex:300,backdropFilter:'blur(4px)'}}>
          <div style={{background:'rgba(30,5,5,0.97)',border:'1px solid #FF4757',borderRadius:20,padding:'32px',maxWidth:400,width:'90%',textAlign:'center'}}>
            <div style={{fontSize:44,marginBottom:12}}>⚠️</div>
            <h2 style={{fontFamily:'Playfair Display,serif',fontSize:19,fontWeight:700,color:'#FF4757',marginBottom:10}}>{lang==='en'?'Fullscreen Exited!':'फुलस्क्रीन बंद हो गया!'}</h2>
            <p style={{color:'#ddd',fontSize:13,marginBottom:20}}>{lang==='en'?'You must stay in fullscreen during the exam. Return now to avoid a warning.':'परीक्षा के दौरान फुलस्क्रीन में रहना अनिवार्य है। चेतावनी से बचने के लिए तुरंत वापस लौटें।'}</p>
            <button onClick={()=>document.documentElement.requestFullscreen?.()} style={{width:'100%',padding:14,borderRadius:10,border:'none',background:'linear-gradient(135deg,#4D9FFF,#0055CC)',color:'#fff',fontWeight:700,fontSize:14,cursor:'pointer'}}>
              {lang==='en'?'↩ Return to Fullscreen':'↩ फुलस्क्रीन पर लौटें'}
            </button>
          </div>
        </div>
      )}
      ${anchor}`;
  if (src.includes(anchor) && !src.includes('Fullscreen Exit Warning Modal')) {
    src = src.replace(anchor, modal);
    count++;
    console.log('✅ Patched: added fullscreen-exit warning modal (showFSWarning UI)');
  } else if (src.includes('Fullscreen Exit Warning Modal')) {
    console.log('⚠️  Warning modal already present — skipping');
  } else {
    console.log('❌ Feature-32 anchor not found — warning modal NOT added. Add manually before the closing </div>.');
  }
}

fs.writeFileSync(TARGET, src, 'utf8');
console.log(`\n✅ F57 v3 patch complete — ${count} block(s) modified. Backup saved as ${TARGET}.bak_v3_*`);
if (count === 0) console.log('⚠️  NOTHING was changed — please share the current file content again for a fresh targeted patch.');
