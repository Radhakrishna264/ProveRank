const mongoose = require('mongoose');

const BatchPaymentSchema = new mongoose.Schema({
  student: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  studentName: { type: String, default: '' },
  studentEmail: { type: String, default: '' },
  itemId: { type: mongoose.Schema.Types.ObjectId, required: true },
  itemType: { type: String, enum: ['batch', 'series'], required: true },
  itemName: { type: String, default: '' },
  examType: { type: String, default: '' },
  amount: { type: Number, required: true },
  razorpayOrderId: { type: String, required: true },
  razorpayPaymentId: { type: String, required: true },
  testMode: { type: Boolean, default: false },
  receiptNo: { type: String, required: true, unique: true }
}, { timestamps: true });

module.exports = mongoose.models.BatchPayment || mongoose.model('BatchPayment', BatchPaymentSchema);
