#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  ProveRank — F37 Getting Started Checklist (FRONTEND)
#  Patches: frontend/app/dashboard/page.tsx
#  Adds: ChecklistWidget component inside DashboardContent
# ═══════════════════════════════════════════════════════════════
set -e

DASH_F=$(find . -path "*/app/dashboard/page.tsx" | grep -v node_modules | head -1)
echo "Dashboard: $DASH_F"
cp "$DASH_F" "${DASH_F}.bak_f37"
export DASH_F

node << 'JSEOF'
const fs = require('fs');
const f  = process.env.DASH_F;
let c = fs.readFileSync(f, 'utf8');

if (c.includes('ChecklistWidget') || c.includes('Getting Started')) {
  console.log('ℹ️  Checklist already present');
  process.exit(0);
}

// ── 1. Add Confetti component + ChecklistWidget before DashboardContent ──
const CHECKLIST_CODE = `
// ── F37: Confetti burst ───────────────────────────────────────
function ChecklistConfetti() {
  const colors = ['#4D9FFF','#00C48C','#FFD700','#FF6B9D','#7B4DFF','#00D4FF']
  return (
    <div style={{position:'fixed',inset:0,pointerEvents:'none',zIndex:999,overflow:'hidden'}}>
      {Array.from({length:50}).map((_,i)=>(
        <div key={i} style={{
          position:'absolute',top:'-10px',
          left:Math.random()*100+'%',
          width:i%3===0?8:5,height:i%3===0?8:5,
          borderRadius:i%2===0?'50%':2,
          background:colors[i%colors.length],
          animation:'confettiFall '+(1.2+Math.random()*1.5)+'s ease-in forwards',
          animationDelay:Math.random()*0.6+'s'
        }}/>
      ))}
      <style>{'@keyframes confettiFall{from{transform:translateY(-10px) rotate(0deg);opacity:1}to{transform:translateY(100vh) rotate(720deg);opacity:0}}'}</style>
    </div>
  )
}

// ── F37: Badge Unlocked Modal ─────────────────────────────────
function BadgeModal({onClose}:{onClose:()=>void}) {
  const C2 = C
  return (
    <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.8)',zIndex:1000,display:'flex',alignItems:'center',justifyContent:'center',padding:20}} onClick={onClose}>
      <div onClick={e=>e.stopPropagation()} style={{background:'rgba(0,18,40,0.98)',border:'1px solid rgba(77,159,255,0.4)',borderRadius:22,padding:'36px 28px',maxWidth:340,width:'100%',textAlign:'center',boxShadow:'0 0 60px rgba(77,159,255,0.2)',animation:'fadeIn .4s ease'}}>
        <div style={{fontSize:64,marginBottom:12,animation:'bounce 1s ease-in-out 3'}}>🏅</div>
        <div style={{fontFamily:'Playfair Display,serif',fontSize:22,fontWeight:700,color:'#E8F4FF',marginBottom:8}}>Badge Unlocked!</div>
        <div style={{fontSize:14,color:'#4D9FFF',fontWeight:700,marginBottom:8}}>"Pathfinder" 🗺️</div>
        <div style={{fontSize:12,color:'#6B8FAF',marginBottom:20,lineHeight:1.6}}>You completed all 5 Getting Started tasks! +220 XP earned.</div>
        <button onClick={onClose} style={{background:'linear-gradient(135deg,#4D9FFF,#0055CC)',border:'none',borderRadius:10,padding:'10px 28px',color:'#fff',fontSize:13,fontWeight:700,cursor:'pointer'}}>
          Awesome! 🚀
        </button>
      </div>
    </div>
  )
}

// ── F37: Welcome Banner trigger ───────────────────────────────
function ChecklistWidget({token,toast,lang}:{token:string;toast:(m:string,t?:'s'|'e'|'w')=>void;lang:'en'|'hi'}) {
  const API2 = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
  const t2 = (en:string,hi:string) => lang==='en'?en:hi
  const [items,    setItems]    = React.useState<any[]>([])
  const [count,    setCount]    = React.useState(0)
  const [allDone,  setAllDone]  = React.useState(false)
  const [confetti, setConfetti] = React.useState(false)
  const [badgeModal,setBadgeModal] = React.useState(false)
  const [hasBadge, setHasBadge]= React.useState(false)
  const [loading,  setLoading]  = React.useState(true)
  const [showBanner,setShowBanner] = React.useState(false)

  React.useEffect(()=>{
    if(!token) return
    fetch(API2+'/api/auth/checklist',{headers:{Authorization:'Bearer '+token}})
      .then(r=>r.json())
      .then(d=>{
        if(d.success){
          setItems(d.items||[])
          setCount(d.completedCount||0)
          setAllDone(d.allDone||false)
          setHasBadge(d.hasBadge||false)
        }
        setLoading(false)
      })
      .catch(()=>setLoading(false))
  },[token])

  // Award badge when all done
  React.useEffect(()=>{
    if(allDone && !hasBadge && !loading){
      setConfetti(true)
      setBadgeModal(true)
      setTimeout(()=>setConfetti(false),4000)
      fetch(API2+'/api/auth/checklist/complete',{method:'POST',headers:{Authorization:'Bearer '+token}})
        .then(r=>r.json())
        .then(d=>{ if(d.success&&!d.alreadyAwarded) toast('🏅 Pathfinder badge unlocked! +220 XP','s') })
        .catch(()=>{})
    }
  },[allDone,hasBadge,loading])

  // 37.3 — on item click: show welcome banner first time
  const handleItemClick = (href:string, itemId:string) => {
    const key = 'pr_checklist_clicked_'+itemId
    const firstTime = !localStorage.getItem(key)
    if(firstTime){
      localStorage.setItem(key,'1')
      setShowBanner(true)
      setTimeout(()=>{ setShowBanner(false); window.location.href=href },2000)
    } else {
      window.location.href = href
    }
    // Mark pyq/analytics as visited
    if(itemId==='pyq'||itemId==='analytics'){
      fetch(API2+'/api/auth/checklist/mark',{
        method:'POST',
        headers:{Authorization:'Bearer '+token,'Content-Type':'application/json'},
        body:JSON.stringify({item:itemId})
      }).catch(()=>{})
    }
  }

  if(loading) return null
  // Hide widget if all done AND badge already given (seen before)
  if(allDone && hasBadge) return null

  const pct = Math.round((count/5)*100)

  return (
    <>
      {confetti && <ChecklistConfetti/>}
      {badgeModal && <BadgeModal onClose={()=>setBadgeModal(false)}/>}

      {/* 37.3 — Welcome banner overlay */}
      {showBanner && (
        <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.75)',zIndex:990,display:'flex',alignItems:'center',justifyContent:'center'}}>
          <div style={{background:'rgba(0,18,36,0.98)',border:'1px solid rgba(77,159,255,0.4)',borderRadius:20,padding:'32px 24px',textAlign:'center',maxWidth:340,animation:'fadeIn .4s ease'}}>
            <div style={{fontSize:48,marginBottom:10}}>🎉</div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:18,fontWeight:700,color:'#E8F4FF',marginBottom:6}}>
              {t2("Let's Go!","चलते हैं!")}
            </div>
            <div style={{fontSize:12,color:'#6B8FAF'}}>
              {t2("Taking you there now...","अभी ले जा रहे हैं...")}
            </div>
          </div>
        </div>
      )}

      {/* 37.8 — Checklist Card */}
      <div style={{
        background:'linear-gradient(135deg,rgba(0,35,80,0.85),rgba(0,22,50,0.9))',
        border:'1px solid rgba(77,159,255,0.25)',
        borderRadius:18, padding:20, marginBottom:20,
        backdropFilter:'blur(16px)',
        boxShadow:'0 4px 28px rgba(0,0,0,0.2)'
      }}>
        {/* Header */}
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
          <div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:15,fontWeight:700,color:'#E8F4FF',marginBottom:2}}>
              🚀 {t2('Getting Started','शुरुआत करें')}
            </div>
            <div style={{fontSize:11,color:'#6B8FAF'}}>
              {t2('Complete tasks to unlock your Pathfinder badge','Pathfinder बैज अनलॉक करें')}
            </div>
          </div>
          <div style={{textAlign:'right'}}>
            <div style={{fontSize:18,fontWeight:800,color:'#4D9FFF'}}>{count}/5</div>
            <div style={{fontSize:9,color:'#6B8FAF'}}>{t2('Complete','पूर्ण')}</div>
          </div>
        </div>

        {/* 37.2 Progress bar */}
        <div style={{background:'rgba(255,255,255,0.06)',borderRadius:6,height:6,overflow:'hidden',marginBottom:16}}>
          <div style={{
            height:'100%',
            width:pct+'%',
            background:'linear-gradient(90deg,#4D9FFF,#00C48C)',
            borderRadius:6,
            transition:'width 0.8s ease'
          }}/>
        </div>

        {/* 37.1 — 5 items */}
        {allDone ? (
          /* 37.7 — All done state */
          <div style={{textAlign:'center',padding:'20px 0'}}>
            <div style={{fontSize:40,marginBottom:8}}>🎉</div>
            <div style={{fontFamily:'Playfair Display,serif',fontSize:16,fontWeight:700,color:'#00C48C',marginBottom:4}}>
              {t2('All done!','सब पूरा!')}
            </div>
            <div style={{fontSize:12,color:'#6B8FAF'}}>
              {t2("You're a Pathfinder! 🏅 +220 XP earned","आप Pathfinder हैं! 🏅 +220 XP मिला")}
            </div>
          </div>
        ) : (
          <div>
            {items.map((item,i)=>(
              <div key={item.id}
                onClick={()=>!item.done&&handleItemClick(item.href,item.id)}
                style={{
                  display:'flex', alignItems:'center', gap:12,
                  padding:'11px 0',
                  borderBottom: i<4 ? '1px solid rgba(77,159,255,0.08)' : 'none',
                  cursor: item.done ? 'default' : 'pointer',
                  transition:'all .2s',
                }}>
                {/* Icon */}
                <div style={{fontSize:20,flexShrink:0,width:32,textAlign:'center'}}>{item.icon}</div>

                {/* Text */}
                <div style={{flex:1}}>
                  {/* 37.9 — strikethrough on done */}
                  <div style={{
                    fontSize:13, fontWeight:600,
                    color: item.done ? '#4B6A8A' : '#E8F4FF',
                    textDecoration: item.done ? 'line-through' : 'none',
                    transition:'all .4s',
                    lineHeight:1.3,
                  }}>
                    {lang==='en' ? item.label_en : item.label_hi}
                  </div>
                  <div style={{fontSize:10,color:'#4B6A8A',marginTop:2}}>
                    +{item.xp} XP
                  </div>
                </div>

                {/* Status */}
                {item.done ? (
                  /* 37.9 — green tick */
                  <div style={{
                    width:24,height:24,borderRadius:'50%',
                    background:'rgba(0,196,140,0.15)',
                    border:'2px solid #00C48C',
                    display:'flex',alignItems:'center',justifyContent:'center',
                    flexShrink:0,
                    animation:'fadeIn .3s ease',
                  }}>
                    <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
                      <polyline points="2,6 5,9 10,3" stroke="#00C48C" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                  </div>
                ) : (
                  /* Arrow */
                  <div style={{color:'rgba(77,159,255,0.4)',fontSize:16,flexShrink:0}}>→</div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </>
  )
}

`;

// ── 2. Add React import if not present ──────────────────────
if (!c.includes("import React")) {
  c = c.replace(
    "import { useState, useEffect } from 'react'",
    "import React, { useState, useEffect } from 'react'"
  );
}

// ── 3. Inject component code before DashboardContent ────────
const INJECT_BEFORE = 'function DashboardContent()';
c = c.replace(INJECT_BEFORE, CHECKLIST_CODE + 'function DashboardContent()');

// ── 4. Inject <ChecklistWidget> inside DashboardContent return ──
// Inject after WelcomeBanner, before Hero Banner
const INJECT_AFTER = "{showWelcome&&welcomeData&&<WelcomeBanner student={welcomeData} onClose={()=>setShowWelcome(false)}/> }";
const WIDGET_JSX   = "\n      {/* F37 — Getting Started Checklist */}\n      <ChecklistWidget token={token} toast={toast} lang={lang}/>\n";
c = c.replace(INJECT_AFTER, INJECT_AFTER + WIDGET_JSX);

fs.writeFileSync(f, c);

// ── Verify ──────────────────────────────────────────────────
const v = fs.readFileSync(f,'utf8');
const checks = [
  ['37.1 5 checklist items fetched from API',     v.includes('/api/auth/checklist')],
  ['37.2 Progress bar (count/5)',                  v.includes('count/5')],
  ['37.3 Welcome banner on first click',           v.includes('pr_checklist_clicked')],
  ['37.4 Dashboard widget (ChecklistWidget)',       v.includes('ChecklistWidget')],
  ['37.5 Auto-check from API data',                v.includes('item.done')],
  ['37.6 XP points shown per item',                v.includes('+{item.xp} XP')],
  ['37.7 All done state with confetti',            v.includes('All done') && v.includes('ChecklistConfetti')],
  ['37.8 Blue-tinted card background',             v.includes('rgba(0,35,80')],
  ['37.9 Strikethrough on completed items',        v.includes('line-through')],
  ['37.10 Badge Unlocked modal (Pathfinder)',       v.includes('BadgeModal') && v.includes('Pathfinder')],
];

let pass=0,fail=0;
checks.forEach(([l,ok])=>{ console.log((ok?'✅':'❌')+' '+l); ok?pass++:fail++; });
console.log('\n'+pass+'/'+checks.length+' passed');
if(fail===0) console.log('🎉 F37 Frontend fully implemented!');
JSEOF

echo ""
echo "git add . && git commit -m 'feat: F37 Getting Started Checklist widget on dashboard' && git push"
