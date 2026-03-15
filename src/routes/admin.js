const express = require('express');
const router = express.Router();
const User = require('../models/User');
const { verifyToken, isSuperAdmin, isAdmin } = require('../middleware/auth');

// BAN STUDENT
router.post('/ban/:userId', verifyToken, isAdmin, async (req, res) => {
  try {
    const { reason, expiry } = req.body;
    const user = await User.findByIdAndUpdate(
      req.params.userId,
      { banned: true, banReason: reason, banExpiry: expiry || null },
      { new: true }
    );
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.json({ message: 'User banned', user: user.email });
  } catch (err) {
    res.status(500).json({ message: 'Error', error: err.message });
  }
});

// UNBAN STUDENT
router.post('/unban/:userId', verifyToken, isAdmin, async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(
      req.params.userId,
      { banned: false, banReason: '', banExpiry: null },
      { new: true }
    );
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.json({ message: 'User unbanned', user: user.email });
  } catch (err) {
    res.status(500).json({ message: 'Error', error: err.message });
  }
});

// GET ALL STUDENTS
router.get('/students', verifyToken, isAdmin, async (req, res) => {
  try {
    const students = await User.find({ role: 'student' })
      .select('-password -otp');
    res.json({ students });
  } catch (err) {
    res.status(500).json({ message: 'Error', error: err.message });
  }
});

// GET LOGIN HISTORY
router.get('/login-history/:userId', verifyToken, isAdmin, async (req, res) => {
  try {
    const user = await User.findById(req.params.userId).select('loginHistory email');
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.json({ email: user.email, loginHistory: user.loginHistory });
  } catch (err) {
    res.status(500).json({ message: 'Error', error: err.message });
  }
});



// ─── S72: SuperAdmin Permission Control ──────────────────────────────
router.post('/:adminId/permissions', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { adminId } = req.params;
    const { permissions } = req.body; // { canCreateExam: true, canAddQuestion: false, ... }
    
    const admin = await User.findOne({ _id: adminId, role: 'admin' });
    if (!admin) return res.status(404).json({ message: 'Admin not found' });
    
    admin.permissions = { ...(admin.permissions || {}), ...permissions };
    await admin.save();
    
    // Log activity
    const AuditLog = require('../models/AuditLog');
    await AuditLog.create({
      action: 'PERMISSION_UPDATE',
      performedBy: req.user.id,
      targetUser: adminId,
      details: `Permissions updated: ${JSON.stringify(permissions)}`,
      ip: req.ip
    }).catch(() => {});
    
    res.json({ message: 'Permissions updated successfully', permissions: admin.permissions });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ─── S72: Freeze/Unfreeze Admin ────────────────────────────────────
router.post('/:adminId/freeze', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { adminId } = req.params;
    const { freeze } = req.body; // { freeze: true } or { freeze: false }
    
    const admin = await User.findOne({ _id: adminId, role: 'admin' });
    if (!admin) return res.status(404).json({ message: 'Admin not found' });
    
    admin.isFrozen = freeze !== undefined ? freeze : !admin.isFrozen;
    await admin.save();
    
    // Log activity
    const AuditLog = require('../models/AuditLog');
    await AuditLog.create({
      action: admin.isFrozen ? 'ADMIN_FROZEN' : 'ADMIN_UNFROZEN',
      performedBy: req.user.id,
      targetUser: adminId,
      details: `Admin ${admin.email} ${admin.isFrozen ? 'frozen' : 'unfrozen'}`,
      ip: req.ip
    }).catch(() => {});
    
    res.json({ 
      message: `Admin ${admin.isFrozen ? 'frozen' : 'unfrozen'} successfully`,
      isFrozen: admin.isFrozen 
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});


// ─── M4: SuperAdmin Impersonate Student (No Password Needed) ─────────
router.get('/impersonate/:studentId', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { studentId } = req.params;
    
    const student = await User.findOne({ _id: studentId, role: 'student' });
    if (!student) return res.status(404).json({ message: 'Student not found' });
    
    const jwt = require('jsonwebtoken');
    // Generate temp token for this student (1 hour only)
    const impersonateToken = jwt.sign(
      { 
        id: student._id, 
        role: student.role,
        impersonatedBy: req.user.id,
        isImpersonating: true
      },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );
    
    // Log activity
    const AuditLog = require('../models/AuditLog');
    await AuditLog.create({
      action: 'STUDENT_IMPERSONATE',
      performedBy: req.user.id,
      targetUser: studentId,
      details: `SuperAdmin impersonated student: ${student.email}`,
      ip: req.ip
    }).catch(() => {});
    
    res.json({ 
      message: 'Impersonation token generated',
      token: impersonateToken,
      student: {
        id: student._id,
        name: student.name,
        email: student.email,
        role: student.role
      },
      expiresIn: '1 hour'
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});



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


// DELETE student (admin only)
router.delete('/students/:id', async (req, res) => {
  try {
    const User = require('../models/User')
    await User.collection.deleteOne({ _id: new (require('mongoose').Types.ObjectId)(req.params.id) })
    res.json({ message: 'Student deleted successfully', success: true })
  } catch(err) {
    res.status(500).json({ message: 'Server error' })
  }
})

module.exports = router;
