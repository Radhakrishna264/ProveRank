const Attempt = require('../models/Attempt');
const Exam = require('../models/Exam');
const ExamInstance = require('../models/ExamInstance');

exports.getRankPrediction = async (req, res) => {
  try {
    const studentId = req.user._id;
    const { examId } = req.params;
    const pastAttempts = await Attempt.find({ studentId, status: 'submitted', score: { $exists: true } }).sort({ createdAt: -1 }).limit(5);
    let predictedRank = null, predictedScore = null, confidence = 'low';
    if (pastAttempts.length >= 3) {
      const avgScore = pastAttempts.reduce((sum, a) => sum + (a.score || 0), 0) / pastAttempts.length;
      const trend = pastAttempts[0].score - pastAttempts[pastAttempts.length - 1].score;
      predictedScore = Math.round(Math.max(0, Math.min(720, avgScore + (trend * 0.3))));
      if (predictedScore >= 650) { predictedRank = Math.floor(Math.random() * 500) + 1; confidence = 'high'; }
      else if (predictedScore >= 550) { predictedRank = Math.floor(Math.random() * 5000) + 500; confidence = 'high'; }
      else if (predictedScore >= 450) { predictedRank = Math.floor(Math.random() * 20000) + 5000; confidence = 'medium'; }
      else { predictedRank = Math.floor(Math.random() * 50000) + 20000; confidence = 'medium'; }
    } else if (pastAttempts.length > 0) {
      predictedScore = pastAttempts[0].score || 0;
      predictedRank = Math.floor(Math.random() * 100000) + 1;
    }
    res.json({ success: true, prediction: { predictedRank, predictedScore, confidence, basedOnAttempts: pastAttempts.length, message: pastAttempts.length === 0 ? 'Pehli baar attempt — prediction baad mein improve hogi!' : `Last ${pastAttempts.length} attempts ke basis pe prediction` } });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.joinWaitingRoom = async (req, res) => {
  try {
    const { examId } = req.params;
    const exam = await Exam.findById(examId);
    if (!exam) return res.status(404).json({ success: false, message: 'Exam nahi mila' });
    const now = new Date();
    const examStart = new Date(exam.startTime);
    const waitingRoomOpen = new Date(examStart.getTime() - 10 * 60 * 1000);
    if (now < waitingRoomOpen) {
      const minutesLeft = Math.ceil((waitingRoomOpen - now) / 60000);
      return res.status(400).json({ success: false, message: `Waiting room ${minutesLeft} minute baad open hogi`, opensAt: waitingRoomOpen });
    }
    res.json({ success: true, message: 'Waiting room mein aa gaye!', waitingRoom: { examId, examName: exam.title, examStartTime: examStart, socketRoomId: exam.socketRoomId || `exam_${examId}`, countdown: Math.max(0, examStart - now) } });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.acceptTerms = async (req, res) => {
  try {
    const { examId } = req.params;
    const { agreed } = req.body;
    const studentId = req.user._id;
    if (!agreed) return res.status(400).json({ success: false, message: 'Terms & Conditions accept karna zaroori hai' });
    let attempt = await Attempt.findOne({ examId, studentId, status: { $in: ['waiting', 'instructions'] } });
    if (!attempt) attempt = new Attempt({ examId, studentId, status: 'instructions' });
    attempt.termsAccepted = true;
    attempt.termsAcceptedAt = new Date();
    attempt.status = 'instructions';
    await attempt.save();
    res.json({ success: true, message: 'Terms accepted! Ab exam start kar sakte ho.', attemptId: attempt._id });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.startAttempt = async (req, res) => {
  try {
    const { examId } = req.params;
    const studentId = req.user._id;
    const ipAddress = req.headers['x-forwarded-for']?.split(',')[0] || req.socket.remoteAddress;
    const exam = await Exam.findById(examId);
    if (!exam) return res.status(404).json({ success: false, message: 'Exam nahi mila' });
    if (exam.accessControl?.whitelistEnabled) {
      const isAllowed = (exam.accessControl.allowedStudents || []).some(id => id.toString() === studentId.toString());
      if (!isAllowed) return res.status(403).json({ success: false, message: 'Aap whitelist mein nahi hain', code: 'NOT_WHITELISTED' });
    }
    const previousAttempts = await Attempt.countDocuments({ examId, studentId, status: { $in: ['submitted', 'timeout'] } });
    const maxAttempts = exam.reAttempt?.maxAttempts || 1;
    if (previousAttempts >= maxAttempts) return res.status(403).json({ success: false, message: `Attempt limit reach ho gayi. Max ${maxAttempts} allowed.`, code: 'ATTEMPT_LIMIT_REACHED' });
    const activeAttempt = await Attempt.findOne({ examId, studentId, status: 'active' });
    if (activeAttempt) return res.json({ success: true, message: 'Attempt already active hai', attempt: activeAttempt, resuming: true });
    const instructionAttempt = await Attempt.findOne({ examId, studentId, status: 'instructions' });
    if (!instructionAttempt?.termsAccepted) return res.status(400).json({ success: false, message: 'Pehle Terms & Conditions accept karo', code: 'TERMS_NOT_ACCEPTED' });
    instructionAttempt.status = 'active';
    instructionAttempt.ipAddress = ipAddress;
    instructionAttempt.startedAt = new Date();
    instructionAttempt.attemptNumber = previousAttempts + 1;
    if (req.body.predictedRank) {
      instructionAttempt.predictedRank = req.body.predictedRank;
      instructionAttempt.predictedScore = req.body.predictedScore;
      instructionAttempt.predictionConfidence = req.body.predictionConfidence;
    }
    await instructionAttempt.save();
    const instance = await ExamInstance.findOne({ examId }).select('questionSnapshot socketRoomId');
    res.json({ success: true, message: 'Exam shuru! All the best! 🎯', attempt: { _id: instructionAttempt._id, status: instructionAttempt.status, startedAt: instructionAttempt.startedAt, attemptNumber: instructionAttempt.attemptNumber, ipAddress: instructionAttempt.ipAddress }, exam: { title: exam.title, duration: exam.duration, totalQuestions: instance?.questionSnapshot?.length || 0, socketRoomId: instance?.socketRoomId } });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.verifyAdmitCard = async (req, res) => {
  try {
    const { examId } = req.params;
    const { qrCode } = req.body;
    const studentId = req.user._id;
    if (!qrCode) return res.status(400).json({ success: false, message: 'QR code provide karo' });
    const expectedQR = `PROVERANK-${studentId}-${examId}`;
    if (qrCode !== expectedQR) return res.status(400).json({ success: false, message: 'Invalid Admit Card QR Code', code: 'INVALID_QR' });
    await Attempt.findOneAndUpdate({ examId, studentId, status: { $in: ['waiting', 'instructions'] } }, { admitCardVerified: true, admitCardVerifiedAt: new Date() });
    res.json({ success: true, message: 'Admit Card verified! ✅', student: { id: studentId, name: req.user.name } });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.logFullscreenWarning = async (req, res) => {
  try {
    const { attemptId } = req.params;
    const studentId = req.user._id;
    const attempt = await Attempt.findOne({ _id: attemptId, studentId, status: 'active' });
    if (!attempt) return res.status(404).json({ success: false, message: 'Active attempt nahi mili' });
    attempt.fullscreenWarnings += 1;
    if (attempt.fullscreenWarnings >= 3) {
      attempt.status = 'submitted';
      attempt.submittedAt = new Date();
      attempt.fullscreenDenied = true;
      await attempt.save();
      return res.json({ success: true, autoSubmitted: true, message: '⚠️ 3 warnings ke baad exam auto-submit ho gaya!', warnings: attempt.fullscreenWarnings });
    }
    await attempt.save();
    res.json({ success: true, autoSubmitted: false, warnings: attempt.fullscreenWarnings, remaining: 3 - attempt.fullscreenWarnings, message: `⚠️ Warning ${attempt.fullscreenWarnings}/3 — Fullscreen mein wapas aao!` });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};

exports.getAttemptStatus = async (req, res) => {
  try {
    const { examId } = req.params;
    const studentId = req.user._id;
    const attempt = await Attempt.findOne({ examId, studentId }).sort({ createdAt: -1 });
    if (!attempt) return res.json({ success: true, hasAttempt: false, status: null });
    res.json({ success: true, hasAttempt: true, status: attempt.status, attemptId: attempt._id, startedAt: attempt.startedAt, termsAccepted: attempt.termsAccepted, admitCardVerified: attempt.admitCardVerified, fullscreenWarnings: attempt.fullscreenWarnings });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
};
