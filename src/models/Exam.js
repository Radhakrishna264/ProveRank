const mongoose = require('mongoose');

const examSchema = new mongoose.Schema({
  title:        { type: String, required: true, trim: true },
  subject:      { type: String, default: 'NEET' },
  duration:     { type: Number, required: true },
  totalMarks:   { type: Number, default: 720 },
  questions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Question' }], // QsBank Integration

  sections: [{
    name:          String,
    subject:       String,
    questionCount: Number,
    timeLimit:     Number,
    marks:         Number,
    fromQNo:       Number,
    toQNo:         Number
  }],

  markingScheme: {
    correct:     { type: Number, default: 4 },
    incorrect:   { type: Number, default: -1 },
    unattempted: { type: Number, default: 0 },
    msqMode:     { type: String, enum: ['ALL_OR_NOTHING', 'PARTIAL_NEGATIVE'], default: 'ALL_OR_NOTHING' }
  },

  password:   { type: String, default: '' },

  schedule: {
    startTime:  Date,
    endTime:    Date,
    resultTime: Date
  },

  audioMonitoringEnabled: { type: Boolean, default: false },
  status: { type: String, enum: ['draft', 'scheduled', 'live', 'ended'], default: 'draft' },


  assignmentType: { type: String, enum: ['series', 'mini_test', 'individual'], default: 'individual' },
  seriesName: { type: String, default: '' },
  testSeriesId: { type: mongoose.Schema.Types.ObjectId, ref: 'TestSeries', default: null },

  category: { type: String, enum: ['Full Mock', 'Chapter Test', 'Part Test', 'Grand Test', 'Mini Test'], default: 'Full Mock' },

  whitelist: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],

  watermark:          { type: Boolean, default: true },
  customInstructions: { type: String, default: '' },

  reviewWindow: {
    enabled:         { type: Boolean, default: false },
    durationMinutes: { type: Number, default: 0 },
  fullscreenForce: { type: Boolean, default: false },
  fullscreenWarnings: { type: Number, default: 0 }
  },

  template:   { type: String, default: '' },
  difficulty: { type: String, default: 'Mixed' },
  type:       { type: String, default: 'NEET' },

  waitingRoomEnabled: { type: Boolean, default: false },
  // Rule 1.15.1 — default waiting-room window is 20 min before exam start (admin-configurable per exam)
  waitingRoomMinutes: { type: Number, default: 20 },
  // Rule 1.15.6 — admin-configurable chat duration inside waiting room (minutes from join)
  waitingChatMinutes: { type: Number, default: 10 },
  // Rule 1.15.5/1.15.6 — admin-configurable auto-close buffer: waiting room force-closes
  // to Instructions screen this many minutes before exam start
  waitingAutoCloseBufferMinutes: { type: Number, default: 8 },

  maxAttempts:    { type: Number, default: 1 },
  reattemptCount: { type: String, enum: ['best', 'last'], default: 'last' },
  unlimitedAttempts: { type: Boolean, default: false },
  questionSnapshot:  { type: Array, default: [] },
  snapshotLocked:    { type: Boolean, default: false },
  snapshotLockedAt:  { type: Date, default: null },

  whitelistEnabled:    { type: Boolean, default: false },
  whitelistedStudents: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  whitelistedGroups:   [{ type: String }],

  subjectWiseCount: [{ subject: String, count: Number }],
  totalQuestionsRequested: { type: Number, default: 0 },

  scheduledPublish: {
    enabled:   { type: Boolean, default: false },
    publishAt: { type: Date, default: null }
  },
  notifyStudents: { type: Boolean, default: false },
  isTemplate: { type: Boolean, default: false },

  sourceMeta: {
    sourceType:     { type: String, enum: ['paste', 'excel', 'pdf', 'manual', ''], default: '' },
    fileName:        { type: String, default: '' },
    uploadedAt:      { type: Date, default: null },
    pageCount:       { type: Number, default: 0 },
    totalParsed:     { type: Number, default: 0 },
    totalErrors:     { type: Number, default: 0 },
    totalDuplicates: { type: Number, default: 0 }
  },

  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

  isPinned: { type: Boolean, default: false },
  clonedFrom: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam', default: null },

  isArchived:  { type: Boolean, default: false },
  archivedAt:  { type: Date, default: null },
  archivedBy:  { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null }

}, { timestamps: true });

module.exports = mongoose.model('Exam', examSchema);
