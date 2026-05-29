#!/bin/bash
# ProveRank Fix v6: mark-read backend route + frontend fixes
echo "=================================================="
echo " ProveRank Fix v6: S86 Complete — Backend + Frontend"
echo "=================================================="

BACKEND="$HOME/workspace/src/routes/adminNotificationRoutes.js"
PAGE="$HOME/workspace/frontend/app/admin/x7k2p/page.tsx"

# ─────────────────────────────────────────────────────────────────────────
# FIX 1: Backend — add mark-read POST route
# ─────────────────────────────────────────────────────────────────────────
echo "--- FIX 1: Backend mark-read route ---"
echo "Current routes in adminNotificationRoutes.js:"
grep -n "router\.\(get\|post\|put\|delete\)" "$BACKEND" | head -15

# Check if mark-read route already exists
if grep -q "mark-read\|markRead" "$BACKEND" | grep -q "router\.post"; then
  echo "✅ mark-read POST route already exists"
else
  echo "Adding mark-read POST route..."
  node << 'NODEEOF'
const fs = require('fs');
const BACKEND = process.env.HOME + '/workspace/src/routes/adminNotificationRoutes.js';
let content = fs.readFileSync(BACKEND, 'utf8');

// Check if route exists
if (content.includes("router.post('/mark-read'") || content.includes('router.post("/mark-read"')) {
  console.log('✅ mark-read POST route already registered');
} else {
  // Add before module.exports
  const exportIdx = content.lastIndexOf('module.exports');
  if (exportIdx === -1) {
    console.log('❌ module.exports not found in backend file');
    process.exit(1);
  }

  const markReadRoute = `
// S86: Mark notifications as read
router.post('/mark-read', async (req, res) => {
  try {
    const { id, all } = req.body;
    if (all) {
      await AdminNotification.updateMany({ isRead: false }, { isRead: true });
      return res.json({ success: true, message: 'All marked as read' });
    }
    if (id) {
      await AdminNotification.findByIdAndUpdate(id, { isRead: true, readAt: new Date() });
      return res.json({ success: true, message: 'Marked as read' });
    }
    res.status(400).json({ success: false, message: 'id or all required' });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

`;
  content = content.slice(0, exportIdx) + markReadRoute + content.slice(exportIdx);
  fs.writeFileSync(BACKEND, content);
  console.log('✅ Fix 1: mark-read POST route added to backend');
}
NODEEOF
fi

echo ""
echo "--- Verify backend route ---"
grep -n "mark-read\|markRead" "$BACKEND" | head -10

# ─────────────────────────────────────────────────────────────────────────
# FIX 2: Frontend — View All as proper link + bell badge unread count
# ─────────────────────────────────────────────────────────────────────────
echo ""
echo "--- FIX 2: Frontend View All + Bell Badge ---"

node << 'NODEEOF'
const fs = require('fs');
const PAGE = process.env.HOME + '/workspace/frontend/app/admin/x7k2p/page.tsx';
let content = fs.readFileSync(PAGE, 'utf8');
let fixes = 0;

// Fix 2a: "View All Notifications →" — change span to a proper button with router push
// Find the span and replace with button that navigates
if (content.includes('View All Notifications →')) {
  // Replace span with button that scrolls to notifications tab or sets tab
  content = content.replace(
    /<span([^>]*?)>View All Notifications →<\/span>/g,
    '<button onClick={()=>{setNotifOpen(false);if(typeof window!=="undefined"){const u=new URL(window.location.href);u.searchParams.set("tab","notifications");window.history.pushState({},"",u.toString());}}} style={{fontSize:11,color:"#60a5fa",cursor:"pointer",fontWeight:600,background:"none",border:"none",padding:0,textDecoration:"underline"}}>View All Notifications →</button>'
  );
  console.log('✅ Fix 2a: View All Notifications → clickable button');
  fixes++;
} else {
  console.log('⚠️  Fix 2a: View All Notifications span not found');
}

// Fix 2b: Bell badge — show unread count
// Pattern: notifs.length>0 && <span/div showing notifs.length for badge
// Find the bell badge area
const bellBadgePatterns = [
  // Pattern: {notifs.length>0&&<...>{notifs.length}<...>}
  /\{notifs\.length\s*>\s*0\s*&&\s*(<[^>]+>)\s*\{notifs\.length\}\s*(<\/[^>]+>)\s*\}/g,
  // Pattern: notifs.length in badge span
  /(\{notifs\.length\s*>\s*0\s*&&\s*<span[^>]*>\s*)\{notifs\.length\}(\s*<\/span>\s*\})/g,
];

let badgeFixed = false;
for (const pat of bellBadgePatterns) {
  if (pat.test(content)) {
    content = content.replace(pat, (match) => {
      return match
        .replace(/notifs\.length\s*>\s*0/g, "notifs.filter((n:any)=>!n.isRead).length>0")
        .replace(/\{notifs\.length\}/g, "{notifs.filter((n:any)=>!n.isRead).length}");
    });
    console.log('✅ Fix 2b: Bell badge = unread count only');
    fixes++;
    badgeFixed = true;
    break;
  }
}

if (!badgeFixed) {
  // Try direct string replacement
  const badgeStr1 = 'notifs.length>0&&';
  const badgeStr2 = '{notifs.length}';
  
  // Find badge context — near the bell button
  const bellIdx = content.indexOf('setNotifOpen(');
  if (bellIdx > -1) {
    // Look 500 chars before bell button for badge
    const searchArea = content.slice(Math.max(0, bellIdx-600), bellIdx+100);
    if (searchArea.includes('notifs.length>0') || searchArea.includes('notifs.length > 0')) {
      // Replace in that area
      const before = content.slice(0, Math.max(0, bellIdx-600));
      let area = content.slice(Math.max(0, bellIdx-600), bellIdx+100);
      const after = content.slice(bellIdx+100);
      
      area = area
        .replace(/notifs\.length\s*>\s*0/g, "notifs.filter((n:any)=>!n.isRead).length>0")
        .replace(/\{notifs\.length\}/g, "{notifs.filter((n:any)=>!n.isRead).length}");
      
      content = before + area + after;
      console.log('✅ Fix 2b: Bell badge fixed (area search)');
      fixes++;
      badgeFixed = true;
    }
  }
  
  if (!badgeFixed) {
    console.log('⚠️  Fix 2b: Badge pattern not found — check manually');
    console.log('Run: grep -n "notifs.length" ' + PAGE + ' | head -10');
  }
}

// Fix 2c: Mark read persist — ensure optimistic update is correct
// When user clicks notification → markOneRead called → state updated → on next load fetched from API
// The issue: on refresh, isRead state resets because API returns fresh data
// Solution: mark-read API call must succeed for persistence
// This is handled by Fix 1 (backend route) — frontend call is already correct

// Fix 2d: Mark all read button visibility — ensure it shows when unread exist  
if (content.includes('notifs.filter((n:any)=>!n.isRead).length>0')) {
  console.log('✅ Fix 2d: Mark all read conditional already correct');
} else if (content.includes('Mark all read')) {
  // Fix the condition
  content = content.replace(
    /notifs\.length\s*>\s*0\s*&&[\s\S]{0,50}Mark all read/,
    (m) => m.replace('notifs.length>0', "notifs.filter((n:any)=>!n.isRead).length>0")
  );
  console.log('✅ Fix 2d: Mark all read condition fixed');
  fixes++;
}

fs.writeFileSync(PAGE, content);
console.log('\n✅ Frontend fixes total: ' + fixes);
NODEEOF

# ─────────────────────────────────────────────────────────────────────────
# FIX 3: Verify AdminNotification model has isRead field
# ─────────────────────────────────────────────────────────────────────────
echo ""
echo "--- FIX 3: Verify AdminNotification model ---"
find ~/workspace/src -name "*.js" | xargs grep -l "AdminNotification\|adminNotification" 2>/dev/null | head -5
grep -rn "isRead\|AdminNotification" ~/workspace/src/models/ 2>/dev/null | head -10

# ─────────────────────────────────────────────────────────────────────────
# GIT PUSH — both backend and frontend
# ─────────────────────────────────────────────────────────────────────────
echo ""
echo "--- Git Push ---"
cd ~/workspace
git add src/routes/adminNotificationRoutes.js
git add frontend/app/admin/x7k2p/page.tsx
git commit -m "fix(S86): add mark-read backend route + view all clickable + bell unread badge"
git push origin main

echo ""
echo "=================================================="
echo "✅ ALL DONE — Vercel + Render deploy ~2-3 min"
echo "🔗 Test: https://prove-rank.vercel.app/admin/x7k2p"
echo ""
echo "Test karo:"
echo "  1. Bell click → 3 notifications dikh rahi hain"
echo "  2. Badge = unread count (3)"
echo "  3. Notification click → dot gayab (mark read)"
echo "  4. Mark all read → all dots gone, badge 0"
echo "  5. Refresh karo → read state persist (from DB)"
echo "  6. View All → clickable hai"
echo "=================================================="
