#!/bin/bash
set -e

# ═══════════════════════════════════════════════════════════════════════
# F59 — Answer Selection (A/B/C/D) + Mark for Review Core
# ProveRank | Full implementation on top of F58 v1+v2+v3
#
# Files touched:
#  1. src/models/Attempt.js        — adds optional `confidence` field
#  2. src/routes/attemptRoutes.js  — save-answer/auto-save/bookmark now
#                                    accept confidence + return a clean
#                                    ATTEMPT_LOCKED code on 403
#  3. frontend/.../attempt/page.tsx — full F59 answer-selection system
#
# What's NEW in this pass (on top of everything F58 already built):
#  §4.3/§7.4/§8.7 — distinct "Answered+Flagged" combined state (was
#                   silently collapsing to just "flagged" before)
#  §6.2/§8.7      — colorblind-safe status icons (✓ ⚑ ✓⚑ !) on the palette
#  §8.5           — Confidence Tag (High/Medium/Low) per question
#  §8.1/§8.12     — real offline queue + auto-retry-save (previously a
#                   silent catch{} that could lose an answer forever)
#  §5/§13.2       — submit-lock detection: if the server says the attempt
#                   is no longer active, the whole answer UI disables
#                   itself with a banner instead of silently failing
#  §6.4           — Integer input validation (numeric-only, inline error)
#  §8.6           — live "X Options Selected" counter for MSQ
#  §6.1           — double-click to deselect (SCQ)
#  §2.2           — hover state on option rows
#  §6.5           — "✓ Saved" / "⏳ Queued" / "📡 Offline" indicators
#
# NOTE on payload field name: the spec text (§1.3) says `{qId,
# selectedOption}`, but the REAL, verified backend route
# (attemptRoutes.js) expects `questionId` — this was already fixed in
# F58 v1 (previously answers were silently never saving because of this
# exact mismatch) and is intentionally kept as `questionId` here, not
# reverted to `qId`.
#
# Run from: ~/workspace  (after F58 v1+v2+v3 have already been applied)
# ═══════════════════════════════════════════════════════════════════════

echo "=================================================="
echo "F59 — Answer Selection + Mark for Review — Starting"
echo "=================================================="

TS=$(date +%Y%m%d_%H%M%S)
mkdir -p backups/f59_$TS
cp src/models/Attempt.js backups/f59_$TS/Attempt.js.bak 2>/dev/null || echo "  (Attempt.js not found at src/models — verify path before continuing)"
cp src/routes/attemptRoutes.js backups/f59_$TS/attemptRoutes.js.bak 2>/dev/null || echo "  (attemptRoutes.js not found at src/routes — verify path before continuing)"
cp "frontend/app/exam/[examId]/attempt/page.tsx" backups/f59_$TS/attempt_page.tsx.bak 2>/dev/null || echo "  (attempt page.tsx not found — verify path before continuing)"
echo "Backups saved to backups/f59_$TS/"

# ── 1) BACKEND MODEL — add optional confidence field (purely additive) ──
cat > src/models/Attempt.js << 'MODELEOF'
const mongoose = require('mongoose');

const attemptSchema = new mongoose.Schema({
  examId: { type: mongoose.Schema.Types.ObjectId, ref: 'Exam', required: true },
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  examInstanceId: { type: mongoose.Schema.Types.ObjectId, ref: 'ExamInstance' },
  status: { type: String, enum: ['waiting','instructions','active','submitted','timeout'], default: 'waiting' },
  ipAddress: { type: String },
  startedAt: { type: Date },
    warningCount: { type: Number, default: 0 },
  integrityScore: { type: Number, default: 100 },
  autoSubmitReason: { type: String, default: null },
  antiCheatFlags: { type: [String], default: [] },
  submittedAt: { type: Date },
  termsAccepted: { type: Boolean, default: false },
  termsAcceptedAt: { type: Date },
  admitCardVerified: { type: Boolean, default: false },
  admitCardVerifiedAt: { type: Date },
  fullscreenWarnings: { type: Number, default: 0 },
  fullscreenDenied: { type: Boolean, default: false },
  answers: [{
    questionId: mongoose.Schema.Types.ObjectId,
    selectedOption: mongoose.Schema.Types.Mixed,
    isMarkedForReview: { type: Boolean, default: false },
    timeTaken: { type: Number, default: 0 },
    savedAt: { type: Date },
    confidence: { type: String, enum: ['high', 'medium', 'low', null], default: null } // F59 §8.5 — optional confidence tag
  }],
  attemptNumber: { type: Number, default: 1 },
  score: { type: Number },
  rank: { type: Number },
  percentile: { type: Number },
  predictedRank: { type: Number },
  predictedScore: { type: Number },
  predictionConfidence: { type: String, enum: ['low','medium','high'] },
  deviceSessionId: { type: String, default: null },
  isPaused: { type: Boolean, default: false },
  pausedAt: { type: Boolean },
  totalCorrect: { type: Number, default: 0 },
  totalIncorrect: { type: Number, default: 0 },
  totalUnattempted: { type: Number, default: 0 },
  subjectStats: { type: mongoose.Schema.Types.Mixed, default: {} },
  sectionStats: { type: mongoose.Schema.Types.Mixed, default: {} },
  resultCalculated: { type: Boolean, default: false },
  resultCalculatedAt: { type: Date },
  difficultyFlag: { type: Boolean, default: false },
  ormSheetData: { type: mongoose.Schema.Types.Mixed },
  shareCardData: { type: mongoose.Schema.Types.Mixed }
}, { timestamps: true });

module.exports = mongoose.model('Attempt', attemptSchema);
MODELEOF

echo "Backend model: src/models/Attempt.js updated (confidence field added)."
node -c src/models/Attempt.js && echo "Attempt.js syntax OK" || (echo "MODEL SYNTAX ERROR — restoring backup"; cp backups/f59_$TS/Attempt.js.bak src/models/Attempt.js; exit 1)

# ── 2) BACKEND ROUTES — confidence passthrough + ATTEMPT_LOCKED code ──
cat > src/routes/attemptRoutes.js << 'ROUTESEOF'
const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Attempt = require('../models/Attempt');
const Exam = require('../models/Exam');
const { verifyToken } = require('../middleware/auth');

// ─────────────────────────────────────────────
// STEP 1 & 2: Save Answer + Auto-Save
// PATCH /api/attempts/:attemptId/save-answer
// ─────────────────────────────────────────────
router.patch('/:attemptId/save-answer', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const { questionId, selectedOption, timeTaken, confidence } = req.body;
    if (!questionId) return res.status(400).json({ message: 'questionId required' });
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    if (attempt.status !== 'active') return res.status(403).json({ message: 'Attempt is not active', code: 'ATTEMPT_LOCKED' });
    const qObjId = new mongoose.Types.ObjectId(questionId);
    const existingIndex = attempt.answers.findIndex(a => a.questionId.toString() === qObjId.toString());
    const validConfidence = ['high', 'medium', 'low'].includes(confidence) ? confidence : null;
    if (existingIndex >= 0) {
      attempt.answers[existingIndex].selectedOption = selectedOption;
      attempt.answers[existingIndex].timeTaken = timeTaken || attempt.answers[existingIndex].timeTaken;
      attempt.answers[existingIndex].savedAt = new Date();
      if (confidence !== undefined) attempt.answers[existingIndex].confidence = validConfidence;
    } else {
      attempt.answers.push({ questionId: qObjId, selectedOption, timeTaken: timeTaken || 0, isMarkedForReview: false, savedAt: new Date(), confidence: validConfidence });
    }
    await attempt.save();
    return res.status(200).json({ message: 'Answer saved', totalAnswered: attempt.answers.filter(a => a.selectedOption !== null && a.selectedOption !== undefined).length });
  } catch (err) {
    console.error('save-answer error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// PATCH /api/attempts/:attemptId/auto-save
router.patch('/:attemptId/auto-save', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const { answers } = req.body;
    if (!answers || !Array.isArray(answers)) return res.status(400).json({ message: 'answers array required' });
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    if (attempt.status !== 'active') return res.status(403).json({ message: 'Attempt is not active', code: 'ATTEMPT_LOCKED' });
    for (const ans of answers) {
      const qObjId = new mongoose.Types.ObjectId(ans.questionId);
      const existingIndex = attempt.answers.findIndex(a => a.questionId.toString() === qObjId.toString());
      const validConfidence = ['high', 'medium', 'low'].includes(ans.confidence) ? ans.confidence : null;
      if (existingIndex >= 0) {
        attempt.answers[existingIndex].selectedOption = ans.selectedOption;
        attempt.answers[existingIndex].timeTaken = ans.timeTaken || 0;
        attempt.answers[existingIndex].savedAt = new Date();
        if (ans.confidence !== undefined) attempt.answers[existingIndex].confidence = validConfidence;
      } else {
        attempt.answers.push({ questionId: qObjId, selectedOption: ans.selectedOption, timeTaken: ans.timeTaken || 0, isMarkedForReview: false, savedAt: new Date(), confidence: validConfidence });
      }
    }
    await attempt.save();
    return res.status(200).json({ message: 'Auto-save complete', savedAt: new Date(), totalAnswered: attempt.answers.filter(a => a.selectedOption !== null && a.selectedOption !== undefined).length });
  } catch (err) {
    console.error('auto-save error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ─────────────────────────────────────────────
// STEP 3: Timer Logic
// GET /api/attempts/:attemptId/timer
// ─────────────────────────────────────────────
router.get('/:attemptId/timer', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    const exam = await Exam.findById(attempt.examId);
    if (!exam) return res.status(404).json({ message: 'Exam not found' });
    // Feature 32: include granted extra time in timer
    let timeExtMin = 0;
    try {
      const TE = require('../models/TimeExtension');
      const exts = await TE.find({ attemptId: attempt._id, isUndone: false });
      timeExtMin = exts.reduce((s, e) => s + e.extraMinutes, 0);
    } catch(_e) {}
    const totalDurationSec = ((exam.duration || 200) + timeExtMin) * 60;
    const elapsedSec = Math.floor((Date.now() - new Date(attempt.startedAt).getTime()) / 1000);
    const remainingSec = Math.max(0, totalDurationSec - elapsedSec);
    return res.status(200).json({ startedAt: attempt.startedAt, startTime: attempt.startedAt, ipAddress: attempt.ipAddress,
      startTime: attempt.startedAt,
      ipAddress: attempt.ipAddress, 
    totalDurationSec, elapsedSec, remainingSec, timeExtMin,
    timeRemaining: remainingSec,
    elapsed: elapsedSec,
    timeLeft: remainingSec,
    remainingTime: remainingSec,
    isExpired: remainingSec <= 0 
  });
  } catch (err) {
    console.error('timer error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ─────────────────────────────────────────────
// STEP 4: Submit + Auto-Submit on Timeout
// POST /api/attempts/:attemptId/submit
// ─────────────────────────────────────────────
router.post('/:attemptId/submit', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const { isAutoSubmit } = req.body;
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    if (attempt.status === 'submitted') return res.status(400).json({ message: 'Already submitted' });
    if (attempt.status !== 'active') return res.status(403).json({ message: 'Attempt is not active' });
    const exam = await Exam.findById(attempt.examId);
    const totalDurationSec = (exam ? exam.duration || 200 : 200) * 60;
    const elapsedSec = Math.floor((Date.now() - new Date(attempt.startedAt).getTime()) / 1000);
    attempt.status = elapsedSec > totalDurationSec + 30 ? 'timeout' : 'submitted';
    attempt.submittedAt = new Date();
    attempt.deviceSessionId = null;
    await attempt.save();
    return res.status(200).json({ message: isAutoSubmit ? 'Auto-submitted on timeout' : 'Exam submitted successfully', status: attempt.status, submittedAt: attempt.submittedAt, totalAnswered: attempt.answers.filter(a => a.selectedOption !== null && a.selectedOption !== undefined).length });
  } catch (err) {
    console.error('submit error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ─────────────────────────────────────────────
// STEP 5: Bookmark / Flag Toggle (S1)
// PATCH /api/attempts/:attemptId/bookmark
// ─────────────────────────────────────────────
router.patch('/:attemptId/bookmark', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const { questionId } = req.body;
    if (!questionId) return res.status(400).json({ message: 'questionId required' });
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    if (attempt.status !== 'active') return res.status(403).json({ message: 'Attempt is not active', code: 'ATTEMPT_LOCKED' });
    const qObjId = new mongoose.Types.ObjectId(questionId);
    const existingIndex = attempt.answers.findIndex(a => a.questionId.toString() === qObjId.toString());
    let isMarkedForReview = false;
    if (existingIndex >= 0) {
      attempt.answers[existingIndex].isMarkedForReview = !attempt.answers[existingIndex].isMarkedForReview;
      isMarkedForReview = attempt.answers[existingIndex].isMarkedForReview;
    } else {
      attempt.answers.push({ questionId: qObjId, selectedOption: null, timeTaken: 0, isMarkedForReview: true, savedAt: new Date() });
      isMarkedForReview = true;
    }
    await attempt.save();
    return res.status(200).json({ message: isMarkedForReview ? 'Question bookmarked' : 'Bookmark removed', isMarkedForReview });
  } catch (err) {
    console.error('bookmark error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ─────────────────────────────────────────────
// STEP 6: Navigation Panel - Color Coded (S2)
// GET /api/attempts/:attemptId/navigation
// ─────────────────────────────────────────────
router.get('/:attemptId/navigation', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    const exam = await Exam.findById(attempt.examId).populate({path: "questions", strictPopulate: false});
    if (!exam) return res.status(404).json({ message: 'Exam not found' });

    const answerMap = {};
    for (const ans of attempt.answers) {
      answerMap[ans.questionId.toString()] = ans;
    }

    const navigation = (exam.questions || []).map((q, index) => {
      const qId = q._id.toString();
      const ans = answerMap[qId];
      let status = 'not-visited'; // grey
      if (ans) {
        if (ans.isMarkedForReview && ans.selectedOption !== null && ans.selectedOption !== undefined) {
          status = 'answered-flagged'; // purple+green
        } else if (ans.isMarkedForReview) {
          status = 'flagged'; // purple
        } else if (ans.selectedOption !== null && ans.selectedOption !== undefined) {
          status = 'answered'; // green
        } else {
          status = 'visited'; // red (visited but not answered)
        }
      }
      return { index: index + 1, questionId: qId, status };
    });

    const summary = {
      answered: navigation.filter(n => n.status === 'answered').length,
      unanswered: navigation.filter(n => n.status === 'visited').length,
      flagged: navigation.filter(n => n.status === 'flagged' || n.status === 'answered-flagged').length,
      notVisited: navigation.filter(n => n.status === 'not-visited').length,
      total: navigation.length
    };

    return res.status(200).json({ navigation, summary });
  } catch (err) {
    console.error('navigation error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ─────────────────────────────────────────────
// STEP 7: Connection Lost Protection (S51)
// PATCH /api/attempts/:attemptId/pause
// PATCH /api/attempts/:attemptId/resume
// ─────────────────────────────────────────────
router.patch('/:attemptId/pause', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    if (attempt.status !== 'active') return res.status(403).json({ message: 'Attempt is not active' });
    attempt.isPaused = true;
    attempt.pausedAt = new Date();
    await attempt.save();
    return res.status(200).json({ message: 'Exam paused - answers saved', pausedAt: attempt.pausedAt });
  } catch (err) {
    console.error('pause error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.patch('/:attemptId/resume', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    if (attempt.status !== 'active') return res.status(403).json({ message: 'Attempt is not active' });
    attempt.isPaused = false;
    attempt.pausedAt = null;
    await attempt.save();
    return res.status(200).json({ message: 'Exam resumed', resumedAt: new Date(), totalAnswered: attempt.answers.filter(a => a.selectedOption !== null && a.selectedOption !== undefined).length });
  } catch (err) {
    console.error('resume error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ─────────────────────────────────────────────
// STEP 8: Multi-Device Session Control (S112)
// POST /api/attempts/:attemptId/register-device
// ─────────────────────────────────────────────
router.post('/:attemptId/register-device', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const { deviceSessionId } = req.body;
    if (!deviceSessionId) return res.status(400).json({ message: 'deviceSessionId required' });
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    if (attempt.status !== 'active') return res.status(403).json({ message: 'Attempt is not active' });

    // If another device already registered
    if (attempt.deviceSessionId && attempt.deviceSessionId !== deviceSessionId) {
      return res.status(403).json({
        message: 'Exam already open on another device. Close it first.',
        blocked: true
      });
    }

    attempt.deviceSessionId = deviceSessionId;
    await attempt.save();
    return res.status(200).json({ message: 'Device registered successfully', deviceSessionId });
  } catch (err) {
    console.error('register-device error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// ─────────────────────────────────────────────
// STEP 9: Exam Paper Encryption Key (N23)
// GET /api/attempts/:attemptId/paper-key
// ─────────────────────────────────────────────
router.get('/:attemptId/paper-key', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    if (attempt.status !== 'active') return res.status(403).json({ message: 'Attempt is not active' });

    // Generate a session-bound encryption key
    // Key = hash of attemptId + studentId + secret
    const crypto = require('crypto');
    const secret = process.env.JWT_SECRET || 'proverank_secret';
    const raw = `${attempt._id}:${attempt.studentId}:${secret}`;
    const encryptionKey = crypto.createHash('sha256').update(raw).digest('hex').substring(0, 32);

    return res.status(200).json({
      message: 'Paper key issued',
      key: encryptionKey,
      expiresIn: '200m'
    });
  } catch (err) {
    console.error('paper-key error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// GET /api/attempts/:attemptId — existing route (Phase 4.1)
router.get('/:attemptId', verifyToken, async (req, res) => {
  try {
    const attemptId = new mongoose.Types.ObjectId(req.params.attemptId);
    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: 'Attempt not found' });
    const a = attempt.toObject(); a.ipAddress = attempt.ipAddress; a.startTime = attempt.startedAt; return res.status(200).json({ attempt: a });
  } catch (err) {
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
ROUTESEOF

echo "Backend routes: src/routes/attemptRoutes.js updated."
node -c src/routes/attemptRoutes.js && echo "attemptRoutes.js syntax OK" || (echo "ROUTES SYNTAX ERROR — restoring backup"; cp backups/f59_$TS/attemptRoutes.js.bak src/routes/attemptRoutes.js; exit 1)

# ── 3) FRONTEND — full F59 answer-selection + mark-for-review system ──
mkdir -p "frontend/app/exam/[examId]/attempt"
cat > "frontend/app/exam/[examId]/attempt/page.tsx" << 'FRONTENDEOF'
'use client'
import { useState, useEffect, useCallback, useRef, useMemo } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { useAuth } from '@/lib/useAuth'
import { renderLatex } from '@/lib/renderLatex'

const API = process.env.NEXT_PUBLIC_API_URL || ''

// ── F58 §6.2 — deterministic color-per-subject palette (multi-exam safe: ──
// ── works for ANY subject name of ANY competitive exam, not just NEET) ──
const SUBJECT_PALETTE = ['#4D9FFF', '#00C48C', '#FFA502', '#A855F7', '#FF4757', '#FFD700', '#22D3EE', '#F472B6']
function subjectColor(name?: string) {
  if (!name) return SUBJECT_PALETTE[0]
  let h = 0
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) >>> 0
  return SUBJECT_PALETTE[h % SUBJECT_PALETTE.length]
}

const OPT_LETTERS = ['A', 'B', 'C', 'D']

export default function ExamAttempt() {
  const { user, loading } = useAuth('student')
  const params   = useParams()
  const router   = useRouter()
  const examId   = params?.examId as string

  // ── Core UI state ──────────────────────────────────────────
  const [lang, setLang]       = useState<'en'|'hi'>('en')
  const [dark, setDark]       = useState(true)
  const [fontSize, setFontSize] = useState(16) // §14 Text Accessibility
  const [mounted, setMounted] = useState(false)

  // ── Attempt / question state ───────────────────────────────
  const [attempt, setAttempt]     = useState<any>(null)
  const [questions, setQuestions] = useState<any[]>([])
  const [examMeta, setExamMeta]   = useState<any>({ sections: [], markingScheme: { correct: 4, incorrect: -1, unattempted: 0 }, duration: 200, title: '', status: '' })
  const [current, setCurrent]     = useState(0)
  const [answers, setAnswers]     = useState<Record<string, any>>({})
  const [flagged, setFlagged]     = useState<Set<string>>(new Set())
  const [visited, setVisited]     = useState<Set<string>>(new Set())
  const [selectedSubject, setSelectedSubject] = useState('All') // §11 Section Tabs
  const [errorState, setErrorState] = useState<{ code: string; message: string } | null>(null)
  const [initializing, setInitializing] = useState(true)

  // ── Timer ───────────────────────────────────────────────────
  const [timeLeft, setTimeLeft]   = useState(0)
  const [totalDurationSec, setTotalDurationSec] = useState(12000)
  const [timeExtNotif, setTimeExtNotif] = useState<string | null>(null) // Feature 32

  // ── Submit flow ─────────────────────────────────────────────
  const [submitting, setSubmitting] = useState(false)
  const [showSubmit, setShowSubmit] = useState(false)

  // ── Anti-cheat (unchanged behaviour, refs fixed) ────────────
  const [warnings, setWarnings] = useState(0)
  const [showFSWarning, setShowFSWarning] = useState(false)
  const [fsCompliant, setFsCompliant] = useState(true)
  const fsExitTimerRef = useRef<any>(null)
  const [focusLocked, setFocusLocked] = useState(true)
  const [warningHistory, setWarningHistory] = useState<{ type: string; at: string }[]>([])
  const integrityImpact = warnings === 0 ? 'none' : warnings === 1 ? 'low' : warnings === 2 ? 'medium' : 'high'

  // ── §15 Image zoom / lightbox ────────────────────────────────
  const [zoomImg, setZoomImg] = useState<string | null>(null)

  // ── §17 Question reporting ──────────────────────────────────
  const [showReportModal, setShowReportModal] = useState(false)
  const [reportReason, setReportReason] = useState('')
  const [reportMsg, setReportMsg] = useState<string | null>(null)
  const [reportSubmitting, setReportSubmitting] = useState(false)

  // ── §16 Per-question time tracking ──────────────────────────
  const [timeSpent, setTimeSpent] = useState<Record<string, number>>({})
  const questionEnterRef = useRef<number>(Date.now())

  // ── Mobile responsive nav drawer (§20) ──────────────────────
  const [showMobileNav, setShowMobileNav] = useState(false)

  // ── §2.5 Mini webcam preview (fixed at bottom of side panel) ────
  const videoRef = useRef<HTMLVideoElement>(null)
  const camStreamRef = useRef<MediaStream | null>(null)
  const [camReady, setCamReady] = useState(false)

  // ── F59 §8.5 Confidence tags, §5/§13.2 submit-lock, §8.1/§8.12 offline ──
  // ── retry queue, §6.5 saved-flash confirmation, §6.4 integer validation ──
  const [confidence, setConfidence] = useState<Record<string, 'high' | 'medium' | 'low' | null>>({})
  const [locked, setLocked] = useState(false)
  const [isOnline, setIsOnline] = useState(true)
  const [queuedCount, setQueuedCount] = useState(0)
  const [savedFlash, setSavedFlash] = useState<string | null>(null)
  const [integerError, setIntegerError] = useState<Record<string, string>>({})
  const retryQueueRef = useRef<Record<string, { selectedOption: any; timeTaken: number; confidence: any }>>({})

  // ── Socket (Feature 32 — time extension push; fixed & guarded) ──
  const socketRef = useRef<any>(null)

  const t = lang === 'en' ? {
    submit: 'Submit Exam', confirm: 'Confirm Submission',
    answered: 'Answered', unanswered: 'Not Answered', flagged: 'Marked', notVisited: 'Not Visited',
    saveNext: 'Save & Next', markReview: 'Mark for Review', unmarkReview: 'Unmark Review', clearResp: 'Clear Response',
    timeLeft: 'Time Remaining', question: 'Question',
    subWarn: 'You have unanswered questions. Submit anyway?',
    cancelSub: 'Cancel', confirmSub: 'Yes, Submit',
    all: 'All', report: 'Report', reportTitle: 'Report this question',
    reportPlaceholder: 'Describe the issue with this question (typo, wrong option, unclear image, etc.)',
    reportSubmit: 'Submit Report', reportSent: 'Question reported. Admin will review it.',
    avgTime: 'Avg/Q', integerHint: 'Enter your numeric answer',
    live: 'LIVE', practice: 'Practice', prev: 'Previous', next: 'Next',
    loadingExam: 'Loading exam...', errTitle: 'Could not start exam',
    backToExams: 'Back to My Exams', retry: 'Retry',
    fontSmaller: 'A−', fontBigger: 'A+',
    optionsSelected: 'Options Selected', integerInvalid: 'Enter a valid whole number',
    confidenceHigh: 'High', confidenceMed: 'Medium', confidenceLow: 'Low', confidenceLabel: 'Confidence',
    saved: 'Saved', queued: 'Offline — will sync', offline: 'Offline', online: 'Online',
    lockedTitle: 'Attempt Locked', lockedMsg: 'This exam attempt has already been submitted or locked. No further changes can be made.',
    viewResults: 'View Results / Back',
  } : {
    submit: 'परीक्षा जमा करें', confirm: 'जमा करने की पुष्टि',
    answered: 'उत्तर दिया', unanswered: 'उत्तर नहीं दिया', flagged: 'चिह्नित', notVisited: 'नहीं देखा',
    saveNext: 'सहेजें और आगे', markReview: 'समीक्षा के लिए', unmarkReview: 'समीक्षा हटाएं', clearResp: 'साफ करें',
    timeLeft: 'शेष समय', question: 'प्रश्न',
    subWarn: 'कुछ प्रश्नों का उत्तर नहीं दिया। क्या फिर भी जमा करें?',
    cancelSub: 'रद्द करें', confirmSub: 'हाँ, जमा करें',
    all: 'सभी', report: 'रिपोर्ट', reportTitle: 'इस प्रश्न को रिपोर्ट करें',
    reportPlaceholder: 'इस प्रश्न की समस्या बताएं (गलती, गलत विकल्प, अस्पष्ट इमेज आदि)',
    reportSubmit: 'रिपोर्ट भेजें', reportSent: 'प्रश्न रिपोर्ट हो गया। एडमिन इसे देखेगा।',
    avgTime: 'औसत/प्रश्न', integerHint: 'अपना संख्यात्मक उत्तर लिखें',
    live: 'लाइव', practice: 'अभ्यास', prev: 'पिछला', next: 'आगे',
    loadingExam: 'परीक्षा लोड हो रही है...', errTitle: 'परीक्षा शुरू नहीं हो पाई',
    backToExams: 'मेरी परीक्षाओं पर वापस जाएं', retry: 'दोबारा कोशिश करें',
    fontSmaller: 'A−', fontBigger: 'A+',
    optionsSelected: 'विकल्प चुने गए', integerInvalid: 'एक सही पूर्णांक लिखें',
    confidenceHigh: 'उच्च', confidenceMed: 'मध्यम', confidenceLow: 'कम', confidenceLabel: 'विश्वास',
    saved: 'सहेजा गया', queued: 'ऑफलाइन — बाद में सिंक होगा', offline: 'ऑफलाइन', online: 'ऑनलाइन',
    lockedTitle: 'प्रयास लॉक हो गया', lockedMsg: 'यह परीक्षा प्रयास पहले ही जमा/लॉक हो चुका है। अब कोई बदलाव संभव नहीं है।',
    viewResults: 'परिणाम देखें / वापस जाएं',
  }

  // ── §2.7 — genuinely distinct Mobile vs Desktop UI (not just a squeeze) ──
  const [isMobile, setIsMobile] = useState(false)
  const [showMobileTools, setShowMobileTools] = useState(false)

  useEffect(() => {
    setMounted(true)
    const sl = localStorage.getItem('pr_lang') as 'en'|'hi'; if (sl) setLang(sl)
    const st = localStorage.getItem('pr_theme'); if (st === 'light') setDark(false)
    const checkMobile = () => setIsMobile(window.innerWidth <= 820)
    checkMobile()
    window.addEventListener('resize', checkMobile)
    return () => window.removeEventListener('resize', checkMobile)
  }, [])

  const toggleLang = () => { const n = lang === 'en' ? 'hi' : 'en'; setLang(n); localStorage.setItem('pr_lang', n) }
  const toggleTheme = () => { const n = !dark; setDark(n); localStorage.setItem('pr_theme', n ? 'dark' : 'light') }

  // ── §1 Exam Availability & §24 State Preservation / §26 Persistence ──
  // Resume an existing active attempt if one exists (via /my-exams,
  // exactly like Instructions/Waiting-Room already do) instead of blindly
  // creating a brand-new Attempt document on every page load/refresh —
  // that previously burned an extra attempt slot on every reload.
  const initAttempt = useCallback(async () => {
    if (!user || !examId) return
    setInitializing(true)
    setErrorState(null)
    try {
      const h = { 'Content-Type': 'application/json', Authorization: `Bearer ${user!.token}` }

      let attemptId: string | null = null
      try {
        const mr = await fetch(`${API}/api/exams/my-exams`, { headers: h })
        const md = await mr.json()
        const mine = (md?.exams || []).find((x: any) => String(x._id) === String(examId))
        if (mine?.activeAttemptId) attemptId = mine.activeAttemptId
      } catch { /* non-fatal — fall through to start-attempt */ }

      if (!attemptId) {
        const r = await fetch(`${API}/api/exams/${examId}/start-attempt`, { method: 'POST', headers: h })
        const d = await r.json()
        if (!r.ok) {
          setErrorState({ code: d?.code || 'START_FAILED', message: d?.error || d?.message || t.errTitle })
          setInitializing(false)
          return
        }
        attemptId = d.attemptId
      }

      // Hydrate the authoritative attempt record (answers, flags) — §24/§26
      const ar = await fetch(`${API}/api/attempts/${attemptId}`, { headers: h })
      const ad = await ar.json()
      const attemptObj = ad?.attempt || ad
      setAttempt(attemptObj)

      const hydratedAnswers: Record<string, any> = {}
      const hydratedFlags = new Set<string>()
      const hydratedVisited = new Set<string>()
      const hydratedConfidence: Record<string, any> = {}
      ;(attemptObj?.answers || []).forEach((a: any) => {
        const qid = String(a.questionId)
        if (a.selectedOption !== null && a.selectedOption !== undefined) hydratedAnswers[qid] = a.selectedOption
        if (a.isMarkedForReview) hydratedFlags.add(qid)
        if (a.confidence) hydratedConfidence[qid] = a.confidence
        hydratedVisited.add(qid)
      })
      setAnswers(hydratedAnswers)
      setFlagged(hydratedFlags)
      setVisited(hydratedVisited)
      setConfidence(hydratedConfidence)

      // Questions (medium-aware, image-aware, subject-tagged) — §26
      const qr = await fetch(`${API}/api/exams/${examId}/questions`, { headers: h })
      const qd = await qr.json()
      if (!qr.ok) {
        setErrorState({ code: qd?.code || 'QUESTIONS_FAILED', message: qd?.message || t.errTitle })
        setInitializing(false)
        return
      }
      setQuestions(qd.questions || [])
      setExamMeta({
        sections: qd.sections || [],
        markingScheme: qd.markingScheme || { correct: 4, incorrect: -1, unattempted: 0 },
        duration: qd.duration || 200,
        title: qd.title || '',
        status: qd.status || ''
      })

      // Accurate authoritative timer — §16 / avoids hardcoded 200-min default
      try {
        const tr = await fetch(`${API}/api/attempts/${attemptId}/timer`, { headers: h })
        const td = await tr.json()
        if (tr.ok) {
          setTimeLeft(typeof td.remainingSec === 'number' ? td.remainingSec : (qd.duration || 200) * 60)
          setTotalDurationSec(typeof td.totalDurationSec === 'number' ? td.totalDurationSec : (qd.duration || 200) * 60)
        } else {
          setTotalDurationSec((qd.duration || 200) * 60)
          setTimeLeft((qd.duration || 200) * 60)
        }
      } catch {
        setTotalDurationSec((qd.duration || 200) * 60)
        setTimeLeft((qd.duration || 200) * 60)
      }

      setInitializing(false)
    } catch (e: any) {
      setErrorState({ code: 'NETWORK', message: e?.message || t.errTitle })
      setInitializing(false)
    }
  }, [user, examId])

  useEffect(() => { if (user && examId) initAttempt() }, [user, examId])

  // ── §2.5 Mini webcam preview — reuses the permission already granted ──
  // ── on the Webcam Check page (Phase 5.2). If denied/unavailable, this ──
  // ── silently hides itself and never blocks the exam screen. ──────────
  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({ video: { width: 240, height: 180 }, audio: false })
        if (cancelled) { stream.getTracks().forEach(tr => tr.stop()); return }
        camStreamRef.current = stream
        if (videoRef.current) videoRef.current.srcObject = stream
        setCamReady(true)
      } catch (e) { setCamReady(false) }
    })()
    return () => {
      cancelled = true
      camStreamRef.current?.getTracks().forEach(tr => tr.stop())
      camStreamRef.current = null
    }
  }, [])

  // ── Anti-cheat: tab switch + window blur + fullscreen enforcement ──
  useEffect(() => {
    const logWarning = (type: string) => setWarningHistory(h => [{ type, at: new Date().toLocaleTimeString() }, ...h].slice(0, 15))

    const onVis = () => {
      if (document.hidden && attempt) {
        logWarning('Tab Switch')
        if (user && attempt?._id) {
          fetch(`${API}/api/anticheat/tab-switch`, {
            method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.token}` },
            body: JSON.stringify({ attemptId: attempt._id, examId })
          }).then(r => r.json()).then(d => {
            if (typeof d?.warningCount === 'number') setWarnings(d.warningCount)
            if (d?.autoSubmitted) autoSubmit(true)
          }).catch(() => {
            setWarnings(w => { const next = w + 1; if (next >= 3) autoSubmit(true); return next })
          })
        }
      }
    }

    const onBlur = () => {
      if (attempt) {
        logWarning('Window Blur')
        if (user && attempt?._id) {
          fetch(`${API}/api/anticheat/window-blur`, {
            method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.token}` },
            body: JSON.stringify({ attemptId: attempt._id, examId })
          }).then(r => r.json()).then(d => {
            if (typeof d?.warningCount === 'number') setWarnings(d.warningCount)
            if (d?.autoSubmitted) autoSubmit(true)
          }).catch(() => {})
        }
      }
    }

    const requestFS = () => { try { document.documentElement.requestFullscreen?.() } catch (e) {} }
    const onFsChange = () => {
      const isFs = !!document.fullscreenElement
      setFsCompliant(isFs)
      setFocusLocked(isFs)
      if (!isFs && attempt) {
        setShowFSWarning(true)
        logWarning('Fullscreen Exit')
        fsExitTimerRef.current = setTimeout(() => {
          if (user && attempt?._id) {
            fetch(`${API}/api/anticheat/fullscreen-exit`, {
              method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.token}` },
              body: JSON.stringify({ attemptId: attempt._id, examId })
            }).then(r => r.json()).then(d => {
              if (typeof d?.warningCount === 'number') setWarnings(d.warningCount)
              if (d?.autoSubmitted) autoSubmit(true)
            }).catch(() => {})
          }
        }, 5000)
      } else {
        setShowFSWarning(false)
        if (fsExitTimerRef.current) { clearTimeout(fsExitTimerRef.current); fsExitTimerRef.current = null }
      }
    }

    requestFS()
    document.addEventListener('fullscreenchange', onFsChange)
    window.addEventListener('blur', onBlur)
    document.addEventListener('visibilitychange', onVis)
    return () => {
      document.removeEventListener('visibilitychange', onVis)
      document.removeEventListener('fullscreenchange', onFsChange)
      window.removeEventListener('blur', onBlur)
      if (fsExitTimerRef.current) clearTimeout(fsExitTimerRef.current)
    }
  }, [attempt, user, examId])

  // ── Timer countdown (now driven by authoritative totalDurationSec) ──
  useEffect(() => {
    if (!attempt || locked) return
    const iv = setInterval(() => {
      setTimeLeft(tl => {
        if (tl <= 1) { clearInterval(iv); autoSubmit(true); return 0 }
        return tl - 1
      })
    }, 1000)
    return () => clearInterval(iv)
  }, [attempt, locked])

  // ── Auto-save every 30s (§ Auto-Save Answers) ──────────────
  const autoSave = useCallback(async () => {
    if (!attempt?._id || !user || locked) return
    try {
      const r = await fetch(`${API}/api/attempts/${attempt._id}/auto-save`, {
        method: 'PATCH', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.token}` },
        body: JSON.stringify({
          answers: Object.entries(answers).map(([questionId, selectedOption]) => ({
            questionId, selectedOption, timeTaken: timeSpent[questionId] || 0, confidence: confidence[questionId] ?? null
          }))
        })
      })
      if (!r.ok) {
        const d = await r.json().catch(() => ({}))
        if (r.status === 403 && d?.code === 'ATTEMPT_LOCKED') setLocked(true)
      }
    } catch {}
  }, [attempt, answers, user, timeSpent, confidence, locked])

  useEffect(() => {
    if (!attempt || locked) return
    const iv = setInterval(() => autoSave(), 30000)
    return () => clearInterval(iv)
  }, [attempt, answers, autoSave])

  // ── §16 per-question time tracking: measure dwell time on each index ──
  useEffect(() => {
    questionEnterRef.current = Date.now()
    const enteredQ = questions[current]
    return () => {
      if (enteredQ) {
        const elapsed = Math.round((Date.now() - questionEnterRef.current) / 1000)
        if (elapsed > 0) setTimeSpent(ts => ({ ...ts, [enteredQ._id]: (ts[enteredQ._id] || 0) + elapsed }))
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [current, questions.length])

  // ── F59 §1/§8.1/§8.12 — reliable save: instant local UI update, then ──
  // ── network save. On failure (offline/network error) the answer is  ──
  // ── queued and auto-retried (flushQueue effect below) so nothing is ──
  // ── ever lost. On a 403 ATTEMPT_LOCKED response (§5/§13.2) the whole ──
  // ── screen locks immediately so the student can't keep "editing" an ──
  // ── attempt that the server has already closed. Uses `questionId` — ──
  // ── the verified real backend field name (attemptRoutes.js), not    ──
  // ── the shorthand `qId` used loosely in some spec text. ─────────────
  const persistAnswer = useCallback(async (qId: string, selectedOption: any, confidenceVal?: 'high' | 'medium' | 'low' | null) => {
    setVisited(v => new Set([...v, qId]))
    if (!attempt?._id || !user || locked) return
    const elapsedNow = Math.round((Date.now() - questionEnterRef.current) / 1000)
    const conf = confidenceVal !== undefined ? confidenceVal : (confidence[qId] ?? null)
    const payload = { selectedOption, timeTaken: elapsedNow, confidence: conf }
    try {
      const r = await fetch(`${API}/api/attempts/${attempt._id}/save-answer`, {
        method: 'PATCH', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.token}` },
        body: JSON.stringify({ questionId: qId, ...payload })
      })
      if (r.ok) {
        delete retryQueueRef.current[qId]
        setQueuedCount(Object.keys(retryQueueRef.current).length)
        setSavedFlash(qId)
        setTimeout(() => setSavedFlash(f => (f === qId ? null : f)), 900)
      } else {
        const d = await r.json().catch(() => ({}))
        if (r.status === 403 && d?.code === 'ATTEMPT_LOCKED') {
          setLocked(true)
          retryQueueRef.current = {}
          setQueuedCount(0)
        } else {
          retryQueueRef.current[qId] = payload
          setQueuedCount(Object.keys(retryQueueRef.current).length)
        }
      }
    } catch {
      // Network unreachable — queue for auto-retry, never lose the answer
      retryQueueRef.current[qId] = payload
      setQueuedCount(Object.keys(retryQueueRef.current).length)
    }
  }, [attempt, user, locked, confidence])

  // ── F59 §8.1/§8.12 — background flush of the offline/retry queue ──
  const flushQueue = useCallback(async () => {
    if (!attempt?._id || !user || locked) return
    const entries = Object.entries(retryQueueRef.current)
    if (entries.length === 0) return
    for (const [qId, payload] of entries) {
      try {
        const r = await fetch(`${API}/api/attempts/${attempt._id}/save-answer`, {
          method: 'PATCH', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.token}` },
          body: JSON.stringify({ questionId: qId, ...payload })
        })
        if (r.ok) {
          delete retryQueueRef.current[qId]
        } else if (r.status === 403) {
          const d = await r.json().catch(() => ({}))
          if (d?.code === 'ATTEMPT_LOCKED') { setLocked(true); retryQueueRef.current = {} }
        }
      } catch { /* still offline — will retry next cycle */ }
    }
    setQueuedCount(Object.keys(retryQueueRef.current).length)
  }, [attempt, user, locked])

  useEffect(() => {
    const iv = setInterval(flushQueue, 5000)
    const onOnline = () => { setIsOnline(true); flushQueue() }
    const onOffline = () => setIsOnline(false)
    setIsOnline(typeof navigator !== 'undefined' ? navigator.onLine : true)
    window.addEventListener('online', onOnline)
    window.addEventListener('offline', onOffline)
    return () => {
      clearInterval(iv)
      window.removeEventListener('online', onOnline)
      window.removeEventListener('offline', onOffline)
    }
  }, [flushQueue])

  const selectOption = (question: any, letter: string) => {
    if (!question || locked) return
    const qId = question._id
    const prev = answers[qId]
    let nextVal: any
    if (question.type === 'MSQ') {
      const arr = Array.isArray(prev) ? [...prev] : []
      const idx = arr.indexOf(letter)
      if (idx >= 0) arr.splice(idx, 1); else arr.push(letter)
      nextVal = arr
    } else {
      // §8.4 Quick Change Answer — a new SCQ choice automatically replaces the old one
      nextVal = letter
    }
    setAnswers(a => ({ ...a, [qId]: nextVal }))
    persistAnswer(qId, nextVal)
  }

  // §6.1 Double-click deselect (SCQ only, optional accessibility behavior)
  const doubleClickDeselect = (question: any, letter: string) => {
    if (!question || locked || question.type === 'MSQ') return
    if (answers[question._id] === letter) clearResponse(question)
  }

  // §6.4 Integer validation — numeric-only input, inline error, blocked save until valid
  const setIntegerAnswer = (question: any, value: string) => {
    if (!question || locked) return
    const cleaned = value.replace(/(?!^-)[^0-9]/g, '')
    setAnswers(a => ({ ...a, [question._id]: cleaned }))
    if (cleaned && !/^-?\d+$/.test(cleaned)) {
      setIntegerError(e => ({ ...e, [question._id]: t.integerInvalid }))
    } else {
      setIntegerError(e => { const n = { ...e }; delete n[question._id]; return n })
    }
  }
  const commitIntegerAnswer = (question: any) => {
    if (!question || locked) return
    const val = answers[question._id]
    if (val !== undefined && val !== null && val !== '' && !/^-?\d+$/.test(String(val))) return
    persistAnswer(question._id, val === '' ? null : val)
  }

  const clearResponse = (question: any) => {
    if (!question || locked) return
    setAnswers(a => { const n = { ...a }; delete n[question._id]; return n })
    setIntegerError(e => { const n = { ...e }; delete n[question._id]; return n })
    persistAnswer(question._id, null)
  }

  // §8.5 Confidence Tag — toggle High/Medium/Low; preserves the existing answer untouched
  const setConfidenceTag = (question: any, level: 'high' | 'medium' | 'low') => {
    if (!question || locked) return
    const qId = question._id
    const newVal = confidence[qId] === level ? null : level
    setConfidence(c => ({ ...c, [qId]: newVal }))
    persistAnswer(qId, answers[qId] ?? null, newVal)
  }

  const toggleFlag = async (question: any) => {
    if (!question || locked) return
    const qId = question._id
    setFlagged(f => { const n = new Set(f); n.has(qId) ? n.delete(qId) : n.add(qId); return n })
    if (!attempt?._id || !user) return
    try {
      const r = await fetch(`${API}/api/attempts/${attempt._id}/bookmark`, {
        method: 'PATCH', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.token}` },
        body: JSON.stringify({ questionId: qId })
      })
      const d = await r.json().catch(() => ({}))
      if (r.ok && typeof d?.isMarkedForReview === 'boolean') {
        // reconcile with server truth in case of a race
        setFlagged(f => { const n = new Set(f); d.isMarkedForReview ? n.add(qId) : n.delete(qId); return n })
      } else if (r.status === 403 && d?.code === 'ATTEMPT_LOCKED') {
        setLocked(true)
      }
    } catch {}
  }

  const autoSubmit = async (isAuto: boolean = false) => {
    if (submitting) return
    setSubmitting(true)
    if (!attempt?._id || !user) { setSubmitting(false); return }
    try {
      const r = await fetch(`${API}/api/attempts/${attempt._id}/submit`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user!.token}` },
        body: JSON.stringify({ isAutoSubmit: isAuto })
      })
      const d = await r.json()
      if (r.ok) router.push(`/exam/${examId}/result?attemptId=${attempt._id}`)
    } catch {}
    finally { setSubmitting(false) }
  }

  // ── §17 Question Reporting (student-facing, does not touch answer state) ──
  const submitReport = async () => {
    const q = questions[current]
    if (!q || !reportReason.trim() || !user) return
    setReportSubmitting(true)
    try {
      const r = await fetch(`${API}/api/questions/${q._id}/report`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${user.token}` },
        body: JSON.stringify({ reason: reportReason.trim() })
      })
      const d = await r.json()
      setReportMsg(r.ok ? t.reportSent : (d?.message || 'Error'))
    } catch {
      setReportMsg('Network error')
    } finally {
      setReportSubmitting(false)
      setShowReportModal(false)
      setReportReason('')
      setTimeout(() => setReportMsg(null), 4000)
    }
  }

  // ── §10 status derivation — generalized for MSQ arrays. §4.3/§7.4 ──
  // ── keeps "answered + flagged" as its OWN distinct state instead of ──
  // ── collapsing to just "flagged" (which used to hide the fact that ──
  // ── the question was actually answered). ──────────────────────────
  const getStatus = (qId: string): 'answered' | 'answered-flagged' | 'flagged' | 'unanswered' | 'unvisited' => {
    const ans = answers[qId]
    const hasAns = Array.isArray(ans) ? ans.length > 0 : (ans !== undefined && ans !== null && ans !== '')
    const isFlagged = flagged.has(qId)
    if (hasAns && isFlagged) return 'answered-flagged'
    if (hasAns) return 'answered'
    if (isFlagged) return 'flagged'
    if (visited.has(qId)) return 'unanswered'
    return 'unvisited'
  }

  // §6.2/§8.7 — colorblind-safe status icons shown alongside color
  const STATUS_ICON: Record<string, string> = { answered: '✓', 'answered-flagged': '✓⚑', flagged: '⚑', unanswered: '!', unvisited: '' }

  const goTo = (idx: number) => {
    setCurrent(idx)
    const qq = questions[idx]
    if (qq) setVisited(v => new Set([...v, qq._id]))
  }

  // ── §11 dynamic subject/section tabs — works for ANY competitive exam ──
  const subjects = useMemo(() => {
    const set = new Set<string>()
    questions.forEach(q => { if (q?.subject) set.add(q.subject) })
    return Array.from(set)
  }, [questions])

  const filteredIndices = useMemo(() => {
    if (selectedSubject === 'All') return questions.map((_, i) => i)
    return questions.map((q, i) => ({ q, i })).filter(x => x.q?.subject === selectedSubject).map(x => x.i)
  }, [questions, selectedSubject])

  const goRelative = (dir: 1 | -1) => {
    const pos = filteredIndices.indexOf(current)
    if (pos === -1) { goTo(Math.max(0, Math.min(questions.length - 1, current + dir))); return }
    const nextPos = pos + dir
    if (nextPos >= 0 && nextPos < filteredIndices.length) goTo(filteredIndices[nextPos])
  }

  const h = Math.floor(timeLeft / 3600), m = Math.floor((timeLeft % 3600) / 60), s = timeLeft % 60
  const fmt = (n: number) => String(n).padStart(2, '0')
  const timerPct = totalDurationSec ? (timeLeft / totalDurationSec) * 100 : 100
  const timerClass = timerPct > 33 ? 'timer-safe' : timerPct > 10 ? 'timer-warning' : 'timer-danger'

  const q = questions[current]
  const isMSQ = q?.type === 'MSQ'
  const isInteger = q?.type === 'Integer'
  const opts = (!isInteger && q) ? OPT_LETTERS : []

  const answeredCount = Object.values(answers).filter(v => Array.isArray(v) ? v.length > 0 : (v !== undefined && v !== null && v !== '')).length
  const totalTimeSpent = Object.values(timeSpent).reduce((a, b) => a + b, 0)
  const avgTimeSec = answeredCount > 0 ? Math.round(totalTimeSpent / Math.max(1, Object.keys(timeSpent).length)) : 0

  // ── Feature 32: Time Extension Socket Listener (fixed — was referencing ──
  // ── an undefined `socket`/`attemptIdRef`, which crashed this entire page ──
  // ── on every render. Now a real, guarded, self-contained connection. ──
  useEffect(() => {
    if (!attempt?._id || !user?.token) return
    let cancelled = false
    ;(async () => {
      try {
        const { io } = await import('socket.io-client')
        if (cancelled) return
        const sock = io(API || undefined, { auth: { token: user.token }, transports: ['websocket', 'polling'] })
        socketRef.current = sock
        const studentId = attempt?.studentId || user?.id || user?._id
        sock.on('connect', () => {
          if (studentId) sock.emit('join', `student:${studentId}`)
          if (attempt?._id) sock.emit('join', `attempt:${attempt._id}`)
        })
        sock.on('time:extend', (data: any) => {
          const extraSec = (data?.extraMinutes || 0) * 60
          if (data?.isUndo) {
            setTimeLeft(prev => Math.max(0, prev - Math.abs(extraSec)))
            setTotalDurationSec(prev => Math.max(0, prev - Math.abs(extraSec)))
            setTimeExtNotif(`Admin cancelled a time extension (${data.extraMinutes} min removed)`)
          } else {
            setTimeLeft(prev => prev + extraSec)
            setTotalDurationSec(prev => prev + extraSec)
            setTimeExtNotif(data?.message || `Admin has given you +${data?.extraMinutes} minutes`)
          }
          setTimeout(() => setTimeExtNotif(null), 8000)
        })
      } catch (e) { /* socket.io-client unavailable — feature degrades silently, page still works */ }
    })()
    return () => {
      cancelled = true
      try { socketRef.current?.disconnect() } catch {}
      socketRef.current = null
    }
  }, [attempt?._id, user?.token])

  if (loading || !mounted) {
    return <div style={{ minHeight: '100vh', background: '#000A18', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#4D9FFF', fontFamily: 'Inter,sans-serif' }}>{t.loadingExam}</div>
  }

  if (initializing) {
    return <div style={{ minHeight: '100vh', background: '#000A18', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#4D9FFF', fontFamily: 'Inter,sans-serif' }}>{t.loadingExam}</div>
  }

  if (errorState) {
    return (
      <div style={{ minHeight: '100vh', background: '#000A18', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 20 }}>
        <div style={{ maxWidth: 420, textAlign: 'center', color: '#E8F4FF', fontFamily: 'Inter,sans-serif' }}>
          <div style={{ fontSize: 44, marginBottom: 12 }}>⚠️</div>
          <div style={{ fontSize: 18, fontWeight: 800, marginBottom: 8 }}>{t.errTitle}</div>
          <div style={{ fontSize: 13, color: '#6B8BAF', marginBottom: 20 }}>{errorState.message}</div>
          <div style={{ display: 'flex', gap: 10, justifyContent: 'center' }}>
            <button onClick={() => router.push('/dashboard/exams')} style={{ padding: '10px 18px', borderRadius: 10, border: '1px solid rgba(77,159,255,0.3)', background: 'transparent', color: '#E8F4FF', cursor: 'pointer' }}>{t.backToExams}</button>
            <button onClick={initAttempt} style={{ padding: '10px 18px', borderRadius: 10, border: 'none', background: 'linear-gradient(135deg,#4D9FFF,#0055CC)', color: '#fff', fontWeight: 700, cursor: 'pointer' }}>{t.retry}</button>
          </div>
        </div>
      </div>
    )
  }

  // ── theme colors — self-contained (this screen intentionally does not ──
  // ── depend on StudentShell so it stays reliable during a locked exam) ──
  const tm   = dark ? '#E8F4FF' : '#0F172A'
  const ts   = dark ? '#6B8BAF' : '#51607A'
  const card = dark ? 'rgba(0,22,40,0.85)' : 'rgba(255,255,255,0.92)'
  const bord = dark ? 'rgba(77,159,255,0.2)' : 'rgba(37,99,235,0.28)'
  const pageBg = dark ? '#000A18' : '#F4F7FB'
  const asideBg = dark ? 'rgba(0,10,24,0.9)' : 'rgba(255,255,255,0.96)'
  const headerBg = dark ? 'rgba(0,10,24,0.95)' : 'rgba(255,255,255,0.97)'

  return (
    <div style={{ minHeight: '100vh', background: pageBg, color: tm, fontFamily: 'Inter,sans-serif', display: 'flex', flexDirection: 'column' }}
      onContextMenu={e => e.preventDefault()}>
      <style>{`
        @keyframes pulse{0%,100%{opacity:.4}50%{opacity:1}}
        .tbtn{padding:6px 14px;border-radius:20px;border:1.5px solid rgba(77,159,255,0.4);background:rgba(0,22,40,0.5);color:#E8F4FF;font-size:13px;font-weight:600;cursor:pointer;transition:all 0.2s;}
        .tbtn.active{background:rgba(77,159,255,0.25);border-color:#4D9FFF;}
        .lb{padding:12px 24px;border-radius:10px;border:none;background:linear-gradient(135deg,#4D9FFF,#0055CC);color:white;font-size:14px;font-weight:700;cursor:pointer;transition:all 0.3s;}
        .lb:hover{transform:translateY(-1px);box-shadow:0 6px 20px rgba(77,159,255,0.4);}
        select option{background:#001628;}
        .examAside{ transition:transform .3s ease; }
        .examMobileNavBtn{ display:none; }
        .imgZoomBtn{ position:absolute; top:6px; right:6px; background:rgba(0,0,0,0.6); color:#fff; border:none; border-radius:6px; padding:4px 8px; font-size:12px; cursor:pointer; }
        .examOption:not(.selected):hover{ border-color:#7db8ff !important; }
        @media (max-width:820px){
          .examAside{ position:fixed !important; top:62px; bottom:0; left:0; width:78vw; max-width:300px; transform:translateX(-105%); z-index:150; box-shadow:8px 0 30px rgba(0,0,0,.5); }
          .examAside.open{ transform:translateX(0); }
          .examMobileNavBtn{ display:flex; position:fixed; bottom:78px; right:18px; z-index:140; width:50px; height:50px; border-radius:50%; align-items:center; justify-content:center; background:linear-gradient(135deg,#4D9FFF,#0055CC); color:#fff; border:none; font-size:19px; box-shadow:0 6px 20px rgba(0,0,0,.4); cursor:pointer; }
          .examHeaderRow{ flex-wrap:wrap; height:auto !important; padding:8px 0 !important; gap:8px !important; }
        }
      `}</style>

      {/* Watermark — §12: opacity ~0.04, diagonal, tiled, non-selectable */}
      <div className="exam-watermark" style={{ color: dark ? 'rgba(77,159,255,0.04)' : 'rgba(37,99,235,0.05)', display: 'flex', flexWrap: 'wrap', alignContent: 'center', gap: '18vw 10vw', fontSize: 'clamp(10px,2vw,16px)' }}>
        {Array.from({ length: 9 }).map((_, i) => (
          <span key={i}>ProveRank • {lang === 'en' ? 'Student' : 'छात्र'}</span>
        ))}
      </div>

      {/* Mobile question-nav floating button */}
      <button className="examMobileNavBtn" onClick={() => setShowMobileNav(v => !v)}>🔢</button>
      {showMobileNav && <div onClick={() => setShowMobileNav(false)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', zIndex: 140 }} />}

      {/* ── HEADER — Desktop: full inline bar. Mobile: compact bar + ── */}
      {/* ── expandable tools panel (a distinct mobile-first design). ── */}
      <header style={{ background: headerBg, borderBottom: `1px solid ${bord}`, padding: '0 16px', position: 'sticky', top: 0, zIndex: 100, display: 'flex', flexDirection: 'column' }}>
        {!isMobile ? (
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', height: 56, gap: 12 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <svg width={24} height={24} viewBox="0 0 64 64"><polygon points={[...Array(6)].map((_, i) => { const a = (Math.PI / 180) * (60 * i - 30); return `${32 + 26 * Math.cos(a)},${32 + 26 * Math.sin(a)}` }).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2" /><text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="12" fontWeight="700" fill="#4D9FFF">PR</text></svg>
              <span style={{ fontFamily: 'Playfair Display,serif', fontWeight: 700, color: '#4D9FFF', fontSize: 15 }}>{examMeta.title || 'ProveRank'}</span>
              {examMeta.status && (
                <span style={{ fontSize: 10, padding: '2px 8px', borderRadius: 20, background: examMeta.status === 'live' ? '#3a1414' : '#123b1e', color: examMeta.status === 'live' ? '#ff8080' : '#7CFC9C' }}>
                  {examMeta.status === 'live' ? `🔴 ${t.live}` : `🕓 ${t.practice}`}
                </span>
              )}
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: 8, background: 'rgba(77,159,255,0.08)', border: `1px solid ${bord}`, borderRadius: 10, padding: '8px 16px' }}>
              <span style={{ fontSize: 14 }}>⏱</span>
              <span style={{ fontFamily: 'Playfair Display,serif', fontSize: 20, fontWeight: 700, color: timerPct < 10 ? '#FF4757' : timerPct < 33 ? '#FFA502' : '#4D9FFF' }}>
                {fmt(h)}:{fmt(m)}:{fmt(s)}
              </span>
              <span style={{ color: ts, fontSize: 12 }}>{t.timeLeft}</span>
            </div>

            <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
              <button onClick={toggleLang} style={{ padding: '5px 10px', borderRadius: 20, border: `1px solid ${bord}`, background: 'transparent', color: tm, cursor: 'pointer', fontSize: 11 }}>{lang === 'hi' ? 'EN' : 'हिं'}</button>
              <button onClick={toggleTheme} style={{ padding: '5px 10px', borderRadius: 20, border: `1px solid ${bord}`, background: 'transparent', color: tm, cursor: 'pointer', fontSize: 12 }}>{dark ? '☀️' : '🌙'}</button>
              {warnings > 0 && <span className="badge badge-red">⚠️ {warnings}/3</span>}
              {!isOnline && <span style={{ fontSize: 10, padding: '2px 8px', borderRadius: 20, background: '#3a1414', color: '#ff8080' }}>📡 {t.offline}</span>}
              {queuedCount > 0 && <span style={{ fontSize: 10, padding: '2px 8px', borderRadius: 20, background: '#3a2a00', color: '#f2d38a' }}>⏳ {queuedCount}</span>}
              <span style={{ fontSize: 10, padding: '2px 8px', borderRadius: 20, background: integrityImpact === 'none' ? '#123b1e' : integrityImpact === 'low' ? '#3a2a00' : integrityImpact === 'medium' ? '#3a2200' : '#3a1414', color: integrityImpact === 'none' ? '#7CFC9C' : integrityImpact === 'low' ? '#f2d38a' : integrityImpact === 'medium' ? '#ffb066' : '#ff8080' }}>
                🛡️ {integrityImpact}
              </span>
              <button className="lb" style={{ background: 'linear-gradient(135deg,#FF4757,#CC2233)', boxShadow: '0 4px 15px rgba(255,71,87,0.3)' }} onClick={() => setShowSubmit(true)}>
                {t.submit}
              </button>
            </div>
          </div>
        ) : (
          <>
            {/* ── Mobile header: compact single row — logo · timer · ⚙ · submit ── */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', height: 54, gap: 8 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, minWidth: 0 }}>
                <svg width={22} height={22} viewBox="0 0 64 64" style={{ flexShrink: 0 }}><polygon points={[...Array(6)].map((_, i) => { const a = (Math.PI / 180) * (60 * i - 30); return `${32 + 26 * Math.cos(a)},${32 + 26 * Math.sin(a)}` }).join(' ')} fill="none" stroke="#4D9FFF" strokeWidth="2" /><text x="32" y="37" textAnchor="middle" fontFamily="Playfair Display,serif" fontSize="12" fontWeight="700" fill="#4D9FFF">PR</text></svg>
                {examMeta.status && (
                  <span style={{ fontSize: 9, padding: '2px 6px', borderRadius: 20, background: examMeta.status === 'live' ? '#3a1414' : '#123b1e', color: examMeta.status === 'live' ? '#ff8080' : '#7CFC9C', flexShrink: 0 }}>
                    {examMeta.status === 'live' ? '🔴' : '🕓'}
                  </span>
                )}
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 5, background: 'rgba(77,159,255,0.08)', border: `1px solid ${bord}`, borderRadius: 8, padding: '5px 10px', flexShrink: 0 }}>
                <span style={{ fontFamily: 'Playfair Display,serif', fontSize: 15, fontWeight: 700, color: timerPct < 10 ? '#FF4757' : timerPct < 33 ? '#FFA502' : '#4D9FFF' }}>
                  {fmt(h)}:{fmt(m)}:{fmt(s)}
                </span>
              </div>
              <button onClick={() => setShowMobileTools(v => !v)} style={{ width: 34, height: 34, borderRadius: 10, border: `1px solid ${bord}`, background: showMobileTools ? 'rgba(77,159,255,0.15)' : 'transparent', color: tm, fontSize: 15, flexShrink: 0 }}>⚙</button>
              <button style={{ padding: '7px 12px', borderRadius: 10, border: 'none', background: 'linear-gradient(135deg,#FF4757,#CC2233)', color: '#fff', fontWeight: 700, fontSize: 12, flexShrink: 0 }} onClick={() => setShowSubmit(true)}>
                {t.submit}
              </button>
            </div>
            {/* ── Mobile expandable tools panel ── */}
            {showMobileTools && (
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', padding: '10px 0 12px' }}>
                <button onClick={toggleLang} style={{ padding: '6px 12px', borderRadius: 20, border: `1px solid ${bord}`, background: 'transparent', color: tm, fontSize: 12 }}>{lang === 'hi' ? 'EN' : 'हिं'}</button>
                <button onClick={toggleTheme} style={{ padding: '6px 12px', borderRadius: 20, border: `1px solid ${bord}`, background: 'transparent', color: tm, fontSize: 13 }}>{dark ? '☀️' : '🌙'}</button>
                <button onClick={() => setFontSize(f => Math.max(13, f - 1))} style={{ padding: '6px 12px', borderRadius: 20, border: `1px solid ${bord}`, background: 'transparent', color: tm, fontSize: 12 }}>A−</button>
                <button onClick={() => setFontSize(f => Math.min(22, f + 1))} style={{ padding: '6px 12px', borderRadius: 20, border: `1px solid ${bord}`, background: 'transparent', color: tm, fontSize: 12 }}>A+</button>
                {warnings > 0 && <span className="badge badge-red">⚠️ {warnings}/3</span>}
                {!isOnline && <span style={{ fontSize: 10, padding: '3px 9px', borderRadius: 20, background: '#3a1414', color: '#ff8080' }}>📡 {t.offline}</span>}
                {queuedCount > 0 && <span style={{ fontSize: 10, padding: '3px 9px', borderRadius: 20, background: '#3a2a00', color: '#f2d38a' }}>⏳ {queuedCount}</span>}
                <span style={{ fontSize: 10, padding: '3px 9px', borderRadius: 20, background: focusLocked ? '#123b1e' : '#3a1414', color: focusLocked ? '#7CFC9C' : '#ff8080' }}>
                  {focusLocked ? '🔒 Locked' : '🔓 Lost'}
                </span>
                <span style={{ fontSize: 10, padding: '3px 9px', borderRadius: 20, background: integrityImpact === 'none' ? '#123b1e' : integrityImpact === 'low' ? '#3a2a00' : integrityImpact === 'medium' ? '#3a2200' : '#3a1414', color: integrityImpact === 'none' ? '#7CFC9C' : integrityImpact === 'low' ? '#f2d38a' : integrityImpact === 'medium' ? '#ffb066' : '#ff8080' }}>
                  🛡️ {integrityImpact}
                </span>
              </div>
            )}
          </>
        )}
        <div style={{ height: 4, background: 'rgba(77,159,255,0.1)' }}>
          <div className={timerClass} style={{ height: '100%', width: `${Math.max(0, Math.min(100, timerPct))}%`, borderRadius: 2, transition: 'width 1s linear' }} />
        </div>
      </header>

      {/* ── BODY ────────────────────────────────────────────────── */}
      <div style={{ display: 'flex', flex: 1, overflow: 'hidden' }}>
        {/* LEFT: Section tabs + legend + Nav Grid (5-column, §10) */}
        <aside className={`examAside ${showMobileNav ? 'open' : ''}`} style={{ width: 240, background: asideBg, borderRight: `1px solid ${bord}`, flexShrink: 0, display: 'flex', flexDirection: 'column' }}>
          {/* Scrollable section: tabs, legend, counter, nav grid — §1.9 §1.11 §1.12 */}
          <div style={{ flex: 1, overflowY: 'auto', padding: '16px 12px', minHeight: 0 }}>
            <div style={{ display: 'flex', gap: 6, marginBottom: 16, flexWrap: 'wrap' }}>
              <button className={`tbtn ${selectedSubject === 'All' ? 'active' : ''}`} style={{ fontSize: 11, padding: '4px 8px' }} onClick={() => setSelectedSubject('All')}>{t.all}</button>
              {subjects.map(sub => (
                <button key={sub} className={`tbtn ${selectedSubject === sub ? 'active' : ''}`} style={{ fontSize: 11, padding: '4px 8px', borderColor: subjectColor(sub) }} onClick={() => setSelectedSubject(sub)}>{sub}</button>
              ))}
            </div>

            {/* §1.9 — explicit question counter in side panel */}
            <div style={{ fontFamily: 'Playfair Display,serif', fontWeight: 700, fontSize: 14, color: tm, marginBottom: 12, textAlign: 'center', padding: '6px 0', border: `1px solid ${bord}`, borderRadius: 8 }}>
              {t.question} {current + 1} / {questions.length || 0}
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 4, marginBottom: 16 }}>
              {[['answered', '#00C48C', t.answered, '✓'], ['unanswered', '#FF4757', t.unanswered, '!'], ['flagged', '#A855F7', t.flagged, '⚑'], ['answered-flagged', 'linear-gradient(135deg,#00C48C 50%,#A855F7 50%)', `${t.answered} + ${t.flagged}`, '✓⚑'], ['unvisited', 'rgba(77,159,255,0.1)', t.notVisited, '']].map(([cls, clr, lbl, ic]) => (
                <div key={String(cls)} style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 11, color: ts }}>
                  <div style={{ width: 12, height: 12, borderRadius: 3, background: String(clr), display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 7, color: '#fff' }}>{ic}</div>
                  {lbl}
                </div>
              ))}
            </div>

            <div style={{ fontSize: 11, color: ts, marginBottom: 8 }}>{t.avgTime}: {avgTimeSec}s</div>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5,1fr)', gap: 4 }}>
              {questions.map((q2: any, i: number) => {
                const st2 = getStatus(q2._id)
                const isCombined = st2 === 'answered-flagged'
                return (
                  <div key={q2._id || i}
                    className={`qnum ${isCombined ? '' : st2} ${i === current ? 'current' : ''}`}
                    style={isCombined && i !== current ? { background: 'linear-gradient(135deg,#00C48C 50%,#A855F7 50%)', color: '#fff', position: 'relative' } : { position: 'relative' }}
                    onClick={() => { goTo(i); setShowMobileNav(false) }} title={`${q2.subject || ''} — ${st2}`}>
                    {i + 1}
                    {STATUS_ICON[st2] && i !== current && (
                      <span style={{ position: 'absolute', top: -4, right: -4, fontSize: 8, background: '#00121F', border: '1px solid rgba(255,255,255,0.4)', borderRadius: '50%', width: 13, height: 13, display: 'flex', alignItems: 'center', justifyContent: 'center', lineHeight: 1, color: '#fff' }}>
                        {STATUS_ICON[st2]}
                      </span>
                    )}
                  </div>
                )
              })}
            </div>
          </div>

          {/* §2.5 §18.5 — Mini webcam, fixed at bottom of side panel, non-scrolling */}
          <div style={{ padding: 10, borderTop: `1px solid ${bord}`, flexShrink: 0 }}>
            <div style={{ position: 'relative', borderRadius: 10, overflow: 'hidden', border: `1px solid ${bord}`, background: '#000', height: 90 }}>
              <video ref={videoRef} autoPlay muted playsInline style={{ width: '100%', height: '100%', objectFit: 'cover', display: camReady ? 'block' : 'none' }} />
              {!camReady && (
                <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#556', fontSize: 20 }}>📷</div>
              )}
              <span style={{ position: 'absolute', top: 6, left: 6, display: 'flex', alignItems: 'center', gap: 4, fontSize: 9, fontWeight: 700, color: '#fff', background: 'rgba(0,0,0,0.55)', padding: '2px 7px', borderRadius: 20 }}>
                <span style={{ width: 6, height: 6, borderRadius: '50%', background: camReady ? '#FF4757' : '#666', animation: camReady ? 'pulse 1.4s infinite' : 'none' }} />
                {camReady ? 'REC' : 'OFF'}
              </span>
              {!isOnline && (
                <span style={{ position: 'absolute', bottom: 6, left: 6, fontSize: 9, fontWeight: 700, color: '#fff', background: 'rgba(255,71,87,0.85)', padding: '2px 7px', borderRadius: 20 }}>📡 {t.offline}</span>
              )}
              {queuedCount > 0 && (
                <span style={{ position: 'absolute', bottom: 6, right: 6, fontSize: 9, fontWeight: 700, color: '#fff', background: 'rgba(255,165,2,0.85)', padding: '2px 7px', borderRadius: 20 }}>⏳ {queuedCount}</span>
              )}
            </div>
          </div>
        </aside>

        {/* RIGHT: Question + Options */}
        <main className="examMain" style={{ flex: 1, overflowY: 'auto', padding: isMobile ? '14px 14px 100px' : '24px' }}>
          {/* ── Mobile-only: horizontal-scroll subject strip (desktop uses the sidebar tabs) ── */}
          {isMobile && subjects.length > 0 && (
            <div style={{ display: 'flex', gap: 6, overflowX: 'auto', marginBottom: 14, paddingBottom: 4, WebkitOverflowScrolling: 'touch' }}>
              <button className={`tbtn ${selectedSubject === 'All' ? 'active' : ''}`} style={{ fontSize: 12, padding: '6px 12px', flexShrink: 0 }} onClick={() => setSelectedSubject('All')}>{t.all}</button>
              {subjects.map(sub => (
                <button key={sub} className={`tbtn ${selectedSubject === sub ? 'active' : ''}`} style={{ fontSize: 12, padding: '6px 12px', flexShrink: 0, borderColor: subjectColor(sub) }} onClick={() => setSelectedSubject(sub)}>{sub}</button>
              ))}
            </div>
          )}

          {!isMobile && (
            <div style={{ display: 'flex', gap: 8, marginBottom: 16, flexWrap: 'wrap', alignItems: 'center' }}>
              <span style={{ fontSize: 11, color: ts }}>{t.fontSmaller}</span>
              <button onClick={() => setFontSize(f => Math.max(13, f - 1))} className="tbtn" style={{ padding: '2px 10px', fontSize: 12 }}>A−</button>
              <button onClick={() => setFontSize(f => Math.min(22, f + 1))} className="tbtn" style={{ padding: '2px 10px', fontSize: 12 }}>A+</button>
              <span style={{ fontSize: 11, color: ts }}>{fontSize}px</span>
            </div>
          )}

          {/* Question Card */}
          <div style={{ background: card, border: `1px solid ${bord}`, borderRadius: isMobile ? 14 : 16, padding: isMobile ? '18px' : '28px', marginBottom: isMobile ? 14 : 20, minHeight: isMobile ? 120 : 200, backdropFilter: 'blur(12px)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: isMobile ? 10 : 16, flexWrap: 'wrap', gap: 8 }}>
              <span style={{ color: '#4D9FFF', fontWeight: 700, fontSize: isMobile ? 12 : 14 }}>{t.question} {current + 1} / {questions.length}</span>
              {q?.subject && (
                <span style={{ fontSize: 11, fontWeight: 700, padding: '3px 10px', borderRadius: 20, background: `${subjectColor(q.subject)}22`, color: subjectColor(q.subject) }}>{q.subject}</span>
              )}
              <span className="badge badge-blue">+{examMeta.markingScheme?.correct ?? 4} / {examMeta.markingScheme?.incorrect ?? -1}</span>
            </div>

            {q ? (
              <div
                style={{ fontSize, lineHeight: 1.7, color: tm, fontFamily: 'Inter,sans-serif' }}
                dangerouslySetInnerHTML={{ __html: renderLatex(lang === 'hi' && q.hindiText ? q.hindiText : q.text) }}
              />
            ) : (
              <div style={{ color: ts }}>—</div>
            )}

            {q && (q.image || q.imageUrl) && (
              <div style={{ position: 'relative', display: 'inline-block', marginTop: 16 }}>
                <img src={q.image || q.imageUrl} alt="Question" style={{ maxWidth: '100%', borderRadius: 8, display: 'block' }} />
                <button className="imgZoomBtn" onClick={(e) => { e.stopPropagation(); setZoomImg(q.image || q.imageUrl) }}>🔍</button>
              </div>
            )}
          </div>

          {isMobile && (
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginBottom: 10 }}>
              <button onClick={() => setFontSize(f => Math.max(13, f - 1))} className="tbtn" style={{ padding: '4px 12px', fontSize: 13 }}>A−</button>
              <button onClick={() => setFontSize(f => Math.min(22, f + 1))} className="tbtn" style={{ padding: '4px 12px', fontSize: 13 }}>A+</button>
            </div>
          )}

          {/* §6.5/§8.1 Save status strip — Saved / Queued (offline) / Offline indicator */}
          {q && (savedFlash === q._id || retryQueueRef.current[q._id] || !isOnline) && (
            <div style={{ display: 'flex', gap: 8, marginBottom: 8, fontSize: 11, fontWeight: 700 }}>
              {savedFlash === q._id && <span style={{ color: '#00C48C' }}>✓ {t.saved}</span>}
              {retryQueueRef.current[q._id] && <span style={{ color: '#FFA502' }}>⏳ {t.queued}</span>}
              {!isOnline && <span style={{ color: '#FF4757' }}>📡 {t.offline}</span>}
            </div>
          )}

          {/* §5 Locked banner — attempt already submitted/closed server-side */}
          {locked && (
            <div style={{ background: 'rgba(255,71,87,0.12)', border: '1px solid rgba(255,71,87,0.4)', borderRadius: 10, padding: '12px 16px', marginBottom: 14, fontSize: 12, color: '#FF8080', fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10, flexWrap: 'wrap' }}>
              <span>🔒 {t.lockedMsg}</span>
              <button onClick={() => router.push(`/exam/${examId}/result?attemptId=${attempt?._id || ''}`)} style={{ padding: '6px 14px', borderRadius: 8, border: '1px solid rgba(255,71,87,0.5)', background: 'rgba(255,71,87,0.15)', color: '#FF8080', fontWeight: 700, fontSize: 11, cursor: 'pointer', flexShrink: 0 }}>
                {t.viewResults}
              </button>
            </div>
          )}

          {/* Options — SCQ/MSQ (OMR bubble, bigger touch targets on mobile) or Integer input */}
          {isInteger ? (
            <div style={{ marginBottom: 20 }}>
              <div style={{ fontSize: 13, color: ts, marginBottom: 8 }}>{t.integerHint}</div>
              <input
                type="text"
                inputMode="numeric"
                disabled={locked}
                value={q ? (answers[q._id] ?? '') : ''}
                onChange={e => setIntegerAnswer(q, e.target.value)}
                onBlur={() => commitIntegerAnswer(q)}
                style={{ width: '100%', maxWidth: isMobile ? '100%' : 260, padding: isMobile ? '16px 18px' : '12px 16px', borderRadius: 10, border: `1.5px solid ${(q && integerError[q._id]) ? '#FF4757' : bord}`, background: dark ? 'rgba(0,22,40,0.5)' : '#fff', color: tm, fontSize: 17, opacity: locked ? 0.6 : 1 }}
              />
              {q && integerError[q._id] && <div style={{ color: '#FF4757', fontSize: 11, marginTop: 6 }}>⚠ {integerError[q._id]}</div>}
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: isMobile ? 10 : 12, marginBottom: 20, opacity: locked ? 0.6 : 1, pointerEvents: locked ? 'none' : 'auto' }}>
              {isMSQ && (
                <div style={{ fontSize: 12, fontWeight: 700, color: '#4D9FFF' }}>
                  {Array.isArray(answers[q?._id]) ? answers[q._id].length : 0} {t.optionsSelected}
                </div>
              )}
              {opts.map(opt => {
                const optIdx = OPT_LETTERS.indexOf(opt)
                const optText = (lang === 'hi' && q?.hindiOptions && q.hindiOptions[optIdx]) ? q.hindiOptions[optIdx] : ((q?.options && q.options[optIdx]) || `Option ${opt}`)
                const optImg = q?.optionImages && q.optionImages[optIdx]
                const curAns = q ? answers[q._id] : undefined
                const isSelected = q && (Array.isArray(curAns) ? curAns.includes(opt) : curAns === opt)
                return (
                  <div key={opt}
                    className={`examOption ${isSelected ? 'selected' : ''}`}
                    onClick={() => q && selectOption(q, opt)}
                    onDoubleClick={() => q && doubleClickDeselect(q, opt)}
                    style={{ display: 'flex', alignItems: 'center', gap: 14, padding: isMobile ? '18px 18px' : '14px 20px', minHeight: isMobile ? 30 : undefined, borderRadius: 12, border: `1.5px solid ${isSelected ? '#4D9FFF' : bord}`, background: isSelected ? 'rgba(77,159,255,0.1)' : (dark ? 'rgba(0,22,40,0.5)' : '#fff'), cursor: locked ? 'default' : 'pointer', transition: 'all .2s' }}>
                    <div className={`omr-bubble ${isSelected ? 'selected' : ''}`} style={{ borderColor: isSelected ? '#4D9FFF' : bord, color: isSelected ? '#fff' : ts, flexShrink: 0, width: isMobile ? 34 : undefined, height: isMobile ? 34 : undefined }}>
                      {opt}
                    </div>
                    <span style={{ color: isSelected ? tm : ts, fontSize: isMobile ? 16 : 15, flex: 1 }} dangerouslySetInnerHTML={{ __html: renderLatex(optText) }} />
                    {optImg && (
                      <div style={{ position: 'relative', flexShrink: 0 }}>
                        <img src={optImg} alt={`Option ${opt}`} style={{ width: 70, height: 70, objectFit: 'cover', borderRadius: 8 }} />
                        <button className="imgZoomBtn" style={{ top: 2, right: 2, padding: '2px 6px', fontSize: 10 }} onClick={(e) => { e.stopPropagation(); setZoomImg(optImg) }}>🔍</button>
                      </div>
                    )}
                  </div>
                )
              })}
            </div>
          )}

          {/* §8.5 Confidence Tag — optional, does not affect scoring, purely self-reported */}
          {q && !locked && (answers[q._id] !== undefined && answers[q._id] !== null && answers[q._id] !== '') && (
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 20, flexWrap: 'wrap' }}>
              <span style={{ fontSize: 11, color: ts }}>{t.confidenceLabel}:</span>
              {(['low', 'medium', 'high'] as const).map(lvl => (
                <button key={lvl} onClick={() => setConfidenceTag(q, lvl)}
                  style={{ padding: '4px 12px', borderRadius: 20, fontSize: 11, fontWeight: 700, cursor: 'pointer', border: `1px solid ${confidence[q._id] === lvl ? (lvl === 'high' ? '#00C48C' : lvl === 'medium' ? '#FFA502' : '#FF4757') : bord}`, background: confidence[q._id] === lvl ? (lvl === 'high' ? 'rgba(0,196,140,0.15)' : lvl === 'medium' ? 'rgba(255,165,2,0.15)' : 'rgba(255,71,87,0.15)') : 'transparent', color: confidence[q._id] === lvl ? (lvl === 'high' ? '#00C48C' : lvl === 'medium' ? '#FFA502' : '#FF4757') : ts }}>
                  {lvl === 'high' ? t.confidenceHigh : lvl === 'medium' ? t.confidenceMed : t.confidenceLow}
                </button>
              ))}
            </div>
          )}

          {/* Action Buttons — Desktop: inline row. Mobile: report/report-only here, ── */}
          {/* Prev/Next/Mark/Clear move to the fixed bottom bar for one-thumb reach. ── */}
          {!isMobile ? (
            <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
              <button className="tbtn" disabled={locked} style={{ color: '#A855F7', borderColor: 'rgba(168,85,247,0.4)', opacity: locked ? 0.5 : 1 }} onClick={() => toggleFlag(q)}>
                🔖 {q && flagged.has(q._id) ? t.unmarkReview : t.markReview}
              </button>
              <button className="tbtn" disabled={locked} style={{ opacity: locked ? 0.5 : 1 }} onClick={() => clearResponse(q)}>🗑 {t.clearResp}</button>
              <button className="tbtn" style={{ color: '#FFA502', borderColor: 'rgba(255,165,2,0.4)' }} onClick={() => setShowReportModal(true)}>🚩 {t.report}</button>
              <div style={{ flex: 1 }} />
              <button className="tbtn" onClick={() => goRelative(-1)} disabled={current === 0}>← {t.prev}</button>
              <button className="lb" disabled={locked} style={{ opacity: locked ? 0.6 : 1 }} onClick={() => goRelative(1)}>{t.saveNext} →</button>
            </div>
          ) : (
            <button className="tbtn" style={{ color: '#FFA502', borderColor: 'rgba(255,165,2,0.4)', width: '100%' }} onClick={() => setShowReportModal(true)}>🚩 {t.report}</button>
          )}
        </main>

        {/* ── §2.7 Mobile-only sticky bottom action bar — one-thumb reachable ── */}
        {isMobile && q && (
          <div style={{ position: 'fixed', bottom: 0, left: 0, right: 0, background: headerBg, borderTop: `1px solid ${bord}`, display: 'flex', alignItems: 'center', padding: '10px 12px', gap: 8, zIndex: 130, boxShadow: '0 -8px 24px rgba(0,0,0,0.35)' }}>
            <button onClick={() => toggleFlag(q)} disabled={locked} style={{ width: 46, height: 46, borderRadius: 12, border: `1.5px solid rgba(168,85,247,0.5)`, background: flagged.has(q._id) ? 'rgba(168,85,247,0.2)' : 'transparent', color: '#A855F7', fontSize: 18, flexShrink: 0, opacity: locked ? 0.5 : 1 }}>🔖</button>
            <button onClick={() => clearResponse(q)} disabled={locked} style={{ width: 46, height: 46, borderRadius: 12, border: `1.5px solid ${bord}`, background: 'transparent', color: tm, fontSize: 17, flexShrink: 0, opacity: locked ? 0.5 : 1 }}>🗑</button>
            <button onClick={() => goRelative(-1)} disabled={current === 0} style={{ flex: 1, height: 46, borderRadius: 12, border: `1.5px solid ${bord}`, background: 'transparent', color: tm, fontWeight: 700, fontSize: 13, opacity: current === 0 ? 0.4 : 1 }}>← {t.prev}</button>
            <button onClick={() => goRelative(1)} disabled={locked} style={{ flex: 1.6, height: 46, borderRadius: 12, border: 'none', background: 'linear-gradient(135deg,#4D9FFF,#0055CC)', color: '#fff', fontWeight: 700, fontSize: 13, opacity: locked ? 0.6 : 1 }}>{t.saveNext} →</button>
          </div>
        )}
      </div>

      {/* ── Submit Modal ─────────────────────────────────────────── */}
      {showSubmit && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200, backdropFilter: 'blur(4px)' }}>
          <div style={{ background: 'rgba(0,22,40,0.95)', border: `1px solid ${bord}`, borderRadius: 20, padding: '36px', maxWidth: 440, width: '90%', textAlign: 'center' }}>
            <div style={{ fontSize: 48, marginBottom: 16 }}>📤</div>
            <h2 style={{ fontFamily: 'Playfair Display,serif', fontSize: 22, fontWeight: 700, marginBottom: 12, color: '#fff' }}>{t.confirm}</h2>
            <div style={{ display: 'flex', justifyContent: 'center', gap: 24, marginBottom: 20 }}>
              <div><div style={{ fontFamily: 'Playfair Display,serif', fontSize: 28, fontWeight: 800, color: '#00C48C' }}>{answeredCount}</div><div style={{ color: '#8DA2C0', fontSize: 12 }}>{t.answered}</div></div>
              <div><div style={{ fontFamily: 'Playfair Display,serif', fontSize: 28, fontWeight: 800, color: '#FF4757' }}>{questions.length - answeredCount}</div><div style={{ color: '#8DA2C0', fontSize: 12 }}>{t.unanswered}</div></div>
              <div><div style={{ fontFamily: 'Playfair Display,serif', fontSize: 28, fontWeight: 800, color: '#A855F7' }}>{flagged.size}</div><div style={{ color: '#8DA2C0', fontSize: 12 }}>{t.flagged}</div></div>
            </div>
            <p style={{ color: '#8DA2C0', fontSize: 14, marginBottom: 24 }}>{t.subWarn}</p>
            <div style={{ display: 'flex', gap: 12 }}>
              <button onClick={() => setShowSubmit(false)} style={{ flex: 1, padding: 14, borderRadius: 10, border: `1px solid ${bord}`, background: 'transparent', color: '#8DA2C0', cursor: 'pointer', fontFamily: 'Inter,sans-serif', fontSize: 14 }}>{t.cancelSub}</button>
              <button className="lb" disabled={submitting} onClick={() => autoSubmit(false)} style={{ flex: 1, background: 'linear-gradient(135deg,#FF4757,#CC2233)' }}>
                {submitting ? '◌ ...' : `✓ ${t.confirmSub}`}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Fullscreen Exit Warning Modal ── */}
      {showFSWarning && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.75)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 300, backdropFilter: 'blur(4px)' }}>
          <div style={{ background: 'rgba(30,5,5,0.97)', border: '1px solid #FF4757', borderRadius: 20, padding: '32px', maxWidth: 400, width: '90%', textAlign: 'center' }}>
            <div style={{ fontSize: 44, marginBottom: 12 }}>⚠️</div>
            <h2 style={{ fontFamily: 'Playfair Display,serif', fontSize: 19, fontWeight: 700, color: '#FF4757', marginBottom: 10 }}>{lang === 'en' ? 'Fullscreen Exited!' : 'फुलस्क्रीन बंद हो गया!'}</h2>
            <p style={{ color: '#ddd', fontSize: 13, marginBottom: 20 }}>{lang === 'en' ? 'You must stay in fullscreen during the exam. Return now to avoid a warning.' : 'परीक्षा के दौरान फुलस्क्रीन में रहना अनिवार्य है। चेतावनी से बचने के लिए तुरंत वापस लौटें।'}</p>
            <button onClick={() => document.documentElement.requestFullscreen?.()} style={{ width: '100%', padding: 14, borderRadius: 10, border: 'none', background: 'linear-gradient(135deg,#4D9FFF,#0055CC)', color: '#fff', fontWeight: 700, fontSize: 14, cursor: 'pointer' }}>
              {lang === 'en' ? '↩ Return to Fullscreen' : '↩ फुलस्क्रीन पर लौटें'}
            </button>
          </div>
        </div>
      )}

      {/* ── Feature 32: Time Extension Notification ── */}
      {timeExtNotif && (
        <div style={{ position: 'fixed', top: 20, right: 20, zIndex: 9999, background: 'linear-gradient(135deg,rgba(22,35,56,0.98),rgba(15,23,42,0.98))', border: '1px solid rgba(167,139,250,0.6)', borderRadius: 14, padding: '14px 20px', maxWidth: 320, boxShadow: '0 0 30px rgba(167,139,250,0.25)', animation: 'slideInRight 0.3s ease' }}>
          <div style={{ fontWeight: 700, fontSize: 13, color: '#a78bfa', marginBottom: 4 }}>⏱️ Extra Time Granted</div>
          <div style={{ fontSize: 12, color: '#e2e8f0' }}>{timeExtNotif}</div>
          <style>{'@keyframes slideInRight{from{transform:translateX(120%);opacity:0}to{transform:translateX(0);opacity:1}}'}</style>
        </div>
      )}

      {/* ── §17 Report Modal ── */}
      {showReportModal && (
        <div onClick={() => setShowReportModal(false)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 250, padding: 16 }}>
          <div onClick={e => e.stopPropagation()} style={{ background: card, border: `1px solid ${bord}`, borderRadius: 16, padding: 22, maxWidth: 420, width: '100%' }}>
            <div style={{ fontWeight: 800, color: tm, marginBottom: 10 }}>🚩 {t.reportTitle}</div>
            <textarea value={reportReason} onChange={e => setReportReason(e.target.value)} placeholder={t.reportPlaceholder}
              style={{ width: '100%', minHeight: 100, padding: 12, borderRadius: 10, border: `1px solid ${bord}`, background: dark ? 'rgba(0,22,40,0.5)' : '#fff', color: tm, fontSize: 13, resize: 'vertical' }} />
            <div style={{ display: 'flex', gap: 10, marginTop: 14 }}>
              <button onClick={() => setShowReportModal(false)} style={{ flex: 1, padding: 12, borderRadius: 10, border: `1px solid ${bord}`, background: 'transparent', color: ts, cursor: 'pointer' }}>{t.cancelSub}</button>
              <button disabled={!reportReason.trim() || reportSubmitting} onClick={submitReport} className="lb" style={{ flex: 1, opacity: (!reportReason.trim() || reportSubmitting) ? 0.5 : 1 }}>{t.reportSubmit}</button>
            </div>
          </div>
        </div>
      )}
      {reportMsg && (
        <div style={{ position: 'fixed', bottom: 20, left: '50%', transform: 'translateX(-50%)', background: '#123b1e', color: '#7CFC9C', padding: '10px 20px', borderRadius: 20, fontSize: 13, zIndex: 9999 }}>{reportMsg}</div>
      )}

      {/* ── §15 Image Zoom / Lightbox ── */}
      {zoomImg && (
        <div onClick={() => setZoomImg(null)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.9)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 400, padding: 20, cursor: 'zoom-out' }}>
          <img src={zoomImg} alt="Zoomed" style={{ maxWidth: '95%', maxHeight: '90%', borderRadius: 8 }} />
          <button onClick={() => setZoomImg(null)} style={{ position: 'absolute', top: 20, right: 20, background: 'rgba(255,255,255,0.15)', color: '#fff', border: 'none', borderRadius: '50%', width: 40, height: 40, fontSize: 18, cursor: 'pointer' }}>✕</button>
        </div>
      )}
    </div>
  )
}
FRONTENDEOF

echo "Frontend: exam attempt page.tsx updated with F59 features."
echo "=================================================="
echo "F59 DONE. Restart backend + frontend and test:"
echo "Server: cd ~/workspace && node src/index.js"
echo "Frontend: cd ~/workspace/frontend && npm run dev"
echo "=================================================="
