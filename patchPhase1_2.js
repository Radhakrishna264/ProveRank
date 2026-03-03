const fs = require('fs');
const path = require('path');

const adminPath = path.join(__dirname, 'src/routes/admin.js');
let content = fs.readFileSync(adminPath, 'utf8');

// ─── S72: Permission Control ───────────────────────────────────────
const s72Code = `

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
      details: \`Permissions updated: \${JSON.stringify(permissions)}\`,
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
      details: \`Admin \${admin.email} \${admin.isFrozen ? 'frozen' : 'unfrozen'}\`,
      ip: req.ip
    }).catch(() => {});
    
    res.json({ 
      message: \`Admin \${admin.isFrozen ? 'frozen' : 'unfrozen'} successfully\`,
      isFrozen: admin.isFrozen 
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});
`;

// ─── M4: Student Impersonate ────────────────────────────────────────
const m4Code = `

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
      details: \`SuperAdmin impersonated student: \${student.email}\`,
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
`;

// ─── Check karo already exist karta hai kya ────────────────────────
const alreadyHasS72 = content.includes("/:adminId/permissions");
const alreadyHasFreeze = content.includes("/:adminId/freeze");
const alreadyHasM4 = content.includes("/impersonate/:studentId");

// ─── Insert before module.exports ──────────────────────────────────
const exportLine = 'module.exports = router;';
if (!content.includes(exportLine)) {
  console.log('❌ ERROR: module.exports = router; not found in admin.js');
  process.exit(1);
}

let newCode = '';
if (!alreadyHasS72 || !alreadyHasFreeze) {
  newCode += s72Code;
  console.log('✅ S72: Permission + Freeze routes added');
} else {
  console.log('ℹ️  S72: Already exists — skip');
}

if (!alreadyHasM4) {
  newCode += m4Code;
  console.log('✅ M4: Impersonate route added');
} else {
  console.log('ℹ️  M4: Already exists — skip');
}

if (newCode) {
  content = content.replace(exportLine, newCode + '\n' + exportLine);
  fs.writeFileSync(adminPath, content);
  console.log('\n✅ admin.js patched successfully!');
} else {
  console.log('\nℹ️  No changes needed — all routes exist');
}
