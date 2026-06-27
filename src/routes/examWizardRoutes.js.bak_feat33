/**
 * ProveRank — Features 26+27+28: Create Exam Wizard Routes
 * Handles: Template load, Draft create, Questions import,
 *          Smart suggest, Multi-set, Publish, Schedule, Clone, Notify
 */
const express   = require('express');
const router    = express.Router();
const mongoose  = require('mongoose');
const multer    = require('multer');
const XLSX      = require('xlsx');
const pdfParse  = require('pdf-parse');
const { verifyToken, isAdmin } = require('../middleware/auth');

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 20 * 1024 * 1024 } });

// ── Helpers ───────────────────────────────────────────────────────────────────
const getExam     = () => mongoose.model('Exam');
const getQuestion = () => mongoose.model('Question');
const getUser     = () => mongoose.model('User');

function parseAnswerKey(text = '') {
  const map = {};
  text.split('\n').forEach(line => {
    const m = line.match(/^(\d+)[.\-\)]\s*([A-Da-d1-4])/);
    if (m) {
      const n = parseInt(m[1]), a = m[2].toUpperCase();
      map[n] = ['A','B','C','D'].indexOf(a) !== -1 ? ['A','B','C','D'].indexOf(a) : parseInt(a) - 1;
    }
  });
  return map;
}

function parseCopyPaste(text = '', answerKey = {}) {
  const blocks = text.split(/\n(?=\d+[\.\)]\s)/);
  const parsed = [];
  blocks.forEach((block, idx) => {
    const lines = block.trim().split('\n').filter(l => l.trim());
    if (lines.length < 2) return;
    const qm = lines[0].match(/^(\d+)[\.\)]\s*(.*)/);
    if (!qm) return;
    const qNum = parseInt(qm[1]);
    let qText  = qm[2].trim();
    const opts = [];
    let explanation = '';
    lines.slice(1).forEach(line => {
      const om = line.match(/^([A-Da-d][\.\)]\s*)(.*)/);
      if (om) opts.push(om[2].trim());
      else if (/^(exp|explanation|sol)[:\s]/i.test(line)) explanation = line.replace(/^[^:]+:\s*/i, '');
      else if (!opts.length) qText += ' ' + line.trim();
    });
    if (qText && opts.length >= 2) {
      const correct = answerKey[qNum] !== undefined ? answerKey[qNum] : 0;
      parsed.push({ qNum, text: qText.trim(), options: opts, correct: [correct], explanation });
    }
  });
  return parsed;
}

// ════════════════════════════════════════════════════════════════
// Templates (26 — pre-configured exam templates)
// ════════════════════════════════════════════════════════════════
router.get('/exam-wizard/templates', verifyToken, isAdmin, async (req, res) => {
  try {
    const defaults = [
      { id: 'neet_full',     name: 'NEET Full Mock',      icon: '🎯', subject: 'Full Mock', category: 'Full Mock',    totalQs: 180, subjectQs: { Physics: 45, Chemistry: 45, Biology: 90 }, duration: 200, totalMarks: 720, correctMarks: 4, negativeMarks: 1, examType: 'NEET', examLevel: 'NEET' },
      { id: 'neet_chapter',  name: 'NEET Chapter Test',   icon: '📖', subject: 'Physics',   category: 'Chapter Test', totalQs: 45,  subjectQs: { Physics: 45 }, duration: 60, totalMarks: 180, correctMarks: 4, negativeMarks: 1, examType: 'NEET', examLevel: 'NEET' },
      { id: 'neet_part',     name: 'NEET Part Test',      icon: '⚡', subject: 'Full Mock', category: 'Part Test',    totalQs: 90,  subjectQs: { Physics: 45, Chemistry: 45 }, duration: 100, totalMarks: 360, correctMarks: 4, negativeMarks: 1, examType: 'NEET', examLevel: 'NEET' },
      { id: 'neet_grand',    name: 'Grand Test',           icon: '🏆', subject: 'Full Mock', category: 'Grand Test',   totalQs: 180, subjectQs: { Physics: 45, Chemistry: 45, Biology: 90 }, duration: 200, totalMarks: 720, correctMarks: 4, negativeMarks: 1, examType: 'NEET', examLevel: 'NEET' },
      { id: 'neet_mini',     name: 'Mini Test',            icon: '⚡', subject: 'Full Mock', category: 'Mini Test',    totalQs: 30,  subjectQs: { Physics: 10, Chemistry: 10, Biology: 10 }, duration: 30,  totalMarks: 120, correctMarks: 4, negativeMarks: 1, examType: 'NEET', examLevel: 'NEET' },
      { id: 'jee_main',      name: 'JEE Main Mock',       icon: '⚙️', subject: 'Full Mock', category: 'Full Mock',    totalQs: 90,  subjectQs: { Physics: 30, Chemistry: 30, Math: 30 }, duration: 180, totalMarks: 300, correctMarks: 4, negativeMarks: 1, examType: 'JEE', examLevel: 'JEE_MAINS' },
      { id: 'pyq_test',      name: 'PYQ Practice',        icon: '📅', subject: 'Full Mock', category: 'PYQ',          totalQs: 50,  subjectQs: { Physics: 17, Chemistry: 17, Biology: 16 }, duration: 70,  totalMarks: 200, correctMarks: 4, negativeMarks: 1, examType: 'NEET', examLevel: 'NEET' },
      { id: 'custom',        name: 'Custom Exam',         icon: '✏️', subject: 'Custom',    category: 'Chapter Test', totalQs: 30,  subjectQs: {},  duration: 45, totalMarks: 120, correctMarks: 4, negativeMarks: 1, examType: 'Custom', examLevel: 'NEET' },
    ];
    // Also get any saved custom templates from DB
    let dbTemplates = [];
    try {
      const ExamTemplate = mongoose.model('ExamTemplate');
      dbTemplates = await ExamTemplate.find({ createdBy: req.user.id }).sort({ createdAt: -1 }).limit(10);
    } catch {}
    res.json({ success: true, templates: [...defaults, ...dbTemplates.map((t) => ({ ...t.toObject(), isCustom: true }))] });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 28.8.4 — Save as Template
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/templates', verifyToken, isAdmin, async (req, res) => {
  try {
    let ExamTemplate;
    try {
      ExamTemplate = mongoose.model('ExamTemplate');
    } catch {
      const s = new mongoose.Schema({ name: String, icon: { type: String, default: '📋' }, subject: String, category: String, totalQs: Number, subjectQs: Object, duration: Number, totalMarks: Number, correctMarks: Number, negativeMarks: Number, examType: String, markingScheme: Object, instructions: String, createdBy: mongoose.Schema.Types.ObjectId }, { timestamps: true });
      ExamTemplate = mongoose.model('ExamTemplate', s);
    }
    const t = await ExamTemplate.create({ ...req.body, createdBy: req.user.id });
    res.json({ success: true, message: 'Template saved!', template: t });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 26 — Create Exam (Step 1 — full wizard payload)
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/create', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const {
      title, subject, category, totalQs, subjectQs, examType, duration,
      totalMarks, correctMarks, negativeMarks, startDate, endDate,
      instructions, passwordEnabled, password,
      whitelist, waitingRoom, waitingMinutes,
      reattempt, reattemptUnlimited, reviewWindow, sectionWise, watermark,
      liveQsRange, assignType, batchId, testSeriesId, miniSeriesId, multiBatches,
      status
    } = req.body;

    if (!title || !title.trim())   return res.status(400).json({ success: false, message: 'Exam title is required' });
    if (!duration || duration < 1) return res.status(400).json({ success: false, message: 'Duration is required' });

    const examData = {
      title: title.trim(),
      subject: subject || 'NEET',
      type: examType || 'NEET',
      category: category || 'Full Mock',
      totalQs: parseInt(totalQs) || 180,
      subjectQs: subjectQs || {},
      duration: parseInt(duration),
      totalMarks: parseInt(totalMarks) || 720,
      correctMarks: parseFloat(correctMarks) || 4,
      negativeMarks: parseFloat(negativeMarks) || 1,
      scheduledAt: startDate ? new Date(startDate) : null,
      endDate: endDate ? new Date(endDate) : null,
      customInstructions: instructions || '',
      password: passwordEnabled ? (password || '') : '',
      whitelist: whitelist || false,
      waitingRoom: waitingRoom || false,
      waitingMinutes: parseInt(waitingMinutes) || 0,
      reattempt: reattemptUnlimited ? -1 : (parseInt(reattempt) || 1),
      reviewWindow: reviewWindow !== false,
      sectionWise: sectionWise || false,
      watermark: watermark || false,
      liveQsRange: liveQsRange || [],
      batch: batchId || '',
      batches: multiBatches || [],
      testSeriesId: testSeriesId || null,
      miniSeriesId: miniSeriesId || null,
      assignType: assignType || 'open',
      status: status || 'draft',
      questions: [],
      createdBy: req.user.id,
    };

    const exam = await Exam.create(examData);
    res.status(201).json({ success: true, message: 'Exam created!', exam, examId: exam._id });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 27.1 — Import questions from Question Bank
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/:id/questions/bank', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const { questionIds } = req.body;
    if (!questionIds || !questionIds.length) return res.status(400).json({ success: false, message: 'No question IDs provided' });
    const exam = await Exam.findById(req.params.id);
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    const existing = new Set((exam.questions || []).map((q) => String(q)));
    const toAdd = questionIds.filter((id) => !existing.has(String(id)));
    await Exam.findByIdAndUpdate(req.params.id, { $push: { questions: { $each: toAdd } } });
    res.json({ success: true, message: `${toAdd.length} questions added`, added: toAdd.length, skipped: questionIds.length - toAdd.length });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 27.3 — Copy-Paste Upload
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/:id/questions/copypaste', verifyToken, isAdmin, async (req, res) => {
  try {
    const Question = getQuestion(); const Exam = getExam();
    const exam = await Exam.findById(req.params.id);
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    const { questionsText, answerKeyText, subject, difficulty } = req.body;
    if (!questionsText) return res.status(400).json({ success: false, message: 'Questions text required' });
    const answerKey = parseAnswerKey(answerKeyText || '');
    const parsed    = parseCopyPaste(questionsText, answerKey);
    if (!parsed.length) return res.status(400).json({ success: false, message: 'No questions parsed. Check format.' });
    let saved = 0; const qIds = [];
    for (const p of parsed) {
      try {
        const q = await Question.create({ text: p.text, options: p.options, correct: p.correct, explanation: p.explanation, subject: subject || 'General', difficulty: difficulty || 'Medium', type: 'SCQ', createdBy: req.user.id, isPYQ: false });
        qIds.push(q._id); saved++;
      } catch {}
    }
    if (qIds.length) await Exam.findByIdAndUpdate(req.params.id, { $push: { questions: { $each: qIds } } });
    res.json({ success: true, saved, failed: parsed.length - saved, message: `${saved} questions uploaded` });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 27.4 — Excel Upload
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/:id/questions/excel', verifyToken, isAdmin, upload.single('file'), async (req, res) => {
  try {
    const Question = getQuestion(); const Exam = getExam();
    const exam = await Exam.findById(req.params.id);
    if (!exam || !req.file) return res.status(400).json({ success: false, message: !exam ? 'Exam not found' : 'File required' });
    const wb   = XLSX.read(req.file.buffer, { type: 'buffer' });
    const rows = XLSX.utils.sheet_to_json(wb.Sheets[wb.SheetNames[0]], { defval: '' });
    let saved = 0; const qIds = []; const errors = [];
    for (const row of rows) {
      const text = String(row['Question'] || row['question'] || '').trim();
      if (!text) continue;
      const opts = ['A','B','C','D'].map(l => String(row[`Option ${l}`] || row[`option_${l.toLowerCase()}`] || row[l] || '').trim()).filter(Boolean);
      if (opts.length < 2) { errors.push(`"${text.slice(0,40)}" — not enough options`); continue; }
      const ca   = String(row['Correct Answer'] || row['correct'] || 'A').toUpperCase().trim();
      const ci   = ['A','B','C','D'].indexOf(ca);
      try {
        const q = await Question.create({ text, options: opts, correct: [ci >= 0 ? ci : 0], subject: String(row['Subject'] || 'General').trim(), chapter: String(row['Chapter'] || '').trim(), difficulty: String(row['Difficulty'] || 'Medium').trim(), explanation: String(row['Explanation'] || '').trim(), hindiText: String(row['Hindi Question'] || '').trim(), type: 'SCQ', createdBy: req.user.id });
        qIds.push(q._id); saved++;
      } catch (e) { errors.push(e.message); }
    }
    if (qIds.length) await Exam.findByIdAndUpdate(req.params.id, { $push: { questions: { $each: qIds } } });
    res.json({ success: true, saved, failed: rows.length - saved, errors: errors.slice(0, 5), message: `${saved} questions from Excel` });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 27.4 — PDF Upload
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/:id/questions/pdf', verifyToken, isAdmin, upload.single('file'), async (req, res) => {
  try {
    const Question = getQuestion(); const Exam = getExam();
    const exam = await Exam.findById(req.params.id);
    if (!exam || !req.file) return res.status(400).json({ success: false, message: !exam ? 'Exam not found' : 'File required' });
    const pdfData = await pdfParse(req.file.buffer);
    const parsed  = parseCopyPaste(pdfData.text || '', {});
    if (!parsed.length) return res.status(400).json({ success: false, message: 'No questions found in PDF' });
    let saved = 0; const qIds = [];
    for (const p of parsed) {
      try {
        const q = await Question.create({ text: p.text, options: p.options, correct: p.correct, subject: String(req.body.subject || 'General'), difficulty: 'Medium', type: 'SCQ', createdBy: req.user.id });
        qIds.push(q._id); saved++;
      } catch {}
    }
    if (qIds.length) await Exam.findByIdAndUpdate(req.params.id, { $push: { questions: { $each: qIds } } });
    res.json({ success: true, saved, failed: parsed.length - saved, pages: pdfData.numpages, message: `${saved} questions from PDF` });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 27.14 — Smart Suggest / Auto-select from Bank
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/:id/questions/smart-suggest', verifyToken, isAdmin, async (req, res) => {
  try {
    const Question = getQuestion(); const Exam = getExam();
    const exam = await Exam.findById(req.params.id);
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    const { subjectQs = {}, examLevel = 'NEET', existingIds = [] } = req.body;
    const existingSet = new Set(existingIds.map(String));
    const suggested = [];
    const baseFilter = { isDeleted: { $ne: true }, isArchived: { $ne: true }, approvalStatus: 'approved', _id: { $nin: existingIds } };
    for (const [subj, count] of Object.entries(subjectQs)) {
      if (!count || count <= 0) continue;
      const qs = await Question.find({ ...baseFilter, subject: subj, examLevel: { $in: [examLevel, 'NEET', ''] } }).sort({ usageCount: 1, similarityScore: -1 }).limit(parseInt(count)).select('_id text subject chapter difficulty type');
      suggested.push(...qs);
    }
    // Fallback if not enough
    const needed = Object.values(subjectQs).reduce((s, v) => s + parseInt(v), 0);
    if (suggested.length < needed) {
      const more = await Question.find({ ...baseFilter, _id: { $nin: [...existingIds, ...suggested.map(q => q._id)] } }).limit(needed - suggested.length).select('_id text subject chapter difficulty type');
      suggested.push(...more);
    }
    res.json({ success: true, questions: suggested, total: suggested.length, message: `${suggested.length} questions suggested` });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 27.16 — Duplicate detector
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/duplicate-check', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const { questionIds } = req.body;
    if (!questionIds || !questionIds.length) return res.json({ success: true, duplicates: {} });
    const exams = await Exam.find({ questions: { $in: questionIds }, status: { $ne: 'deleted' } }).select('title questions status');
    const map = {};
    questionIds.forEach((id) => {
      const inExams = exams.filter(e => (e.questions || []).some(q => String(q) === String(id)));
      if (inExams.length > 0) map[String(id)] = inExams.map(e => ({ title: e.title, status: e.status }));
    });
    res.json({ success: true, duplicates: map });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 27.18+27.19 — Multi-set generate (Set A/B/C auto-shuffle)
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/:id/generate-sets', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const exam = await Exam.findById(req.params.id).populate('questions');
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    const { setCount = 2 } = req.body;
    const count = Math.min(parseInt(setCount) || 2, 6);
    const baseQs = exam.questions || [];
    const sets = [];
    for (let i = 0; i < count; i++) {
      const shuffled = [...baseQs].sort(() => Math.random() - 0.5);
      const setLabel = String.fromCharCode(65 + i); // A, B, C...
      sets.push({
        setLabel,
        questions: shuffled.map(q => ({ _id: q._id, text: q.text, options: q.options, correct: q.correct, explanation: q.explanation, subject: q.subject, chapter: q.chapter, difficulty: q.difficulty }))
      });
    }
    await Exam.findByIdAndUpdate(req.params.id, { multiSets: sets, setCount: count, multiSetEnabled: true });
    res.json({ success: true, sets, setCount: count, message: `${count} sets generated (A–${String.fromCharCode(64 + count)})` });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 28 — Get full exam details for Review step
// ════════════════════════════════════════════════════════════════
router.get('/exam-wizard/:id/review', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const exam = await Exam.findById(req.params.id).populate('questions', 'text subject chapter difficulty type options correct explanation image').lean();
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    // Student count if batch assigned
    let studentCount = 0;
    try {
      if (exam.batch) { const User = getUser(); studentCount = await User.countDocuments({ role: 'student', batch: exam.batch }); }
    } catch {}
    res.json({ success: true, exam, studentCount });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 28.8.2 — Publish Now
// ════════════════════════════════════════════════════════════════
router.patch('/exam-wizard/:id/publish', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const exam = await Exam.findByIdAndUpdate(req.params.id, { status: 'published', publishedAt: new Date() }, { new: true });
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    res.json({ success: true, message: 'Exam published!', exam });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 28.8.3 — Save as Draft
// ════════════════════════════════════════════════════════════════
router.patch('/exam-wizard/:id/draft', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const exam = await Exam.findByIdAndUpdate(req.params.id, { status: 'draft' }, { new: true });
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    res.json({ success: true, message: 'Saved as draft', exam });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 28.8.1 — Schedule auto-publish
// ════════════════════════════════════════════════════════════════
router.patch('/exam-wizard/:id/schedule-publish', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const { publishAt } = req.body;
    if (!publishAt) return res.status(400).json({ success: false, message: 'publishAt date required' });
    const exam = await Exam.findByIdAndUpdate(req.params.id, { status: 'scheduled', scheduledPublishAt: new Date(publishAt) }, { new: true });
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    res.json({ success: true, message: `Exam scheduled to publish at ${new Date(publishAt).toLocaleString()}`, exam });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 28.8.6 — Notify Students
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/:id/notify-students', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const exam = await Exam.findById(req.params.id);
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    // Check if notification service exists
    try {
      const Notification = mongoose.model('Notification');
      const User = getUser();
      const filter = exam.batch ? { role: 'student', batch: exam.batch } : { role: 'student' };
      const students = await User.find(filter).select('_id');
      const notifs = students.map(s => ({ user: s._id, title: `New Exam: ${exam.title}`, message: `A new exam "${exam.title}" has been scheduled. Duration: ${exam.duration} min.`, type: 'exam', examId: exam._id }));
      if (notifs.length) await Notification.insertMany(notifs, { ordered: false });
      res.json({ success: true, message: `${students.length} students notified`, count: students.length });
    } catch {
      res.json({ success: true, message: 'Notification service not available. Students will see exam on next login.' });
    }
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// 28.11 — Clone Exam
// ════════════════════════════════════════════════════════════════
router.post('/exam-wizard/:id/clone', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const orig = await Exam.findById(req.params.id).lean();
    if (!orig) return res.status(404).json({ success: false, message: 'Exam not found' });
    delete orig._id; delete orig.createdAt; delete orig.updatedAt;
    const clone = await Exam.create({ ...orig, title: `${orig.title} (Copy)`, status: 'draft', publishedAt: null, scheduledPublishAt: null, createdBy: req.user.id });
    res.json({ success: true, message: 'Exam cloned!', exam: clone, examId: clone._id });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// ════════════════════════════════════════════════════════════════
// Reorder questions in exam
// ════════════════════════════════════════════════════════════════
router.patch('/exam-wizard/:id/questions/reorder', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    const { orderedIds } = req.body;
    if (!orderedIds || !Array.isArray(orderedIds)) return res.status(400).json({ success: false, message: 'orderedIds required' });
    await Exam.findByIdAndUpdate(req.params.id, { questions: orderedIds });
    res.json({ success: true, message: 'Questions reordered' });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// Remove one question from exam
router.delete('/exam-wizard/:id/questions/:qid', verifyToken, isAdmin, async (req, res) => {
  try {
    const Exam = getExam();
    await Exam.findByIdAndUpdate(req.params.id, { $pull: { questions: req.params.qid } });
    res.json({ success: true, message: 'Question removed from exam' });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

module.exports = router;
