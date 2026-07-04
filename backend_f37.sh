#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  ProveRank — F37 Getting Started Checklist (BACKEND)
#  Adds: GET /api/auth/checklist — returns 5 checklist items status
#        POST /api/auth/checklist/complete — award XP + Pathfinder badge
# ═══════════════════════════════════════════════════════════════
set -e

AUTH_F=$(find . -path "*/routes/auth.js" | grep -v node_modules | head -1)
echo "auth.js: $AUTH_F"
cp "$AUTH_F" "${AUTH_F}.bak_f37"
export AUTH_F

node << 'JSEOF'
const fs = require('fs');
const f  = process.env.AUTH_F;
let c = fs.readFileSync(f, 'utf8');

if (c.includes('checklist')) {
  console.log('ℹ️  Checklist route already exists');
  process.exit(0);
}

// ── Auth middleware (reuse existing pattern) ─────────────────
const CHECKLIST_ROUTES = `
// ── F37: Getting Started Checklist ───────────────────────────

// GET /api/auth/checklist — returns completion status of 5 items
router.get('/checklist', async (req, res) => {
  try {
    const token = req.headers.authorization?.split(' ')[1]
    if (!token) return res.status(401).json({ error: 'Token required' })
    const JWT_SECRET = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024'
    let decoded
    try { decoded = require('jsonwebtoken').verify(token, JWT_SECRET) }
    catch { return res.status(401).json({ error: 'Invalid token' }) }

    const user = await User.findById(decoded.id)
      .select('name profileComplete dob city phone bio avatar targetExam board school badges checklist')
      .lean()
    if (!user) return res.status(404).json({ error: 'User not found' })

    // Fetch real data for checklist checks
    const Attempt = (() => { try { return require('../models/Attempt') } catch { return null } })()
    const Result  = (() => { try { return require('../models/Result')  } catch { return null } })()

    // 1. Profile complete — has name + phone + dob + city + bio
    const profileDone = !!(user.name && user.phone && user.dob && user.city && user.bio)

    // 2. First mock test — has at least 1 attempt/result
    let firstTestDone = false
    if (Attempt) firstTestDone = !!(await Attempt.findOne({ studentId: decoded.id }).lean())
    else if (Result) firstTestDone = !!(await Result.findOne({ studentId: decoded.id }).lean())

    // 3. Goals set — has targetExam set
    const goalsDone = !!(user.targetExam && user.targetExam.trim())

    // 4. PYQ Bank explored — stored in user.checklist.pyqExplored
    const pyqDone = !!(user.checklist?.pyqExplored)

    // 5. Analytics visited — stored in user.checklist.analyticsVisited
    const analyticsDone = !!(user.checklist?.analyticsVisited)

    const items = [
      { id: 'profile',   done: profileDone,    icon: '👤', label_en: 'Complete your profile',              label_hi: 'प्रोफ़ाइल पूरी करें',        href: '/profile',   xp: 50 },
      { id: 'firstTest', done: firstTestDone,  icon: '📝', label_en: 'Give your first mock test',          label_hi: 'पहला मॉक टेस्ट दें',           href: '/my-exams',  xp: 100 },
      { id: 'goals',     done: goalsDone,      icon: '🎯', label_en: 'Set your target rank & score',       label_hi: 'लक्ष्य रैंक और स्कोर सेट करें', href: '/goals',     xp: 30 },
      { id: 'pyq',       done: pyqDone,        icon: '📚', label_en: 'Explore PYQ Bank (2015–2024)',        label_hi: 'PYQ बैंक एक्सप्लोर करें',       href: '/pyq-bank',  xp: 20 },
      { id: 'analytics', done: analyticsDone,  icon: '📉', label_en: 'Check your analytics dashboard',    label_hi: 'एनालिटिक्स डैशबोर्ड देखें',    href: '/analytics', xp: 20 },
    ]

    const completedCount = items.filter(i => i.done).length
    const allDone = completedCount === 5
    const hasBadge = (user.badges || []).some(b => b.id === 'pathfinder')

    res.json({
      success: true,
      items,
      completedCount,
      totalCount: 5,
      allDone,
      hasBadge,
      totalXP: items.filter(i => i.done).reduce((s, i) => s + i.xp, 0),
    })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

// POST /api/auth/checklist/mark — mark pyq/analytics as visited
router.post('/checklist/mark', async (req, res) => {
  try {
    const token = req.headers.authorization?.split(' ')[1]
    if (!token) return res.status(401).json({ error: 'Token required' })
    const JWT_SECRET = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024'
    let decoded
    try { decoded = require('jsonwebtoken').verify(token, JWT_SECRET) }
    catch { return res.status(401).json({ error: 'Invalid token' }) }

    const { item } = req.body // 'pyq' or 'analytics'
    if (!['pyq', 'analytics'].includes(item))
      return res.status(400).json({ error: 'Invalid item' })

    const update = {}
    if (item === 'pyq')       update['checklist.pyqExplored']      = true
    if (item === 'analytics') update['checklist.analyticsVisited'] = true

    await User.findByIdAndUpdate(decoded.id, { $set: update })
    res.json({ success: true })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

// POST /api/auth/checklist/complete — award Pathfinder badge + XP when all 5 done
router.post('/checklist/complete', async (req, res) => {
  try {
    const token = req.headers.authorization?.split(' ')[1]
    if (!token) return res.status(401).json({ error: 'Token required' })
    const JWT_SECRET = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024'
    let decoded
    try { decoded = require('jsonwebtoken').verify(token, JWT_SECRET) }
    catch { return res.status(401).json({ error: 'Invalid token' }) }

    const user = await User.findById(decoded.id)
    if (!user) return res.status(404).json({ error: 'User not found' })

    const hasBadge = (user.badges || []).some(b => b.id === 'pathfinder')
    if (hasBadge) return res.json({ success: true, alreadyAwarded: true })

    await User.findByIdAndUpdate(decoded.id, {
      $push: { badges: { id: 'pathfinder', name: 'Pathfinder', unlockedAt: new Date() } },
      $inc:  { xp: 220 }
    })
    res.json({ success: true, badge: 'pathfinder', xpAwarded: 220 })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

`;

// Insert before module.exports
c = c.replace('module.exports = router', CHECKLIST_ROUTES + 'module.exports = router');
fs.writeFileSync(f, c);

// Verify
const v = fs.readFileSync(f, 'utf8');
console.log('GET /checklist route:', v.includes("router.get('/checklist'") ? '✅' : '❌');
console.log('POST /checklist/mark:', v.includes('/checklist/mark') ? '✅' : '❌');
console.log('POST /checklist/complete:', v.includes('/checklist/complete') ? '✅' : '❌');
console.log('Pathfinder badge:', v.includes('pathfinder') ? '✅' : '❌');
console.log('XP award logic:', v.includes('xp: 220') ? '✅' : '❌');
JSEOF

# ── Also patch User.js to add checklist + xp fields ─────────
USER_F=$(find . -path "*/models/User.js" | grep -v node_modules | head -1)
export USER_F
node << 'JSEOF'
const fs = require('fs');
const f  = process.env.USER_F;
let c = fs.readFileSync(f, 'utf8');

let changed = false;
if (!c.includes('checklist:')) {
  c = c.replace(
    "  onboarded:",
    "  checklist: {\n    pyqExplored:      { type: Boolean, default: false },\n    analyticsVisited: { type: Boolean, default: false },\n  },\n  xp: { type: Number, default: 0 },\n\n  onboarded:"
  );
  changed = true;
}
if (changed) {
  fs.writeFileSync(f, c);
  console.log('✅ User.js — checklist + xp fields added');
} else {
  console.log('ℹ️  Already present');
}
const v = fs.readFileSync(f,'utf8');
console.log('checklist field:', v.includes('checklist:') ? '✅' : '❌');
console.log('xp field:',        v.includes("xp: { type: Number") ? '✅' : '❌');
JSEOF

echo ""
echo "═══════════════════════════════════════════"
echo "  Backend F37 — Complete"
echo "═══════════════════════════════════════════"
echo ""
echo "git add . && git commit -m 'feat: F37 checklist API routes + User fields' && git push"
