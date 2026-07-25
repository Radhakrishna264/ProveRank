// ═══════════════════════════════════════════════════════════════
// ProveRank — Smart Paper Generator Controller
// Feature 17 (17.1–17.26) — S101
// ═══════════════════════════════════════════════════════════════
const Question = require('../models/Question');
const Exam     = require('../models/Exam');

// 17.18 — In-memory saved templates (upgradeable to DB later)
let savedPaperTemplates = [];

// ─────────────────────────────────────────────────────────────
// HELPER: Smart Question Selector (17.3 / 17.12 / 17.13 / 17.16 / 17.26)
// ─────────────────────────────────────────────────────────────
async function smartSelect({ subject, count, chapters, difficultyMix, formats, excludeUsed, excludeUsedPct, excludePYQ, excludePYQPct }) {
  const baseFilter = { subject };

  // 17.2 — Chapter filter
  if (chapters && chapters.length > 0) baseFilter.chapter = { $in: chapters };

  // 17.13 — Exclude PYQ (100% = fully exclude; <100% = allow some)
  const pyqPct = excludePYQPct != null ? excludePYQPct : 100;
  if (excludePYQ && pyqPct >= 100) baseFilter.isPYQ = { $ne: true };

  const usedPct = excludeUsedPct != null ? excludeUsedPct : 100;

  const proj = { text:1, hindiText:1, options:1, hindiOptions:1, hindiExplanation:1, correct:1, subject:1, chapter:1, topic:1, difficulty:1, type:1, explanation:1, format:1, isPYQ:1, usageCount:1, image:1, imageUrl:1, optionImages:1 };

  let selected = [];
  const alreadyIds = () => selected.map(q => q._id);

  // 17.26 — Format-based selection with %
  if (formats && formats.length > 0) {
    for (const fConf of formats) {
      const fCount = Math.ceil(count * (fConf.percent / 100));
      if (fCount <= 0) continue;
      const fFilter = { ...baseFilter, format: fConf.format };
      if (excludeUsed && usedPct >= 100) fFilter.usageCount = 0;
      const qs = await Question.aggregate([
        { $match: { ...fFilter, _id: { $nin: alreadyIds() } } },
        { $sample: { size: fCount } },
        { $project: proj }
      ]);
      selected.push(...qs);
    }
  }

  // 17.3 — Difficulty mix (% or defaults)
  const easy   = Math.round(count * ((difficultyMix && difficultyMix.easy   != null ? difficultyMix.easy   : 33) / 100));
  const medium = Math.round(count * ((difficultyMix && difficultyMix.medium != null ? difficultyMix.medium : 44) / 100));
  const hard   = count - easy - medium;

  const diffMap = [
    { level: 'Easy',   need: easy   },
    { level: 'Medium', need: medium },
    { level: 'Hard',   need: hard   }
  ];

  for (const d of diffMap) {
    const still = d.need - selected.filter(q => (q.difficulty||'').toLowerCase() === d.level.toLowerCase()).length;
    if (still <= 0) continue;
    const dFilter = { ...baseFilter, difficulty: d.level };
    if (excludeUsed && usedPct >= 100) dFilter.usageCount = 0;
    const qs = await Question.aggregate([
      { $match: { ...dFilter, _id: { $nin: alreadyIds() } } },
      { $sample: { size: still } },
      { $project: proj }
    ]);
    selected.push(...qs);
  }

  // 17.16 — Auto-balance: still short? Fill with any difficulty
  const shortfall = count - selected.length;
  if (shortfall > 0) {
    const fillFilter = { ...baseFilter };
    if (excludeUsed && usedPct >= 100) fillFilter.usageCount = 0;
    const fill = await Question.aggregate([
      { $match: { ...fillFilter, _id: { $nin: alreadyIds() } } },
      { $sample: { size: shortfall } },
      { $project: proj }
    ]);
    selected.push(...fill);
  }

  // 17.12 — Partial used allowance: if usedPct < 100, allow some used Qs
  if (excludeUsed && usedPct < 100 && selected.length < count) {
    const usedAllowed = Math.ceil(count * (usedPct / 100));
    const usedFill = await Question.aggregate([
      { $match: { ...baseFilter, usageCount: { $gt: 0 }, _id: { $nin: alreadyIds() } } },
      { $sample: { size: usedAllowed } },
      { $project: proj }
    ]);
    selected.push(...usedFill);
  }

  // 17.13 — Partial PYQ allowance
  if (excludePYQ && pyqPct < 100 && selected.length < count) {
    const pyqAllowed = Math.ceil(count * (pyqPct / 100));
    const pyqFill = await Question.aggregate([
      { $match: { ...baseFilter, isPYQ: true, _id: { $nin: alreadyIds() } } },
      { $sample: { size: pyqAllowed } },
      { $project: proj }
    ]);
    selected.push(...pyqFill);
  }

  return selected.slice(0, count);
}

// Fisher-Yates shuffle
function shuffle(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

// ─────────────────────────────────────────────────────────────
// GENERATE PAPER (17.1–17.17 / 17.26)
// POST /api/paper/generate
// ─────────────────────────────────────────────────────────────
exports.generatePaper = async (req, res) => {
  try {
    const {
      mode,             // 'neet'|'jee'|'cuet'|'custom'|'surprise'
      subjects,         // [{name, count, chapters:[], difficultyMix:{easy,medium,hard}, formats:[{format,percent}]}]
      markingScheme,    // {correct, incorrect, unattempted} — 17.4
      sets,             // 1|2|3 — 17.9
      examTitle,
      excludeUsed,      // bool — 17.12
      excludeUsedPct,   // 0-100 — 17.12
      excludePYQ,       // bool — 17.13
      excludePYQPct,    // 0-100 — 17.13
      questionFormats,  // [{format, percent}] global override — 17.26
      totalCount        // for surprise/simple modes
    } = req.body;

    let subjectConfig = [];

    // 17.15 — Surprise Me mode
    if (mode === 'surprise') {
      const total = totalCount || 90 + Math.floor(Math.random() * 91);
      const perSubj = Math.floor(total / 3);
      const diffMix = {
        easy:   20 + Math.floor(Math.random() * 20),
        medium: 40 + Math.floor(Math.random() * 15),
        hard:   0
      };
      diffMix.hard = 100 - diffMix.easy - diffMix.medium;
      const allSubjs = ['Physics', 'Chemistry', 'Biology'];
      subjectConfig = allSubjs.map(s => ({ name: s, count: perSubj, chapters: [], difficultyMix: diffMix, formats: [] }));

    } else if (mode === 'neet') {
      // 17.6 — NEET template auto-fill
      const def = { difficultyMix: { easy: 33, medium: 44, hard: 23 }, formats: questionFormats || [] };
      subjectConfig = [
        { name: 'Physics',   count: 45, chapters: [], ...def },
        { name: 'Chemistry', count: 45, chapters: [], ...def },
        { name: 'Biology',   count: 90, chapters: [], ...def }
      ];

    } else if (mode === 'jee') {
      const def = { difficultyMix: { easy: 25, medium: 50, hard: 25 }, formats: questionFormats || [] };
      subjectConfig = [
        { name: 'Physics',   count: 30, chapters: [], ...def },
        { name: 'Chemistry', count: 30, chapters: [], ...def },
        { name: 'Maths',     count: 30, chapters: [], ...def }
      ];

    } else if (mode === 'cuet') {
      const def = { difficultyMix: { easy: 40, medium: 45, hard: 15 }, formats: questionFormats || [] };
      subjectConfig = [
        { name: 'Physics',   count: 40, chapters: [], ...def },
        { name: 'Chemistry', count: 40, chapters: [], ...def },
        { name: 'Biology',   count: 40, chapters: [], ...def }
      ];

    } else {
      // 17.1 / 17.5 — Custom: subject-wise config
      if (!subjects || subjects.length === 0)
        return res.status(400).json({ success: false, message: 'Subjects config required for custom mode' });
      subjectConfig = subjects.map(s => ({
        ...s,
        formats: s.formats && s.formats.length > 0 ? s.formats : (questionFormats || [])
      }));
    }

    // Select questions per subject
    const allSelected = [];
    const selectionLog = [];

    for (const subj of subjectConfig) {
      const qs = await smartSelect({
        subject:       subj.name,
        count:         subj.count || 10,
        chapters:      subj.chapters || [],
        difficultyMix: subj.difficultyMix,
        formats:       subj.formats || [],
        excludeUsed:   excludeUsed   || false,
        excludeUsedPct: excludeUsedPct != null ? excludeUsedPct : 100,
        excludePYQ:    excludePYQ    || false,
        excludePYQPct: excludePYQPct  != null ? excludePYQPct  : 100
      });

      selectionLog.push({
        subject:   subj.name,
        requested: subj.count,
        found:     qs.length,
        shortfall: Math.max(0, (subj.count || 0) - qs.length),
        // 17.16 note
        autoBalanced: qs.length < (subj.count || 0) ? false : true
      });

      allSelected.push(...qs);
    }

    if (allSelected.length === 0) {
      return res.status(400).json({ success: false, message: 'Question Bank mein matching questions nahi hain. Pehle questions add karo.', selectionLog });
    }

    // 17.9 — Multiple Sets A / B / C
    const setCount  = Math.min(Math.max(parseInt(sets) || 1, 1), 3);
    const setLabels = ['A', 'B', 'C'];
    const generatedSets = [];

    for (let i = 0; i < setCount; i++) {
      const shuffled = shuffle(allSelected);
      generatedSets.push({
        setLabel:       setLabels[i],
        totalQuestions: shuffled.length,
        questions: shuffled.map((q, idx) => ({
          serialNo:       idx + 1,
          questionId:     q._id,
          text:           q.text,
          hindiText:      q.hindiText        || '',  // 17.27
          options:        q.options,
          hindiOptions:   q.hindiOptions     || [],  // 17.28
          optionImages:   q.optionImages     || [],  // 17.28
          imageUrl:       q.imageUrl || q.image || '', // 17.27
          correct:        q.correct,
          explanation:    q.explanation      || '',
          hindiExplanation: q.hindiExplanation || '', // 17.30
          subject:        q.subject,
          chapter:        q.chapter          || '',
          topic:          q.topic            || '',
          difficulty:     q.difficulty,
          type:           q.type             || 'SCQ',
          format:         q.format           || '',
          isPYQ:          q.isPYQ            || false
        }))
      });
    }

    // 17.17 — Set comparison (overlap count)
    const setComparison = [];
    for (let i = 0; i < generatedSets.length - 1; i++) {
      for (let j = i + 1; j < generatedSets.length; j++) {
        const idsA = new Set(generatedSets[i].questions.map(q => String(q.questionId)));
        const idsB = new Set(generatedSets[j].questions.map(q => String(q.questionId)));
        const overlap = [...idsA].filter(id => idsB.has(id)).length;
        setComparison.push({
          pair:           `Set ${generatedSets[i].setLabel} vs Set ${generatedSets[j].setLabel}`,
          overlap,
          overlapPercent: idsA.size > 0 ? Math.round((overlap / idsA.size) * 100) : 0
        });
      }
    }

    // 17.14 — answerKey: questionId → {correct, explanation}
    const answerKey = {};
    allSelected.forEach(q => {
      answerKey[String(q._id)] = { correct: q.correct, explanation: q.explanation || '' };
    });

    // Subject summary
    const subjectSummary = {};
    allSelected.forEach(q => {
      if (!subjectSummary[q.subject]) subjectSummary[q.subject] = { total: 0, Easy: 0, Medium: 0, Hard: 0, Untagged: 0 };
      subjectSummary[q.subject].total++;
      const d = q.difficulty || 'Untagged';
      if (subjectSummary[q.subject][d] !== undefined) subjectSummary[q.subject][d]++;
    });

    const mScheme = markingScheme || { correct: 4, incorrect: -1, unattempted: 0 };
    const totalMarks = allSelected.length * mScheme.correct;

    return res.json({
      success: true,
      message: `Paper generated! ${setCount} set(s) ready — ${allSelected.length} questions`,
      meta: {
        mode: mode || 'custom',
        examTitle: examTitle || 'Generated Paper',
        totalQuestions: allSelected.length,
        totalMarks,
        markingScheme: mScheme,
        setsGenerated: setCount,
        subjectConfig: subjectConfig.map(s => ({ name: s.name, count: s.count })),
        generatedAt: new Date()
      },
      selectionLog,
      subjectSummary,
      setComparison, // 17.17
      answerKey,     // 17.14
      sets: generatedSets
    });

  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ─────────────────────────────────────────────────────────────
// USE AS EXAM (17.11)
// POST /api/paper/use-as-exam
// ─────────────────────────────────────────────────────────────
exports.useAsExam = async (req, res) => {
  try {
    const { sets, meta, answerKey, examTitle, batch, type, targetType, selectedSetLabel } = req.body;

    if (!sets || sets.length === 0)
      return res.status(400).json({ success: false, message: 'No sets provided' });

    const primarySet = sets.find(s => s.setLabel === (selectedSetLabel || 'A')) || sets[0];

    // 17.14 — questionSnapshot includes correct answers (server-side only, never sent to students via attempt API)
    const questionSnapshot = primarySet.questions.map(q => ({
      questionId:      q.questionId,
      set:             primarySet.setLabel,
      serialNo:        q.serialNo,
      text:            q.text,
      hindiText:       q.hindiText        || '', // 17.27
      options:         q.options,
      hindiOptions:    q.hindiOptions     || [], // 17.28
      optionImages:    q.optionImages     || [], // 17.28
      imageUrl:        q.imageUrl         || '', // 17.27
      correct:         q.correct,
      explanation:     q.explanation      || '',
      hindiExplanation: q.hindiExplanation || '', // 17.30
      subject:         q.subject,
      chapter:         q.chapter          || '',
      difficulty:      q.difficulty,
      type:            q.type             || 'SCQ',
      format:          q.format           || '',
      isPYQ:           q.isPYQ            || false
    }));

    // Build sections from subject distribution
    const secMap = {};
    primarySet.questions.forEach(q => {
      if (!secMap[q.subject]) secMap[q.subject] = 0;
      secMap[q.subject]++;
    });
    const sections = Object.entries(secMap).map(([subject, count]) => ({
      name:          subject,
      subject,
      questionCount: count,
      marks:         count * ((meta.markingScheme && meta.markingScheme.correct) || 4)
    }));

    const exam = await Exam.create({
      title:      examTitle || meta.examTitle || 'Smart Generated Exam',
      duration:   meta.duration || 200,
      totalMarks: meta.totalMarks || primarySet.questions.length * 4,
      questions:  primarySet.questions.map(q => q.questionId),
      questionSnapshot,
      sections,
      markingScheme: {
        correct:     (meta.markingScheme && meta.markingScheme.correct)     || 4,
        incorrect:   (meta.markingScheme && meta.markingScheme.incorrect)   || -1,
        unattempted: (meta.markingScheme && meta.markingScheme.unattempted) || 0
      },
      batch:      batch    || '',
      category:   type     || 'Full Mock',
      type:       (meta.mode || 'Custom').toUpperCase(),
      status:     'draft',
      medium:     req.body.medium || 'bilingual', // 17.30
      createdBy:  req.user.id
    });

    // Update usageCount for selected questions
    const qIds = primarySet.questions.map(q => q.questionId);
    await Question.updateMany({ _id: { $in: qIds } }, { $inc: { usageCount: 1 } });

    return res.json({ success: true, message: 'Exam created! ✅', exam: { _id: exam._id, title: exam.title }, examId: exam._id });

  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ─────────────────────────────────────────────────────────────
// SAVE GENERATED SET AS TEMPLATE (17.18)
// POST /api/paper/save-template
// ─────────────────────────────────────────────────────────────
exports.saveTemplate = async (req, res) => {
  try {
    const { templateName, criteria, meta } = req.body;
    const tmpl = {
      id:          Date.now().toString(),
      name:        templateName || 'Saved Template',
      criteria:    criteria || {},
      meta:        meta     || {},
      savedAt:     new Date(),
      savedBy:     req.user.id
    };
    savedPaperTemplates.unshift(tmpl);
    if (savedPaperTemplates.length > 30) savedPaperTemplates = savedPaperTemplates.slice(0, 30);
    return res.json({ success: true, message: 'Template saved!', template: tmpl });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

// GET saved templates
exports.getSavedTemplates = async (req, res) => {
  return res.json({ success: true, templates: savedPaperTemplates });
};

// ─────────────────────────────────────────────────────────────
// EXPORT AS PDF / EXCEL (17.19)
// POST /api/paper/export
// ─────────────────────────────────────────────────────────────
exports.exportSet = async (req, res) => {
  try {
    const { format, sets, meta, selectedSet } = req.body;
    const primarySet = (sets || []).find(s => s.setLabel === (selectedSet || 'A')) || (sets || [])[0];
    if (!primarySet) return res.status(400).json({ success: false, message: 'No set data provided' });
    const title = (meta && meta.examTitle) || 'Generated_Paper';
    const scheme = (meta && meta.markingScheme) || { correct: 4, incorrect: -1 };

    if (format === 'excel') {
      const XLSX = require('xlsx');
      const wb   = XLSX.utils.book_new();
      const rows = [['#','Subject','Chapter','Difficulty','Type','Format','PYQ','Question Text','Option A','Option B','Option C','Option D','Correct (index)','Explanation']];
      primarySet.questions.forEach((q, i) => {
        rows.push([
          i + 1,
          q.subject    || '',
          q.chapter    || '',
          q.difficulty || '',
          q.type       || 'SCQ',
          q.format     || '',
          q.isPYQ      ? 'Yes' : 'No',
          q.text       || '',
          (q.options && q.options[0]) || '',
          (q.options && q.options[1]) || '',
          (q.options && q.options[2]) || '',
          (q.options && q.options[3]) || '',
          (q.correct  || []).join(','),
          q.explanation || ''
        ]);
      });
      const ws = XLSX.utils.aoa_to_sheet(rows);
      ws['!cols'] = [{wch:4},{wch:12},{wch:16},{wch:10},{wch:8},{wch:16},{wch:5},{wch:60},{wch:25},{wch:25},{wch:25},{wch:25},{wch:12},{wch:60}];
      XLSX.utils.book_append_sheet(wb, ws, `Set_${primarySet.setLabel}`);
      const buf = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });
      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.setHeader('Content-Disposition', `attachment; filename="${title}_Set_${primarySet.setLabel}.xlsx"`);
      return res.send(buf);
    }

    if (format === 'pdf') {
      const PDFDocument = require('pdfkit');
      const doc = new PDFDocument({ margin: 50, size: 'A4' });
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename="${title}_Set_${primarySet.setLabel}.pdf"`);
      doc.pipe(res);
      doc.fontSize(16).font('Helvetica-Bold').text(`${title} — Set ${primarySet.setLabel}`, { align: 'center' });
      doc.moveDown(0.3);
      doc.fontSize(10).font('Helvetica').text(`Total: ${primarySet.totalQuestions} Questions | Marking: +${scheme.correct} / ${scheme.incorrect} | Generated: ${new Date().toLocaleDateString()}`, { align: 'center' });
      doc.moveDown(1);
      primarySet.questions.forEach((q, i) => {
        if (doc.y > 720) doc.addPage();
        doc.fontSize(11).font('Helvetica-Bold').text(`Q${i + 1}. [${q.subject}] [${q.difficulty}]${q.isPYQ ? ' [PYQ]' : ''} ${q.text}`);
        (q.options || []).forEach((opt, j) => {
          doc.fontSize(10).font('Helvetica').text(`    ${String.fromCharCode(65 + j)}) ${opt}`);
        });
        doc.moveDown(0.6);
      });
      doc.addPage();
      doc.fontSize(14).font('Helvetica-Bold').text('ANSWER KEY', { align: 'center' });
      doc.moveDown(0.5);
      primarySet.questions.forEach((q, i) => {
        const ans = (q.correct || []).map(idx => String.fromCharCode(65 + idx)).join(', ');
        doc.fontSize(9).font('Helvetica').text(`Q${i + 1}: ${ans}   `, { continued: (i + 1) % 6 !== 0 });
      });
      doc.end();
      return;
    }

    return res.status(400).json({ success: false, message: 'format must be pdf or excel' });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ─────────────────────────────────────────────────────────────
// BANK STATS (enhanced — includes formatWise for 17.26)
// GET /api/paper/stats
// ─────────────────────────────────────────────────────────────
exports.getBankStats = async (req, res) => {
  try {
    const stats = await Question.aggregate([
      { $group: { _id: { subject: '$subject', difficulty: '$difficulty' }, count: { $sum: 1 } } },
      { $sort: { '_id.subject': 1 } }
    ]);
    const formatStats = await Question.aggregate([
      { $group: { _id: '$format', count: { $sum: 1 } } },
      { $sort: { count: -1 } }
    ]);
    const chapterStats = await Question.aggregate([
      { $match: { chapter: { $ne: '' } } },
      { $group: { _id: { subject: '$subject', chapter: '$chapter' }, count: { $sum: 1 } } },
      { $sort: { '_id.subject': 1, '_id.chapter': 1 } }
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

    // Chapters by subject
    const chaptersBySubject = {};
    chapterStats.forEach(c => {
      const subj = c._id.subject || 'Unknown';
      if (!chaptersBySubject[subj]) chaptersBySubject[subj] = [];
      chaptersBySubject[subj].push({ chapter: c._id.chapter, count: c.count });
    });

    return res.json({
      success: true,
      totalQuestions: total,
      neetReady: {
        physics:          summary['Physics']?.total   || 0,
        chemistry:        summary['Chemistry']?.total || 0,
        biology:          summary['Biology']?.total   || 0,
        canGenerateNEET:  (summary['Physics']?.total || 0) >= 45 && (summary['Chemistry']?.total || 0) >= 45 && (summary['Biology']?.total || 0) >= 90
      },
      subjectWise:       summary,
      formatWise:        formatStats,
      chaptersBySubject
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};


// ─────────────────────────────────────────────────────────────
// REPLACE QUESTION (17.29) — reject one, get another from QB
// POST /api/paper/replace-question
// ─────────────────────────────────────────────────────────────
exports.replaceQuestion = async (req, res) => {
  try {
    const { questionId, subject, chapter, difficulty, excludeIds } = req.body;
    const filter = {
      subject,
      _id: { $nin: [...(excludeIds || []), questionId].filter(Boolean) }
    };
    if (chapter)    filter.chapter    = chapter;
    if (difficulty) filter.difficulty = difficulty;

    const [replacement] = await Question.aggregate([
      { $match: filter },
      { $sample: { size: 1 } },
      { $project: {
        text:1, hindiText:1, options:1, hindiOptions:1, hindiExplanation:1,
        correct:1, subject:1, chapter:1, topic:1, difficulty:1, type:1,
        explanation:1, format:1, isPYQ:1, usageCount:1,
        image:1, imageUrl:1, optionImages:1
      }}
    ]);

    if (!replacement)
      return res.status(404).json({ success:false, message:'No replacement question found in QB' });

    return res.json({ success:true, question: replacement });
  } catch (err) {
    return res.status(500).json({ success:false, message: err.message });
  }
};
