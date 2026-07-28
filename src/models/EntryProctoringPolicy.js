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

