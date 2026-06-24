/**
 * ProveRank — Feature 25: Question Bank Stats Dashboard
 * Comprehensive analytics: type dist · approval · quality · growth · contributors
 */
const express  = require('express');
const router   = express.Router();
const Question = require('../models/Question');
const { verifyToken, isAdmin } = require('../middleware/auth');

// ════════════════════════════════════════════════════════════════
// 25 — Master Stats (single endpoint, all sub-features)
// ════════════════════════════════════════════════════════════════
router.get('/question-bank/stats', verifyToken, isAdmin, async (req, res) => {
  try {
    const now    = new Date();
    const week   = new Date(now - 7  * 86400000);
    const month  = new Date(now - 30 * 86400000);
    const base   = { isDeleted: { $ne: true }, isArchived: { $ne: true } };

    // ── Parallel aggregations ──────────────────────────────────────────────────
    const [
      total, bySubject, byDifficulty, byType, byApproval,
      withImage, withoutExplanation, neverUsed, mostUsed,
      addedThisWeek, addedThisMonth, weeklyGrowth, contributors,
      pyqCount
    ] = await Promise.all([

      // Total active
      Question.countDocuments(base),

      // 25 — By subject
      Question.aggregate([
        { $match: base },
        { $group: { _id: '$subject', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]),

      // 25 — By difficulty
      Question.aggregate([
        { $match: base },
        { $group: { _id: '$difficulty', count: { $sum: 1 } } }
      ]),

      // 25.1 — Type distribution (SCQ/MSQ/Integer)
      Question.aggregate([
        { $match: base },
        { $group: { _id: '$type', count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ]),

      // 25.2 — Approval breakdown
      Question.aggregate([
        { $match: base },
        { $group: { _id: '$approvalStatus', count: { $sum: 1 } } }
      ]),

      // 25.3 — With image
      Question.countDocuments({ ...base, $or: [{ image: { $ne: '' } }, { imageUrl: { $ne: '' } }] }),

      // 25.4 — Without explanation
      Question.countDocuments({ ...base, $or: [{ explanation: '' }, { explanation: null }] }),

      // 25.5 — Never used
      Question.countDocuments({ ...base, usageCount: { $lte: 0 } }),

      // 25.6 — Most used top 10
      Question.find({ ...base, usageCount: { $gt: 0 } })
        .sort({ usageCount: -1 })
        .limit(10)
        .select('text subject chapter difficulty usageCount type'),

      // 25.7 — Added this week
      Question.countDocuments({ ...base, createdAt: { $gte: week } }),

      // 25.7 — Added this month
      Question.countDocuments({ ...base, createdAt: { $gte: month } }),

      // 25.10 — Week-over-week growth (last 12 weeks)
      Question.aggregate([
        { $match: { ...base, createdAt: { $gte: new Date(now - 84 * 86400000) } } },
        {
          $group: {
            _id: {
              year:  { $year: '$createdAt' },
              week:  { $week: '$createdAt' }
            },
            count: { $sum: 1 },
            from:  { $min: '$createdAt' }
          }
        },
        { $sort: { '_id.year': 1, '_id.week': 1 } },
        { $limit: 12 }
      ]),

      // 25.11 — Contributor stats (top 10 by count)
      Question.aggregate([
        { $match: base },
        { $group: { _id: '$createdBy', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 10 },
        { $lookup: { from: 'users', localField: '_id', foreignField: '_id', as: 'user' } },
        { $unwind: { path: '$user', preserveNullAndEmpty: true } },
        {
          $project: {
            count: 1,
            name:  { $ifNull: ['$user.name',  'Unknown'] },
            email: { $ifNull: ['$user.email', ''] },
            role:  { $ifNull: ['$user.role',  'admin'] }
          }
        }
      ]),

      // PYQ count
      Question.countDocuments({ ...base, isPYQ: true })
    ]);

    // ── 25.9 Health Score ──────────────────────────────────────────────────────
    const t = total || 1;
    const withExpl   = t - withoutExplanation;
    const withImg    = withImage;
    const approved   = (byApproval.find((a:any) => a._id === 'approved') || { count: 0 }).count;
    const usedOnce   = t - neverUsed;

    const explScore  = Math.round((withExpl / t) * 30);    // 30pts: explanations
    const imgScore   = Math.round((withImg  / t) * 20);    // 20pts: images
    const apprScore  = Math.round((approved / t) * 25);    // 25pts: approval rate
    const usageScore = Math.round((usedOnce / t) * 15);    // 15pts: usage
    const pyqScore   = Math.min(10, Math.round((pyqCount / t) * 10)); // 10pts: PYQ
    const healthScore = explScore + imgScore + apprScore + usageScore + pyqScore;

    // ── Format response ────────────────────────────────────────────────────────
    const bySubjectMap: Record<string, number> = {};
    bySubject.forEach((s: any) => { bySubjectMap[s._id || 'Unknown'] = s.count; });

    const byDiffMap: Record<string, number> = {};
    byDifficulty.forEach((d: any) => { byDiffMap[d._id || 'Unknown'] = d.count; });

    const byTypeMap: Record<string, number> = {};
    byType.forEach((t: any) => { byTypeMap[t._id || 'Unknown'] = t.count; });

    const byApprovalMap: Record<string, number> = { approved: 0, pending: 0, rejected: 0 };
    byApproval.forEach((a: any) => { byApprovalMap[a._id || 'pending'] = a.count; });

    res.json({
      success: true,
      fetchedAt: new Date(),
      overview: {
        total, pyqCount,
        addedThisWeek, addedThisMonth,
        withImage, withoutExplanation,
        withExplanation: withExpl,
        neverUsed, usedAtLeastOnce: usedOnce,
      },
      bySubject:    bySubjectMap,
      byDifficulty: byDiffMap,
      byType:       byTypeMap,       // 25.1
      byApproval:   byApprovalMap,   // 25.2
      mostUsed:     mostUsed.map((q: any) => ({
        _id: q._id, text: (q.text||'').slice(0,80),
        subject: q.subject, chapter: q.chapter,
        difficulty: q.difficulty, type: q.type,
        usageCount: q.usageCount
      })),                           // 25.6
      weeklyGrowth: weeklyGrowth.map((w: any) => ({
        week:  `W${w._id.week}/${w._id.year}`,
        count: w.count,
        from:  w.from
      })),                           // 25.10
      contributors,                  // 25.11
      health: {
        score: healthScore,
        breakdown: { explScore, imgScore, apprScore, usageScore, pyqScore },
        label: healthScore >= 85 ? 'Excellent' : healthScore >= 70 ? 'Good' : healthScore >= 50 ? 'Fair' : 'Needs Work'
      }                              // 25.9
    });
  } catch (err: any) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ════════════════════════════════════════════════════════════════
// 25.8 — Export Stats as JSON (for PDF/Excel generation on frontend)
// ════════════════════════════════════════════════════════════════
router.get('/question-bank/stats/export', verifyToken, isAdmin, async (req, res) => {
  try {
    const base = { isDeleted: { $ne: true }, isArchived: { $ne: true } };
    const questions = await Question.find(base)
      .select('subject difficulty type approvalStatus usageCount explanation image imageUrl isPYQ createdAt createdBy chapter')
      .populate('createdBy', 'name email')
      .lean();

    // Format for Excel rows
    const rows = questions.map((q: any, i: number) => ({
      'No':          i + 1,
      'Subject':     q.subject || '',
      'Chapter':     q.chapter || '',
      'Difficulty':  q.difficulty || '',
      'Type':        q.type || 'SCQ',
      'Approval':    q.approvalStatus || 'pending',
      'Usage Count': q.usageCount || 0,
      'Has Explanation': q.explanation ? 'Yes' : 'No',
      'Has Image':   (q.image || q.imageUrl) ? 'Yes' : 'No',
      'Is PYQ':      q.isPYQ ? 'Yes' : 'No',
      'Added By':    q.createdBy?.name || 'Unknown',
      'Added On':    q.createdAt ? new Date(q.createdAt).toLocaleDateString('en-IN') : '',
    }));

    res.json({ success: true, rows, total: rows.length });
  } catch (err: any) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ════════════════════════════════════════════════════════════════
// 25.5 — Never-used questions list (paginated)
// ════════════════════════════════════════════════════════════════
router.get('/question-bank/never-used', verifyToken, isAdmin, async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query as any;
    const base = { isDeleted: { $ne: true }, isArchived: { $ne: true }, usageCount: { $lte: 0 } };
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const questions = await Question.find(base).sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit)).select('text subject chapter difficulty type createdAt');
    const total     = await Question.countDocuments(base);
    res.json({ success: true, total, questions });
  } catch (err: any) {
    res.status(500).json({ success: false, message: err.message }); }
});

module.exports = router;
