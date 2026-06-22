const mongoose = require('mongoose');
const schema = new mongoose.Schema({
  examName:   { type: String, required: true, trim: true },
  year:       { type: Number, required: true },
  status:     { type: String, enum: ['Complete','Partial','Empty'], default: 'Empty' },
  paperCount: { type: Number, default: 0 },
  notes:      { type: String, default: '' },
  createdBy:  { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null }
}, { timestamps: true });
schema.index({ examName: 1, year: 1 }, { unique: true });
module.exports = mongoose.model('PYQYearCard', schema);
