// ══════════════════════════════════════════════════════════════════
// Coupon — scoped ONLY to a single Batch or single TestSeries via
// scopeType + scopeId. No global coupon manager. Uniqueness of `code`
// is enforced within (scopeType, scopeId) only, among non-deleted docs.
// ══════════════════════════════════════════════════════════════════
const mongoose = require('mongoose');

const CouponSchema = new mongoose.Schema({
  code: { type: String, required: true, uppercase: true, trim: true },
  scopeType: { type: String, required: true, enum: ['batch', 'series'] },
  scopeId: { type: mongoose.Schema.Types.ObjectId, required: true },

  type: { type: String, required: true, enum: ['percent', 'flat'], default: 'percent' },
  value: { type: Number, required: true, min: 0 },
  maxDiscount: { type: Number, default: null },

  usageLimit: { type: Number, required: true, min: 1, default: 100 },
  perStudentLimitType: { type: String, enum: ['once', 'unlimited', 'custom'], default: 'once' },
  perStudentLimitCustom: { type: Number, default: 1 },

  validFrom: { type: Date, required: true },
  validTill: { type: Date, required: true },

  description: { type: String, default: '' },
  // NOTE: 'scheduled' and 'expired' are DERIVED at read-time from
  // validFrom/validTill (see getEffectiveCouponStatus in the route
  // files) — not persisted, to avoid relying on cron (unreliable on
  // Render free-tier spin-down). Only these 3 states are ever stored:
  status: { type: String, enum: ['draft', 'active', 'disabled'], default: 'draft' },
  visibility: { type: String, enum: ['public', 'hidden'], default: 'public' },
  autoApplyBest: { type: Boolean, default: false },
  applicablePlan: { type: String, enum: ['entire', 'base_price'], default: 'entire' },

  usageCount: { type: Number, default: 0 },
  uniqueStudents: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  revenueGenerated: { type: Number, default: 0 },
  discountGiven: { type: Number, default: 0 },
  firstUsedAt: { type: Date, default: null },
  lastUsedAt: { type: Date, default: null },
  usageHistory: [{
    student: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    studentName: String,
    appliedAmount: Number,
    discountAmount: Number,
    timestamp: { type: Date, default: Date.now },
    orderRef: String,
    status: { type: String, default: 'success' }
  }],

  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  createdByName: String,
  updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  updatedByName: String,
  statusChangedBy: String,
  statusChangedAt: Date,

  isDeleted: { type: Boolean, default: false },
  deletedBy: String,
  deletedAt: Date,

  history: [{
    field: String,
    oldValue: mongoose.Schema.Types.Mixed,
    newValue: mongoose.Schema.Types.Mixed,
    action: String,
    performedBy: String,
    performedByName: String,
    timestamp: { type: Date, default: Date.now }
  }]
}, { timestamps: true });

CouponSchema.index({ scopeType: 1, scopeId: 1, code: 1 }, { unique: true, partialFilterExpression: { isDeleted: false } });

module.exports = mongoose.models.Coupon || mongoose.model('Coupon', CouponSchema);
