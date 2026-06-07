const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
  product:  { type: mongoose.Schema.Types.ObjectId, ref: 'Product', required: true },
  student:  { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  order:    { type: mongoose.Schema.Types.ObjectId, ref: 'Order' },
  rating:   { type: Number, required: true, min: 1, max: 5 },
  title:    String,
  body:     String,
  images:   [String],
  isVerifiedPurchase: { type: Boolean, default: false },
  helpful:  [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  adminReply:   String,
  adminReplyAt: Date,
  isVisible: { type: Boolean, default: true }
}, { timestamps: true });

reviewSchema.index({ product: 1, createdAt: -1 });

module.exports = mongoose.model('ProductReview', reviewSchema);
