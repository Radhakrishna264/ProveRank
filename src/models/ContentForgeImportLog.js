const mongoose = require('mongoose');

// F20.15 / F21.x — Import history log for the NEW upgraded content-forge flow
// (separate from the legacy ExcelUploadLog used by the old /api/excel routes,
// so this is purely additive — does not touch existing log/history behaviour).
const contentForgeImportLogSchema = new mongoose.Schema({
  sourceType: { type: String, enum: ['excel', 'pdf'], required: true },
  target:     { type: String, enum: ['qs_bank', 'pyq_bank', 'exam'], required: true },
  fileName:   { type: String, default: '' },
  imported:   { type: Number, default: 0 },
  skipped:    { type: Number, default: 0 },
  errorCount: { type: Number, default: 0 },
  errorDetails: [{ row: mongoose.Schema.Types.Mixed, message: String }],
  createdBy:  { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, { timestamps: true });

module.exports = mongoose.model('ContentForgeImportLog', contentForgeImportLogSchema);

