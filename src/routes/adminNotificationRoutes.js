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


// S86: Mark notifications as read
router.post('/mark-read', async (req, res) => {
  try {
    const { id, all } = req.body;
    if (all) {
      await AdminNotification.updateMany({ isRead: false }, { isRead: true });
      return res.json({ success: true, message: 'All marked as read' });
    }
    if (id) {
      await AdminNotification.findByIdAndUpdate(id, { isRead: true, readAt: new Date() });
      return res.json({ success: true, message: 'Marked as read' });
    }
    res.status(400).json({ success: false, message: 'id or all required' });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

module.exports = router;
