const express  = require('express');
const router   = express.Router();
const jwt      = require('jsonwebtoken');
const mongoose = require('mongoose');
const BatchActivity = require('../models/BatchActivity');
const JWT = process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024';

const auth = (req, res, next) => {
  const h = req.headers.authorization;
  if (!h || !h.startsWith('Bearer ')) return res.status(401).json({ error: 'Unauthorized' });
  try { req.user = jwt.verify(h.split(' ')[1], JWT); next(); }
  catch (e) { res.status(401).json({ error: 'Invalid token' }); }
};
const isAdmin = (req, res, next) => {
  if (!['admin','superadmin'].includes(req.user?.role)) return res.status(403).json({ error: 'Admin only' });
  next();
};

// GET /api/batch-activity/:batchId — get activities for a batch
router.get('/:batchId', auth, async (req, res) => {
  try {
    const activities = await BatchActivity.find({ batchId: req.params.batchId, isActive: true })
      .sort({ createdAt: -1 }).limit(10).lean();
    res.json({ activities });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /api/batch-activity — admin push activity
router.post('/', auth, isAdmin, async (req, res) => {
  try {
    const { batchId, type, title, message, icon } = req.body;
    if (!batchId || !title) return res.status(400).json({ error: 'batchId and title required' });
    const activity = await BatchActivity.create({
      batchId, type: type || 'announcement',
      title, message: message || '', icon: icon || '📢',
      createdBy: req.user.id
    });
    res.json({ success: true, activity });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// DELETE /api/batch-activity/:id — admin remove activity
router.delete('/:id', auth, isAdmin, async (req, res) => {
  try {
    await BatchActivity.findByIdAndUpdate(req.params.id, { isActive: false });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = router;
