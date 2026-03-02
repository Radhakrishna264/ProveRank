const mongoose = require('mongoose');

const customFieldSchema = new mongoose.Schema({
  fieldName:  { type: String, required: true, unique: true, trim: true },
  label:      { type: String, required: true },
  fieldType:  { type: String, enum: ['text', 'number', 'select', 'date'], default: 'text' },
  options:    [{ type: String }],
  required:   { type: Boolean, default: false },
  isActive:   { type: Boolean, default: true },
  createdBy:  { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, { timestamps: true });

module.exports = mongoose.model('CustomField', customFieldSchema);
