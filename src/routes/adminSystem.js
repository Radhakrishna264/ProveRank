const express = require('express');
const router = express.Router();
const { verifyToken, isSuperAdmin } = require('../middleware/auth');

// In-memory store (MongoDB mein save karna ho toh model banao)
let maintenanceState = { enabled: false, message: '', updatedAt: null };
let featureFlags = {
  darkMode: true, liveRank: true, webcam: true,
  twoFactor: true, aiFeatures: true, pyqBank: true,
  bulkImport: true, pdfExport: true, emailNotifications: false
};

// ── S66: MAINTENANCE MODE ────────────────────────────────────
router.post('/maintenance', verifyToken, isSuperAdmin, (req, res) => {
  const { enabled, message } = req.body;
  maintenanceState = { enabled: enabled === true, message: message || '', updatedAt: new Date() };
  res.json({ success: true, message: `Maintenance mode ${enabled ? 'ON' : 'OFF'} ho gaya`, state: maintenanceState });
});

router.get('/maintenance', (req, res) => {
  res.json({ success: true, maintenance: maintenanceState });
});

// ── N21: FEATURE FLAG SYSTEM ─────────────────────────────────
router.get('/feature-flags', verifyToken, isSuperAdmin, (req, res) => {
  res.json({ success: true, flags: featureFlags });
});

router.put('/feature-flags', verifyToken, isSuperAdmin, (req, res) => {
  const { feature, enabled } = req.body;
  if (!feature) return res.status(400).json({ message: 'feature name required' });
  featureFlags[feature] = enabled === true;
  res.json({ success: true, message: `Feature '${feature}' ${enabled ? 'ON' : 'OFF'} ho gaya`, flags: featureFlags });
});

router.put('/feature-flags/bulk', verifyToken, isSuperAdmin, (req, res) => {
  const { flags } = req.body;
  if (!flags || typeof flags !== 'object')
    return res.status(400).json({ message: 'flags object required' });
  Object.assign(featureFlags, flags);
  res.json({ success: true, message: 'Bulk flags update ho gaye', flags: featureFlags });
});

module.exports = router;
