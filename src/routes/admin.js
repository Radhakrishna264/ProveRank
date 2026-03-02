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

module.exports = router;
