const express = require('express');
const router = express.Router();
const speakeasy = require('speakeasy');
const qrcode = require('qrcode');
const { verifyToken } = require('../middleware/auth');
const User = require('../models/User');

// POST /api/auth/2fa/enable
router.post('/2fa/enable', verifyToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User nahi mila' });
    if (user.twoFactorEnabled)
      return res.status(400).json({ message: '2FA already enabled hai' });
    const secret = speakeasy.generateSecret({
      name: `ProveRank (${user.email})`, length: 20
    });
    await User.findByIdAndUpdate(req.user.id, { twoFactorTempSecret: secret.base32 });
    const qrCode = await qrcode.toDataURL(secret.otpauth_url);
    res.json({
      success: true,
      message: 'QR scan karo phir /2fa/verify se confirm karo',
      secret: secret.base32,
      qrCode
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// POST /api/auth/2fa/verify
router.post('/2fa/verify', verifyToken, async (req, res) => {
  try {
    const { otp } = req.body;
    if (!otp) return res.status(400).json({ message: 'OTP required hai' });
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User nahi mila' });
    const secret = user.twoFactorTempSecret || user.twoFactorSecret;
    if (!secret) return res.status(400).json({ message: 'Pehle 2FA enable karo' });
    const verified = speakeasy.totp.verify({
      secret, encoding: 'base32', token: otp, window: 2
    });
    if (!verified) return res.status(400).json({ message: 'Invalid OTP' });
    await User.findByIdAndUpdate(req.user.id, {
      twoFactorEnabled: true,
      twoFactorSecret: secret,
      twoFactorTempSecret: null
    });
    res.json({ success: true, message: '2FA activate ho gaya!' });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// POST /api/auth/2fa/disable
router.post('/2fa/disable', verifyToken, async (req, res) => {
  try {
    const { otp } = req.body;
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User nahi mila' });
    if (!user.twoFactorEnabled)
      return res.status(400).json({ message: '2FA already disabled hai' });
    if (req.user.role !== 'superadmin') {
      if (!otp) return res.status(400).json({ message: 'OTP required hai' });
      const verified = speakeasy.totp.verify({
        secret: user.twoFactorSecret, encoding: 'base32', token: otp, window: 2
      });
      if (!verified) return res.status(400).json({ message: 'Invalid OTP' });
    }
    await User.findByIdAndUpdate(req.user.id, {
      twoFactorEnabled: false,
      twoFactorSecret: null,
      twoFactorTempSecret: null
    });
    res.json({ success: true, message: '2FA disable ho gaya' });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// POST /api/auth/2fa/validate
router.post('/2fa/validate', verifyToken, async (req, res) => {
  try {
    const { otp } = req.body;
    const user = await User.findById(req.user.id);
    if (!user || !user.twoFactorEnabled)
      return res.status(400).json({ message: '2FA enabled nahi hai' });
    const verified = speakeasy.totp.verify({
      secret: user.twoFactorSecret, encoding: 'base32', token: otp, window: 2
    });
    if (!verified) return res.status(400).json({ message: 'Invalid OTP' });
    res.json({ success: true, message: '2FA validated!' });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
