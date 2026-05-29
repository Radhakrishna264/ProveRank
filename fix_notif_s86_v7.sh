#!/bin/bash
# ProveRank Fix v7: Notification click detail + View All navigation
echo "=================================================="
echo " ProveRank Fix v7: Notif Detail + View All Nav"
echo "=================================================="

PAGE="$HOME/workspace/frontend/app/admin/x7k2p/page.tsx"
if [ ! -f "$PAGE" ]; then echo "❌ page.tsx not found"; exit 1; fi

cp "$PAGE" "${PAGE}.bak_v7"
echo "✅ Backup done"

# Check what tab key notifications uses
echo "--- Checking notifications tab key ---"
grep -n "notifications\|notif.*tab\|tab.*notif" "$PAGE" | grep -i "key\|value\|tab=" | head -10

echo "--- Checking setTab/setSection pattern ---"
grep -n "setTab\|setSection\|setActiveTab\|setPage\|setView" "$PAGE" | head -10

node << 'NODEEOF'
const fs = require('fs');
const PAGE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let content = fs.readFileSync(PAGE, 'utf8');
let fixes = 0;

// ─────────────────────────────────────────────────────────────────────────
// Step 1: Find the tab/navigation function name
// ─────────────────────────────────────────────────────────────────────────
let tabFn = '';
let tabKey = '';

// Find setTab or similar
const tabFnMatch = content.match(/const\s+(setTab|setSection|setActiveTab|setPage|setView)\s*=/);
if (tabFnMatch) {
  tabFn = tabFnMatch[1];
  console.log('Tab function: ' + tabFn);
}

// Find notifications tab key
const notifTabMatch = content.match(/['"](notifications?|notif)['"]/g);
if (notifTabMatch) {
  tabKey = notifTabMatch[0].replace(/['"]/g, '');
  console.log('Notifications tab key: ' + tabKey);
}

// ─────────────────────────────────────────────────────────────────────────
// FIX 1: Add notifDetail state for selected notification
// ─────────────────────────────────────────────────────────────────────────
if (!content.includes('notifDetail') && !content.includes('selectedNotif')) {
  // Add state near other notif states
  const notifOpenState = content.indexOf('notifOpen,setNotifOpen');
  if (notifOpenState > -1) {
    // Find the full line
    const lineStart = content.lastIndexOf('\n', notifOpenState) + 1;
    const lineEnd = content.indexOf('\n', notifOpenState);
    const line = content.slice(lineStart, lineEnd);
    content = content.slice(0, lineEnd) + '\n  const [notifDetail,setNotifDetail]=useState<any>(null);' + content.slice(lineEnd);
    console.log('✅ Fix 1: notifDetail state added');
    fixes++;
  } else {
    // Find useState for notifs
    const notifState = content.indexOf('setNotifs]=useState');
    if (notifState > -1) {
      const lineEnd = content.indexOf('\n', notifState);
      content = content.slice(0, lineEnd) + '\n  const [notifDetail,setNotifDetail]=useState<any>(null);' + content.slice(lineEnd);
      console.log('✅ Fix 1b: notifDetail state added near notifs');
      fixes++;
    }
  }
} else {
  console.log('✅ Fix 1: notifDetail state already exists');
}

// ─────────────────────────────────────────────────────────────────────────
// FIX 2: Update markOneRead to also set notifDetail
// ─────────────────────────────────────────────────────────────────────────
if (content.includes('const markOneRead=async(id:string)')) {
  // Replace markOneRead to also open detail
  content = content.replace(
    /const markOneRead=async\(id:string\)=>\{[^}]+\};/,
    `const markOneRead=async(id:string,notif?:any)=>{const tk=getToken();if(!tk)return;if(notif)setNotifDetail(notif);try{await fetch(\`\${API}/api/admin/notifications/mark-read\`,{method:'POST',headers:{'Content-Type':'application/json',Authorization:\`Bearer \${tk}\`},body:JSON.stringify({id})});setNotifs((prev:any[])=>prev.map((n:any)=>n._id===id?{...n,isRead:true}:n));}catch(e){}};`
  );
  console.log('✅ Fix 2: markOneRead updated to open detail');
  fixes++;
}

// ─────────────────────────────────────────────────────────────────────────
// FIX 3: Update notification item onClick to pass notif object
// ─────────────────────────────────────────────────────────────────────────
// Find onClick={()=>markOneRead(n._id)} and replace with onClick={()=>markOneRead(n._id,n)}
if (content.includes('onClick={()=>markOneRead(n._id)}')) {
  content = content.replace(
    /onClick=\{=\(\)=>markOneRead\(n\._id\)\}/g,
    'onClick={()=>markOneRead(n._id,n)}'
  );
  // Also try without extra =
  content = content.replace(
    /onClick=\{()=>markOneRead\(n\._id\)\}/g,
    'onClick={()=>markOneRead(n._id,n)}'
  );
  console.log('✅ Fix 3: notification onClick passes notif object');
  fixes++;
} else {
  // Try finding the pattern more broadly
  const clickIdx = content.indexOf('markOneRead(n._id)');
  if (clickIdx > -1) {
    content = content.replace(/markOneRead\(n\._id\)/g, 'markOneRead(n._id,n)');
    console.log('✅ Fix 3b: markOneRead calls updated with notif param');
    fixes++;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// FIX 4: Add notification detail modal JSX
// ─────────────────────────────────────────────────────────────────────────
const detailModal = `
      {/* S86: Notification Detail Modal */}
      {notifDetail&&(
        <div onClick={()=>setNotifDetail(null)} style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.7)',zIndex:10000,display:'flex',alignItems:'center',justifyContent:'center',padding:16}}>
          <div onClick={(e)=>e.stopPropagation()} style={{background:'#0d1b2e',border:'1px solid #1e3a5f',borderRadius:14,padding:24,maxWidth:400,width:'100%',boxShadow:'0 16px 48px rgba(0,0,0,0.8)'}}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:16}}>
              <span style={{fontSize:16,fontWeight:700,color:'#e2e8f0',flex:1}}>{notifDetail.title||'Notification'}</span>
              <button onClick={()=>setNotifDetail(null)} style={{background:'none',border:'none',color:'#64748b',fontSize:20,cursor:'pointer',marginLeft:8,lineHeight:1}}>×</button>
            </div>
            <div style={{fontSize:13,color:'#94a3b8',marginBottom:16,lineHeight:1.6}}>{notifDetail.message||notifDetail.description||'No details available'}</div>
            {notifDetail.severity&&<div style={{marginBottom:12}}><span style={{fontSize:11,background:'rgba(59,130,246,0.2)',color:'#60a5fa',borderRadius:6,padding:'3px 10px',fontWeight:600}}>Type: {notifDetail.severity||notifDetail.type}</span></div>}
            {notifDetail.createdAt&&<div style={{fontSize:11,color:'#475569',marginBottom:16}}>🕐 {new Date(notifDetail.createdAt).toLocaleString('en-IN',{dateStyle:'medium',timeStyle:'short'})}</div>}
            <button onClick={()=>setNotifDetail(null)} style={{width:'100%',padding:'10px',background:'#1e3a5f',border:'none',borderRadius:8,color:'#e2e8f0',cursor:'pointer',fontSize:13,fontWeight:600}}>Close</button>
          </div>
        </div>
      )}`;

// Insert modal before closing of main return
if (!content.includes('Notification Detail Modal')) {
  // Find </div>\n) at the end of return
  const lastDiv = content.lastIndexOf('    </div>\n  )\n}');
  if (lastDiv > -1) {
    content = content.slice(0, lastDiv) + detailModal + '\n' + content.slice(lastDiv);
    console.log('✅ Fix 4: notification detail modal added');
    fixes++;
  } else {
    // Try alternate ending
    const altEnd = content.lastIndexOf('\n  );\n}');
    if (altEnd > -1) {
      content = content.slice(0, altEnd) + detailModal + content.slice(altEnd);
      console.log('✅ Fix 4b: modal added (alt position)');
      fixes++;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// FIX 5: View All → navigate to notifications tab
// ─────────────────────────────────────────────────────────────────────────
// Find the View All button and fix its onClick
const viewAllOld = /onClick=\{\(\)=>\{setNotifOpen\(false\);[^}]*window\.history[^}]*\}\}/;
const newTabNav = tabFn 
  ? `onClick={()=>{setNotifOpen(false);${tabFn}('notifications');}}`
  : `onClick={()=>{setNotifOpen(false);const el=document.querySelector('[data-tab="notifications"],[data-value="notifications"]');if(el){(el as HTMLElement).click();}else{const u=new URL(window.location.href);u.searchParams.set('tab','notifications');window.location.href=u.toString();}}}`;

if (viewAllOld.test(content)) {
  content = content.replace(viewAllOld, newTabNav);
  console.log('✅ Fix 5: View All → tab navigation fixed');
  fixes++;
} else if (content.includes('View All Notifications')) {
  // Find the button with View All and update onClick
  content = content.replace(
    /(<button[^>]*?)onClick=\{[^}]*searchParams[^}]*\}([^>]*>View All Notifications)/,
    `$1${newTabNav}$2`
  );
  console.log('✅ Fix 5b: View All navigation updated');
  fixes++;
}

fs.writeFileSync(PAGE, content);
console.log('\n✅ Total fixes: ' + fixes);
NODEEOF

echo ""
echo "--- Verify ---"
grep -n "notifDetail\|setNotifDetail" "$PAGE" | head -8
grep -n "View All Notifications" "$PAGE" | head -3

echo ""
echo "--- Git Push ---"
cd ~/workspace
git add frontend/app/admin/x7k2p/page.tsx
git commit -m "feat(S86): notification click → detail modal + view all tab navigation"
git push origin main

echo ""
echo "=================================================="
echo "✅ DONE — Vercel deploy ~2 min"
echo "Test:"
echo "  1. Notification click → detail modal opens"
echo "  2. View All → navigates to notifications tab"
echo "=================================================="
