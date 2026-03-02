const mongoose = require('mongoose');

const excelUploadLogSchema = new mongoose.Schema({
  uploadedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  type: { type: String, enum: ['questions', 'students'], required: true },
  totalRows: { type: Number, default: 0 },
  successCount: { type: Number, default: 0 },
  errorCount: { type: Number, default: 0 },
  errors: [{ row: Number, message: String }],
  uploadedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('ExcelUploadLog', excelUploadLogSchema);
