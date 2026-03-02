const express = require('express');
const router = express.Router();
const { verifyToken, isSuperAdmin } = require('../middleware/auth');
const CustomField = require('../models/CustomField');
const User = require('../models/User');

// GET /api/auth/registration-fields
router.get('/registration-fields', verifyToken, async (req, res) => {
  try {
    const fields = await CustomField.find({ isActive: true });
    res.json({ success: true, fields });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// POST /api/auth/registration-fields (SuperAdmin only)
router.post('/registration-fields', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const { fieldName, label, fieldType, options, required } = req.body;
    if (!fieldName || !label)
      return res.status(400).json({ message: 'fieldName aur label required hain' });
    const existing = await CustomField.findOne({ fieldName });
    if (existing)
      return res.status(400).json({ message: 'Yeh field already exist karti hai' });
    const field = await CustomField.create({
      fieldName, label,
      fieldType: fieldType || 'text',
      options: options || [],
      required: required || false,
      createdBy: req.user.id
    });
    res.status(201).json({ success: true, message: 'Custom field add ho gaya', field });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// PUT /api/auth/registration-fields/:id
router.put('/registration-fields/:id', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    const field = await CustomField.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!field) return res.status(404).json({ message: 'Field nahi mili' });
    res.json({ success: true, message: 'Field update ho gaya', field });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// DELETE /api/auth/registration-fields/:id
router.delete('/registration-fields/:id', verifyToken, isSuperAdmin, async (req, res) => {
  try {
    await CustomField.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Field delete ho gaya' });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// GET /api/auth/me
router.get('/me', verifyToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id)
      .select('-password -twoFactorSecret -twoFactorTempSecret');
    if (!user) return res.status(404).json({ message: 'User nahi mila' });
    res.json({ success: true, user });
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
