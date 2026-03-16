const mongoose = require('mongoose');
const featureFlagSchema = new mongoose.Schema({
  key: { type: String, required: true, unique: true },
  enabled: { type: Boolean, default: false },
  label: { type: String },
  description: { type: String },
  updatedAt: { type: Date, default: Date.now }
});
module.exports = mongoose.model('FeatureFlag', featureFlagSchema);
