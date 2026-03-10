const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { generateOTP, sendOTP } = require('../utils/otp');
const { verifyToken, isSuperAdmin } = require('../middleware/auth');
const CustomField = require('../models/CustomField');

router.post('/register', async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;
    const exists = await User.findOne({ email });
    if (exists) return res.status(400).json({ message: 'Email already registered' });
    const hashed = await bcrypt.hash(password, 12);
    const otp = generateOTP();
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000);
    const user = await User.create({ name, email, phone, password: hashed, otp, otpExpiry, verified: false });
    try {
      await sendOTP(email, otp);
      res.status(201).json({ message: 'OTP sent to email', userId: user._id });
    } catch (emailErr) {
      res.status(201).json({ message: 'User created. OTP: ' + otp, userId: user._id });
    }
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.post('/verify-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });
    if (user.verified) return res.status(400).json({ message: 'Already verified' });
    if (user.otp !== otp) return res.status(400).json({ message: 'Invalid OTP' });
    if (user.otpExpiry < new Date()) return res.status(400).json({ message: 'OTP expired' });
    user.verified = true;
    user.otp = undefined;
    user.otpExpiry = undefined;
    await user.save();
    res.json({ message: 'Email verified successfully' });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    console.log('LOGIN ATTEMPT:', email);
    const user = await User.findOne({ email });
    console.log('USER FOUND:', user ? user.email : 'NULL');
    if (!user) return res.status(400).json({ message: 'Invalid credentials' });
    if (!user.verified && user.role !== 'superadmin' && user.role !== 'admin') {
      return res.status(400).json({ message: 'Email not verified' });
    }
    if (user.banned) return res.status(403).json({ message: 'Account banned', reason: user.banReason });
    const match = await bcrypt.compare(password, user.password);
    console.log('BCRYPT MATCH:', match);
    if (!match) return res.status(400).json({ message: 'Invalid credentials' });
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    user.loginHistory = user.loginHistory || [];
    user.loginHistory.push({ ip, device: req.headers['user-agent'], time: new Date() });
    await user.save();
    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '7d' });
    try {
      const AuditLog = require('../models/AuditLog');
      await AuditLog.create({ action: 'LOGIN', performedBy: user._id, details: 'Login successful', ip: ip });
    } catch (auditErr) {
      console.log('AuditLog skip:', auditErr.message);
    }
    res.json({ message: 'Login successful', token, role: user.role });
  } catch (err) {
    console.log('LOGIN ERROR:', err.message);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.get('/registration-fields', verifyToken, async (req, res) => {
  try {
    const fields = await CustomField.find({ isActive: true });
    const u = await require('../models/User').findById(user._id || user.id).select('loginHistory email role').lean(); res.json({ success: true, fields, loginHistory: u?.loginHistory || [] });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.post('/registration-fields', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { fieldName, label, fieldType, options, required } = req.body;
    const field = await CustomField.create({ fieldName, label, fieldType, options, required });
    res.json({ success: true, field });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
