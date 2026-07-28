// ══════════════════════════════════════════════════════════════════
// F53–57-B — 12) Policy Templates (Entry & Proctoring)
// Distinct from the existing ExamTemplate model (exam CREATION templates:
// title/pattern/marks). This one stores reusable ENTRY-FLOW configuration
// (waiting room / instructions / T&C / webcam / fullscreen / join rules)
// so admins can apply a full proctoring posture to any exam in one click.
// ══════════════════════════════════════════════════════════════════
const mongoose = require('mongoose');

const EntryPolicyTemplateSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  icon: { type: String, default: '🛡️' },
  kind: {
    type: String, default: 'custom',
    enum: ['standard_exam', 'strict_proctoring', 'relaxed_entry', 'webcam_mandatory', 'full_lockdown', 'custom']
  },
  description: { type: String, default: '' },
  // Full settings snapshot — same shape as EntryProctoringPolicy's config sections
  settings: {
    waitingRoom: { type: mongoose.Schema.Types.Mixed, default: {} },
    instructionsTrigger: { type: mongoose.Schema.Types.Mixed, default: {} },
    permissionCheckTrigger: { type: mongoose.Schema.Types.Mixed, default: {} },
    lateJoin: { type: mongoose.Schema.Types.Mixed, default: {} },
    waitingRoomLock: { type: mongoose.Schema.Types.Mixed, default: {} },
    instructions: { type: mongoose.Schema.Types.Mixed, default: {} },
    tnc: { type: mongoose.Schema.Types.Mixed, default: {} },
    webcam: { type: mongoose.Schema.Types.Mixed, default: {} },
    fullscreen: { type: mongoose.Schema.Types.Mixed, default: {} },
    joinRules: { type: mongoose.Schema.Types.Mixed, default: {} }
  },
  usageCount: { type: Number, default: 0 },
  lastUsedAt: { type: Date, default: null },
  isPinned: { type: Boolean, default: false },
  isBuiltIn: { type: Boolean, default: false }, // seeded defaults (12.2.1-12.2.5) — not deletable
  versions: [{
    settings: mongoose.Schema.Types.Mixed,
    savedAt: { type: Date, default: Date.now }
  }],
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });

module.exports = mongoose.models.EntryPolicyTemplate || mongoose.model('EntryPolicyTemplate', EntryPolicyTemplateSchema);

