const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { setSession } = require('../middleware/session');
const { generateOTP, sendOTP } = require('../utils/otp');

// REGISTER - OTP bhejo
router.post('/register', async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;
    const exists = await User.findOne({ email });
    if (exists) return res.status(400).json({ message: 'Email already registered' });
    const hashed = await bcrypt.hash(password, 12);
    const otp = generateOTP();
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000);
    const user = await User.create({
      name, email, phone,
      password: hashed,
      otp, otpExpiry,
      verified: false
    });
    try {
      await sendOTP(email, otp);
      res.status(201).json({ message: 'OTP sent to email', userId: user._id });
    } catch (emailErr) {
      res.status(201).json({ message: 'User created. Email failed - use verify-otp with OTP: ' + otp, userId: user._id });
    }
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// VERIFY OTP
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

// LOGIN
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ message: 'Invalid credentials' });
    if (!user.verified) return res.status(400).json({ message: 'Email not verified' });
    if (user.banned) return res.status(403).json({ message: 'Account banned', reason: user.banReason });
    const match = await bcrypt.compare(password, user.password);
    if (!match) return res.status(400).json({ message: 'Invalid credentials' });
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    user.loginHistory.push({ ip, device: req.headers['user-agent'], time: new Date() });
    await user.save();
    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '7d' });
const AuditLog = require('../models/AuditLog');

    await AuditLog.create({
      action: 'LOGIN',
      performedBy: user._id,
      details: 'Login successful',
      ip: ip
    });
    setSession(user._id.toString(), token);
    res.json({ message: 'Login successful', token, role: user.role });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
