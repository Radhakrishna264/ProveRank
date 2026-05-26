const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const AdminNotification = require('../models/AdminNotification');

const JWT = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';

const auth = (req, res, next) => {
  const h = req.headers.authorization;
  if (!h || !h.startsWith('Bearer ')) return res.status(401).json({ error: 'Unauthorized' });
  try { req.user = jwt.verify(h.split(' ')[1], JWT); next(); }
  catch (e) { res.status(401).json({ error: 'Invalid token' }); }
};

// GET /api/admin/notifications
router.get('/', auth, async (req, res) => {
  try {
    const notifs = await AdminNotification.find()
      .sort({ createdAt: -1 }).limit(50).lean();
    const unread = notifs.filter(n => !n.isRead).length;
    res.json({ notifications: notifs, unread });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /api/admin/notifications/read-all
router.put('/read-all', auth, async (req, res) => {
  try {
    await AdminNotification.updateMany({ isRead: false }, { isRead: true });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /api/admin/notifications/:id/read
router.put('/:id/read', auth, async (req, res) => {
  try {
    await AdminNotification.findByIdAndUpdate(req.params.id, { isRead: true, readAt: new Date() });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// DELETE /api/admin/notifications/:id
router.delete('/:id', auth, async (req, res) => {
  try {
    await AdminNotification.findByIdAndDelete(req.params.id);
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /api/admin/notifications/test — test notification (enum: general)
router.post('/test', auth, async (req, res) => {
  try {
    const notif = await AdminNotification.create({
      type: req.body.type || 'general',
      title: req.body.title || 'Test Notification',
      message: req.body.message || 'ProveRank Notification system S86 working!',
      severity: req.body.severity || 'info',
      isRead: false
    });
    res.json({ success: true, notification: notif });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
