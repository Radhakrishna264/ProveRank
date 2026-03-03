const fs = require('fs');
const content = fs.readFileSync('./src/routes/admin.js', 'utf8');

const s93Code = `

// ─── S93: Platform Audit Trail (Tamper-Proof) ─────────────────────
router.get('/audit-trail', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const AuditLog = require('../models/AuditLog');
    const { page = 1, limit = 50, action, adminId } = req.query;
    
    const filter = {};
    if (action) filter.action = action;
    if (adminId) filter.performedBy = adminId;
    
    const logs = await AuditLog.find(filter)
      .populate('performedBy', 'name email role')
      .populate('targetUser', 'name email role')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);
    
    const total = await AuditLog.countDocuments(filter);
    
    res.json({ logs, total, page: Number(page), pages: Math.ceil(total / limit) });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});
`;

if (content.includes('/audit-trail')) {
  console.log('ℹ️  S93 audit-trail route already exists — skip');
} else {
  const updated = content.replace('module.exports = router;', s93Code + '\nmodule.exports = router;');
  fs.writeFileSync('./src/routes/admin.js', updated);
  console.log('✅ S93 audit-trail route added!');
}
