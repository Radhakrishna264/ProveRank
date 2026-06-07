const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
  product:       { type: mongoose.Schema.Types.ObjectId, ref: 'Product' },
  name:          String,
  image:         String,
  sku:           String,
  quantity:      { type: Number, min: 1, default: 1 },
  price:         Number,
  originalPrice: Number,
  discount:      Number
}, { _id: false });

const addressSchema = new mongoose.Schema({
  fullName:    String,
  phone:       String,
  addressLine1: String,
  addressLine2: String,
  city:        String,
  state:       String,
  pincode:     String,
  country:     { type: String, default: 'India' },
  landmark:    String
}, { _id: false });

const statusHistorySchema = new mongoose.Schema({
  status:    String,
  note:      String,
  updatedBy: String,
  timestamp: { type: Date, default: Date.now }
}, { _id: false });

const orderSchema = new mongoose.Schema({
  orderId:  { type: String, unique: true },
  student:  { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  items:    [orderItemSchema],
  shippingAddress: addressSchema,
  payment: {
    method:        { type: String, enum: ['COD', 'UPI', 'Card', 'NetBanking', 'Wallet'], default: 'COD' },
    status:        { type: String, enum: ['pending', 'paid', 'failed', 'refunded'], default: 'pending' },
    transactionId: String,
    upiId:         String,
    paidAt:        Date,
    refundedAt:    Date,
    refundAmount:  Number,
    gatewayRef:    String
  },
  pricing: {
    subtotal:       { type: Number, default: 0 },
    deliveryCharge: { type: Number, default: 0 },
    couponDiscount: { type: Number, default: 0 },
    totalDiscount:  { type: Number, default: 0 },
    total:          { type: Number, default: 0 }
  },
  couponCode:    String,
  status: {
    type: String,
    enum: ['pending','confirmed','packed','shipped','out_for_delivery','delivered','cancelled','return_requested','returned','refunded'],
    default: 'pending'
  },
  statusHistory:     [statusHistorySchema],
  trackingNumber:    String,
  trackingUrl:       String,
  courierName:       String,
  estimatedDelivery: Date,
  deliveredAt:       Date,
  cancelledAt:       Date,
  cancellationReason: String,
  returnReason:      String,
  buyerNotes:        String,
  adminNotes:        String,
  invoiceNumber:     String
}, { timestamps: true });

orderSchema.pre('save', async function (next) {
  if (!this.orderId) {
    const count = await mongoose.model('Order').countDocuments();
    const rand = Math.random().toString(36).substring(2, 5).toUpperCase();
    this.orderId = 'PRO-' + String(count + 1001).padStart(6, '0') + rand;
  }
  if (!this.invoiceNumber) {
    const d = new Date();
    this.invoiceNumber = 'INV-' + d.getFullYear() + String(d.getMonth()+1).padStart(2,'0') + '-' + this.orderId;
  }
  next();
});

orderSchema.index({ student: 1, createdAt: -1 });
orderSchema.index({ status: 1, createdAt: -1 });

module.exports = mongoose.model('Order', orderSchema);
