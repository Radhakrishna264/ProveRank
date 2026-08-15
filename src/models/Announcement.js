const mongoose = require('mongoose')

// ══════════════════════════════════════════════════════════════
// F42 — Announcement model
// Backs F42A (Admin Panel — Announcements) and F42B (Student Panel —
// Announcements). One collection, targeted per-audience, with full
// read/ack tracking, scheduling, drafts, and email delivery stats.
//
// F53–57-B additive change: optional examId + entryContext so this
// same model can also carry Entry & Proctoring "Broadcasts &
// Notifications" (waiting room announcements, instruction updates,
// consent reminders, camera/fullscreen reminders, join-window
// warnings, emergency notices) without creating a parallel model.
// examFlow.js's GET /:id/broadcasts route already queries by examId —
// this field was simply missing from the schema until now.
// ══════════════════════════════════════════════════════════════
const AnnouncementSchema = new mongoose.Schema({
  title:      { type: String, required: true },
  titleHi:    { type: String, default: '' },          // F42A §2.1.7 / F42B §3.5 bilingual
  message:    { type: String, required: true },        // sanitized HTML (bold/italic/link) — F42A §2.1.5
  messageHi:  { type: String, default: '' },

  type: { type: String, enum: ['exam', 'update', 'result', 'maintenance', 'urgent'], default: 'update' }, // F42A §2.1.1 (v2: +maintenance)

  audience: {
    mode:         { type: String, enum: ['all', 'testseries', 'students'], default: 'all' }, // F42A §1.2.2 / §2.1.9 (v2: +testseries)
    testSeriesIds:[{ type: mongoose.Schema.Types.ObjectId, ref: 'TestSeries' }],   // multi-select test series
    studentIds:   [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],    // specific students
  },

  sendVia: { type: String, enum: ['in-app', 'email', 'both'], default: 'in-app' }, // F42A §1.2.3

  pinned:     { type: Boolean, default: false },  // F42A §2.1.2 / F42B §2
  imageUrl:   { type: String, default: '' },      // F42A §2.1.6 / F42B §3.4
  scheduledAt:{ type: Date, default: null },      // F42A §2.1.3
  expiryDate: { type: Date, default: null },      // F42A §2.1.8 / F42B §3.9

  status: { type: String, enum: ['sent', 'scheduled', 'draft'], default: 'sent' }, // F42A §2.2.5

  createdBy:    { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  templateName: { type: String, default: '' },    // F42A §2.4.1
  targetCount:  { type: Number, default: 0 },      // total resolved recipients at send time

  // F42B §4 read tracking (per-student) — used for F42A §2.2.2 read-receipt stats
  readBy: [{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    readAt: { type: Date, default: Date.now },
  }],
  // F42B §6.5 — explicit "👍 Got it" acknowledgement (separate from passive read tracking)
  ackBy: [{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    ackAt:  { type: Date, default: Date.now },
  }],

  // F42A §2.3.2 per-series/email delivery status
  emailStats: {
    sent:      { type: Number, default: 0 },
    delivered: { type: Number, default: 0 },
    failed:    { type: Number, default: 0 },
  },

  // ── F53–57-B (additive, optional) — entry-stage broadcast support ──
  examId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam', default: null },
  entryContext: {
    isEntryBroadcast: { type: Boolean, default: false },
    broadcastType: {
      type: String, default: '',
      enum: ['', 'waiting_room_announcement', 'instruction_update', 'consent_reminder',
        'camera_reminder', 'fullscreen_reminder', 'join_window_warning', 'emergency_notice']
    },
    channel: { type: String, default: 'in-app', enum: ['in-app', 'waiting_room_popup', 'notification_center', 'email'] }
  }
}, { timestamps: true })

AnnouncementSchema.index({ status: 1, createdAt: -1 })
AnnouncementSchema.index({ 'audience.testSeriesIds': 1 })
AnnouncementSchema.index({ 'audience.studentIds': 1 })
AnnouncementSchema.index({ examId: 1, createdAt: -1 })

module.exports = mongoose.model('Announcement', AnnouncementSchema)

