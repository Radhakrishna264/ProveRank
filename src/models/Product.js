const mongoose = require('mongoose');

const specSchema  = new mongoose.Schema({ key: String, value: String }, { _id: false });
const imageSchema = new mongoose.Schema({ url: String, alt: String, isPrimary: { type: Boolean, default: false } }, { _id: false });

const productSchema = new mongoose.Schema({
  name:             { type: String, required: true, trim: true },
  slug:             { type: String, unique: true, sparse: true },
  description:      { type: String, required: true },
  shortDescription: String,
  category: {
    type: String,
    enum: ['Books','Notes','Stationery','Lab Equipment','Combo Pack','Digital','Other'],
    required: true
  },
  subject: {
    type: String,
    enum: ['Physics','Chemistry','Biology','Mathematics','All Subjects','Other'],
    default: 'All Subjects'
  },
  classLevel:  { type: String, enum: ['Class 11','Class 12','Both','All'], default: 'All' },
  examType:    { type: String, enum: ['NEET','JEE','Both','All'], default: 'All' },
  images:      [imageSchema],
  price:          { type: Number, required: true, min: 0 },
  originalPrice:  { type: Number, required: true, min: 0 },
  discountPercent:{ type: Number, default: 0 },
  stock:              { type: Number, default: 0, min: 0 },
  lowStockThreshold:  { type: Number, default: 10 },
  sold:               { type: Number, default: 0 },
  sku:    { type: String, unique: true, sparse: true },
  isbn:   String,
  author: String,
  publisher: String,
  edition:   String,
  language:  { type: String, default: 'English' },
  pages:   Number,
  weight:  Number,
  dimensions: { length: Number, width: Number, height: Number },
  ratings: {
    average: { type: Number, default: 0 },
    count:   { type: Number, default: 0 }
  },
  tags:           [String],
  features:       [String],
  specifications: [specSchema],
  isActive:     { type: Boolean, default: true },
  isFeatured:   { type: Boolean, default: false },
  isNew:        { type: Boolean, default: true },
  isBestSeller: { type: Boolean, default: false },
  deliveryTime:      { type: String, default: '3-5 business days' },
  returnPolicy:      { type: String, default: '7 days return policy' },
  deliveryCharge:    { type: Number, default: 49 },
  freeDeliveryAbove: { type: Number, default: 499 },
  relatedProducts:   [{ type: mongoose.Schema.Types.ObjectId, ref: 'Product' }]
}, { timestamps: true });

// ── async pre-save (NO next parameter — avoids "next is not a function") ──
productSchema.pre('save', async function () {
  if (!this.slug) {
    this.slug = this.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '') + '-' + Date.now();
  }
  if (!this.sku) {
    this.sku = 'PRK-' + Math.random().toString(36).substring(2, 8).toUpperCase();
  }
  if (this.originalPrice && this.price) {
    this.discountPercent = Math.round(((this.originalPrice - this.price) / this.originalPrice) * 100);
  }
});

productSchema.index({ name: 'text', description: 'text', tags: 'text', author: 'text' });
productSchema.index({ category: 1, subject: 1, isActive: 1 });

// ── safe model export (avoid OverwriteModelError on hot reload) ──
module.exports = mongoose.models.Product || mongoose.model('Product', productSchema);
