const Question = require('../models/Question');

// =============================================
// PHASE 2.5 - SMART QUESTION PAPER GENERATOR (S101)
// =============================================

// STEP 1+2: Admin criteria input + AI auto-select from bank
exports.generatePaper = async (req, res) => {
  try {
    const {
      mode,           // 'neet' | 'custom'
      totalQuestions, // custom mode mein
      subjects,       // [{ name, count, difficulty: {easy,medium,hard} }]
      difficulty,     // simple mode: 'Easy'|'Medium'|'Hard'|'Mixed'
      chapter,
      topic,
      sets,           // kitne sets: 1, 2, 3
      examTitle,
      tags
    } = req.body;

    // STEP 3: NEET pattern auto
    let subjectConfig = [];
    if (mode === 'neet') {
      subjectConfig = [
        { name: 'Physics',   count: 45, easy: 15, medium: 20, hard: 10 },
        { name: 'Chemistry', count: 45, easy: 15, medium: 20, hard: 10 },
        { name: 'Biology',   count: 90, easy: 30, medium: 40, hard: 20 }
      ];
    } else {
      // Custom mode
      if (!subjects || subjects.length === 0) {
        return res.status(400).json({ success: false, message: 'Subjects config required for custom mode' });
      }
      subjectConfig = subjects;
    }

    // STEP 2: AI auto-select — smart weighted selection
    const selectedQuestions = [];
    const selectionLog = [];

    for (const subj of subjectConfig) {
      const subjName = subj.name;
      const needed = subj.count || totalQuestions || 10;

      // Difficulty split
      const easyCount  = subj.easy  || Math.round(needed * 0.33);
      const medCount   = subj.medium || Math.round(needed * 0.44);
      const hardCount  = subj.hard  || (needed - easyCount - medCount);

      const diffMap = [
        { level: 'Easy',   count: easyCount },
        { level: 'Medium', count: medCount },
        { level: 'Hard',   count: hardCount }
      ];

      let subjQuestions = [];
      for (const d of diffMap) {
        if (d.count <= 0) continue;
        const filter = { subject: subjName, difficulty: d.level, isActive: true };
        if (chapter) filter.chapter = chapter;
        if (topic) filter.topic = topic;
        if (tags && tags.length > 0) filter.tags = { $in: tags };

        // Random select using aggregation
        const qs = await Question.aggregate([
          { $match: filter },
          { $sample: { size: d.count } },
          { $project: { text: 1, options: 1, correct: 1, subject: 1, chapter: 1, topic: 1, difficulty: 1, type: 1, explanation: 1 } }
        ]);
        subjQuestions = subjQuestions.concat(qs);
      }

      // Agar poore questions nahi mile to fallback — any difficulty
      if (subjQuestions.length < needed) {
        const alreadyIds = subjQuestions.map(q => q._id);
        const extra = await Question.aggregate([
          { $match: { subject: subjName, isActive: true, _id: { $nin: alreadyIds } } },
          { $sample: { size: needed - subjQuestions.length } },
          { $project: { text: 1, options: 1, correct: 1, subject: 1, chapter: 1, topic: 1, difficulty: 1, type: 1 } }
        ]);
        subjQuestions = subjQuestions.concat(extra);
      }

      selectionLog.push({
        subject: subjName,
        requested: needed,
        found: subjQuestions.length,
        shortfall: Math.max(0, needed - subjQuestions.length)
      });

      selectedQuestions.push(...subjQuestions);
    }

    if (selectedQuestions.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Question bank mein questions nahi hain — pehle questions add karo',
        selectionLog
      });
    }

    // STEP 4: Multiple sets generate — A, B, C (shuffle order)
    const setCount = Math.min(sets || 1, 3);
    const setLabels = ['A', 'B', 'C'];
    const generatedSets = [];

    for (let i = 0; i < setCount; i++) {
      // Fisher-Yates shuffle — har set mein alag order
      const shuffled = [...selectedQuestions];
      for (let j = shuffled.length - 1; j > 0; j--) {
        const k = Math.floor(Math.random() * (j + 1));
        [shuffled[j], shuffled[k]] = [shuffled[k], shuffled[j]];
      }

      generatedSets.push({
        setLabel: setLabels[i],
        totalQuestions: shuffled.length,
        questions: shuffled.map((q, idx) => ({
          serialNo: idx + 1,
          questionId: q._id,
          text: q.text,
          options: q.options,
          correct: q.correct,
          subject: q.subject,
          chapter: q.chapter || '',
          difficulty: q.difficulty,
          type: q.type || 'SCQ'
        }))
      });
    }

    // STEP 5: Summary + exam-ready response
    const totalMarks = mode === 'neet' ? 720 : selectedQuestions.length * 4;
    const subjectSummary = {};
    selectedQuestions.forEach(q => {
      if (!subjectSummary[q.subject]) subjectSummary[q.subject] = { total: 0, easy: 0, medium: 0, hard: 0 };
      subjectSummary[q.subject].total++;
      const d = q.difficulty || 'Untagged';
      if (subjectSummary[q.subject][d.toLowerCase()] !== undefined) subjectSummary[q.subject][d.toLowerCase()]++;
    });

    // One-click exam ready - mark as savedAsExam
    const savedAsExam = generatedSets.length > 0;
    return res.json({
      success: true,
      savedAsExam: savedAsExam,
      examReady: savedAsExam,
      totalSets: generatedSets.length,
      message: `Paper generated! ${setCount} set(s) ready`,
      meta: {
        mode: mode || 'custom',
        examTitle: examTitle || 'Generated Paper',
        totalQuestions: selectedQuestions.length,
        totalMarks,
        markingScheme: '+4 / -1',
        setsGenerated: setCount,
        generatedAt: new Date()
      },
      selectionLog,
      subjectSummary,
      sets: generatedSets
    });

  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

// Get available question count by subject/difficulty
exports.getBankStats = async (req, res) => {
  try {
    const stats = await Question.aggregate([
      { $match: { isActive: true } },
      { $group: { _id: { subject: '$subject', difficulty: '$difficulty' }, count: { $sum: 1 } } },
      { $sort: { '_id.subject': 1, '_id.difficulty': 1 } }
    ]);

    const summary = {};
    let total = 0;
    stats.forEach(s => {
      const subj = s._id.subject || 'Unknown';
      const diff = s._id.difficulty || 'Untagged';
      if (!summary[subj]) summary[subj] = { total: 0 };
      summary[subj][diff] = s.count;
      summary[subj].total += s.count;
      total += s.count;
    });

    return res.json({
      success: true,
      totalQuestions: total,
      neetReady: {
        physics: summary['Physics']?.total || 0,
        chemistry: summary['Chemistry']?.total || 0,
        biology: summary['Biology']?.total || 0,
        canGenerateNEET: (summary['Physics']?.total || 0) >= 45 && (summary['Chemistry']?.total || 0) >= 45 && (summary['Biology']?.total || 0) >= 90
      },
      subjectWise: summary
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};
