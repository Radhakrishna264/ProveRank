const mongoose = require('mongoose');
const ReviewSchema = new mongoose.Schema({
  batchId:     { type: mongoose.Schema.Types.ObjectId, ref: 'Batch', required: true },
  studentId:   { type: mongoose.Schema.Types.ObjectId, ref: 'User',  required: true },
  studentName: { type: String, default: 'Student' },
  rating:      { type: Number, required: true, min: 1, max: 5 },
  comment:     { type: String, default: '' },
  status:      { type: String, enum: ['pending','approved','rejected'], default: 'pending' },
  approvedBy:  { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  approvedAt:  { type: Date },
}, { timestamps: true });
module.exports = mongoose.model('Review', ReviewSchema);
