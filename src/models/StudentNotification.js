const mongoose = require('mongoose');
const StudentNotificationSchema = new mongoose.Schema({
  userId:  { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  type:    { type: String, enum: ['price_drop','batch_update','trial_expiry','general'], default: 'general' },
  title:   { type: String, required: true },
  message: { type: String, required: true },
  batchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Batch' },
  isRead:  { type: Boolean, default: false },
  link:    { type: String, default: '/dashboard/test-series' },
}, { timestamps: true });
module.exports = mongoose.model('StudentNotification', StudentNotificationSchema);
