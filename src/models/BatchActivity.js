const mongoose = require('mongoose');
const BatchActivitySchema = new mongoose.Schema({
  batchId:   { type: mongoose.Schema.Types.ObjectId, ref: 'Batch', required: true },
  type:      { type: String, enum: ['new_test','new_material','announcement','update','tip'], default: 'announcement' },
  title:     { type: String, required: true },
  message:   { type: String, default: '' },
  icon:      { type: String, default: '📢' },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  isActive:  { type: Boolean, default: true },
}, { timestamps: true });
module.exports = mongoose.model('BatchActivity', BatchActivitySchema);
