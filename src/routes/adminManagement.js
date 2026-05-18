const generateStudentId=require('../utils/generateStudentId');
const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { verifyToken, isSuperAdmin } = require('../middleware/auth');
const User = require('../models/User');
const ActivityLog = require('../models/ActivityLog');
const { logActivity } = require('../utils/activityLogger');

async function generateAdminId(){
  const yr=new Date().getFullYear().toString().slice(-2);
  const ch='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let id,ex;
  do{
    let r='';
    for(let i=0;i<3;i++)r+=ch[Math.floor(Math.random()*ch.length)];
    id='PRA'+yr+r;
    ex=await User.findOne({adminId:id});
  }while(ex);
  return id;
}


// ── S37: CREATE ADMIN ────────────────────────────────────────
router.post('/create-admin', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { name, email, password, permissions } = req.body;
    if (!name || !email || !password)
      return res.status(400).json({ message: 'Name, email and password are required' });

    const existing = await User.findOne({ email });
    if (existing)
      return res.status(400).json({ message: 'This email is already registered' });

    const hashedPassword = await bcrypt.hash(password, 12);
    const adminId = await generateAdminId();
  const newUser = await User.create({
      name, email,
      password: hashedPassword,
      role: 'admin',
      verified: true,
      adminId,
      permissions: permissions || {},
    });

    try{await logActivity({userId:req.user.id,userName:req.user.name,userRole:req.user.role,action:'CREATE_ADMIN',details:`New admin created: ${email}`,module:'admin_management',isAudit:true});}catch(logErr){console.error('logActivity error:',logErr.message);}

    res.status(201).json({
      success: true,
      message: 'Admin account created successfully',
      admin: { id: admin._id, name: admin.name, email: admin.email, role: admin.role }
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ── S37: GET ALL ADMINS ──────────────────────────────────────
router.get('/admins', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const admins = await User.find({ role: { $in: ['admin', 'moderator'] }, archived: { $ne: true } })
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

    const adminToUpdate=await User.findById(req.params.id);
    if(!adminToUpdate) return res.status(404).json({message:'Admin nahi mila'});
    if(!adminToUpdate.permissions) adminToUpdate.permissions=new Map();
    Object.entries(permissions).forEach(([k,v])=>adminToUpdate.permissions.set(k,v));
    await adminToUpdate.save();

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


// S37: FREEZE ADMIN
router.put('/freeze/:id', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { frozen } = req.body
    const admin = await User.findById(req.params.id)
    if (!admin) return res.status(404).json({ message: 'Admin not found' })
    if (admin.role === 'superadmin') return res.status(403).json({ message: 'Cannot freeze SuperAdmin' })
    await User.findByIdAndUpdate(req.params.id, { frozen: frozen === true })
    await logActivity({ userId: req.user.id, userName: req.user.name, userRole: req.user.role, action: frozen ? 'FREEZE_ADMIN' : 'UNFREEZE_ADMIN', details: `Admin ${frozen ? 'frozen' : 'unfrozen'}: ${admin.email}`, module: 'admin_management', isAudit: true })
    res.json({ success: true, message: `Admin ${frozen ? 'frozen' : 'unfrozen'} successfully` })
  } catch(err) { res.status(500).json({ message: 'Server error', error: err.message }) }
})

// S37: ARCHIVE (SOFT REMOVE) ADMIN
router.put('/archive/:id', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const admin = await User.findById(req.params.id)
    if (!admin) return res.status(404).json({ message: 'Admin not found' })
    if (admin.role === 'superadmin') return res.status(403).json({ message: 'Cannot remove SuperAdmin' })
    await User.findByIdAndUpdate(req.params.id, { archived: true, frozen: true, archivedAt: new Date(), archivedBy: req.user.email })
    await logActivity({ userId: req.user.id, userName: req.user.name, userRole: req.user.role, action: 'ARCHIVE_ADMIN', details: `Admin archived: ${admin.email}`, module: 'admin_management', isAudit: true })
    res.json({ success: true, message: 'Admin archived successfully' })
  } catch(err) { res.status(500).json({ message: 'Server error', error: err.message }) }
})

// S37: RESTORE ARCHIVED ADMIN
router.put('/restore/:id', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const admin = await User.findById(req.params.id)
    if (!admin) return res.status(404).json({ message: 'Admin not found' })
    await User.findByIdAndUpdate(req.params.id, { archived: false, frozen: false, archivedAt: null, archivedBy: null })
    await logActivity({ userId: req.user.id, userName: req.user.name, userRole: req.user.role, action: 'RESTORE_ADMIN', details: `Admin restored: ${admin.email}`, module: 'admin_management', isAudit: true })
    res.json({ success: true, message: 'Admin restored successfully' })
  } catch(err) { res.status(500).json({ message: 'Server error', error: err.message }) }
})

// S37: GET ARCHIVED ADMINS
router.get('/archived', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const admins = await User.find({ role: { $in: ['admin','moderator'] }, archived: true, archived: true }).select('-password -twoFactorSecret')
    res.json({ success: true, admins })
  } catch(err) { res.status(500).json({ message: 'Server error', error: err.message }) }
})

// ===== Admin Full Profile + Activity Logs =====

router.get('/profile/me',verifyToken,async(req,res)=>{
  try{
    const admin=await User.findById(req.user.id);
    if(!admin)return res.status(404).json({success:false,message:'Not found'});
    const perms=admin.permissions instanceof Map ? Object.fromEntries(admin.permissions) : (admin.permissions||{});
    res.json({success:true,admin:{...admin.toObject(),permissions:perms}});
  }catch(e){res.status(500).json({success:false,message:e.message});}
});
router.get('/profile/:id', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const admin = await User.findById(req.params.id)
      .select('-password -twoFactorSecret -emailVerifyOTP -loginOTP -resetOTP');
    if (!admin) return res.status(404).json({ success: false, message: 'Admin not found' });
    let activityLogs = [];
    try {
      const mongoose = require('mongoose');
      let AL = null;
      try { AL = mongoose.model('ActivityLog'); } catch(e2) {}
      if (AL) {
        activityLogs = await AL.find({ userId: req.params.id })
          .sort({ createdAt: -1 }).limit(30).lean();
      }
    } catch(e) {}
    return res.json({
      success: true,
      admin: { ...admin.toObject(), permissions: admin.permissions instanceof Map ? Object.fromEntries(admin.permissions) : (admin.permissions||{}) },
      activityLogs: activityLogs,
      loginHistory: admin.loginHistory || []
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});


// Mark welcome banner as seen
router.post('/welcome-seen', async(req,res)=>{
  try{
    const token=req.headers.authorization?.split(' ')[1];
    if(!token)return res.status(401).json({success:false});
    const jwt=require('jsonwebtoken');
    const decoded=jwt.verify(token,process.env.JWT_SECRET||'proverank_secret');
    const User=require('../models/User');

    await User.findByIdAndUpdate(decoded.id||decoded._id,{welcomeSeen:true});
    res.json({success:true});
  }catch(e){res.status(500).json({success:false,message:e.message});}
});

module.exports = router;
