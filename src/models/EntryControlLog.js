// ══════════════════════════════════════════════════════════════════
// F53–57-B — 15) Control Logs (runtime entry/proctoring events)
// Populated by students' own attempt-flow pages calling
// POST /api/entry-proctoring/log-event, and read by the admin
// Control Logs tab + 16.8/16.9/16.10 analytics.
// ══════════════════════════════════════════════════════════════════
const mongoose = require('mongoose');

const EntryControlLogSchema = new mongoose.Schema({
  examId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam', required: true },
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  eventType: {
    type: String, required: true,
    enum: [
      'permission_denied', 'chat_disabled', 'join_blocked', 'fullscreen_exit',
      'camera_denied', 'auto_transition', 'instruction_accepted', 'tc_accepted',
      'waiting_room_joined', 'waiting_room_left', 'late_join_attempt', 'rejoin_attempt',
      'retry_attempt', 'step_reached', 'step_failed'
    ]
  },
  step: { type: String, default: '' }, // waiting_room / chat / instructions / tnc / permission_check / ready / exam
  severity: { type: String, enum: ['info', 'warning', 'critical'], default: 'info' },
  status: { type: String, enum: ['success', 'failed', 'blocked'], default: 'success' },
  details: { type: String, default: '' },
  meta: { type: mongoose.Schema.Types.Mixed, default: {} }
}, { timestamps: true });

EntryControlLogSchema.index({ examId: 1, createdAt: -1 });
EntryControlLogSchema.index({ eventType: 1, createdAt: -1 });

module.exports = mongoose.models.EntryControlLog || mongoose.model('EntryControlLog', EntryControlLogSchema);

