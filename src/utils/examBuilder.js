const Question = require('../models/Question');
const Exam = require('../models/Exam');
const Batch = require('../models/Batch');
const TestSeries = require('../models/TestSeries');
const StudentNotification = require('../models/StudentNotification');
const User = require('../models/User');

// ══════════════════════════════════════════════════════════════
// Shared "Create Exam from parsed questions" engine — used by
// Feature 19B (paste), 20B (excel), 21B (pdf). Mirrors the proven
// useAsExam() pattern already used elsewhere in this codebase.
// ══════════════════════════════════════════════════════════════

// F19B.5.4 / F20B.5.4 / F21B.8.4 — auto-select N out of M parsed questions,
// honouring subject-wise distribution if provided (F19B.5.5/F20B.5.5/F21B.8.5)
function selectQuestions(parsedList, totalRequested, subjectWiseCount) {
  if (!totalRequested || totalRequested >= parsedList.length) return parsedList;

  if (Array.isArray(subjectWiseCount) && subjectWiseCount.length > 0) {
    const out = [];
    subjectWiseCount.forEach(({ subject, count }) => {
      const pool = parsedList.filter(q => (q.subject || '').toLowerCase() === String(subject || '').toLowerCase());
      out.push(...pool.slice(0, count));
    });
    if (out.length > 0) return out;
  }
  return parsedList.slice(0, totalRequested);
}

// F19B.5.21 / F20B.5.21 / F21B.8.21 — order questions by subject so the live exam
// shows "Q.No X to Y => Subject Z" as continuous ranges, and build `sections[]`.
function orderAndBuildSections(list) {
  const bySubject = {};
  const order = [];
  list.forEach(q => {
    const subj = q.subject || 'General';
    if (!bySubject[subj]) { bySubject[subj] = []; order.push(subj); }
    bySubject[subj].push(q);
  });
  const ordered = [];
  const sections = [];
  let cursor = 1;
  order.forEach(subj => {
    const group = bySubject[subj];
    const from = cursor;
    const to = cursor + group.length - 1;
    sections.push({ name: subj, subject: subj, questionCount: group.length, timeLimit: 0, marks: 0, fromQNo: from, toQNo: to });
    ordered.push(...group);
    cursor = to + 1;
  });
  return { ordered, sections };
}

/**
 * Inserts parsed questions as real Question documents (so they're searchable
 * in QsBank too, per F19B.7.1/F19B.7.4), then creates the Exam linked to them,
 * with a tamper-proof questionSnapshot (same convention as paperGenerator.useAsExam).
 *
 * @param {object} p
 *   parsedQuestions   - array of { text, hindiText, options, hindiOptions, correct, subject,
 *                        chapter, topic, difficulty, type, explanation, hindiExplanation,
 *                        imageUrl, optionImages, tags }
 *   examDetails       - { title, subject, category, type, duration, totalMarks, markingScheme,
 *                          schedule, customInstructions, password, whitelistEnabled, waitingRoomEnabled,
 *                          waitingRoomMinutes, reattemptCount, unlimitedAttempts, reviewWindow,
 *                          watermark, totalQuestionsRequested, subjectWiseCount }
 *   assignment        - { assignmentType, batch, multiBatch, seriesName, notifyStudents }
 *   postCreate         - { scheduledPublish, isTemplate, status }
 *   sourceMeta        - { sourceType, fileName, uploadedAt, pageCount, totalParsed, totalErrors, totalDuplicates }
 *   createdBy         - user id
 */
async function createExamFromQuestions({ parsedQuestions, examDetails, assignment, postCreate, sourceMeta, createdBy }) {
  if (!Array.isArray(parsedQuestions) || parsedQuestions.length === 0) {
    throw new Error('No questions to create exam with');
  }

  // F19B.5.4/20B.5.4/21B.8.4 + F19B.5.5/20B.5.5/21B.8.5
  const selected = selectQuestions(parsedQuestions, examDetails.totalQuestionsRequested, examDetails.subjectWiseCount);
  const { ordered, sections } = orderAndBuildSections(selected); // F19B.5.21/20B.5.21/21B.8.21

  // Insert as real Question docs (F19B.7.1 "creates exam with questions[]")
  const docs = ordered.map(q => ({
    text: q.text,
    hindiText: q.hindiText || '',
    options: q.options,
    hindiOptions: q.hindiOptions || [],
    correct: q.correct,
    subject: q.subject || 'General',
    chapter: q.chapter || '',
    topic: q.topic || '',
    difficulty: q.difficulty || 'Medium',
    type: q.type || 'SCQ',
    explanation: q.explanation || '',
    hindiExplanation: q.hindiExplanation || '',
    imageUrl: q.imageUrl || '',
    optionImages: q.optionImages || [],
    tags: q.tags || [],
    isPYQ: false,
    sourceExam: examDetails.title || '',
    createdBy,
  }));

  const inserted = await Question.insertMany(docs);

  // questionSnapshot — tamper-proof copy shown live (same convention as paperGenerator.useAsExam)
  const questionSnapshot = inserted.map((doc, i) => ({
    _id: doc._id,
    text: doc.text,
    hindiText: doc.hindiText,
    options: doc.options,
    hindiOptions: doc.hindiOptions,
    correct: doc.correct,
    subject: doc.subject,
    type: doc.type,
    explanation: doc.explanation,
    hindiExplanation: doc.hindiExplanation,
    imageUrl: doc.imageUrl,
    optionImages: doc.optionImages,
  }));

  const totalMarks = examDetails.totalMarks || (ordered.length * (examDetails.markingScheme?.correct || 4));

  // F19B.6 / F20B.6 / F21B.9 — Assignment Type resolution
  const assignmentType = assignment.assignmentType || 'individual';
  const category = examDetails.category || 'Full Mock';

  // 🔧 FIX (Assign System) — resolve real Test Series name instead of storing raw text
  let resolvedSeriesName = '';
  if (assignmentType === 'series' && assignment.testSeriesId) {
    try {
      const seriesDoc = await TestSeries.findById(assignment.testSeriesId).select('name title').lean();
      resolvedSeriesName = seriesDoc ? (seriesDoc.name || seriesDoc.title || '') : '';
    } catch {}
  }

  // F19B.5.16 / F20B.5.16 / F21B.8.16 — Unlimited attempts -> large maxAttempts (no other code needs to change)
  const maxAttempts = examDetails.unlimitedAttempts ? 99999 : (examDetails.maxAttempts || 1);

  const exam = await Exam.create({
    title: examDetails.title,
    subject: examDetails.subject || sections[0]?.subject || 'NEET',
    duration: examDetails.duration, // F19B.5.7/20B.5.7/21B.8.7 ⚠️ field name "duration", NOT totalDurationSec
    totalMarks,
    questions: inserted.map(d => d._id),
    sections,
    markingScheme: examDetails.markingScheme || { correct: 4, incorrect: -1, unattempted: 0 },
    password: examDetails.password || '',
    schedule: examDetails.schedule || {},
    category,
    batch: assignmentType === 'batch' ? (assignment.batch || '') : '',
    multiBatch: assignment.multiBatch || [],
    assignmentType,
    testSeriesId: assignmentType === 'series' ? (assignment.testSeriesId || null) : null,
    seriesName: resolvedSeriesName,
    watermark: examDetails.watermark !== false,
    customInstructions: examDetails.customInstructions || '',
    reviewWindow: examDetails.reviewWindow || { enabled: false, durationMinutes: 0 },
    type: examDetails.type || 'NEET',
    waitingRoomEnabled: !!examDetails.waitingRoomEnabled,
    waitingRoomMinutes: examDetails.waitingRoomMinutes || 10,
    maxAttempts,
    unlimitedAttempts: !!examDetails.unlimitedAttempts,
    reattemptCount: examDetails.reattemptCount || 'last',
    questionSnapshot,
    whitelistEnabled: !!examDetails.whitelistEnabled,
    whitelistedStudents: examDetails.whitelistedStudents || [],
    whitelistedGroups: examDetails.whitelistedGroups || [],
    subjectWiseCount: examDetails.subjectWiseCount || [],
    totalQuestionsRequested: examDetails.totalQuestionsRequested || 0,
    scheduledPublish: postCreate?.scheduledPublish || { enabled: false, publishAt: null },
    notifyStudents: !!assignment.notifyStudents,
    isTemplate: !!postCreate?.isTemplate,
    sourceMeta: sourceMeta || {},
    createdBy,
    // F19B.7.3 — Do NOT send `status`; schema default 'draft' applies UNLESS explicit publish-now requested
    ...(postCreate?.status
        ? { status: postCreate.status }
        : (postCreate?.scheduledPublish?.enabled && postCreate?.scheduledPublish?.publishAt)
          // F56 FIX — scheduledPublish.publishAt was written but never actually used
          // to set status/schedule.startTime, so computeExamState() never picked it up
          // and the exam stayed an invisible draft forever.
          ? { status: 'scheduled', schedule: { ...(examDetails.schedule || {}), startTime: (examDetails.schedule && examDetails.schedule.startTime) || new Date(postCreate.scheduledPublish.publishAt) } }
          : {})
  });

  await Question.updateMany({ _id: { $in: inserted.map(d => d._id) } }, { $inc: { usageCount: 1 } }).catch(() => {});

  // 🔧 FIX (Assign System) — link the exam back into the Batch/TestSeries so it actually
  // "uploads" into that batch/series (same fix applied to Create Exam wizard + Smart Paper Gen).
  try {
    if (assignmentType === 'batch' && assignment.batch) {
      await Batch.findByIdAndUpdate(assignment.batch, { $addToSet: { exams: exam._id } });
    } else if (assignmentType === 'series' && assignment.testSeriesId) {
      await TestSeries.findByIdAndUpdate(assignment.testSeriesId, { $addToSet: { tests: exam._id } });
    }
    if (assignment.multiBatch && assignment.multiBatch.length) {
      await Batch.updateMany({ _id: { $in: assignment.multiBatch } }, { $addToSet: { exams: exam._id } });
    }
  } catch (linkErr) {
    console.error('Assign-link warning (exam created but batch/series link failed):', linkErr.message);
  }

  // F19B.8.6 / F20B.8.6 / F21B.11.6 — Notify Students toggle
  let notifiedCount = 0;
  if (assignment.notifyStudents && assignment.batch) {
    try {
      const students = await User.find({ batch: assignment.batch, role: 'student' }).select('_id');
      const notifs = students.map(s => ({
        userId: s._id,
        batchId: assignment.batch,
        type: 'batch_update', // reuse existing enum value (no model changes needed)
        title: 'New Exam Published',
        message: `A new exam "${exam.title}" has been added to your batch.`,
        link: `/exam/${exam._id}`,
      }));
      if (notifs.length > 0) { await StudentNotification.insertMany(notifs); notifiedCount = notifs.length; }
    } catch (e) { /* notification failure should never block exam creation */ }
  }

  return { exam, questionsCreated: inserted.length, notifiedCount };
}

module.exports = { createExamFromQuestions, selectQuestions, orderAndBuildSections };

