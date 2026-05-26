#!/bin/bash
set -e
echo "======================================"
echo " ProveRank Fix: Notifications + Top Students"
echo "======================================"

# =====================================================
# FIX 1: BACKEND — top-students route add karo
# =====================================================
node << 'NODESCRIPT'
const fs = require('fs');

// Try both admin route files
const files = [
  '/home/runner/workspace/src/routes/adminNotificationRoutes.js',
  '/home/runner/workspace/src/routes/adminMonitoringRoutes.js'
];

let done = false;
for (const fp of files) {
  if (!fs.existsSync(fp)) continue;
  let c = fs.readFileSync(fp, 'utf8');
  if (c.includes('top-students')) {
    console.log('Already exists in: ' + fp);
    done = true;
    break;
  }
  if (!c.includes('module.exports')) continue;

  const newRoute = `
// ---- GET /api/admin/top-students (Real Data) ----
router.get('/top-students', async (req, res) => {
  try {
    const mongoose = require('mongoose');
    const limit = parseInt(req.query.limit) || 10;
    const db = mongoose.connection.db;
    if (!db) return res.json({ success: true, topStudents: [] });

    const results = await db.collection('results').aggregate([
      { $group: {
        _id: '$studentId',
        bestScore: { $max: '$totalScore' },
        totalExams: { $sum: 1 },
        avgScore: { $avg: '$totalScore' }
      }},
      { $sort: { bestScore: -1 } },
      { $limit: limit }
    ]).toArray();

    const { ObjectId } = require('mongodb');
    const ids = results.map(r => {
      try { return new ObjectId(r._id); } catch(e) { return r._id; }
    }).filter(Boolean);

    const students = ids.length
      ? await db.collection('students').find(
          { _id: { $in: ids } },
          { projection: { name: 1, email: 1, studentId: 1 } }
        ).toArray()
      : [];

    const sMap = {};
    students.forEach(s => { sMap[s._id.toString()] = s; });

    const top = results.map((r, i) => {
      const st = sMap[r._id ? r._id.toString() : ''] || {};
      return {
        rank: i + 1,
        name: st.name || 'Unknown',
        studentId: st.studentId || '',
        bestScore: Math.round(r.bestScore || 0),
        totalExams: r.totalExams || 0,
        avgScore: Math.round(r.avgScore || 0)
      };
    });

    res.json({ success: true, topStudents: top });
  } catch (e) {
    console.error('top-students err:', e.message);
    res.status(500).json({ success: false, message: e.message });
  }
});
`;

  c = c.replace('module.exports = router;', newRoute + '\nmodule.exports = router;');
  fs.writeFileSync(fp, c, 'utf8');
  console.log('✅ top-students route added to: ' + fp);
  done = true;
  break;
}

if (!done) {
  console.log('⚠️ Could not find route file to add. Creating new one...');
  const newFile = `const express = require('express');
const router = express.Router();

router.get('/top-students', async (req, res) => {
  try {
    const mongoose = require('mongoose');
    const limit = parseInt(req.query.limit) || 10;
    const db = mongoose.connection.db;
    if (!db) return res.json({ success: true, topStudents: [] });

    const results = await db.collection('results').aggregate([
      { $group: {
        _id: '$studentId',
        bestScore: { $max: '$totalScore' },
        totalExams: { $sum: 1 },
        avgScore: { $avg: '$totalScore' }
      }},
      { $sort: { bestScore: -1 } },
      { $limit: limit }
    ]).toArray();

    const { ObjectId } = require('mongodb');
    const ids = results.map(r => {
      try { return new ObjectId(r._id); } catch(e) { return r._id; }
    }).filter(Boolean);

    const students = ids.length
      ? await db.collection('students').find(
          { _id: { $in: ids } },
          { projection: { name: 1, email: 1, studentId: 1 } }
        ).toArray()
      : [];

    const sMap = {};
    students.forEach(s => { sMap[s._id.toString()] = s; });

    const top = results.map((r, i) => {
      const st = sMap[r._id ? r._id.toString() : ''] || {};
      return {
        rank: i + 1,
        name: st.name || 'Unknown',
        studentId: st.studentId || '',
        bestScore: Math.round(r.bestScore || 0),
        totalExams: r.totalExams || 0,
        avgScore: Math.round(r.avgScore || 0)
      };
    });

    res.json({ success: true, topStudents: top });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

module.exports = router;
`;
  fs.writeFileSync('/home/runner/workspace/src/routes/adminTopStudents.js', newFile, 'utf8');
  console.log('✅ adminTopStudents.js created');
}
NODESCRIPT

# index.js mein mount karo (agar new file bani ho)
node << 'NODESCRIPT'
const fs = require('fs');
const fp = '/home/runner/workspace/src/index.js';
let c = fs.readFileSync(fp, 'utf8');

if (c.includes('adminTopStudents')) {
  console.log('⏭ Already mounted in index.js');
} else if (fs.existsSync('/home/runner/workspace/src/routes/adminTopStudents.js')) {
  // Mount before app.listen
  c = c.replace(
    /app\.listen\(/,
    `app.use('/api/admin', require('./routes/adminTopStudents'));\n\napp.listen(`
  );
  fs.writeFileSync(fp, c, 'utf8');
  console.log('✅ adminTopStudents mounted in index.js');
} else {
  console.log('⏭ Route was added to existing file — no index.js change needed');
}
NODESCRIPT

echo ""
echo "✅ Backend done"

# =====================================================
# FIX 2: FRONTEND — page.tsx notification + top students
# =====================================================
node << 'NODESCRIPT'
const fs = require('fs');
const fp = '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx';
let c = fs.readFileSync(fp, 'utf8');
let fixes = 0;

// ---------------------------------------------------
// 2a: Badge filter — n.read → n.isRead
// ---------------------------------------------------
if (c.includes('filter(n=>!n.read)')) {
  c = c.replace(/filter\(n=>!n\.read\)/g, 'filter(n=>!n.isRead)');
  console.log('✅ 2a: badge filter fixed (n.read → n.isRead)');
  fixes++;
} else {
  console.log('⚠️ 2a: n.read pattern not found (may already be fixed)');
}

// ---------------------------------------------------
// 2b: Notification item fields — n.msg, n.icon, n.t fix
// ---------------------------------------------------
// Fix n.icon + n.msg together
if (c.includes('{n.icon}') || c.includes('{n.msg}')) {
  c = c.replace(/\{n\.icon\}\s*\{n\.msg\}/g, '{n.title||n.type||"Notification"}');
  c = c.replace(/\{n\.icon\}/g, '');
  c = c.replace(/\{n\.msg\}/g, '{n.message||""}');
  console.log('✅ 2b: n.icon + n.msg fixed');
  fixes++;
}

// Fix n.t → createdAt timestamp
if (c.includes('{n.t}')) {
  c = c.replace(
    /\{n\.t\}/g,
    '{n.createdAt ? new Date(n.createdAt).toLocaleString("en-IN",{day:"2-digit",month:"short",hour:"2-digit",minute:"2-digit"}) : ""}'
  );
  console.log('✅ 2b: n.t → createdAt fixed');
  fixes++;
}

// Fix key n.id → n._id
if (c.includes('key={n.id||')) {
  c = c.replace(/key=\{n\.id\|\|/g, 'key={n._id||');
  console.log('✅ 2b: key n.id → n._id fixed');
  fixes++;
}

// Add severity color border + isRead opacity to notification items
c = c.replace(
  /style=\{\{\.\.\.cs,padding:'10px 12px',marginBottom:8\}\}/g,
  "style={{...cs,padding:'10px 12px',marginBottom:8,borderLeft:`3px solid ${n.severity==='warning'?'#f59e0b':n.severity==='error'?'#ef4444':'#38bdf8'}`,opacity:n.isRead?0.6:1}}"
);

// Add n.title line (if only n.type shown after fix, add separate title row)
// Check if title is shown — already handled above via n.title||n.type

// ---------------------------------------------------
// 2c: Add topStudents state
// ---------------------------------------------------
if (!c.includes('topStudents,setTopStudents') && !c.includes('setTopStudents')) {
  c = c.replace(
    'const [notifOpen,setNotifOpen]=useState(false)',
    'const [notifOpen,setNotifOpen]=useState(false);\nconst [topStudents,setTopStudents]=useState<{rank:number,name:string,bestScore:number,totalExams:number}[]>([])'
  );
  console.log('✅ 2c: topStudents state added');
  fixes++;
}

// ---------------------------------------------------
// 2d: Add top students fetch
// ---------------------------------------------------
if (!c.includes('/api/admin/top-students')) {
  // Find the notifications get call (uses get() helper)
  const notifMatch = c.match(/get\([`']\$\{API\}\/api\/admin\/notifications[`']\)/);
  if (notifMatch) {
    const original = notifMatch[0];
    const topFetch = `fetch(\`\${API}/api/admin/top-students?limit=10\`,{headers:{Authorization:\`Bearer \${token}\`}}).then(r=>r.ok?r.json():null).then(d=>{if(d&&d.success&&d.topStudents)setTopStudents(d.topStudents);}).catch(()=>{}),`;
    c = c.replace(original, topFetch + '\n    ' + original);
    console.log('✅ 2d: top students fetch added');
    fixes++;
  } else {
    // Fallback — add in useEffect or fetchAll
    console.log('⚠️ 2d: notifications get() pattern not found — adding fetch manually');
    c = c.replace(
      'const [topStudents,setTopStudents]',
      `// top students auto fetch
useEffect(()=>{
  const tok=typeof window!=='undefined'?localStorage.getItem('pr_token'):'';
  if(!tok)return;
  const API=process.env.NEXT_PUBLIC_API_URL||'https://proverank.onrender.com';
  fetch(\`\${API}/api/admin/top-students?limit=10\`,{headers:{Authorization:\`Bearer \${tok}\`}}).then(r=>r.ok?r.json():null).then(d=>{if(d&&d.success&&d.topStudents)setTopStudents(d.topStudents);}).catch(()=>{});
},[]);
const [topStudents,setTopStudents]`
    );
    fixes++;
  }
}

// ---------------------------------------------------
// 2e: Fix Top Students render in Dashboard
// ---------------------------------------------------
const topHeading = `<div style={{fontWeight:700,marginBottom:8,fontSize:12}}>🏆 Top Students</div>`;
if (c.includes(topHeading) && !c.includes('topStudents.slice')) {
  const newTopRender = `<div style={{fontWeight:700,marginBottom:8,fontSize:12}}>🏆 Top Students</div>
{topStudents.length===0
  ?<div style={{fontSize:12,color:'#64748b',textAlign:'center',padding:'10px 0'}}>No exam data yet</div>
  :topStudents.slice(0,5).map((s,idx)=>(
    <div key={idx} style={{display:'flex',alignItems:'center',gap:8,padding:'5px 0',borderBottom:'1px solid rgba(255,255,255,0.05)'}}>
      <span style={{fontSize:12,fontWeight:700,minWidth:18,color:idx===0?'#fbbf24':idx===1?'#94a3b8':idx===2?'#b45309':'#64748b'}}>{idx+1}</span>
      <span style={{fontSize:12,color:'#e2e8f0',flex:1,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{s.name}</span>
      <span style={{fontSize:11,color:'#38bdf8',fontWeight:600}}>{s.bestScore}pts</span>
    </div>
  ))
}`;
  c = c.replace(topHeading, newTopRender);
  console.log('✅ 2e: top students render replaced with real data');
  fixes++;
} else if (c.includes('topStudents.slice')) {
  console.log('⏭ 2e: top students render already fixed');
}

fs.writeFileSync(fp, c, 'utf8');
console.log('\n✅ Frontend fixes total: ' + fixes);
NODESCRIPT

echo ""
echo "✅ Frontend done"

# =====================================================
# GIT PUSH
# =====================================================
cd ~/workspace
git add -A
git commit -m "fix: S86 notifications (title/message/isRead/createdAt) + top students real DB data"
git push origin main

echo ""
echo "============================================"
echo "✅ ALL DONE — Vercel deploy in ~2 min"
echo "🔔 Test: https://prove-rank.vercel.app/admin/x7k2p"
echo "📡 API:  https://proverank.onrender.com/api/admin/top-students"
echo "============================================"
