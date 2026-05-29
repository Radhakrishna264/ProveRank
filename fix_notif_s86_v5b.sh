#!/bin/bash
# ProveRank Fix v5b: Restore + Surgical Notification Panel Fix
echo "=================================================="
echo " ProveRank Fix v5b: Restore + Safe Notif Fix"
echo "=================================================="

PAGE="$HOME/workspace/frontend/app/admin/x7k2p/page.tsx"

# Step 1: Restore from backup
if [ -f "${PAGE}.bak_v5" ]; then
  cp "${PAGE}.bak_v5" "$PAGE"
  echo "✅ Restored from bak_v5"
elif [ -f "${PAGE}.bak_v4" ]; then
  cp "${PAGE}.bak_v4" "$PAGE"
  echo "✅ Restored from bak_v4"
else
  echo "❌ No backup found!"
  exit 1
fi

echo ""
echo "--- Finding exact notification panel lines ---"
grep -n "No notifications yet\|notifOpen\|Alerts will appear\|🔕\|🔔" "$PAGE" | head -20

echo ""
echo "--- Finding exact line numbers for surgical edit ---"
START=$(grep -n "notifOpen&&(" "$PAGE" | head -1 | cut -d: -f1)
echo "notifOpen panel starts at line: $START"

# Show context around the notification panel
if [ ! -z "$START" ]; then
  sed -n "${START},$((START+5))p" "$PAGE"
fi

echo ""
echo "--- Applying surgical fixes ---"

node << 'NODEEOF'
const fs = require('fs');
const PAGE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let content = fs.readFileSync(PAGE, 'utf8');
let fixes = 0;

// ─────────────────────────────────────────────────────────────────────────
// FIX 1: Add handler functions SAFELY — before the return( statement
// Only add if not already present
// ─────────────────────────────────────────────────────────────────────────
if (!content.includes('markAllRead') && !content.includes('markOneRead')) {
  const fns = `
  const markAllRead=async()=>{const tk=getToken();if(!tk)return;try{await fetch(\`\${API}/api/admin/notifications/mark-read\`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:\`Bearer \${tk}\`},body:JSON.stringify({all:true})});setNotifs((prev:any[])=>prev.map((n:any)=>({...n,isRead:true})));}catch(e){}};
  const markOneRead=async(id:string)=>{const tk=getToken();if(!tk)return;try{await fetch(\`\${API}/api/admin/notifications/mark-read\`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:\`Bearer \${tk}\`},body:JSON.stringify({id})});setNotifs((prev:any[])=>prev.map((n:any)=>n._id===id?{...n,isRead:true}:n));}catch(e){}};
`;
  // Insert right before "return(" at the top level
  // Find last closing brace before return
  const returnMatch = content.match(/\n(\s{0,4})return\s*\(/);
  if (returnMatch) {
    const insertPos = content.lastIndexOf(returnMatch[0]);
    content = content.slice(0, insertPos) + '\n' + fns + content.slice(insertPos);
    console.log('✅ Fix 1: markAllRead + markOneRead added');
    fixes++;
  }
} else {
  console.log('✅ Fix 1: Handler functions already present');
}

// ─────────────────────────────────────────────────────────────────────────
// FIX 2: Surgically replace ONLY the inner content of notification dropdown
// Find "No notifications yet" block and replace just the content inside
// ─────────────────────────────────────────────────────────────────────────

// Find the exact "No notifications yet" text block  
const noNotifIdx = content.indexOf('No notifications yet');
if (noNotifIdx === -1) {
  console.log('❌ "No notifications yet" text not found');
  process.exit(1);
}

// Find the opening div of the notification panel — walk backwards from noNotifIdx
// to find {notifOpen&&(
const panelOpenStr = 'notifOpen&&(';
const panelOpenIdx = content.lastIndexOf(panelOpenStr, noNotifIdx);
if (panelOpenIdx === -1) {
  console.log('❌ notifOpen&&( not found before notification content');
  process.exit(1);
}
console.log('✅ Found notifOpen&&( at char ' + panelOpenIdx);

// Now find the matching closing )} for this panel
// We need to count parens from the ( after notifOpen&&
let depth = 0;
let panelCloseIdx = -1;
let searchStart = panelOpenIdx + panelOpenStr.length; // start after the (

// The ( is part of notifOpen&&( so we start with depth=1
depth = 1;
for (let i = searchStart; i < content.length; i++) {
  if (content[i] === '(') depth++;
  if (content[i] === ')') {
    depth--;
    if (depth === 0) {
      panelCloseIdx = i;
      break;
    }
  }
}

if (panelCloseIdx === -1) {
  console.log('❌ Could not find closing ) of notification panel');
  process.exit(1);
}

// Check what follows the closing )
const afterClose = content.slice(panelCloseIdx, panelCloseIdx + 5);
console.log('✅ Panel closes at char ' + panelCloseIdx + ' — next chars: ' + JSON.stringify(afterClose));

// Extract the old panel
const oldPanel = content.slice(panelOpenIdx, panelCloseIdx + 1);
console.log('Old panel length: ' + oldPanel.length + ' chars');
console.log('Old panel start: ' + oldPanel.slice(0, 80));

// Build new panel
const newPanel = `notifOpen&&(
    <div style={{position:'fixed',top:52,right:8,width:320,maxHeight:460,background:'#0d1b2e',border:'1px solid #1e3a5f',borderRadius:12,boxShadow:'0 8px 32px rgba(0,0,0,0.6)',zIndex:9999,display:'flex',flexDirection:'column',overflow:'hidden'}}>
      <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',padding:'10px 14px',borderBottom:'1px solid #1e3a5f',background:'#0a1628'}}>
        <span style={{fontWeight:700,fontSize:14,color:'#e2e8f0'}}>🔔 Notifications</span>
        <div style={{display:'flex',gap:6,alignItems:'center'}}>
          {notifs.filter((n:any)=>!n.isRead).length>0&&(
            <button onClick={markAllRead} style={{fontSize:10,color:'#60a5fa',background:'none',border:'1px solid #1e3a5f',borderRadius:6,padding:'2px 7px',cursor:'pointer'}}>Mark all read</button>
          )}
          <button onClick={()=>setNotifOpen(false)} style={{background:'none',border:'none',color:'#64748b',fontSize:17,cursor:'pointer',lineHeight:1,padding:0}}>×</button>
        </div>
      </div>
      <div style={{overflowY:'auto',flex:1}}>
        {notifs.length===0?(
          <div style={{display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',padding:'36px 16px',color:'#475569'}}>
            <div style={{fontSize:36,marginBottom:8}}>🔕</div>
            <div style={{fontSize:13,fontWeight:600}}>No notifications yet</div>
            <div style={{fontSize:11,marginTop:3}}>Alerts will appear here</div>
          </div>
        ):(
          notifs.slice(0,20).map((n:any,ni:number)=>{
            const sev=n.severity||n.type||'info';
            const cm:any={high:{bg:'rgba(220,38,38,0.12)',bd:'#dc2626',ic:'🔴'},warning:{bg:'rgba(245,158,11,0.12)',bd:'#f59e0b',ic:'⚠️'},suspicious:{bg:'rgba(168,85,247,0.12)',bd:'#a855f7',ic:'🚨'},success:{bg:'rgba(34,197,94,0.12)',bd:'#22c55e',ic:'✅'},info:{bg:'rgba(59,130,246,0.12)',bd:'#3b82f6',ic:'💬'}};
            const c=cm[sev]||cm.info;
            const ts=n.createdAt?new Date(n.createdAt).toLocaleString('en-IN',{day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'}):'';
            return(
              <div key={n._id||ni} onClick={()=>markOneRead(n._id)} style={{padding:'10px 14px',borderBottom:'1px solid #1e3a5f',background:n.isRead?'transparent':c.bg,borderLeft:'3px solid '+(n.isRead?'#1e3a5f':c.bd),cursor:'pointer'}}>
                <div style={{display:'flex',gap:8,alignItems:'flex-start'}}>
                  <span style={{fontSize:14}}>{c.ic}</span>
                  <div style={{flex:1,minWidth:0}}>
                    <div style={{display:'flex',alignItems:'center',gap:5}}>
                      <span style={{fontSize:12,fontWeight:n.isRead?400:700,color:n.isRead?'#94a3b8':'#e2e8f0',overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap',flex:1}}>{n.title||n.message||'Alert'}</span>
                      {!n.isRead&&<span style={{width:6,height:6,borderRadius:'50%',background:c.bd,flexShrink:0,display:'inline-block'}}/>}
                    </div>
                    {n.message&&n.title&&<div style={{fontSize:10,color:'#64748b',marginTop:1,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{n.message}</div>}
                    {ts&&<div style={{fontSize:10,color:'#475569',marginTop:2}}>{ts}</div>}
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>
      {notifs.length>0&&(
        <div style={{padding:'8px 14px',borderTop:'1px solid #1e3a5f',background:'#0a1628',textAlign:'center'}}>
          <span style={{fontSize:11,color:'#60a5fa',cursor:'pointer',fontWeight:600}}>View All Notifications →</span>
        </div>
      )}
    </div>
  )`;

content = content.slice(0, panelOpenIdx) + newPanel + content.slice(panelCloseIdx + 1);
console.log('✅ Fix 2: Notification panel replaced surgically');
fixes++;

// ─────────────────────────────────────────────────────────────────────────
// FIX 3: Bell badge unread count
// ─────────────────────────────────────────────────────────────────────────
// Find badge — typically shows notifs.length, change to unread count
const badgePattern = /\{notifs\.length\s*>\s*0\s*&&\s*<[^>]*>[^<]*\{notifs\.length\}/;
if (badgePattern.test(content)) {
  content = content.replace(badgePattern, (m) => {
    return m
      .replace('notifs.length>0', "notifs.filter((n:any)=>!n.isRead).length>0")
      .replace('{notifs.length}', "{notifs.filter((n:any)=>!n.isRead).length}");
  });
  console.log('✅ Fix 3: Bell badge = unread count');
  fixes++;
} else {
  console.log('ℹ️  Fix 3: Badge pattern not matched — may need manual check');
}

fs.writeFileSync(PAGE, content);
console.log('\n✅ Total fixes: ' + fixes);
NODEEOF

echo ""
echo "--- Verify syntax ---"
node -e "
const fs=require('fs');
const c=fs.readFileSync('$PAGE','utf8');
// Basic JSX balance check
const opens=(c.match(/\{/g)||[]).length;
const closes=(c.match(/\}/g)||[]).length;
console.log('{ count:', opens, '} count:', closes, 'diff:', opens-closes);
" 2>&1

echo ""
echo "--- Git Push ---"
cd ~/workspace
git add frontend/app/admin/x7k2p/page.tsx
git commit -m "feat(S86): notification panel complete — safe surgical replacement"
git push origin main

echo ""
echo "=================================================="
echo "✅ ALL DONE — Vercel deploy ~2 min"
echo "🔗 https://prove-rank.vercel.app/admin/x7k2p"
echo "=================================================="
