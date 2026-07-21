const mongoose = require('mongoose');

const BrandKitSchema = new mongoose.Schema({
  name: { type: String, default: 'Default Brand Kit' },
  primaryColor: { type: String, default: '#4D9FFF' },
  secondaryColor: { type: String, default: '#00D4FF' },
  accentColor: { type: String, default: '#FFD700' },
  fontPair: { type: String, default: 'modern' },
  logoUrl: { type: String, default: '' },
  watermarkUrl: { type: String, default: '' },
  defaultCtaStyle: { type: String, enum: ['rounded', 'square', 'pill', 'outline'], default: 'pill' },
  defaultBadgeStyle: { type: String, enum: ['pill', 'ribbon', 'corner'], default: 'pill' },
  defaultBannerLayout: { type: String, default: 'classic' },
  isDefault: { type: Boolean, default: true },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  createdByName: String
}, { timestamps: true });

module.exports = mongoose.models.BrandKit || mongoose.model('BrandKit', BrandKitSchema);
