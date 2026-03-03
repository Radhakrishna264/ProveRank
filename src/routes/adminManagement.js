const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { verifyToken, isSuperAdmin } = require('../middleware/auth');
const User = require('../models/User');
const ActivityLog = require('../models/ActivityLog');
const { logActivity } = require('../utils/activityLogger');

// ── S37: CREATE ADMIN ────────────────────────────────────────
router.post('/create-admin', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { name, email, password, permissions } = req.body;
    if (!name || !email || !password)
      return res.status(400).json({ message: 'name, email, password required hain' });

    const existing = await User.findOne({ email });
    if (existing)
      return res.status(400).json({ message: 'Yeh email already registered hai' });

    const hashedPassword = await bcrypt.hash(password, 12);
    const admin = await User.create({
      name, email,
      password: hashedPassword,
      role: 'admin',
      verified: true,
      permissions: permissions || {},
    });

    await logActivity({
      userId: req.user.id,
      userName: req.user.name,
      userRole: req.user.role,
      action: 'CREATE_ADMIN',
      details: `New admin created: ${email}`,
      module: 'admin_management',
      isAudit: true
    });

    res.status(201).json({
      success: true,
      message: 'Admin create ho gaya',
      admin: { id: admin._id, name: admin.name, email: admin.email, role: admin.role }
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── S37: GET ALL ADMINS ──────────────────────────────────────
router.get('/admins', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const admins = await User.find({ role: { $in: ['admin', 'moderator'] } })
      .select('-password -twoFactorSecret');
    res.json({ success: true, count: admins.length, admins });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── S72: UPDATE ADMIN PERMISSIONS ───────────────────────────
router.put('/permissions/:id', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { permissions } = req.body;
    const admin = await User.findById(req.params.id);
    if (!admin) return res.status(404).json({ message: 'Admin nahi mila' });
    if (admin.role === 'superadmin')
      return res.status(403).json({ message: 'SuperAdmin ki permissions change nahi ho sakti' });

    await User.findByIdAndUpdate(req.params.id, { permissions });

    await logActivity({
      userId: req.user.id,
      userName: req.user.name,
      userRole: req.user.role,
      action: 'UPDATE_PERMISSIONS',
      details: `Permissions updated for: ${admin.email}`,
      module: 'admin_management',
      isAudit: true
    });

    res.json({ success: true, message: 'Permissions update ho gayi' });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── S72: FREEZE / UNFREEZE ADMIN ────────────────────────────
router.put('/freeze/:id', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { frozen } = req.body;
    const admin = await User.findById(req.params.id);
    if (!admin) return res.status(404).json({ message: 'Admin nahi mila' });
    if (admin.role === 'superadmin')
      return res.status(403).json({ message: 'SuperAdmin ko freeze nahi kar sakte' });

    await User.findByIdAndUpdate(req.params.id, { frozen: frozen === true });

    await logActivity({
      userId: req.user.id,
      userRole: req.user.role,
      action: frozen ? 'FREEZE_ADMIN' : 'UNFREEZE_ADMIN',
      details: `Admin ${frozen ? 'frozen' : 'unfrozen'}: ${admin.email}`,
      module: 'admin_management',
      isAudit: true
    });

    res.json({ success: true, message: `Admin ${frozen ? 'freeze' : 'unfreeze'} ho gaya` });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── S38: GET ACTIVITY LOGS ───────────────────────────────────
router.get('/activity-logs', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { page = 1, limit = 50, userId, action, module } = req.query;
    const filter = {};
    if (userId) filter.userId = userId;
    if (action) filter.action = action;
    if (module) filter.module = module;

    const logs = await ActivityLog.find(filter)
      .sort({ createdAt: -1 })
      .limit(Number(limit))
      .skip((Number(page) - 1) * Number(limit))
      .populate('userId', 'name email role');

    const total = await ActivityLog.countDocuments(filter);
    res.json({ success: true, total, page: Number(page), logs });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── S38: POST ACTIVITY LOG (manual) ─────────────────────────
router.post('/activity-logs', verifyToken, async (req, res) => {
  try {
    const { action, details, module, status } = req.body;
    if (!action) return res.status(400).json({ message: 'action required hai' });

    await logActivity({
      userId: req.user.id,
      userName: req.user.name,
      userRole: req.user.role,
      action, details,
      module: module || 'manual',
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
      status: status || 'success'
    });

    res.status(201).json({ success: true, message: 'Activity log save ho gaya' });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── S93: AUDIT TRAIL ─────────────────────────────────────────
router.get('/audit-trail', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { page = 1, limit = 50, startDate, endDate } = req.query;
    const filter = { isAudit: true };
    if (startDate || endDate) {
      filter.createdAt = {};
      if (startDate) filter.createdAt.$gte = new Date(startDate);
      if (endDate)   filter.createdAt.$lte = new Date(endDate);
    }

    const logs = await ActivityLog.find(filter)
      .sort({ createdAt: -1 })
      .limit(Number(limit))
      .skip((Number(page) - 1) * Number(limit));

    const total = await ActivityLog.countDocuments(filter);
    res.json({ success: true, total, page: Number(page), auditTrail: logs });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── M4: STUDENT LOGIN VIEW (Impersonate) ─────────────────────
router.post('/impersonate/:id', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const targetUser = await User.findById(req.params.id)
      .select('-password -twoFactorSecret');
    if (!targetUser) return res.status(404).json({ message: 'User nahi mila' });
    if (targetUser.role === 'superadmin')
      return res.status(403).json({ message: 'SuperAdmin ko impersonate nahi kar sakte' });

    // Generate temp token for impersonation
    const impersonateToken = jwt.sign(
      {
        id: targetUser._id,
        role: targetUser.role,
        impersonatedBy: req.user.id,
        isImpersonation: true
      },
      process.env.JWT_SECRET,
      { expiresIn: '2h' }
    );

    await logActivity({
      userId: req.user.id,
      userRole: req.user.role,
      action: 'IMPERSONATE_USER',
      details: `Impersonated: ${targetUser.email} (${targetUser.role})`,
      module: 'admin_management',
      isAudit: true,
      status: 'warning'
    });

    res.json({
      success: true,
      message: `${targetUser.name} ki view mein ho — 2 hours valid`,
      impersonateToken,
      user: targetUser
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
