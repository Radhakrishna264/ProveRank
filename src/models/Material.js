const mongoose = require('mongoose');

const MaterialSchema = new mongoose.Schema({
  title:     { type: String, required: true, trim: true },
  content:   { type: String, required: true },
  fileType:  { type: String, default: 'txt' },
  fileSize:  { type: Number, default: 0 },
  adminId:   { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Material', MaterialSchema);
