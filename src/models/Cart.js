const mongoose = require('mongoose');

const cartSchema = new mongoose.Schema({
  student: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  items: [{
    product:  { type: mongoose.Schema.Types.ObjectId, ref: 'Product' },
    quantity: { type: Number, default: 1, min: 1, max: 20 }
  }],
  couponCode:     String,
  couponDiscount: { type: Number, default: 0 }
}, { timestamps: true });

module.exports = mongoose.model('Cart', cartSchema);
