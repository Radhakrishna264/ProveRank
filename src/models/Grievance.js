const mongoose = require('mongoose');
const grievanceSchema = new mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  subject: { type: String, required: true },
  description: { type: String, required: true },
  status: { type: String, enum: ['open', 'in_progress', 'resolved'], default: 'open' },
  adminReply: { type: String },
  resolvedAt: { type: Date }
}, { timestamps: true });
module.exports = mongoose.model('Grievance', grievanceSchema);
