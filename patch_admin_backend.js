const fs = require('fs');
const fp = process.env.HOME + '/workspace/src/routes/adminManagement.js';
let c = fs.readFileSync(fp, 'utf8');
let n = 0;

// FIX 1: /archived route bug — $ne:true → true
const arM = c.match(/router\.get\(['"]\/archived['"]([\s\S]*?)(?=router\.|module\.exports)/);
if(arM) {
  const orig = arM[0];
  if(orig.includes('$ne')) {
    const fixed = orig.replace(/archived:\s*\{\s*\$ne:\s*true\s*\}/g, 'archived: true');
    c = c.replace(orig, fixed);
    n++; console.log('FIX1: /archived route query fixed — now returns actually archived admins');
  } else { console.log('INFO: /archived route already correct'); }
} else { console.log('WARN: /archived route not matched'); }

// FIX 2: Add /profile/:id route
if(!c.includes("'/profile/:id'") && !c.includes('"/profile/:id"')) {
  const pr = `
// ===== Admin Full Profile + Activity Logs =====
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
      admin: admin.toObject(),
      activityLogs: activityLogs,
      loginHistory: admin.loginHistory || []
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
});
`;
  c = c.replace(/\nmodule\.exports\s*=\s*router/, pr + '\nmodule.exports = router');
  n++; console.log('FIX2: /profile/:id route added');
} else { console.log('INFO: /profile/:id already exists'); }

fs.writeFileSync(fp, c);
console.log('BACKEND PATCH DONE — ' + n + ' changes applied');
