const express = require('express')
const router = express.Router()
const Settings = require('../models/Settings')
const { verifyToken, isAdmin } = require('../middleware/auth')

// GET /api/admin/branding
router.get('/branding', verifyToken, isAdmin, async (req, res) => {
  try {
    let s = await Settings.findOne({ key: 'platform' })
    if (!s) s = await Settings.create({ key: 'platform' })
    res.json({ success: true, branding: s })
  } catch (err) {
    res.status(500).json({ success: false, message: err.message })
  }
})

// POST /api/admin/branding
router.post('/branding', verifyToken, isAdmin, async (req, res) => {
  try {
    const { brandName, tagline, supportEmail, phone, seoTitle, seoDesc, seoKeywords } = req.body
    const s = await Settings.findOneAndUpdate(
      { key: 'platform' },
      { brandName, tagline, supportEmail, phone, seoTitle, seoDesc, seoKeywords },
      { upsert: true, new: true }
    )
    res.json({ success: true, message: 'Branding saved successfully', branding: s })
  } catch (err) {
    res.status(500).json({ success: false, message: err.message })
  }
})

module.exports = router
