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
