// ============================================
// Phase 3.1 - Random Selection Engine
// Step 1: Utility | Step 2: Subject Filter
// Step 3: Difficulty Filter | Step 4: Weighted Algorithm
// Step 5: Snapshot Lock | Step 6: S58 Randomize Order
// ============================================

const Question = require('../models/Question');

// Step 2: NEET Default Distribution
const NEET_DISTRIBUTION = {
  Physics: 45,
  Chemistry: 45,
  Biology: 90
};

// Step 3: Default Difficulty Weights (%)
const DEFAULT_DIFFICULTY_WEIGHTS = {
  Easy: 30,
  Medium: 50,
  Hard: 20
};

// ─── Step 1+3+4: Weighted Selection (ek subject ke liye) ───
async function selectBySubjectAndDifficulty(subject, count, weights) {
  const w = weights || DEFAULT_DIFFICULTY_WEIGHTS;
  const total = w.Easy + w.Medium + w.Hard;

  const easyCount  = Math.round((w.Easy   / total) * count);
  const hardCount  = Math.round((w.Hard   / total) * count);
  const mediumCount = count - easyCount - hardCount;

  const matchBase = {
    subject,
    approvalStatus: { $ne: 'rejected' }
  };

  const [easyQs, mediumQs, hardQs] = await Promise.all([
    Question.aggregate([
      { $match: { ...matchBase, difficulty: 'Easy' } },
      { $sample: { size: easyCount } },
      { $project: { _id:1, text:1, hindiText:1, options:1, correct:1,
                    subject:1, chapter:1, difficulty:1, type:1,
                    image:1, explanation:1, isPYQ:1, pyqYear:1 } }
    ]),
    Question.aggregate([
      { $match: { ...matchBase, difficulty: 'Medium' } },
      { $sample: { size: mediumCount } },
      { $project: { _id:1, text:1, hindiText:1, options:1, correct:1,
                    subject:1, chapter:1, difficulty:1, type:1,
                    image:1, explanation:1, isPYQ:1, pyqYear:1 } }
    ]),
    Question.aggregate([
      { $match: { ...matchBase, difficulty: 'Hard' } },
      { $sample: { size: hardCount } },
      { $project: { _id:1, text:1, hindiText:1, options:1, correct:1,
                    subject:1, chapter:1, difficulty:1, type:1,
                    image:1, explanation:1, isPYQ:1, pyqYear:1 } }
    ])
  ]);

  return [...easyQs, ...mediumQs, ...hardQs];
}

// ─── Step 2: Full NEET Paper Generate karo ───
async function generateNEETPaper(customDistribution, difficultyWeights) {
  const distribution = customDistribution || NEET_DISTRIBUTION;
  const weights      = difficultyWeights  || DEFAULT_DIFFICULTY_WEIGHTS;

  const allQuestions = [];
  const shortfall    = [];

  for (const [subject, count] of Object.entries(distribution)) {
    const selected = await selectBySubjectAndDifficulty(subject, count, weights);

    if (selected.length < count) {
      shortfall.push(
        `${subject}: ${selected.length} available, ${count} chahiye`
      );
    }
    allQuestions.push(...selected);
  }

  if (shortfall.length > 0) {
    return {
      success: false,
      error: `Question bank mein enough questions nahi hain:\n${shortfall.join('\n')}`
    };
  }

  return { success: true, questions: allQuestions };
}

// ─── Step 5: Question Snapshot Lock ───
async function lockQuestionSnapshot(examId, questions) {
  const Exam = require('../models/Exam');

  const snapshot = questions.map((q, index) => ({
    questionId  : q._id,
    order       : index + 1,
    text        : q.text,
    hindiText   : q.hindiText   || '',
    options     : q.options,
    correct     : q.correct,
    subject     : q.subject,
    chapter     : q.chapter     || '',
    difficulty  : q.difficulty,
    type        : q.type        || 'SCQ',
    image       : q.image       || null,
    explanation : q.explanation || '',
    isPYQ       : q.isPYQ       || false,
    pyqYear     : q.pyqYear     || null
  }));

  await Exam.findByIdAndUpdate(examId, {
    questionSnapshot  : snapshot,
    snapshotLocked    : true,
    snapshotLockedAt  : new Date()
  });

  return snapshot;
}

// ─── Step 6: S58 — Randomize Order per Student ───
// Same student ko har refresh pe same order milega (deterministic)
function randomizeForStudent(questions, studentId, examId) {
  const seed = `${studentId}-${examId}`;
  let seedNum = 0;

  for (let i = 0; i < seed.length; i++) {
    seedNum = ((seedNum << 5) - seedNum) + seed.charCodeAt(i);
    seedNum |= 0;
  }

  const arr = [...questions];
  let rand = Math.abs(seedNum);

  // Fisher-Yates seeded shuffle
  for (let i = arr.length - 1; i > 0; i--) {
    rand = (rand * 1664525 + 1013904223) & 0xffffffff;
    const j = Math.abs(rand) % (i + 1);
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }

  return arr.map((q, idx) => ({
    ...q,
    displayOrder: idx + 1
  }));
}

module.exports = {
  generateNEETPaper,
  selectBySubjectAndDifficulty,
  lockQuestionSnapshot,
  randomizeForStudent,
  NEET_DISTRIBUTION,
  DEFAULT_DIFFICULTY_WEIGHTS
};
