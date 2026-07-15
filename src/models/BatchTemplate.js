const mongoose = require('mongoose');

const BatchTemplateSchema = new mongoose.Schema({
  name: { type: String, required: true },
  config: { type: mongoose.Schema.Types.Mixed, default: {} },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  createdByName: { type: String, default: 'Admin' }
}, { timestamps: true });

module.exports = mongoose.models.BatchTemplate || mongoose.model('BatchTemplate', BatchTemplateSchema);
