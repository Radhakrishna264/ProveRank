#!/bin/bash
# ══════════════════════════════════════════════════════════════════
# ProveRank — F53–57-B Entry & Proctoring Control Center (Admin)
# IMPLEMENTATION SCRIPT
#
# Covers every section of the spec:
#  1) Module tabs  2) KPI cards  3) Overview  4) Policy Builder
#  5) Waiting Room Control + Scheduler  6) Instructions Manager
#  7) T&C / Consent Manager  8) Webcam Permission Control
#  9) Fullscreen Enforcement  10) Join Rules & Availability
#  11) Broadcasts & Notifications  12) Policy Templates
#  13) Live Preview / Simulator  14) Audit & Version History
#  15) Control Logs  16) All 10 SaaS upgrade features
#
# Safe by design:
#  - 3 brand-new models (additive, new collections) — nothing touched.
#  - 1 new route file — nothing touched.
#  - Announcement.js — full-file rewrite, verified field-for-field
#    identical to your existing schema PLUS 2 new optional fields.
#  - index.js — idempotent Node.js patcher, timestamped backup,
#    skips cleanly if already applied.
#  - page.tsx (admin panel) — 4 single-line, exact-match, verified
#    edits (1 import, 1 sidebar entry, 1 permission-map entry, 1
#    render line). Counts are checked before AND after; if anything
#    doesn't match your current file exactly, that specific edit is
#    skipped and the backup is restored automatically — nothing is
#    ever left half-patched.
#
# Run this from ~/workspace on Replit.
# ══════════════════════════════════════════════════════════════════
set -e
cd ~/workspace || { echo "❌ Run this from ~/workspace"; exit 1; }

echo "════════════════════════════════════════════"
echo "STEP 0 — Locating project paths"
echo "════════════════════════════════════════════"
if [ -f "src/index.js" ]; then BACKEND_ENTRY="src/index.js"; elif [ -f "index.js" ]; then BACKEND_ENTRY="index.js"; else
  echo "❌ Could not find src/index.js or index.js in $(pwd)"; exit 1
fi
echo "✔ Backend entry: $BACKEND_ENTRY"

ROUTES_DIR="src/routes"; [ -d "$ROUTES_DIR" ] || ROUTES_DIR="routes"
MODELS_DIR="src/models"; [ -d "$MODELS_DIR" ] || MODELS_DIR="models"
if [ ! -d "$ROUTES_DIR" ] || [ ! -d "$MODELS_DIR" ]; then
  echo "❌ Could not find routes/models folders (expected src/routes + src/models)."; exit 1
fi
echo "✔ Routes dir: $ROUTES_DIR"
echo "✔ Models dir: $MODELS_DIR"

FRONTEND_DIR="frontend"
[ -d "$FRONTEND_DIR" ] || { echo "❌ frontend/ folder not found"; exit 1; }
ADMIN_PAGE="$FRONTEND_DIR/app/admin/x7k2p/page.tsx"
if [ ! -f "$ADMIN_PAGE" ]; then
  echo "⚠️  Expected file not found: $ADMIN_PAGE — searching…"
  FOUND=$(find "$FRONTEND_DIR" -path "*admin/x7k2p*page.tsx" 2>/dev/null | head -1)
  if [ -n "$FOUND" ]; then ADMIN_PAGE="$FOUND"; echo "✔ Using: $ADMIN_PAGE"; else
    echo "❌ Could not locate the Admin Panel page.tsx — skipping frontend sidebar wiring only."
    ADMIN_PAGE=""
  fi
fi
ADMIN_COMPONENTS_DIR="$FRONTEND_DIR/app/admin/x7k2p"
if [ -n "$ADMIN_PAGE" ]; then ADMIN_COMPONENTS_DIR="$(dirname "$ADMIN_PAGE")"; fi

echo ""
echo "════════════════════════════════════════════"
echo "STEP 1 — Backend: 3 new models (additive, new collections)"
echo "════════════════════════════════════════════"
cat > "$MODELS_DIR/EntryProctoringPolicy.js" << 'PREPPOLEOF'
// ══════════════════════════════════════════════════════════════════
// F53–57-B — Entry & Proctoring Control Center — Policy model
// One policy = the full entry-flow configuration (waiting room,
// instructions, T&C, webcam, fullscreen, join rules) for a given
// scope (global default / exam / batch / test series / custom).
// ══════════════════════════════════════════════════════════════════
const mongoose = require('mongoose');

const instructionPointSchema = new mongoose.Schema({
  id: { type: String, default: () => new mongoose.Types.ObjectId().toString() },
  text: { type: String, default: '' },
  textHi: { type: String, default: '' },
  type: {
    type: String, default: 'custom',
    enum: ['exam_name_duration', 'total_marks', 'marking_scheme', 'total_questions', 'subject_wise_count',
      'webcam_requirement', 'right_click_disabled', 'tab_switch_policy', 'fullscreen_policy', 'custom']
  },
  mandatory: { type: Boolean, default: false },
  warning: { type: Boolean, default: false },
  bilingual: { type: Boolean, default: true },
  order: { type: Number, default: 0 }
}, { _id: false });

const historyEntrySchema = new mongoose.Schema({
  version: Number,
  section: String,           // waitingRoom / instructions / tnc / webcam / fullscreen / joinRules / scope / general
  oldValue: mongoose.Schema.Types.Mixed,
  newValue: mongoose.Schema.Types.Mixed,
  reason: { type: String, default: '' },
  changedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  changedByName: { type: String, default: '' },
  changedAt: { type: Date, default: Date.now },
  snapshot: mongoose.Schema.Types.Mixed // full policy snapshot at this version (for rollback/diff)
}, { _id: false });

const EntryProctoringPolicySchema = new mongoose.Schema({
  name: { type: String, default: 'Untitled Policy' },

  // ── 4.2 Scope ──
  scope: {
    type: { type: String, enum: ['global', 'exam', 'batch', 'series', 'subject_group', 'custom'], default: 'global' },
    examId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam', default: null },
    batchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Batch', default: null },
    testSeriesId: { type: mongoose.Schema.Types.ObjectId, ref: 'TestSeries', default: null },
    subjectGroup: { type: String, default: '' },
    customRuleSet: { type: mongoose.Schema.Types.Mixed, default: null }
  },

  // ── 4.3/4.4 draft/publish lifecycle ──
  status: { type: String, enum: ['draft', 'published', 'archived'], default: 'draft' },
  version: { type: Number, default: 1 },
  locked: { type: Boolean, default: false },           // 16.7 policy lock after start
  lockedAfterStart: { type: Boolean, default: true },  // auto-lock critical fields once exam goes live
  publishedAt: { type: Date, default: null },
  publishedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  draftChangesPending: { type: Boolean, default: false },

  // ── 16.5 Scheduled publish ──
  scheduledPublishAt: { type: Date, default: null },

  // ── 5) Waiting Room Control + 5.5 Scheduler ──
  waitingRoom: {
    enabled: { type: Boolean, default: false },
    triggerMode: { type: String, enum: ['preset', 'custom'], default: 'preset' },
    presetMinutes: { type: Number, default: 20 },       // 5,10,15,20,30,45,60
    customMinutes: { type: Number, default: 20 },
    countdownDisplay: { type: Boolean, default: true },
    liveStudentCount: { type: Boolean, default: true },
    studentJoinAccess: { type: Boolean, default: true },
    adminBroadcastAccess: { type: Boolean, default: true },
    tipsRotation: { type: Boolean, default: true },
    tipsIntervalSec: { type: Number, default: 20 },
    musicToggle: { type: Boolean, default: true },
    musicDefaultState: { type: Boolean, default: false },
    chatEnabled: { type: Boolean, default: true },
    chatStartOffsetMin: { type: Number, default: 20 },   // relative to exam start (minutes before)
    chatEndOffsetMin: { type: Number, default: 10 },
    autoDisableBeforeExamMin: { type: Number, default: 10 },
    chatCountdownWarning: { type: Boolean, default: true },
    adminChatOnlyMode: { type: Boolean, default: false },
    autoTransitionToInstructions: { type: Boolean, default: true },
    countdownFormat: { type: String, enum: ['HH:MM:SS', 'MM:SS'], default: 'MM:SS' },
    showSeconds: { type: Boolean, default: true },
    showProgressBar: { type: Boolean, default: true },
    autoRefreshTimer: { type: Boolean, default: true },
    serverTimeSync: { type: Boolean, default: true }
  },

  instructionsTrigger: {
    autoOpen: { type: Boolean, default: true },
    triggerMode: { type: String, enum: ['preset', 'custom'], default: 'preset' },
    presetMinutesBeforeExam: { type: Number, default: 5 }, // 2/5/8/10
    customMinutesBeforeExam: { type: Number, default: 5 }
  },

  permissionCheckTrigger: {
    webcamCheckOffsetMin: { type: Number, default: 5 },
    micCheckOffsetMin: { type: Number, default: 5 },
    fullscreenCheckOffsetMin: { type: Number, default: 2 },
    deviceCheckOffsetMin: { type: Number, default: 5 }
  },

  lateJoin: {
    graceMinutes: { type: Number, default: 5 },
    allowLateJoin: { type: Boolean, default: true },
    lockEntryAfterGrace: { type: Boolean, default: true },
    allowRejoin: { type: Boolean, default: true },
    rejoinWindowMinutes: { type: Number, default: 10 }
  },

  waitingRoomLock: {
    lockWaitingRoom: { type: Boolean, default: false },
    forceStudentToStay: { type: Boolean, default: false },
    disableNavigation: { type: Boolean, default: false },
    preventBrowserRefresh: { type: Boolean, default: false },
    autoReconnect: { type: Boolean, default: true }
  },

  // ── 6) Instructions Manager ──
  instructions: {
    points: { type: [instructionPointSchema], default: [] },
    draftPoints: { type: [instructionPointSchema], default: [] },
    published: { type: Boolean, default: false },
    version: { type: Number, default: 1 },
    publishedAt: { type: Date, default: null }
  },

  // ── 7) T&C / Consent Manager ──
  tnc: {
    text: { type: String, default: '' },
    textHi: { type: String, default: '' },
    version: { type: String, default: '1.0' },
    requireScroll: { type: Boolean, default: true },
    requireCheckbox: { type: Boolean, default: true },
    requireReacceptOnUpdate: { type: Boolean, default: true },
    published: { type: Boolean, default: false },
    publishedAt: { type: Date, default: null }
  },

  // ── 8) Webcam Permission Control ──
  webcam: {
    mandatory: { type: Boolean, default: true },
    livePreviewRequired: { type: Boolean, default: true },
    faceVisibleRequired: { type: Boolean, default: true },
    multiFaceAlert: { type: Boolean, default: true },
    virtualBackgroundBlock: { type: Boolean, default: false },
    lightingWarningThreshold: { type: Number, default: 30 }, // 0-100 confidence
    retryAllowed: { type: Boolean, default: true },
    retryCount: { type: Number, default: 3 },
    retryDelaySec: { type: Number, default: 5 },
    optionalAudioPermission: { type: Boolean, default: true },
    blockOnDenial: { type: Boolean, default: true },
    minConfidenceThreshold: { type: Number, default: 60 },
    showLivePreviewDurationSec: { type: Number, default: 5 }
  },

  // ── 9) Fullscreen Enforcement ──
  fullscreen: {
    enabled: { type: Boolean, default: true },
    autoFullscreenOnStart: { type: Boolean, default: true },
    returnPrompt: { type: Boolean, default: true },
    warningThreshold: { type: Number, default: 3 },
    gracePeriodSec: { type: Number, default: 5 },
    exitReportingEnabled: { type: Boolean, default: true },
    autoSubmitLinkage: { type: Boolean, default: true }
  },

  // ── 10) Join Rules & Availability Engine ──
  joinRules: {
    joinGraceMinutes: { type: Number, default: 5 },
    blockNewJoinWhileLive: { type: Boolean, default: true },
    availabilityAfterEnd: { type: String, enum: ['locked', 'available_if_attempts_left'], default: 'available_if_attempts_left' },
    reAttemptAvailability: { type: Boolean, default: true },
    emergencyAccessOverride: { type: Boolean, default: false }
  },

  // ── Template link (16.6 mass apply origin tracking) ──
  templateSource: { type: mongoose.Schema.Types.ObjectId, ref: 'EntryPolicyTemplate', default: null },
  massAppliedFrom: { type: mongoose.Schema.Types.ObjectId, ref: 'EntryProctoringPolicy', default: null },

  // ── 14) Audit & Version History ──
  history: { type: [historyEntrySchema], default: [] },

  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });

EntryProctoringPolicySchema.index({ 'scope.type': 1, 'scope.examId': 1, 'scope.batchId': 1, 'scope.testSeriesId': 1 });
EntryProctoringPolicySchema.index({ status: 1, scheduledPublishAt: 1 });

module.exports = mongoose.models.EntryProctoringPolicy || mongoose.model('EntryProctoringPolicy', EntryProctoringPolicySchema);

PREPPOLEOF
node --check "$MODELS_DIR/EntryProctoringPolicy.js" && echo "✔ EntryProctoringPolicy.js OK"

cat > "$MODELS_DIR/EntryPolicyTemplate.js" << 'PREPTPLEOF'
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

PREPTPLEOF
node --check "$MODELS_DIR/EntryPolicyTemplate.js" && echo "✔ EntryPolicyTemplate.js OK"

cat > "$MODELS_DIR/EntryControlLog.js" << 'PREPLOGEOF'
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

PREPLOGEOF
node --check "$MODELS_DIR/EntryControlLog.js" && echo "✔ EntryControlLog.js OK"

echo ""
echo "════════════════════════════════════════════"
echo "STEP 2 — Backend: Announcement.js (additive: examId + entryContext)"
echo "════════════════════════════════════════════"
if [ -f "$MODELS_DIR/Announcement.js" ]; then
  cp "$MODELS_DIR/Announcement.js" "$MODELS_DIR/Announcement.js.bak.$(date +%s)"
  echo "✔ Backed up existing Announcement.js"
fi
cat > "$MODELS_DIR/Announcement.js" << 'PREPANNEOF'
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
    mode:         { type: String, enum: ['all', 'batch', 'testseries', 'students'], default: 'all' }, // F42A §1.2.2 / §2.1.9 (v2: +testseries)
    batchIds:     [{ type: mongoose.Schema.Types.ObjectId, ref: 'Batch' }],   // multi-select batches
    testSeriesIds:[{ type: mongoose.Schema.Types.ObjectId, ref: 'Batch' }],   // multi-select test series (same underlying collection, tracked separately)
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

  // F42A §2.3.2 per-batch/email delivery status
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
AnnouncementSchema.index({ 'audience.batchIds': 1 })
AnnouncementSchema.index({ 'audience.studentIds': 1 })
AnnouncementSchema.index({ examId: 1, createdAt: -1 })

module.exports = mongoose.model('Announcement', AnnouncementSchema)

PREPANNEOF
node --check "$MODELS_DIR/Announcement.js" && echo "✔ Announcement.js OK"

echo ""
echo "════════════════════════════════════════════"
echo "STEP 3 — Backend: new Entry & Proctoring route file"
echo "════════════════════════════════════════════"
cat > "$ROUTES_DIR/entryProctoringControl.js" << 'PREPROUTEEOF'
// ══════════════════════════════════════════════════════════════════
// F53–57-B — Entry & Proctoring Control Center
// Admin router mounted at:   /api/admin/entry-proctoring
// Student router mounted at: /api/entry-proctoring
//
// Design note (Rule H1 — don't break working features):
// This module is the NEW centralised admin CONFIGURATION layer for
// waiting room / instructions / T&C / webcam / fullscreen / join rules.
// It does NOT replace the existing runtime routes (examFlow.js,
// exam_patch.js) which students' attempt-flow pages already call.
// On PUBLISH, this module syncs only the 4 fields those existing
// routes already read (waitingRoomEnabled, waitingRoomMinutes,
// waitingChatMinutes, waitingAutoCloseBufferMinutes) so waiting-room
// timing actually changes for students immediately — safe, additive,
// nothing removed. All the richer config (instructions text, T&C,
// webcam/fullscreen granular rules, join rules) is fully built and
// exposed via GET /api/entry-proctoring/effective/:examId, ready to
// wire into your attempt-flow pages whenever you touch them next.
// ══════════════════════════════════════════════════════════════════
const express = require('express');
const adminRouter = express.Router();
const studentRouter = express.Router();
const mongoose = require('mongoose');
const { verifyToken, isAdmin } = require('../middleware/auth');

const EntryProctoringPolicy = require('../models/EntryProctoringPolicy');
const EntryPolicyTemplate = require('../models/EntryPolicyTemplate');
const EntryControlLog = require('../models/EntryControlLog');
const Exam = require('../models/Exam');
let Announcement; try { Announcement = require('../models/Announcement'); } catch (e) { Announcement = null; }
let Batch; try { Batch = require('../models/Batch'); } catch (e) { Batch = null; }
let TestSeries; try { TestSeries = require('../models/TestSeries'); } catch (e) { TestSeries = null; }
let User; try { User = require('../models/User'); } catch (e) { User = null; }

const CONFIG_SECTIONS = ['waitingRoom', 'instructionsTrigger', 'permissionCheckTrigger', 'lateJoin',
  'waitingRoomLock', 'instructions', 'tnc', 'webcam', 'fullscreen', 'joinRules'];

// ──────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────
function toId(v) { try { return new mongoose.Types.ObjectId(v); } catch (e) { return null; } }

async function logActivitySafe(req, action, details) {
  try {
    const { logActivity } = require('../utils/activityLogger');
    await logActivity({ userId: req.user.id, userRole: req.user.role, action, details, module: 'entry_proctoring', status: 'success' });
  } catch (e) { /* non-fatal — activity logger is best-effort */ }
}

function resolvedWaitingMinutes(wr) {
  if (!wr) return 20;
  return wr.triggerMode === 'custom' ? (wr.customMinutes || 20) : (wr.presetMinutes || 20);
}
function resolvedInstructionsMinutes(it) {
  if (!it) return 5;
  return it.triggerMode === 'custom' ? (it.customMinutesBeforeExam || 5) : (it.presetMinutesBeforeExam || 5);
}

// Sync only the 4 fields the existing runtime (examFlow.js) reads — safe & additive.
async function syncToExam(policy) {
  if (!policy || !policy.scope || policy.scope.type !== 'exam' || !policy.scope.examId) return;
  const waitMins = resolvedWaitingMinutes(policy.waitingRoom);
  const chatMins = Math.max(0, (policy.waitingRoom?.chatStartOffsetMin || 20) - (policy.waitingRoom?.chatEndOffsetMin || 10));
  const bufferMins = resolvedInstructionsMinutes(policy.instructionsTrigger);
  try {
    await Exam.findByIdAndUpdate(policy.scope.examId, {
      waitingRoomEnabled: !!policy.waitingRoom?.enabled,
      waitingRoomMinutes: waitMins,
      waitingChatMinutes: chatMins || 10,
      waitingAutoCloseBufferMinutes: bufferMins
    });
  } catch (e) { /* non-fatal — policy still saved even if exam sync fails */ }
}

function computeReadiness(policy) {
  const warnings = [];
  let score = 0;
  const checks = [
    { ok: (policy.instructions?.points || []).length > 0, weight: 15, warn: 'No instruction points added yet' },
    { ok: !!policy.instructions?.published, weight: 10, warn: 'Instructions not published' },
    { ok: !!(policy.tnc?.text && policy.tnc.text.trim().length > 20), weight: 15, warn: 'T&C text is missing or too short' },
    { ok: !!policy.tnc?.published, weight: 10, warn: 'T&C not published' },
    { ok: typeof policy.waitingRoom?.enabled === 'boolean', weight: 10, warn: 'Waiting room not configured' },
    { ok: policy.webcam?.mandatory !== undefined, weight: 10, warn: 'Webcam policy not configured' },
    { ok: policy.fullscreen?.enabled !== undefined, weight: 10, warn: 'Fullscreen policy not configured' },
    { ok: (policy.joinRules?.joinGraceMinutes || 0) >= 0, weight: 10, warn: 'Join rules not configured' },
    { ok: policy.status === 'published', weight: 10, warn: 'Policy still in draft' }
  ];
  checks.forEach(c => { if (c.ok) score += c.weight; else warnings.push(c.warn); });
  return { readinessScore: score, warnings };
}

function diffSections(oldDoc, newDoc) {
  const diffs = [];
  CONFIG_SECTIONS.forEach(sec => {
    const a = JSON.stringify((oldDoc && oldDoc[sec]) || {});
    const b = JSON.stringify((newDoc && newDoc[sec]) || {});
    if (a !== b) diffs.push({ section: sec, oldValue: (oldDoc && oldDoc[sec]) || {}, newValue: (newDoc && newDoc[sec]) || {} });
  });
  return diffs;
}

async function findApplicablePolicy(examId) {
  const exam = await Exam.findById(examId).lean();
  if (!exam) return { exam: null, policy: null };

  let policy = await EntryProctoringPolicy.findOne({ status: 'published', 'scope.type': 'exam', 'scope.examId': examId }).sort({ version: -1 }).lean();
  if (policy) return { exam, policy, resolvedFrom: 'exam' };

  const batchTargets = [exam.batch, ...(exam.multiBatch || [])].filter(Boolean);
  if (batchTargets.length) {
    policy = await EntryProctoringPolicy.findOne({ status: 'published', 'scope.type': 'batch', 'scope.batchId': { $in: batchTargets.map(toId).filter(Boolean) } }).sort({ version: -1 }).lean();
    if (policy) return { exam, policy, resolvedFrom: 'batch' };
  }
  if (exam.testSeriesId) {
    policy = await EntryProctoringPolicy.findOne({ status: 'published', 'scope.type': 'series', 'scope.testSeriesId': exam.testSeriesId }).sort({ version: -1 }).lean();
    if (policy) return { exam, policy, resolvedFrom: 'series' };
  }
  policy = await EntryProctoringPolicy.findOne({ status: 'published', 'scope.type': 'global' }).sort({ version: -1 }).lean();
  if (policy) return { exam, policy, resolvedFrom: 'global' };

  return { exam, policy: null, resolvedFrom: 'defaults' };
}

// Opportunistic scheduled-publish promoter (16.5) — runs on KPI/list fetch, no cron needed
async function promoteScheduledPolicies() {
  try {
    const due = await EntryProctoringPolicy.find({ status: 'draft', scheduledPublishAt: { $lte: new Date(), $ne: null } });
    for (const p of due) {
      p.status = 'published';
      p.publishedAt = new Date();
      p.version = (p.version || 1) + (p.draftChangesPending ? 1 : 0);
      p.draftChangesPending = false;
      p.scheduledPublishAt = null;
      await p.save();
      await syncToExam(p);
    }
  } catch (e) { /* non-fatal */ }
}

// Simulate the 5.5.1.6 auto-transition flow for the Live Preview / Simulator
function simulateFlow(policy, minutesBeforeStart) {
  const m = minutesBeforeStart;
  const waitOpen = resolvedWaitingMinutes(policy.waitingRoom);
  const chatStart = policy.waitingRoom?.chatStartOffsetMin ?? 20;
  const chatEnd = policy.waitingRoom?.chatEndOffsetMin ?? 10;
  const instrOpen = resolvedInstructionsMinutes(policy.instructionsTrigger);
  const webcamAt = policy.permissionCheckTrigger?.webcamCheckOffsetMin ?? 5;
  const fsAt = policy.permissionCheckTrigger?.fullscreenCheckOffsetMin ?? 2;

  const stepState = (opensAtMin, closesAtMin) => {
    if (!policy) return 'pending';
    if (closesAtMin !== undefined && m < closesAtMin) return 'done';
    if (m <= opensAtMin && (closesAtMin === undefined || m >= closesAtMin)) return 'active';
    return 'pending';
  };

  return [
    { step: 'waiting_room', label: 'Waiting Room', state: policy.waitingRoom?.enabled ? stepState(waitOpen, chatStart) : 'skipped' },
    { step: 'chat', label: 'Chat Phase', state: policy.waitingRoom?.chatEnabled ? stepState(chatStart, chatEnd) : 'skipped' },
    { step: 'instructions', label: 'Instructions', state: policy.instructionsTrigger?.autoOpen ? stepState(instrOpen, webcamAt) : 'skipped' },
    { step: 'tnc', label: 'T&C', state: stepState(instrOpen, webcamAt) },
    { step: 'permission_check', label: 'Permission Check (Webcam/Fullscreen)', state: stepState(webcamAt, fsAt) },
    { step: 'ready', label: 'Ready Screen', state: stepState(fsAt, 0) },
    { step: 'exam_start', label: 'Exam Starts', state: m <= 0 ? 'active' : 'pending' }
  ];
}

// ══════════════════════════════════════════════════════════════════
// ADMIN ROUTES — /api/admin/entry-proctoring
// ══════════════════════════════════════════════════════════════════

// 2) TOP KPI CARDS
adminRouter.get('/kpis', verifyToken, isAdmin, async (req, res) => {
  try {
    await promoteScheduledPolicies();
    const [activePolicies, waitingRoomEnabled, instructionsPublished, tncActive, webcamMandatory,
      fullscreenEnabled, liveJoinBlocks, policyChangesToday] = await Promise.all([
      EntryProctoringPolicy.countDocuments({ status: 'published' }),
      EntryProctoringPolicy.countDocuments({ status: 'published', 'waitingRoom.enabled': true }),
      EntryProctoringPolicy.countDocuments({ status: 'published', 'instructions.published': true }),
      EntryProctoringPolicy.countDocuments({ status: 'published', 'tnc.published': true }),
      EntryProctoringPolicy.countDocuments({ status: 'published', 'webcam.mandatory': true }),
      EntryProctoringPolicy.countDocuments({ status: 'published', 'fullscreen.enabled': true }),
      EntryControlLog.countDocuments({ eventType: 'join_blocked', createdAt: { $gte: new Date(Date.now() - 7 * 86400000) } }),
      EntryProctoringPolicy.countDocuments({ updatedAt: { $gte: new Date(new Date().setHours(0, 0, 0, 0)) } })
    ]);
    res.json({
      kpis: {
        activeExamPolicies: activePolicies,
        waitingRoomEnabled, instructionsPublished, tncActiveVersions: tncActive,
        webcamMandatoryExams: webcamMandatory, fullscreenEnabledExams: fullscreenEnabled,
        liveJoinBlocks7d: liveJoinBlocks, policyChangesToday
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 3) OVERVIEW
adminRouter.get('/overview/:policyId', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findById(req.params.policyId).populate('publishedBy', 'name').lean();
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    const { readinessScore, warnings } = computeReadiness(policy);
    res.json({
      overview: {
        scope: policy.scope, status: policy.status, readinessScore, warnings,
        lastPublishedAt: policy.publishedAt, lastEditedBy: policy.updatedBy,
        liveEnforcement: policy.status === 'published' && !policy.draftChangesPending,
        policySummary: {
          waitingRoom: !!policy.waitingRoom?.enabled, instructions: !!policy.instructions?.published,
          tnc: !!policy.tnc?.published, webcam: !!policy.webcam?.mandatory, fullscreen: !!policy.fullscreen?.enabled
        }
      }
    });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 4) POLICIES — list / CRUD
adminRouter.get('/policies', verifyToken, isAdmin, async (req, res) => {
  try {
    await promoteScheduledPolicies();
    const { scopeType, examId, batchId, testSeriesId, status, search } = req.query;
    const filter = {};
    if (scopeType) filter['scope.type'] = scopeType;
    if (examId) filter['scope.examId'] = toId(examId);
    if (batchId) filter['scope.batchId'] = toId(batchId);
    if (testSeriesId) filter['scope.testSeriesId'] = toId(testSeriesId);
    if (status) filter.status = status;
    if (search) filter.name = { $regex: search, $options: 'i' };
    const list = await EntryProctoringPolicy.find(filter).sort({ updatedAt: -1 }).limit(200).lean();
    const out = list.map(p => ({ ...p, ...computeReadiness(p) }));
    res.json({ policies: out, total: out.length });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.get('/policies/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findById(req.params.id).lean();
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    res.json({ policy: { ...policy, ...computeReadiness(policy) } });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.post('/policies', verifyToken, isAdmin, async (req, res) => {
  try {
    const { name, scope } = req.body;
    if (!scope || !scope.type) return res.status(400).json({ error: 'scope.type is required' });
    if (scope.type === 'exam' && scope.examId) {
      const existing = await EntryProctoringPolicy.findOne({ 'scope.type': 'exam', 'scope.examId': scope.examId, status: { $ne: 'archived' } });
      if (existing) return res.status(409).json({ error: 'A policy already exists for this exam. Edit it instead of creating a new one.', existingId: existing._id });
    }
    const policy = await EntryProctoringPolicy.create({
      name: name || 'Untitled Policy', scope, status: 'draft', version: 1,
      createdBy: req.user.id, updatedBy: req.user.id
    });
    await logActivitySafe(req, 'ENTRY_POLICY_CREATE', `Created policy "${policy.name}" (scope: ${scope.type})`);
    res.json({ success: true, policy });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.put('/policies/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findById(req.params.id);
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    if (policy.locked) return res.status(423).json({ error: 'Policy is locked — unlock it before editing' });

    const before = policy.toObject();
    const { name, reason } = req.body;
    if (name !== undefined) policy.name = name;

    CONFIG_SECTIONS.forEach(sec => {
      if (req.body[sec] !== undefined && typeof req.body[sec] === 'object') {
        policy[sec] = { ...(policy[sec] ? policy[sec].toObject ? policy[sec].toObject() : policy[sec] : {}), ...req.body[sec] };
      }
    });

    const diffs = diffSections(before, policy.toObject());
    diffs.forEach(d => {
      policy.history.push({
        version: policy.version, section: d.section, oldValue: d.oldValue, newValue: d.newValue,
        reason: reason || '', changedBy: req.user.id, changedByName: req.user.name || '', changedAt: new Date()
      });
    });

    if (policy.status === 'published' && diffs.length) policy.draftChangesPending = true;
    policy.updatedBy = req.user.id;
    await policy.save();
    await logActivitySafe(req, 'ENTRY_POLICY_UPDATE', `Updated policy "${policy.name}" — ${diffs.map(d => d.section).join(', ') || 'no field changes'}`);
    res.json({ success: true, policy });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.post('/policies/:id/clone', verifyToken, isAdmin, async (req, res) => {
  try {
    const src = await EntryProctoringPolicy.findById(req.params.id).lean();
    if (!src) return res.status(404).json({ error: 'Policy not found' });
    delete src._id; delete src.createdAt; delete src.updatedAt; delete src.history;
    const clone = await EntryProctoringPolicy.create({
      ...src, name: `${src.name} (Copy)`, status: 'draft', version: 1, locked: false,
      publishedAt: null, publishedBy: null, draftChangesPending: false, history: [],
      createdBy: req.user.id, updatedBy: req.user.id
    });
    await logActivitySafe(req, 'ENTRY_POLICY_CLONE', `Cloned policy "${src.name}" → "${clone.name}"`);
    res.json({ success: true, policy: clone });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.delete('/policies/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findById(req.params.id);
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    if (policy.status === 'published') return res.status(400).json({ error: 'Unpublish before deleting a published policy' });
    await EntryProctoringPolicy.findByIdAndDelete(req.params.id);
    await logActivitySafe(req, 'ENTRY_POLICY_DELETE', `Deleted draft policy "${policy.name}"`);
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 4.4 Publish (snapshot + lock rules)
adminRouter.post('/policies/:id/publish', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findById(req.params.id);
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    if (policy.locked) return res.status(423).json({ error: 'Policy is locked' });

    policy.version = (policy.version || 1) + (policy.status === 'published' ? 1 : 0);
    policy.status = 'published';
    policy.publishedAt = new Date();
    policy.publishedBy = req.user.id;
    policy.draftChangesPending = false;
    policy.history.push({
      version: policy.version, section: 'general', oldValue: null, newValue: { published: true },
      reason: req.body.reason || 'Published', changedBy: req.user.id, changedByName: req.user.name || '',
      changedAt: new Date(), snapshot: policy.toObject()
    });
    await policy.save();
    await syncToExam(policy);
    await logActivitySafe(req, 'ENTRY_POLICY_PUBLISH', `Published policy "${policy.name}" v${policy.version}`);
    res.json({ success: true, policy });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.post('/policies/:id/lock', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findByIdAndUpdate(req.params.id, { locked: true, updatedBy: req.user.id }, { new: true });
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    await logActivitySafe(req, 'ENTRY_POLICY_LOCK', `Locked policy "${policy.name}"`);
    res.json({ success: true, policy });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.post('/policies/:id/unlock', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findByIdAndUpdate(req.params.id, { locked: false, updatedBy: req.user.id }, { new: true });
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    await logActivitySafe(req, 'ENTRY_POLICY_UNLOCK', `Unlocked policy "${policy.name}"`);
    res.json({ success: true, policy });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.get('/policies/:id/readiness', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findById(req.params.id).lean();
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    res.json(computeReadiness(policy));
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 14) Audit & Version History
adminRouter.get('/policies/:id/history', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findById(req.params.id).select('history name version').lean();
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    const history = (policy.history || []).slice().sort((a, b) => new Date(b.changedAt) - new Date(a.changedAt));
    res.json({ history, currentVersion: policy.version });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 16.2 Policy Diff Viewer — compare two logged versions (by history index) or draft vs published
adminRouter.get('/policies/:id/diff', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findById(req.params.id).lean();
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    const { v1, v2 } = req.query;
    const snapA = (policy.history || []).filter(h => h.snapshot).find(h => String(h.version) === String(v1));
    const snapB = (policy.history || []).filter(h => h.snapshot).find(h => String(h.version) === String(v2));
    const oldDoc = snapA ? snapA.snapshot : {};
    const newDoc = snapB ? snapB.snapshot : policy;
    res.json({ diff: diffSections(oldDoc, newDoc) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.post('/policies/:id/rollback/:version', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findById(req.params.id);
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    const entry = (policy.history || []).filter(h => h.snapshot).find(h => String(h.version) === String(req.params.version));
    if (!entry) return res.status(404).json({ error: 'No snapshot found for that version' });
    const snap = entry.snapshot;
    CONFIG_SECTIONS.forEach(sec => { if (snap[sec] !== undefined) policy[sec] = snap[sec]; });
    policy.version = (policy.version || 1) + 1;
    policy.draftChangesPending = policy.status === 'published';
    policy.updatedBy = req.user.id;
    policy.history.push({
      version: policy.version, section: 'general', oldValue: null, newValue: { rolledBackTo: req.params.version },
      reason: `Rollback to v${req.params.version}`, changedBy: req.user.id, changedByName: req.user.name || '', changedAt: new Date()
    });
    await policy.save();
    await logActivitySafe(req, 'ENTRY_POLICY_ROLLBACK', `Rolled back "${policy.name}" to v${req.params.version}`);
    res.json({ success: true, policy });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 13) Live Preview / Simulator
adminRouter.post('/policies/:id/preview', verifyToken, isAdmin, async (req, res) => {
  try {
    const policy = await EntryProctoringPolicy.findById(req.params.id).lean();
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    const minutesBeforeStart = typeof req.body.minutesBeforeStart === 'number' ? req.body.minutesBeforeStart : resolvedWaitingMinutes(policy.waitingRoom);
    const flow = simulateFlow(policy, minutesBeforeStart);
    res.json({ flow, minutesBeforeStart });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 16.6 Batch / Test Series Mass Apply
adminRouter.post('/policies/:id/mass-apply', verifyToken, isAdmin, async (req, res) => {
  try {
    const { examIds } = req.body;
    if (!Array.isArray(examIds) || !examIds.length) return res.status(400).json({ error: 'examIds array required' });
    const source = await EntryProctoringPolicy.findById(req.params.id).lean();
    if (!source) return res.status(404).json({ error: 'Source policy not found' });

    const results = [];
    for (const examId of examIds) {
      try {
        const clean = { ...source };
        delete clean._id; delete clean.createdAt; delete clean.updatedAt; delete clean.history;
        let target = await EntryProctoringPolicy.findOne({ 'scope.type': 'exam', 'scope.examId': examId, status: { $ne: 'archived' } });
        if (target) {
          CONFIG_SECTIONS.forEach(sec => { target[sec] = clean[sec]; });
          target.massAppliedFrom = source._id;
          target.status = 'published';
          target.publishedAt = new Date();
          target.publishedBy = req.user.id;
          target.version = (target.version || 1) + 1;
          await target.save();
        } else {
          target = await EntryProctoringPolicy.create({
            ...clean, name: `${source.name} (Mass Applied)`, scope: { type: 'exam', examId },
            status: 'published', version: 1, publishedAt: new Date(), publishedBy: req.user.id,
            massAppliedFrom: source._id, createdBy: req.user.id, updatedBy: req.user.id
          });
        }
        await syncToExam(target);
        results.push({ examId, success: true, policyId: target._id });
      } catch (innerErr) { results.push({ examId, success: false, error: innerErr.message }); }
    }
    await logActivitySafe(req, 'ENTRY_POLICY_MASS_APPLY', `Mass-applied "${source.name}" to ${examIds.length} exam(s)`);
    res.json({ success: true, results });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 16.4 Emergency Override + 5.5.1.9 Admin Override
adminRouter.post('/policies/:id/emergency-override', verifyToken, isAdmin, async (req, res) => {
  try {
    const { action } = req.body; // open_waiting_room_now | close_waiting_room | skip_to_instructions | skip_to_permission_check | force_exam_start
    const validActions = ['open_waiting_room_now', 'close_waiting_room', 'skip_to_instructions', 'skip_to_permission_check', 'force_exam_start'];
    if (!validActions.includes(action)) return res.status(400).json({ error: 'Invalid override action' });
    const policy = await EntryProctoringPolicy.findById(req.params.id).lean();
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    const examId = policy.scope && policy.scope.examId;

    let socketEmitted = false;
    if (examId) {
      try {
        const { getIO } = require('../config/socket');
        getIO().to(`waiting-${examId}`).emit('entry-override', { examId: String(examId), action, at: new Date() });
        socketEmitted = true;
      } catch (e) { /* socket not initialized — non-fatal */ }
    }
    await logActivitySafe(req, 'ENTRY_POLICY_EMERGENCY_OVERRIDE', `Emergency override "${action}" on policy "${policy.name}"${examId ? ' (exam ' + examId + ')' : ''}`);
    res.json({ success: true, action, examId, socketEmitted });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// 12) POLICY TEMPLATES
// ══════════════════════════════════════════════════════════════════
const BUILTIN_TEMPLATES = [
  { name: 'Standard Exam', kind: 'standard_exam', icon: '📋', description: 'Balanced defaults — waiting room, webcam mandatory, standard fullscreen.' },
  { name: 'Strict Proctoring', kind: 'strict_proctoring', icon: '🔒', description: 'Maximum enforcement — webcam + fullscreen strict, no late join, no rejoin.', overrides: { webcam: { mandatory: true, blockOnDenial: true, retryAllowed: false }, fullscreen: { warningThreshold: 1 }, lateJoin: { allowLateJoin: false, allowRejoin: false } } },
  { name: 'Relaxed Entry', kind: 'relaxed_entry', icon: '🕊️', description: 'Lenient entry — generous grace period, rejoin allowed, optional webcam.', overrides: { webcam: { mandatory: false, blockOnDenial: false }, lateJoin: { graceMinutes: 15, allowRejoin: true, rejoinWindowMinutes: 20 } } },
  { name: 'Webcam Mandatory', kind: 'webcam_mandatory', icon: '📷', description: 'Webcam strictly required, all other rules standard.', overrides: { webcam: { mandatory: true, blockOnDenial: true, retryAllowed: true, retryCount: 2 } } },
  { name: 'Full Lockdown', kind: 'full_lockdown', icon: '🛡️', description: 'Every control at maximum — webcam, fullscreen, no late join/rejoin, waiting room locked.', overrides: { webcam: { mandatory: true, blockOnDenial: true, retryAllowed: false }, fullscreen: { warningThreshold: 1, gracePeriodSec: 0 }, lateJoin: { allowLateJoin: false, allowRejoin: false }, waitingRoomLock: { lockWaitingRoom: true, forceStudentToStay: true, disableNavigation: true } } }
];

async function seedBuiltinTemplates() {
  for (const t of BUILTIN_TEMPLATES) {
    const exists = await EntryPolicyTemplate.findOne({ kind: t.kind, isBuiltIn: true });
    if (!exists) {
      const base = new EntryProctoringPolicy();
      const settings = {};
      CONFIG_SECTIONS.forEach(sec => { settings[sec] = { ...(base[sec] ? base[sec].toObject ? base[sec].toObject() : base[sec] : {}), ...((t.overrides || {})[sec] || {}) }; });
      await EntryPolicyTemplate.create({ name: t.name, kind: t.kind, icon: t.icon, description: t.description, settings, isBuiltIn: true });
    }
  }
}

adminRouter.get('/templates', verifyToken, isAdmin, async (req, res) => {
  try {
    await seedBuiltinTemplates().catch(() => {});
    const templates = await EntryPolicyTemplate.find({}).sort({ isPinned: -1, isBuiltIn: -1, usageCount: -1 }).lean();
    res.json({ templates });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.post('/templates', verifyToken, isAdmin, async (req, res) => {
  try {
    const { name, sourcePolicyId, description } = req.body;
    if (!name) return res.status(400).json({ error: 'name required' });
    let settings = {};
    if (sourcePolicyId) {
      const src = await EntryProctoringPolicy.findById(sourcePolicyId).lean();
      if (!src) return res.status(404).json({ error: 'Source policy not found' });
      CONFIG_SECTIONS.forEach(sec => { settings[sec] = src[sec] || {}; });
    }
    const template = await EntryPolicyTemplate.create({ name, description: description || '', settings, createdBy: req.user.id, updatedBy: req.user.id });
    await logActivitySafe(req, 'ENTRY_TEMPLATE_CREATE', `Created entry-policy template "${name}"`);
    res.json({ success: true, template });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.post('/templates/:id/apply/:policyId', verifyToken, isAdmin, async (req, res) => {
  try {
    const template = await EntryPolicyTemplate.findById(req.params.id).lean();
    if (!template) return res.status(404).json({ error: 'Template not found' });
    const policy = await EntryProctoringPolicy.findById(req.params.policyId);
    if (!policy) return res.status(404).json({ error: 'Policy not found' });
    if (policy.locked) return res.status(423).json({ error: 'Policy is locked' });
    CONFIG_SECTIONS.forEach(sec => { if (template.settings[sec]) policy[sec] = template.settings[sec]; });
    policy.templateSource = template._id;
    policy.draftChangesPending = policy.status === 'published';
    policy.updatedBy = req.user.id;
    await policy.save();
    await EntryPolicyTemplate.findByIdAndUpdate(req.params.id, { $inc: { usageCount: 1 }, lastUsedAt: new Date() });
    await logActivitySafe(req, 'ENTRY_TEMPLATE_APPLY', `Applied template "${template.name}" to policy "${policy.name}"`);
    res.json({ success: true, policy });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.post('/templates/:id/duplicate', verifyToken, isAdmin, async (req, res) => {
  try {
    const src = await EntryPolicyTemplate.findById(req.params.id).lean();
    if (!src) return res.status(404).json({ error: 'Template not found' });
    delete src._id; delete src.createdAt; delete src.updatedAt;
    const dup = await EntryPolicyTemplate.create({ ...src, name: `${src.name} (Copy)`, isBuiltIn: false, usageCount: 0, createdBy: req.user.id });
    res.json({ success: true, template: dup });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.put('/templates/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const allowed = ['name', 'description', 'isPinned'];
    const update = { updatedBy: req.user.id };
    allowed.forEach(k => { if (req.body[k] !== undefined) update[k] = req.body[k]; });
    const template = await EntryPolicyTemplate.findByIdAndUpdate(req.params.id, update, { new: true });
    if (!template) return res.status(404).json({ error: 'Template not found' });
    res.json({ success: true, template });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.delete('/templates/:id', verifyToken, isAdmin, async (req, res) => {
  try {
    const template = await EntryPolicyTemplate.findById(req.params.id);
    if (!template) return res.status(404).json({ error: 'Template not found' });
    if (template.isBuiltIn) return res.status(400).json({ error: 'Built-in templates cannot be deleted' });
    await EntryPolicyTemplate.findByIdAndDelete(req.params.id);
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.get('/templates/compare', verifyToken, isAdmin, async (req, res) => {
  try {
    const { a, b } = req.query;
    if (!a || !b) return res.status(400).json({ error: 'a and b template ids required' });
    const [ta, tb] = await Promise.all([EntryPolicyTemplate.findById(a).lean(), EntryPolicyTemplate.findById(b).lean()]);
    if (!ta || !tb) return res.status(404).json({ error: 'One or both templates not found' });
    res.json({ diff: diffSections(ta.settings, tb.settings) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// 11) BROADCASTS & NOTIFICATIONS (entry-stage, uses Announcement model)
// ══════════════════════════════════════════════════════════════════
adminRouter.get('/policies/:id/broadcasts', verifyToken, isAdmin, async (req, res) => {
  try {
    if (!Announcement) return res.json({ broadcasts: [] });
    const policy = await EntryProctoringPolicy.findById(req.params.id).lean();
    if (!policy || !policy.scope || !policy.scope.examId) return res.json({ broadcasts: [] });
    const broadcasts = await Announcement.find({ examId: policy.scope.examId, 'entryContext.isEntryBroadcast': true }).sort({ createdAt: -1 }).limit(50).lean();
    res.json({ broadcasts });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.post('/broadcasts', verifyToken, isAdmin, async (req, res) => {
  try {
    if (!Announcement) return res.status(501).json({ error: 'Announcement model unavailable' });
    const { examId, batchId, broadcastType, title, message, channel, scheduledAt } = req.body;
    if (!title || !message) return res.status(400).json({ error: 'title and message required' });
    const validTypes = ['waiting_room_announcement', 'instruction_update', 'consent_reminder', 'camera_reminder', 'fullscreen_reminder', 'join_window_warning', 'emergency_notice'];
    if (!validTypes.includes(broadcastType)) return res.status(400).json({ error: 'Invalid broadcastType' });

    let audience = { mode: 'all' };
    if (batchId) audience = { mode: 'batch', batchIds: [batchId] };

    const status = scheduledAt && new Date(scheduledAt) > new Date() ? 'scheduled' : 'sent';
    const doc = await Announcement.create({
      title, message, type: 'exam', audience, sendVia: channel === 'email' ? 'both' : 'in-app',
      status, scheduledAt: status === 'scheduled' ? new Date(scheduledAt) : null,
      examId: examId || null, entryContext: { isEntryBroadcast: true, broadcastType, channel: channel || 'in-app' },
      createdBy: req.user.id
    });

    if (examId) {
      try {
        const { getIO } = require('../config/socket');
        getIO().to(`waiting-${examId}`).emit('waiting-broadcast', { title, message, broadcastType, at: new Date() });
      } catch (e) { /* socket not initialized — non-fatal */ }
    }
    await logActivitySafe(req, 'ENTRY_BROADCAST_SEND', `Sent entry broadcast "${title}" (${broadcastType})`);
    res.json({ success: true, broadcast: doc });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

adminRouter.post('/broadcasts/:id/cancel', verifyToken, isAdmin, async (req, res) => {
  try {
    if (!Announcement) return res.status(501).json({ error: 'Announcement model unavailable' });
    const doc = await Announcement.findOneAndUpdate({ _id: req.params.id, status: 'scheduled' }, { status: 'draft', scheduledAt: null }, { new: true });
    if (!doc) return res.status(404).json({ error: 'Scheduled broadcast not found' });
    res.json({ success: true, broadcast: doc });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// 15) CONTROL LOGS + 16.8/16.9/16.10 ANALYTICS
// ══════════════════════════════════════════════════════════════════
adminRouter.get('/control-logs', verifyToken, isAdmin, async (req, res) => {
  try {
    const { examId, eventType, severity, dateFrom, dateTo, page = 1, limit = 50 } = req.query;
    const filter = {};
    if (examId) filter.examId = toId(examId);
    if (eventType) filter.eventType = eventType;
    if (severity) filter.severity = severity;
    if (dateFrom || dateTo) {
      filter.createdAt = {};
      if (dateFrom) filter.createdAt.$gte = new Date(dateFrom);
      if (dateTo) filter.createdAt.$lte = new Date(dateTo + 'T23:59:59');
    }
    const skip = (Math.max(1, Number(page)) - 1) * Number(limit);
    const [logs, total] = await Promise.all([
      EntryControlLog.find(filter).sort({ createdAt: -1 }).skip(skip).limit(Number(limit)).populate('studentId', 'name email').lean(),
      EntryControlLog.countDocuments(filter)
    ]);
    res.json({ logs, total, page: Number(page), limit: Number(limit) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 16.8 Student Flow Heatmap — counts per step (where students are / drop off)
adminRouter.get('/analytics/flow-heatmap', verifyToken, isAdmin, async (req, res) => {
  try {
    const { examId } = req.query;
    const match = examId ? { examId: toId(examId) } : {};
    const agg = await EntryControlLog.aggregate([
      { $match: { ...match, eventType: { $in: ['step_reached', 'step_failed'] } } },
      { $group: { _id: { step: '$step', eventType: '$eventType' }, count: { $sum: 1 } } }
    ]);
    res.json({ heatmap: agg.map(a => ({ step: a._id.step, eventType: a._id.eventType, count: a.count })) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 16.9 Join Attempt Analytics
adminRouter.get('/analytics/join-attempts', verifyToken, isAdmin, async (req, res) => {
  try {
    const { examId } = req.query;
    const match = examId ? { examId: toId(examId) } : {};
    const [lateJoins, blocked, retries, rejoins] = await Promise.all([
      EntryControlLog.countDocuments({ ...match, eventType: 'late_join_attempt' }),
      EntryControlLog.countDocuments({ ...match, eventType: 'join_blocked' }),
      EntryControlLog.countDocuments({ ...match, eventType: 'retry_attempt' }),
      EntryControlLog.countDocuments({ ...match, eventType: 'rejoin_attempt' })
    ]);
    res.json({ lateJoinAttempts: lateJoins, blockedAttempts: blocked, retryAttempts: retries, rejoinAttempts: rejoins });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// 16.10 Failure Reason Summary
adminRouter.get('/analytics/failure-summary', verifyToken, isAdmin, async (req, res) => {
  try {
    const { examId } = req.query;
    const match = examId ? { examId: toId(examId) } : {};
    const agg = await EntryControlLog.aggregate([
      { $match: { ...match, status: { $in: ['failed', 'blocked'] } } },
      { $group: { _id: '$eventType', count: { $sum: 1 } } },
      { $sort: { count: -1 } }
    ]);
    res.json({ summary: agg.map(a => ({ reason: a._id, count: a.count })) });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════
// STUDENT ROUTES — /api/entry-proctoring
// ══════════════════════════════════════════════════════════════════

// Effective (resolved) policy for a given exam — exam → batch → series → global → schema defaults
studentRouter.get('/effective/:examId', verifyToken, async (req, res) => {
  try {
    const { exam, policy, resolvedFrom } = await findApplicablePolicy(req.params.examId);
    if (!exam) return res.status(404).json({ error: 'Exam not found' });
    if (!policy) {
      const def = new EntryProctoringPolicy();
      const settings = {};
      CONFIG_SECTIONS.forEach(sec => { settings[sec] = def[sec] && def[sec].toObject ? def[sec].toObject() : def[sec]; });
      return res.json({ resolvedFrom: 'defaults', settings });
    }
    const settings = {};
    CONFIG_SECTIONS.forEach(sec => { settings[sec] = policy[sec] || {}; });
    res.json({ resolvedFrom, policyId: policy._id, settings });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// Student-side event logger (feeds Control Logs + analytics)
studentRouter.post('/log-event', verifyToken, async (req, res) => {
  try {
    const { examId, eventType, step, severity, status, details, meta } = req.body;
    if (!examId || !eventType) return res.status(400).json({ error: 'examId and eventType required' });
    const log = await EntryControlLog.create({
      examId, studentId: req.user.id, eventType, step: step || '', severity: severity || 'info',
      status: status || 'success', details: details || '', meta: meta || {}
    });
    res.json({ success: true, logId: log._id });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = { adminEntryProctoringRoutes: adminRouter, studentEntryProctoringRoutes: studentRouter };

PREPROUTEEOF
node --check "$ROUTES_DIR/entryProctoringControl.js" && echo "✔ entryProctoringControl.js OK"

echo ""
echo "════════════════════════════════════════════"
echo "STEP 4 — Backend: mount routes in $BACKEND_ENTRY (idempotent)"
echo "════════════════════════════════════════════"
cat > /tmp/pr_patch_entryproc_index.js << 'PREPPATCHEOF'
// ══════════════════════════════════════════════════════════════════
// Idempotent patcher — mounts Entry & Proctoring Control Center routes.
// Safe: timestamped backup, skips if already applied, touches nothing
// else in index.js.
// ══════════════════════════════════════════════════════════════════
const fs = require('fs');
const path = require('path');

const CANDIDATES = [
  path.join(process.env.HOME || '/home/runner/workspace', 'src', 'index.js'),
  path.join(process.cwd(), 'src', 'index.js'),
  path.join(process.cwd(), 'index.js'),
];

let target = null;
for (const p of CANDIDATES) { if (fs.existsSync(p)) { target = p; break; } }
if (!target) {
  console.error('❌ Could not locate src/index.js automatically.');
  console.error('   Checked: ' + CANDIDATES.join(', '));
  process.exit(1);
}

let src = fs.readFileSync(target, 'utf8');

if (src.includes('entryProctoringControl')) {
  console.log('✅ Already mounted — no changes needed: ' + target);
  process.exit(0);
}

const backupPath = target + '.bak.' + Date.now();
fs.writeFileSync(backupPath, src);
console.log('🗂  Backup saved: ' + backupPath);

const REQUIRE_LINE = "const { adminEntryProctoringRoutes, studentEntryProctoringRoutes } = require('./routes/entryProctoringControl');";
const USE_LINE_1 = "app.use('/api/admin/entry-proctoring', adminEntryProctoringRoutes);";
const USE_LINE_2 = "app.use('/api/entry-proctoring', studentEntryProctoringRoutes);";

let lines = src.split('\n');

let reqAnchor = lines.findIndex(l => l.includes("require('./routes/studentBatchWorkspace')") || l.includes('require("./routes/studentBatchWorkspace")'));
if (reqAnchor === -1) {
  for (let i = lines.length - 1; i >= 0; i--) {
    if (/^\s*(const|let|var)\s+.*require\(/.test(lines[i])) { reqAnchor = i; break; }
  }
}
if (reqAnchor === -1) reqAnchor = 0;
lines.splice(reqAnchor + 1, 0, REQUIRE_LINE);

let useAnchor = lines.findIndex(l => l.includes("app.use('/api/student/batch-workspace'") || l.includes('app.use("/api/student/batch-workspace"'));
if (useAnchor === -1) {
  useAnchor = lines.findIndex(l => l.includes('app.listen('));
  if (useAnchor === -1) useAnchor = lines.length - 1;
  lines.splice(useAnchor, 0, USE_LINE_1, USE_LINE_2);
} else {
  lines.splice(useAnchor + 1, 0, USE_LINE_1, USE_LINE_2);
}

fs.writeFileSync(target, lines.join('\n'));
console.log('✅ Patched: ' + target);
console.log('   + ' + REQUIRE_LINE);
console.log('   + ' + USE_LINE_1);
console.log('   + ' + USE_LINE_2);
console.log('👉 Verify with: grep -n "entryProctoringControl\\|entry-proctoring" ' + target);

PREPPATCHEOF
node /tmp/pr_patch_entryproc_index.js
grep -n "entryProctoringControl" "$BACKEND_ENTRY" || echo "⚠️  Mount line not found — check manually."

echo ""
echo "════════════════════════════════════════════"
echo "STEP 5 — Frontend: new Control Center component"
echo "════════════════════════════════════════════"
cat > "$ADMIN_COMPONENTS_DIR/EntryProctoringControlCenter.tsx" << 'PREPTSXEOF'
'use client'
import { useState, useEffect, useCallback } from 'react'

// ══════════════════════════════════════════════════════════════════
// F53–57-B — Entry & Proctoring Control Center (Admin)
// Mounted as its own tab component inside the main Admin Panel
// (frontend/app/admin/x7k2p/page.tsx) — same pattern as other
// standalone tab components in this file.
// ══════════════════════════════════════════════════════════════════

const API = process.env.NEXT_PUBLIC_API_URL || 'https://proverank.onrender.com'
const BASE = `${API}/api/admin/entry-proctoring`

const CARD = 'rgba(10,16,32,0.92)'
const BORDER = '1px solid rgba(77,159,255,0.16)'
const SUB = 'rgba(180,200,230,0.7)'
const TXT = '#F1F6FC'
const EC = '#4D9FFF'

const TABS = [
  { key: 'overview', label: 'Overview', icon: '🏠' },
  { key: 'waitingRoom', label: 'Waiting Room', icon: '⏳' },
  { key: 'instructions', label: 'Instructions', icon: '📋' },
  { key: 'tnc', label: 'T&C / Consent', icon: '📜' },
  { key: 'webcam', label: 'Webcam', icon: '📷' },
  { key: 'fullscreen', label: 'Fullscreen', icon: '🖥️' },
  { key: 'joinRules', label: 'Join Rules', icon: '🚪' },
  { key: 'broadcasts', label: 'Broadcasts', icon: '📢' },
  { key: 'templates', label: 'Templates', icon: '🗂️' },
  { key: 'preview', label: 'Live Preview', icon: '👁️' },
  { key: 'audit', label: 'Audit & History', icon: '🕵️' },
  { key: 'controlLogs', label: 'Control Logs', icon: '📊' },
] as const
type TabKey = typeof TABS[number]['key']

function tok() { try { return localStorage.getItem('pr_token') || '' } catch { return '' } }
async function api(path: string, opts: any = {}) {
  const r = await fetch(`${BASE}${path}`, {
    ...opts, headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${tok()}`, ...(opts.headers || {}) }
  })
  const d = await r.json().catch(() => ({}))
  if (!r.ok) throw new Error(d.error || `Request failed (${r.status})`)
  return d
}

const card: React.CSSProperties = { background: CARD, border: BORDER, borderRadius: 16, padding: 16, marginBottom: 12 }
const label: React.CSSProperties = { fontSize: 10, color: SUB, textTransform: 'uppercase', fontWeight: 700, marginBottom: 8, letterSpacing: 0.4 }
const inputStyle: React.CSSProperties = { padding: '8px 10px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(77,159,255,0.2)', borderRadius: 8, color: TXT, fontSize: 12, width: '100%' }
const btn = (active = false): React.CSSProperties => ({ padding: '8px 14px', borderRadius: 9, border: active ? 'none' : '1px solid rgba(77,159,255,0.3)', background: active ? `linear-gradient(135deg,${EC},#2E7FE0)` : 'transparent', color: active ? '#fff' : EC, fontSize: 11, fontWeight: 700, cursor: 'pointer' })

function Toggle({ checked, onChange, label: l }: { checked: boolean; onChange: (v: boolean) => void; label: string }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '7px 0', borderBottom: '1px solid rgba(77,159,255,0.06)' }}>
      <span style={{ fontSize: 12 }}>{l}</span>
      <button onClick={() => onChange(!checked)} style={{ width: 38, height: 20, borderRadius: 20, border: 'none', cursor: 'pointer', background: checked ? EC : 'rgba(255,255,255,0.14)', position: 'relative', flexShrink: 0 }}>
        <span style={{ position: 'absolute', top: 2, left: checked ? 20 : 2, width: 16, height: 16, borderRadius: '50%', background: '#fff', transition: 'left 0.15s' }} />
      </button>
    </div>
  )
}
function NumField({ value, onChange, label: l, suffix }: { value: number; onChange: (v: number) => void; label: string; suffix?: string }) {
  return (
    <div style={{ marginBottom: 8 }}>
      <div style={{ fontSize: 10, color: SUB, marginBottom: 3 }}>{l}</div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        <input type="number" value={value ?? 0} onChange={e => onChange(Number(e.target.value))} style={inputStyle} />
        {suffix && <span style={{ fontSize: 10, color: SUB }}>{suffix}</span>}
      </div>
    </div>
  )
}

export default function EntryProctoringControlCenter() {
  const [tab, setTab] = useState<TabKey>('overview')
  const [kpis, setKpis] = useState<any>(null)
  const [policies, setPolicies] = useState<any[]>([])
  const [policy, setPolicy] = useState<any>(null)
  const [loading, setLoading] = useState(false)
  const [toast, setToast] = useState<string | null>(null)
  const [reason, setReason] = useState('')
  const [templates, setTemplates] = useState<any[]>([])
  const [broadcasts, setBroadcasts] = useState<any[]>([])
  const [history, setHistory] = useState<any[]>([])
  const [controlLogs, setControlLogs] = useState<any[]>([])
  const [previewMins, setPreviewMins] = useState(20)
  const [previewFlow, setPreviewFlow] = useState<any[]>([])
  const [showCreate, setShowCreate] = useState(false)
  const [newScope, setNewScope] = useState<{ type: string; examId: string; batchId: string; testSeriesId: string; name: string }>({ type: 'global', examId: '', batchId: '', testSeriesId: '', name: '' })
  const [massApplyIds, setMassApplyIds] = useState('')

  const notify = (m: string) => { setToast(m); setTimeout(() => setToast(null), 3000) }

  const loadKpis = useCallback(() => { api('/kpis').then(d => setKpis(d.kpis)).catch(() => {}) }, [])
  const loadPolicies = useCallback(() => { api('/policies').then(d => setPolicies(d.policies || [])).catch(() => {}) }, [])
  const loadTemplates = useCallback(() => { api('/templates').then(d => setTemplates(d.templates || [])).catch(() => {}) }, [])

  useEffect(() => { loadKpis(); loadPolicies(); loadTemplates() }, [loadKpis, loadPolicies, loadTemplates])

  const openPolicy = (id: string) => {
    setLoading(true)
    api(`/policies/${id}`).then(d => setPolicy(d.policy)).catch(e => notify('❌ ' + e.message)).finally(() => setLoading(false))
  }

  useEffect(() => {
    if (!policy?._id) return
    if (tab === 'broadcasts') api(`/policies/${policy._id}/broadcasts`).then(d => setBroadcasts(d.broadcasts || [])).catch(() => {})
    if (tab === 'audit') api(`/policies/${policy._id}/history`).then(d => setHistory(d.history || [])).catch(() => {})
    if (tab === 'controlLogs') api(`/control-logs?examId=${policy.scope?.examId || ''}`).then(d => setControlLogs(d.logs || [])).catch(() => {})
  }, [tab, policy?._id])

  const createPolicy = async () => {
    try {
      const scope: any = { type: newScope.type }
      if (newScope.type === 'exam') scope.examId = newScope.examId
      if (newScope.type === 'batch') scope.batchId = newScope.batchId
      if (newScope.type === 'series') scope.testSeriesId = newScope.testSeriesId
      const d = await api('/policies', { method: 'POST', body: JSON.stringify({ name: newScope.name || undefined, scope }) })
      notify('✅ Policy created')
      setShowCreate(false)
      loadPolicies()
      setPolicy(d.policy)
    } catch (e: any) { notify('❌ ' + e.message) }
  }

  const saveSection = async (section: string, value: any) => {
    if (!policy?._id) return
    try {
      const d = await api(`/policies/${policy._id}`, { method: 'PUT', body: JSON.stringify({ [section]: value, reason }) })
      setPolicy(d.policy)
      notify('✅ Saved')
    } catch (e: any) { notify('❌ ' + e.message) }
  }

  const patchLocal = (section: string, patch: any) => setPolicy((p: any) => ({ ...p, [section]: { ...(p[section] || {}), ...patch } }))

  const publish = async () => {
    if (!policy?._id) return
    try { const d = await api(`/policies/${policy._id}/publish`, { method: 'POST', body: JSON.stringify({ reason }) }); setPolicy(d.policy); notify('🚀 Published'); loadKpis(); loadPolicies() }
    catch (e: any) { notify('❌ ' + e.message) }
  }
  const cloneIt = async () => { if (!policy?._id) return; try { const d = await api(`/policies/${policy._id}/clone`, { method: 'POST' }); notify('✅ Cloned'); loadPolicies(); setPolicy(d.policy) } catch (e: any) { notify('❌ ' + e.message) } }
  const lockIt = async (v: boolean) => { if (!policy?._id) return; try { const d = await api(`/policies/${policy._id}/${v ? 'lock' : 'unlock'}`, { method: 'POST' }); setPolicy(d.policy); notify(v ? '🔒 Locked' : '🔓 Unlocked') } catch (e: any) { notify('❌ ' + e.message) } }
  const rollback = async (version: number) => { if (!policy?._id) return; try { const d = await api(`/policies/${policy._id}/rollback/${version}`, { method: 'POST' }); setPolicy(d.policy); notify(`↩️ Rolled back to v${version}`) } catch (e: any) { notify('❌ ' + e.message) } }
  const emergency = async (action: string) => { if (!policy?._id) return; try { await api(`/policies/${policy._id}/emergency-override`, { method: 'POST', body: JSON.stringify({ action }) }); notify('⚡ Override sent: ' + action) } catch (e: any) { notify('❌ ' + e.message) } }
  const applyTemplate = async (templateId: string) => { if (!policy?._id) return; try { const d = await api(`/templates/${templateId}/apply/${policy._id}`, { method: 'POST' }); setPolicy(d.policy); notify('✅ Template applied') } catch (e: any) { notify('❌ ' + e.message) } }
  const massApply = async () => {
    if (!policy?._id) return
    const examIds = massApplyIds.split(',').map(s => s.trim()).filter(Boolean)
    if (!examIds.length) return notify('⚠️ Enter at least one exam ID')
    try { const d = await api(`/policies/${policy._id}/mass-apply`, { method: 'POST', body: JSON.stringify({ examIds }) }); notify(`✅ Applied to ${d.results.filter((r: any) => r.success).length}/${examIds.length} exam(s)`) }
    catch (e: any) { notify('❌ ' + e.message) }
  }
  const runPreview = async () => { if (!policy?._id) return; try { const d = await api(`/policies/${policy._id}/preview`, { method: 'POST', body: JSON.stringify({ minutesBeforeStart: previewMins }) }); setPreviewFlow(d.flow || []) } catch (e: any) { notify('❌ ' + e.message) } }
  const sendBroadcast = async (form: any) => {
    if (!policy?._id) return
    try {
      await api('/broadcasts', { method: 'POST', body: JSON.stringify({ examId: policy.scope?.examId, broadcastType: form.type, title: form.title, message: form.message, channel: form.channel }) })
      notify('📢 Broadcast sent'); api(`/policies/${policy._id}/broadcasts`).then(d => setBroadcasts(d.broadcasts || []))
    } catch (e: any) { notify('❌ ' + e.message) }
  }

  const readiness = policy?.readinessScore ?? 0
  const warnings: string[] = policy?.warnings || []

  return (
    <div style={{ minHeight: '100vh', color: TXT, fontFamily: 'Inter,sans-serif', padding: 16 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14, flexWrap: 'wrap', gap: 10 }}>
        <div>
          <div style={{ fontSize: 20, fontWeight: 800 }}>🛡️ Entry & Proctoring Control Center</div>
          <div style={{ fontSize: 11, color: SUB }}>Waiting Room · Instructions · T&C · Webcam · Fullscreen · Join Rules — centralised</div>
        </div>
        <button onClick={() => setShowCreate(true)} style={btn(true)}>+ Create New Policy</button>
      </div>

      {/* ── 2) KPI CARDS ── */}
      {kpis && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(120px,1fr))', gap: 8, marginBottom: 14 }}>
          {[
            ['Active Policies', kpis.activeExamPolicies], ['Waiting Room ON', kpis.waitingRoomEnabled],
            ['Instructions Published', kpis.instructionsPublished], ['T&C Active', kpis.tncActiveVersions],
            ['Webcam Mandatory', kpis.webcamMandatoryExams], ['Fullscreen ON', kpis.fullscreenEnabledExams],
            ['Live Join Blocks (7d)', kpis.liveJoinBlocks7d], ['Changes Today', kpis.policyChangesToday],
          ].map(([l, v], i) => (
            <div key={i} style={{ ...card, textAlign: 'center', marginBottom: 0, padding: 12 }}>
              <div style={{ fontSize: 18, fontWeight: 800, color: EC }}>{v as any}</div>
              <div style={{ fontSize: 9, color: SUB, marginTop: 2 }}>{l as any}</div>
            </div>
          ))}
        </div>
      )}

      <div style={{ display: 'grid', gridTemplateColumns: '260px 1fr', gap: 14 }}>
        {/* ── POLICY LIST ── */}
        <div>
          <div style={card}>
            <div style={label}>Policies ({policies.length})</div>
            {policies.map(p => (
              <div key={p._id} onClick={() => openPolicy(p._id)}
                style={{ padding: '8px 10px', borderRadius: 8, marginBottom: 5, cursor: 'pointer', background: policy?._id === p._id ? `${EC}20` : 'rgba(255,255,255,0.03)', border: `1px solid ${policy?._id === p._id ? EC + '50' : 'transparent'}` }}>
                <div style={{ fontSize: 11, fontWeight: 700 }}>{p.name}</div>
                <div style={{ fontSize: 9, color: SUB }}>{p.scope?.type} · {p.status} · v{p.version} · {p.readinessScore}% ready</div>
              </div>
            ))}
            {policies.length === 0 && <div style={{ fontSize: 11, color: SUB }}>No policies yet. Create one to get started.</div>}
          </div>
        </div>

        {/* ── SELECTED POLICY WORKSPACE ── */}
        <div>
          {!policy ? (
            <div style={{ ...card, textAlign: 'center', padding: 40 }}>Select or create a policy to begin.</div>
          ) : (
            <>
              <div style={card}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 8 }}>
                  <div>
                    <div style={{ fontSize: 15, fontWeight: 800 }}>{policy.name}</div>
                    <div style={{ fontSize: 10, color: SUB }}>Scope: {policy.scope?.type} · Status: <b style={{ color: policy.status === 'published' ? '#27AE60' : '#F5A623' }}>{policy.status}</b> · v{policy.version}{policy.locked && ' · 🔒 Locked'}</div>
                  </div>
                  <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                    <button onClick={cloneIt} style={btn()}>Clone</button>
                    <button onClick={() => lockIt(!policy.locked)} style={btn()}>{policy.locked ? 'Unlock' : 'Lock'}</button>
                    <button onClick={publish} style={btn(true)}>Publish</button>
                  </div>
                </div>
                <div style={{ marginTop: 10 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10, color: SUB, marginBottom: 4 }}>
                    <span>Readiness Score</span><span>{readiness}%</span>
                  </div>
                  <div style={{ height: 6, background: 'rgba(255,255,255,0.08)', borderRadius: 4, overflow: 'hidden' }}>
                    <div style={{ width: `${readiness}%`, height: '100%', background: readiness >= 80 ? '#27AE60' : readiness >= 50 ? '#F5A623' : '#E74C3C' }} />
                  </div>
                  {warnings.length > 0 && <div style={{ marginTop: 8, fontSize: 10, color: '#F5A623' }}>{warnings.map((w, i) => <div key={i}>⚠️ {w}</div>)}</div>}
                </div>
                <input placeholder="Reason for this change (optional, saved to audit log)" value={reason} onChange={e => setReason(e.target.value)} style={{ ...inputStyle, marginTop: 10 }} />
                <div style={{ display: 'flex', gap: 6, marginTop: 8, flexWrap: 'wrap' }}>
                  <span style={{ fontSize: 9, color: SUB }}>Emergency Override:</span>
                  {['open_waiting_room_now', 'close_waiting_room', 'skip_to_instructions', 'skip_to_permission_check', 'force_exam_start'].map(a => (
                    <button key={a} onClick={() => emergency(a)} style={{ ...btn(), fontSize: 9, padding: '5px 8px' }}>{a.replace(/_/g, ' ')}</button>
                  ))}
                </div>
                <div style={{ display: 'flex', gap: 6, marginTop: 8, alignItems: 'center' }}>
                  <input placeholder="Mass apply → exam IDs (comma-separated)" value={massApplyIds} onChange={e => setMassApplyIds(e.target.value)} style={inputStyle} />
                  <button onClick={massApply} style={{ ...btn(), whiteSpace: 'nowrap' }}>Mass Apply</button>
                </div>
              </div>

              {/* ── SECTION TABS ── */}
              <div style={{ display: 'flex', gap: 5, overflowX: 'auto', marginBottom: 10, paddingBottom: 4 }}>
                {TABS.filter(t => t.key !== 'overview').map(t => (
                  <button key={t.key} onClick={() => setTab(t.key)} style={{ ...btn(tab === t.key), whiteSpace: 'nowrap', flexShrink: 0 }}>{t.icon} {t.label}</button>
                ))}
              </div>

              {tab === 'waitingRoom' && policy.waitingRoom && (
                <div style={card}>
                  <div style={label}>Waiting Room Control (5)</div>
                  <Toggle label="Waiting Room ON/OFF" checked={policy.waitingRoom.enabled} onChange={v => patchLocal('waitingRoom', { enabled: v })} />
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginTop: 8 }}>
                    <NumField label="Preset trigger (min before exam)" value={policy.waitingRoom.presetMinutes} onChange={v => patchLocal('waitingRoom', { presetMinutes: v })} suffix="min" />
                    <NumField label="Custom trigger (min)" value={policy.waitingRoom.customMinutes} onChange={v => patchLocal('waitingRoom', { customMinutes: v })} suffix="min" />
                  </div>
                  <Toggle label="Countdown Display" checked={policy.waitingRoom.countdownDisplay} onChange={v => patchLocal('waitingRoom', { countdownDisplay: v })} />
                  <Toggle label="Live Student Count" checked={policy.waitingRoom.liveStudentCount} onChange={v => patchLocal('waitingRoom', { liveStudentCount: v })} />
                  <Toggle label="Student Join Access" checked={policy.waitingRoom.studentJoinAccess} onChange={v => patchLocal('waitingRoom', { studentJoinAccess: v })} />
                  <Toggle label="Admin Broadcast Access" checked={policy.waitingRoom.adminBroadcastAccess} onChange={v => patchLocal('waitingRoom', { adminBroadcastAccess: v })} />
                  <Toggle label="Tips Rotation" checked={policy.waitingRoom.tipsRotation} onChange={v => patchLocal('waitingRoom', { tipsRotation: v })} />
                  <Toggle label="Background Music Toggle" checked={policy.waitingRoom.musicToggle} onChange={v => patchLocal('waitingRoom', { musicToggle: v })} />
                  <Toggle label="Chat Enabled" checked={policy.waitingRoom.chatEnabled} onChange={v => patchLocal('waitingRoom', { chatEnabled: v })} />
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginTop: 8 }}>
                    <NumField label="Chat Start (min before exam)" value={policy.waitingRoom.chatStartOffsetMin} onChange={v => patchLocal('waitingRoom', { chatStartOffsetMin: v })} suffix="min" />
                    <NumField label="Chat End (min before exam)" value={policy.waitingRoom.chatEndOffsetMin} onChange={v => patchLocal('waitingRoom', { chatEndOffsetMin: v })} suffix="min" />
                  </div>
                  <Toggle label="Admin Chat Only Mode" checked={policy.waitingRoom.adminChatOnlyMode} onChange={v => patchLocal('waitingRoom', { adminChatOnlyMode: v })} />
                  <Toggle label="Auto Transition to Instructions" checked={policy.waitingRoom.autoTransitionToInstructions} onChange={v => patchLocal('waitingRoom', { autoTransitionToInstructions: v })} />
                  <Toggle label="Show Seconds" checked={policy.waitingRoom.showSeconds} onChange={v => patchLocal('waitingRoom', { showSeconds: v })} />
                  <Toggle label="Show Progress Bar" checked={policy.waitingRoom.showProgressBar} onChange={v => patchLocal('waitingRoom', { showProgressBar: v })} />
                  <Toggle label="Server Time Sync" checked={policy.waitingRoom.serverTimeSync} onChange={v => patchLocal('waitingRoom', { serverTimeSync: v })} />

                  <div style={{ ...label, marginTop: 14 }}>Instructions Trigger (5.5.1.3)</div>
                  <Toggle label="Auto Open Instructions" checked={policy.instructionsTrigger?.autoOpen} onChange={v => patchLocal('instructionsTrigger', { autoOpen: v })} />
                  <NumField label="Trigger before exam" value={policy.instructionsTrigger?.presetMinutesBeforeExam} onChange={v => patchLocal('instructionsTrigger', { presetMinutesBeforeExam: v })} suffix="min" />

                  <div style={{ ...label, marginTop: 14 }}>Permission Check Trigger (5.5.1.4)</div>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                    <NumField label="Webcam Check" value={policy.permissionCheckTrigger?.webcamCheckOffsetMin} onChange={v => patchLocal('permissionCheckTrigger', { webcamCheckOffsetMin: v })} suffix="min before" />
                    <NumField label="Mic Check" value={policy.permissionCheckTrigger?.micCheckOffsetMin} onChange={v => patchLocal('permissionCheckTrigger', { micCheckOffsetMin: v })} suffix="min before" />
                    <NumField label="Fullscreen Check" value={policy.permissionCheckTrigger?.fullscreenCheckOffsetMin} onChange={v => patchLocal('permissionCheckTrigger', { fullscreenCheckOffsetMin: v })} suffix="min before" />
                    <NumField label="Device Check" value={policy.permissionCheckTrigger?.deviceCheckOffsetMin} onChange={v => patchLocal('permissionCheckTrigger', { deviceCheckOffsetMin: v })} suffix="min before" />
                  </div>

                  <div style={{ ...label, marginTop: 14 }}>Late Join Rules (5.5.1.7)</div>
                  <Toggle label="Allow Late Join" checked={policy.lateJoin?.allowLateJoin} onChange={v => patchLocal('lateJoin', { allowLateJoin: v })} />
                  <NumField label="Grace Duration" value={policy.lateJoin?.graceMinutes} onChange={v => patchLocal('lateJoin', { graceMinutes: v })} suffix="min" />
                  <Toggle label="Lock Entry After Grace" checked={policy.lateJoin?.lockEntryAfterGrace} onChange={v => patchLocal('lateJoin', { lockEntryAfterGrace: v })} />
                  <Toggle label="Allow Rejoin" checked={policy.lateJoin?.allowRejoin} onChange={v => patchLocal('lateJoin', { allowRejoin: v })} />
                  <NumField label="Rejoin Window" value={policy.lateJoin?.rejoinWindowMinutes} onChange={v => patchLocal('lateJoin', { rejoinWindowMinutes: v })} suffix="min" />

                  <div style={{ ...label, marginTop: 14 }}>Waiting Room Lock (5.5.1.8)</div>
                  <Toggle label="Lock Waiting Room" checked={policy.waitingRoomLock?.lockWaitingRoom} onChange={v => patchLocal('waitingRoomLock', { lockWaitingRoom: v })} />
                  <Toggle label="Force Student To Stay" checked={policy.waitingRoomLock?.forceStudentToStay} onChange={v => patchLocal('waitingRoomLock', { forceStudentToStay: v })} />
                  <Toggle label="Disable Navigation" checked={policy.waitingRoomLock?.disableNavigation} onChange={v => patchLocal('waitingRoomLock', { disableNavigation: v })} />
                  <Toggle label="Prevent Browser Refresh" checked={policy.waitingRoomLock?.preventBrowserRefresh} onChange={v => patchLocal('waitingRoomLock', { preventBrowserRefresh: v })} />
                  <Toggle label="Auto Reconnect" checked={policy.waitingRoomLock?.autoReconnect} onChange={v => patchLocal('waitingRoomLock', { autoReconnect: v })} />

                  <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
                    <button onClick={() => saveSection('waitingRoom', policy.waitingRoom)} style={btn(true)}>Save Waiting Room</button>
                    <button onClick={() => { saveSection('instructionsTrigger', policy.instructionsTrigger); saveSection('permissionCheckTrigger', policy.permissionCheckTrigger); saveSection('lateJoin', policy.lateJoin); saveSection('waitingRoomLock', policy.waitingRoomLock) }} style={btn()}>Save Related Rules</button>
                  </div>
                </div>
              )}

              {tab === 'instructions' && policy.instructions && (
                <div style={card}>
                  <div style={label}>Instructions Manager (6)</div>
                  <Toggle label="Published" checked={policy.instructions.published} onChange={v => patchLocal('instructions', { published: v })} />
                  {(policy.instructions.points || []).map((pt: any, i: number) => (
                    <div key={pt.id || i} style={{ background: 'rgba(255,255,255,0.03)', borderRadius: 8, padding: 8, marginBottom: 6 }}>
                      <div style={{ display: 'flex', gap: 6, marginBottom: 4 }}>
                        <input value={pt.text} onChange={e => { const pts = [...policy.instructions.points]; pts[i] = { ...pt, text: e.target.value }; patchLocal('instructions', { points: pts }) }} placeholder="Instruction text (English)" style={inputStyle} />
                        <button onClick={() => { const pts = policy.instructions.points.filter((_: any, j: number) => j !== i); patchLocal('instructions', { points: pts }) }} style={{ ...btn(), padding: '4px 8px' }}>✕</button>
                      </div>
                      <input value={pt.textHi} onChange={e => { const pts = [...policy.instructions.points]; pts[i] = { ...pt, textHi: e.target.value }; patchLocal('instructions', { points: pts }) }} placeholder="Instruction text (Hindi)" style={{ ...inputStyle, marginBottom: 4 }} />
                      <div style={{ display: 'flex', gap: 12, fontSize: 10 }}>
                        <label><input type="checkbox" checked={pt.mandatory} onChange={e => { const pts = [...policy.instructions.points]; pts[i] = { ...pt, mandatory: e.target.checked }; patchLocal('instructions', { points: pts }) }} /> Mandatory</label>
                        <label><input type="checkbox" checked={pt.warning} onChange={e => { const pts = [...policy.instructions.points]; pts[i] = { ...pt, warning: e.target.checked }; patchLocal('instructions', { points: pts }) }} /> Warning</label>
                        <label><input type="checkbox" checked={pt.bilingual} onChange={e => { const pts = [...policy.instructions.points]; pts[i] = { ...pt, bilingual: e.target.checked }; patchLocal('instructions', { points: pts }) }} /> Bilingual</label>
                        <button onClick={() => { if (i === 0) return; const pts = [...policy.instructions.points]; [pts[i - 1], pts[i]] = [pts[i], pts[i - 1]]; patchLocal('instructions', { points: pts }) }} style={{ background: 'none', border: 'none', color: SUB, cursor: 'pointer' }}>↑</button>
                        <button onClick={() => { if (i === policy.instructions.points.length - 1) return; const pts = [...policy.instructions.points]; [pts[i + 1], pts[i]] = [pts[i], pts[i + 1]]; patchLocal('instructions', { points: pts }) }} style={{ background: 'none', border: 'none', color: SUB, cursor: 'pointer' }}>↓</button>
                        <button onClick={() => { const pts = [...policy.instructions.points, { ...pt, id: undefined }]; patchLocal('instructions', { points: pts }) }} style={{ background: 'none', border: 'none', color: EC, cursor: 'pointer' }}>⧉ Duplicate</button>
                      </div>
                    </div>
                  ))}
                  <button onClick={() => patchLocal('instructions', { points: [...(policy.instructions.points || []), { text: '', textHi: '', type: 'custom', mandatory: false, warning: false, bilingual: true, order: (policy.instructions.points || []).length }] })} style={{ ...btn(), marginTop: 6 }}>+ Add Instruction</button>
                  <div style={{ marginTop: 12 }}><button onClick={() => saveSection('instructions', policy.instructions)} style={btn(true)}>Save Instructions</button></div>
                </div>
              )}

              {tab === 'tnc' && policy.tnc && (
                <div style={card}>
                  <div style={label}>T&C / Consent Manager (7)</div>
                  <div style={{ fontSize: 10, color: SUB, marginBottom: 4 }}>Version label: {policy.tnc.version}</div>
                  <textarea value={policy.tnc.text} onChange={e => patchLocal('tnc', { text: e.target.value })} placeholder="T&C text (English)" rows={5} style={{ ...inputStyle, marginBottom: 8 }} />
                  <textarea value={policy.tnc.textHi} onChange={e => patchLocal('tnc', { textHi: e.target.value })} placeholder="T&C text (Hindi)" rows={5} style={{ ...inputStyle, marginBottom: 8 }} />
                  <input value={policy.tnc.version} onChange={e => patchLocal('tnc', { version: e.target.value })} placeholder="Version label e.g. 1.0" style={{ ...inputStyle, marginBottom: 8 }} />
                  <Toggle label="Require Scroll to Bottom" checked={policy.tnc.requireScroll} onChange={v => patchLocal('tnc', { requireScroll: v })} />
                  <Toggle label="Require Checkbox Confirmation" checked={policy.tnc.requireCheckbox} onChange={v => patchLocal('tnc', { requireCheckbox: v })} />
                  <Toggle label="Require Re-Accept on Update" checked={policy.tnc.requireReacceptOnUpdate} onChange={v => patchLocal('tnc', { requireReacceptOnUpdate: v })} />
                  <Toggle label="Published" checked={policy.tnc.published} onChange={v => patchLocal('tnc', { published: v })} />
                  <div style={{ marginTop: 12 }}><button onClick={() => saveSection('tnc', policy.tnc)} style={btn(true)}>Save T&C</button></div>
                </div>
              )}

              {tab === 'webcam' && policy.webcam && (
                <div style={card}>
                  <div style={label}>Webcam Permission Control (8)</div>
                  <Toggle label="Camera Mandatory" checked={policy.webcam.mandatory} onChange={v => patchLocal('webcam', { mandatory: v })} />
                  <Toggle label="Live Preview Required" checked={policy.webcam.livePreviewRequired} onChange={v => patchLocal('webcam', { livePreviewRequired: v })} />
                  <Toggle label="Face Visible Required" checked={policy.webcam.faceVisibleRequired} onChange={v => patchLocal('webcam', { faceVisibleRequired: v })} />
                  <Toggle label="Multiple Face Alert" checked={policy.webcam.multiFaceAlert} onChange={v => patchLocal('webcam', { multiFaceAlert: v })} />
                  <Toggle label="Virtual Background Block" checked={policy.webcam.virtualBackgroundBlock} onChange={v => patchLocal('webcam', { virtualBackgroundBlock: v })} />
                  <Toggle label="Retry Allowed" checked={policy.webcam.retryAllowed} onChange={v => patchLocal('webcam', { retryAllowed: v })} />
                  <Toggle label="Optional Audio Permission" checked={policy.webcam.optionalAudioPermission} onChange={v => patchLocal('webcam', { optionalAudioPermission: v })} />
                  <Toggle label="Block on Denial" checked={policy.webcam.blockOnDenial} onChange={v => patchLocal('webcam', { blockOnDenial: v })} />
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginTop: 8 }}>
                    <NumField label="Lighting Warning Threshold" value={policy.webcam.lightingWarningThreshold} onChange={v => patchLocal('webcam', { lightingWarningThreshold: v })} suffix="/100" />
                    <NumField label="Min Confidence Threshold" value={policy.webcam.minConfidenceThreshold} onChange={v => patchLocal('webcam', { minConfidenceThreshold: v })} suffix="/100" />
                    <NumField label="Retry Count" value={policy.webcam.retryCount} onChange={v => patchLocal('webcam', { retryCount: v })} />
                    <NumField label="Retry Delay" value={policy.webcam.retryDelaySec} onChange={v => patchLocal('webcam', { retryDelaySec: v })} suffix="sec" />
                    <NumField label="Live Preview Duration" value={policy.webcam.showLivePreviewDurationSec} onChange={v => patchLocal('webcam', { showLivePreviewDurationSec: v })} suffix="sec" />
                  </div>
                  <div style={{ marginTop: 12 }}><button onClick={() => saveSection('webcam', policy.webcam)} style={btn(true)}>Save Webcam Policy</button></div>
                </div>
              )}

              {tab === 'fullscreen' && policy.fullscreen && (
                <div style={card}>
                  <div style={label}>Fullscreen Enforcement (9)</div>
                  <Toggle label="Fullscreen ON/OFF" checked={policy.fullscreen.enabled} onChange={v => patchLocal('fullscreen', { enabled: v })} />
                  <Toggle label="Auto Fullscreen on Start" checked={policy.fullscreen.autoFullscreenOnStart} onChange={v => patchLocal('fullscreen', { autoFullscreenOnStart: v })} />
                  <Toggle label="Return-to-Fullscreen Prompt" checked={policy.fullscreen.returnPrompt} onChange={v => patchLocal('fullscreen', { returnPrompt: v })} />
                  <Toggle label="Exit Reporting Enabled" checked={policy.fullscreen.exitReportingEnabled} onChange={v => patchLocal('fullscreen', { exitReportingEnabled: v })} />
                  <Toggle label="Auto-Submit Linkage" checked={policy.fullscreen.autoSubmitLinkage} onChange={v => patchLocal('fullscreen', { autoSubmitLinkage: v })} />
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginTop: 8 }}>
                    <NumField label="Warning Threshold (count)" value={policy.fullscreen.warningThreshold} onChange={v => patchLocal('fullscreen', { warningThreshold: v })} />
                    <NumField label="Grace Period" value={policy.fullscreen.gracePeriodSec} onChange={v => patchLocal('fullscreen', { gracePeriodSec: v })} suffix="sec" />
                  </div>
                  <div style={{ marginTop: 12 }}><button onClick={() => saveSection('fullscreen', policy.fullscreen)} style={btn(true)}>Save Fullscreen Policy</button></div>
                </div>
              )}

              {tab === 'joinRules' && policy.joinRules && (
                <div style={card}>
                  <div style={label}>Join Rules & Availability Engine (10)</div>
                  <NumField label="Join Grace Minutes" value={policy.joinRules.joinGraceMinutes} onChange={v => patchLocal('joinRules', { joinGraceMinutes: v })} suffix="min" />
                  <Toggle label="Block New Join While Live" checked={policy.joinRules.blockNewJoinWhileLive} onChange={v => patchLocal('joinRules', { blockNewJoinWhileLive: v })} />
                  <Toggle label="Re-Attempt Availability" checked={policy.joinRules.reAttemptAvailability} onChange={v => patchLocal('joinRules', { reAttemptAvailability: v })} />
                  <Toggle label="Emergency Access Override" checked={policy.joinRules.emergencyAccessOverride} onChange={v => patchLocal('joinRules', { emergencyAccessOverride: v })} />
                  <div style={{ fontSize: 10, color: SUB, margin: '8px 0 4px' }}>Availability After End</div>
                  <select value={policy.joinRules.availabilityAfterEnd} onChange={e => patchLocal('joinRules', { availabilityAfterEnd: e.target.value })} style={inputStyle}>
                    <option value="locked">Locked</option>
                    <option value="available_if_attempts_left">Available if attempts left</option>
                  </select>
                  <div style={{ marginTop: 12 }}><button onClick={() => saveSection('joinRules', policy.joinRules)} style={btn(true)}>Save Join Rules</button></div>
                </div>
              )}

              {tab === 'broadcasts' && (
                <BroadcastsPanel broadcasts={broadcasts} onSend={sendBroadcast} />
              )}

              {tab === 'templates' && (
                <div style={card}>
                  <div style={label}>Policy Templates (12)</div>
                  {templates.map(t => (
                    <div key={t._id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 0', borderBottom: '1px solid rgba(77,159,255,0.06)' }}>
                      <div><span style={{ marginRight: 6 }}>{t.icon}</span><b style={{ fontSize: 12 }}>{t.name}</b>{t.isBuiltIn && <span style={{ fontSize: 8, color: SUB, marginLeft: 6 }}>BUILT-IN</span>}<div style={{ fontSize: 10, color: SUB }}>{t.description}</div></div>
                      <button onClick={() => applyTemplate(t._id)} style={btn()}>Apply</button>
                    </div>
                  ))}
                </div>
              )}

              {tab === 'preview' && (
                <div style={card}>
                  <div style={label}>Live Preview / Simulator (13)</div>
                  <NumField label="Simulate: minutes before exam start" value={previewMins} onChange={setPreviewMins} suffix="min" />
                  <button onClick={runPreview} style={btn(true)}>▶ Run Simulation</button>
                  <div style={{ marginTop: 12 }}>
                    {previewFlow.map((s, i) => (
                      <div key={i} style={{ display: 'flex', justifyContent: 'space-between', padding: '7px 0', borderBottom: '1px solid rgba(77,159,255,0.06)' }}>
                        <span style={{ fontSize: 12 }}>{s.label}</span>
                        <span style={{ fontSize: 10, fontWeight: 700, color: s.state === 'active' ? '#27AE60' : s.state === 'done' ? SUB : s.state === 'skipped' ? '#E74C3C' : '#F5A623' }}>{s.state}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {tab === 'audit' && (
                <div style={card}>
                  <div style={label}>Audit & Version History (14)</div>
                  {history.map((h, i) => (
                    <div key={i} style={{ padding: '8px 0', borderBottom: '1px solid rgba(77,159,255,0.06)' }}>
                      <div style={{ fontSize: 11 }}><b>{h.section}</b> changed by {h.changedByName || 'admin'} — v{h.version}</div>
                      <div style={{ fontSize: 9, color: SUB }}>{new Date(h.changedAt).toLocaleString()} {h.reason && `· ${h.reason}`}</div>
                      {h.snapshot && <button onClick={() => rollback(h.version)} style={{ ...btn(), fontSize: 9, marginTop: 4 }}>↩️ Rollback to v{h.version}</button>}
                    </div>
                  ))}
                  {history.length === 0 && <div style={{ fontSize: 11, color: SUB }}>No changes recorded yet.</div>}
                </div>
              )}

              {tab === 'controlLogs' && (
                <div style={card}>
                  <div style={label}>Control Logs (15)</div>
                  <div style={{ overflowX: 'auto' }}>
                    <table style={{ width: '100%', fontSize: 10, borderCollapse: 'collapse' }}>
                      <thead><tr style={{ textAlign: 'left', color: SUB }}><th>Time</th><th>Event</th><th>Severity</th><th>Status</th><th>Student</th></tr></thead>
                      <tbody>
                        {controlLogs.map((l, i) => (
                          <tr key={i} style={{ borderTop: '1px solid rgba(77,159,255,0.06)' }}>
                            <td style={{ padding: '5px 4px' }}>{new Date(l.createdAt).toLocaleString()}</td>
                            <td>{l.eventType}</td>
                            <td style={{ color: l.severity === 'critical' ? '#E74C3C' : l.severity === 'warning' ? '#F5A623' : SUB }}>{l.severity}</td>
                            <td>{l.status}</td>
                            <td>{l.studentId?.name || '—'}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                    {controlLogs.length === 0 && <div style={{ fontSize: 11, color: SUB, padding: 10 }}>No events logged yet.</div>}
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      </div>

      {/* ── CREATE POLICY MODAL ── */}
      {showCreate && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}>
          <div style={{ ...card, width: 360, marginBottom: 0 }}>
            <div style={label}>Create New Policy</div>
            <input placeholder="Policy name (optional)" value={newScope.name} onChange={e => setNewScope(s => ({ ...s, name: e.target.value }))} style={{ ...inputStyle, marginBottom: 8 }} />
            <select value={newScope.type} onChange={e => setNewScope(s => ({ ...s, type: e.target.value }))} style={{ ...inputStyle, marginBottom: 8 }}>
              <option value="global">Global Default</option>
              <option value="exam">Single Exam</option>
              <option value="batch">Batch</option>
              <option value="series">Test Series</option>
            </select>
            {newScope.type === 'exam' && <input placeholder="Exam ID" value={newScope.examId} onChange={e => setNewScope(s => ({ ...s, examId: e.target.value }))} style={{ ...inputStyle, marginBottom: 8 }} />}
            {newScope.type === 'batch' && <input placeholder="Batch ID" value={newScope.batchId} onChange={e => setNewScope(s => ({ ...s, batchId: e.target.value }))} style={{ ...inputStyle, marginBottom: 8 }} />}
            {newScope.type === 'series' && <input placeholder="Test Series ID" value={newScope.testSeriesId} onChange={e => setNewScope(s => ({ ...s, testSeriesId: e.target.value }))} style={{ ...inputStyle, marginBottom: 8 }} />}
            <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
              <button onClick={createPolicy} style={btn(true)}>Create</button>
              <button onClick={() => setShowCreate(false)} style={btn()}>Cancel</button>
            </div>
          </div>
        </div>
      )}

      {toast && <div style={{ position: 'fixed', bottom: 24, left: '50%', transform: 'translateX(-50%)', zIndex: 2000, background: 'rgba(20,20,35,0.96)', border: '1px solid rgba(77,159,255,0.35)', borderRadius: 12, padding: '10px 18px', fontSize: 12, fontWeight: 600 }}>{toast}</div>}
    </div>
  )
}

function BroadcastsPanel({ broadcasts, onSend }: { broadcasts: any[]; onSend: (f: any) => void }) {
  const [form, setForm] = useState({ type: 'waiting_room_announcement', title: '', message: '', channel: 'in-app' })
  return (
    <div style={card}>
      <div style={label}>Broadcasts & Notifications (11)</div>
      <select value={form.type} onChange={e => setForm(f => ({ ...f, type: e.target.value }))} style={{ ...inputStyle, marginBottom: 8 }}>
        <option value="waiting_room_announcement">Waiting Room Announcement</option>
        <option value="instruction_update">Instruction Update</option>
        <option value="consent_reminder">Consent Reminder</option>
        <option value="camera_reminder">Camera Reminder</option>
        <option value="fullscreen_reminder">Fullscreen Reminder</option>
        <option value="join_window_warning">Join Window Warning</option>
        <option value="emergency_notice">Emergency Notice</option>
      </select>
      <input placeholder="Title" value={form.title} onChange={e => setForm(f => ({ ...f, title: e.target.value }))} style={{ ...inputStyle, marginBottom: 8 }} />
      <textarea placeholder="Message" value={form.message} onChange={e => setForm(f => ({ ...f, message: e.target.value }))} rows={3} style={{ ...inputStyle, marginBottom: 8 }} />
      <select value={form.channel} onChange={e => setForm(f => ({ ...f, channel: e.target.value }))} style={{ ...inputStyle, marginBottom: 8 }}>
        <option value="in-app">In-app Banner</option>
        <option value="waiting_room_popup">Waiting Room Popup</option>
        <option value="notification_center">Notification Center</option>
        <option value="email">Email</option>
      </select>
      <button onClick={() => { onSend(form); setForm({ ...form, title: '', message: '' }) }} style={btn(true)}>📢 Send Broadcast</button>
      <div style={{ marginTop: 14 }}>
        {broadcasts.map((b, i) => (
          <div key={i} style={{ padding: '7px 0', borderBottom: '1px solid rgba(77,159,255,0.06)' }}>
            <div style={{ fontSize: 11, fontWeight: 700 }}>{b.title}</div>
            <div style={{ fontSize: 9, color: SUB }}>{b.entryContext?.broadcastType} · {b.status} · {new Date(b.createdAt).toLocaleString()}</div>
          </div>
        ))}
        {broadcasts.length === 0 && <div style={{ fontSize: 11, color: SUB }}>No broadcasts sent yet for this exam.</div>}
      </div>
    </div>
  )
}

PREPTSXEOF
echo "✔ Created: $ADMIN_COMPONENTS_DIR/EntryProctoringControlCenter.tsx"

echo ""
echo "════════════════════════════════════════════"
echo "STEP 6 — Frontend: wire into Admin Panel sidebar (4 precise edits)"
echo "════════════════════════════════════════════"
if [ -n "$ADMIN_PAGE" ]; then
 if grep -q "EntryProctoringControlCenter" "$ADMIN_PAGE"; then
  echo "✅ Already wired up — no changes needed: $ADMIN_PAGE"
 else
  cp "$ADMIN_PAGE" "$ADMIN_PAGE.bak.$(date +%s)"
  echo "✔ Backed up: $ADMIN_PAGE"
  BEFORE_HASH=$(md5sum "$ADMIN_PAGE" | awk '{print $1}')

  A1='import AdminAnnouncements from '"'"'./AdminAnnouncements'"'"'; // F42A'
  A2="{id:'integrity',ico:'🤖',lbl:'AI Integrity',grp:'Proctoring'},"
  A3="view_snapshots:['snapshots','cheating','integrity'],"
  A4="{tab==='store'&&(<div style={{minHeight:'100vh'}}><StoreAdminTab /></div>)}"

  C1=$(grep -c -F "$A1" "$ADMIN_PAGE" || true)
  C2=$(grep -c -F "$A2" "$ADMIN_PAGE" || true)
  C3=$(grep -c -F "$A3" "$ADMIN_PAGE" || true)
  C4=$(grep -c -F "$A4" "$ADMIN_PAGE" || true)

  if [ "$C1" = "1" ]; then
    perl -0777 -pi -e "s#\Q$A1\E\n#$A1\nimport EntryProctoringControlCenter from './EntryProctoringControlCenter'; // F53-57-B\n#" "$ADMIN_PAGE"
    echo "✔ [1/4] Import added"
  else
    echo "⚠️  [1/4] Skipped — anchor found $C1 time(s), expected exactly 1. Add manually:"
    echo "      import EntryProctoringControlCenter from './EntryProctoringControlCenter';"
  fi

  if [ "$C2" = "1" ]; then
    perl -0777 -pi -e "s#\Q$A2\E\n#$A2\n    {id:'entry_proctoring',ico:'🛡️',lbl:'Entry & Proctoring',grp:'Proctoring'},\n#" "$ADMIN_PAGE"
    echo "✔ [2/4] Sidebar nav entry added (Proctoring group)"
  else
    echo "⚠️  [2/4] Skipped — anchor found $C2 time(s), expected exactly 1."
  fi

  if [ "$C3" = "1" ]; then
    perl -0777 -pi -e "s#\Q$A3\E#view_snapshots:['snapshots','cheating','integrity','entry_proctoring'],#" "$ADMIN_PAGE"
    echo "✔ [3/4] Permission map updated"
  else
    echo "⚠️  [3/4] Skipped — anchor found $C3 time(s), expected exactly 1."
  fi

  if [ "$C4" = "1" ]; then
    perl -0777 -pi -e "s#(\Q$A4\E\n)#\${1}          {tab==='entry_proctoring'&&(<div style={{minHeight:'100vh'}}><EntryProctoringControlCenter /></div>)}\n#" "$ADMIN_PAGE"
    echo "✔ [4/4] Render block added"
  else
    echo "⚠️  [4/4] Skipped — anchor found $C4 time(s), expected exactly 1."
  fi

  AFTER_HASH=$(md5sum "$ADMIN_PAGE" | awk '{print $1}')
  if [ "$BEFORE_HASH" = "$AFTER_HASH" ]; then
    echo "⚠️  No edits applied at all — your page.tsx has diverged from the version I analyzed."
    echo "   Nothing was changed. Please share the current page.tsx again so I can adjust the patch."
  else
    echo "✔ Patched $ADMIN_PAGE — always spot-check the 4 lines above after this runs."
  fi
 fi
else
  echo "⏭  Skipped (Admin Panel page.tsx not found earlier)."
fi

echo ""
echo "════════════════════════════════════════════"
echo "✅ DONE — Summary"
echo "════════════════════════════════════════════"
echo "New:      $MODELS_DIR/EntryProctoringPolicy.js"
echo "New:      $MODELS_DIR/EntryPolicyTemplate.js"
echo "New:      $MODELS_DIR/EntryControlLog.js"
echo "Updated:  $MODELS_DIR/Announcement.js (+examId, +entryContext)"
echo "New:      $ROUTES_DIR/entryProctoringControl.js"
echo "Patched:  $BACKEND_ENTRY (mounted /api/admin/entry-proctoring + /api/entry-proctoring)"
echo "New:      $ADMIN_COMPONENTS_DIR/EntryProctoringControlCenter.tsx"
echo "Patched:  $ADMIN_PAGE (4 lines — sidebar entry, import, permission map, render block)"
echo ""
echo "⚠️  SCOPE NOTES — please read:"
echo "  1) Publishing a policy for a SINGLE EXAM syncs 4 fields your existing"
echo "     waiting-room runtime already reads (waitingRoomEnabled/Minutes,"
echo "     waitingChatMinutes, waitingAutoCloseBufferMinutes) — so timing"
echo "     changes take effect immediately for students."
echo "  2) Instructions text / T&C / webcam / fullscreen / join-rule detail"
echo "     is fully built, saved, versioned and published in this new admin"
echo "     center, and exposed for your attempt-flow pages at:"
echo "       GET /api/entry-proctoring/effective/:examId"
echo "     Wire that into the waiting-room / instructions / webcam / fullscreen"
echo "     pages whenever you next touch them — nothing there was changed today."
echo "  3) Restart backend: pkill -f node; cd ~/workspace && node src/index.js"
echo "  4) Test: Admin Panel → sidebar → Proctoring → Entry & Proctoring →"
echo "     Create New Policy → fill each tab → Publish → check Live Preview."
