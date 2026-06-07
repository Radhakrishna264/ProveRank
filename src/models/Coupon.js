const mongoose = require('mongoose');

const couponSchema = new mongoose.Schema({
  code:        { type: String, required: true, unique: true, uppercase: true, trim: true },
  description: String,
  type:        { type: String, enum: ['percent', 'flat'], required: true },
  value:       { type: Number, required: true, min: 0 },
  minOrderValue: { type: Number, default: 0 },
  maxDiscount:   Number,
  validFrom:   Date,
  validTill:   Date,
  usageLimit:  { type: Number, default: 100 },
  usedCount:   { type: Number, default: 0 },
  usedBy:      [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  isActive:    { type: Boolean, default: true },
  applicableCategories: [String],
  applicableSubjects:   [String],
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });

module.exports = mongoose.model('Coupon', couponSchema);
