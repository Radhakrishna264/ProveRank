#!/bin/bash
G='\033[0;32m'; N='\033[0m'
log(){ echo -e "${G}[OK]${N} $1"; }

# Step 1: Settings Model banana
cat > ~/workspace/src/models/Settings.js << 'ENDMODEL'
const mongoose = require('mongoose')
const settingsSchema = new mongoose.Schema({
  key: { type: String, unique: true, default: 'platform' },
  brandName: { type: String, default: 'ProveRank' },
  tagline: { type: String, default: 'Prove Your Rank' },
  supportEmail: { type: String, default: '' },
  phone: { type: String, default: '' },
  seoTitle: { type: String, default: '' },
  seoDesc: { type: String, default: '' },
  seoKeywords: { type: String, default: '' }
}, { timestamps: true })
module.exports = mongoose.model('Settings', settingsSchema)
ENDMODEL
log "Settings model created"

# Step 2: Branding route file banana
cat > ~/workspace/src/routes/brandingRoutes.js << 'ENDROUTE'
const express = require('express')
const router = express.Router()
const Settings = require('../models/Settings')
const { verifyToken, requireRole } = require('../middleware/auth')

// GET /api/admin/branding
router.get('/branding', verifyToken, requireRole(['superadmin','admin']), async (req, res) => {
  try {
    let s = await Settings.findOne({ key: 'platform' })
    if (!s) s = await Settings.create({ key: 'platform' })
    res.json({ success: true, branding: s })
  } catch (err) {
    res.status(500).json({ success: false, message: err.message })
  }
})

// POST /api/admin/branding
router.post('/branding', verifyToken, requireRole(['superadmin','admin']), async (req, res) => {
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
ENDROUTE
log "Branding route created"

# Step 3: index.js mein mount karo
INDEX=~/workspace/src/index.js
if grep -q "brandingRoutes" "$INDEX"; then
  log "Branding route already mounted"
else
  MOUNT_LINE=$(grep -n "adminSystemRoutes\|app.use.*api/admin" "$INDEX" | tail -1 | cut -d: -f1)
  if [ ! -z "$MOUNT_LINE" ]; then
    sed -i "${MOUNT_LINE}a const brandingRoutes = require('./routes/brandingRoutes')\napp.use('/api/admin', brandingRoutes)" "$INDEX"
    log "Branding route mounted in index.js"
  else
    echo "Manual step needed - index.js mein add karo:"
    echo "const brandingRoutes = require('./routes/brandingRoutes')"
    echo "app.use('/api/admin', brandingRoutes)"
  fi
fi

echo ""
log "All done! Now run: cd ~/workspace && node src/index.js"
