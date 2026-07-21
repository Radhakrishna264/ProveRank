const mongoose = require('mongoose');

const BannerTemplateSchema = new mongoose.Schema({
  name: { type: String, required: true },
  category: { type: String, default: 'Custom' },
  source: { type: String, enum: ['custom', 'cloned'], default: 'custom' },
  clonedFromBuiltIn: { type: String, default: '' }, // built-in template id it was cloned from, if any
  config: { type: mongoose.Schema.Types.Mixed, required: true }, // full design snapshot
  isFavorite: { type: Boolean, default: false },
  usageCount: { type: Number, default: 0 },
  lastUsedAt: { type: Date, default: null },
  versions: [{
    config: mongoose.Schema.Types.Mixed,
    savedAt: { type: Date, default: Date.now },
    label: String
  }],
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  createdByName: String,
  isDeleted: { type: Boolean, default: false }
}, { timestamps: true });

module.exports = mongoose.models.BannerTemplate || mongoose.model('BannerTemplate', BannerTemplateSchema);
