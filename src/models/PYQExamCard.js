const mongoose = require('mongoose');
const schema = new mongoose.Schema({
  name:       { type: String, required: true, unique: true, trim: true },
  icon:       { type: String, default: '📚' },
  color:      { type: String, default: '#4D9FFF' },
  desc:       { type: String, default: '' },
  isDefault:  { type: Boolean, default: false },
  order:      { type: Number, default: 99 },
  createdBy:  { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null }
}, { timestamps: true });
module.exports = mongoose.model('PYQExamCard', schema);
