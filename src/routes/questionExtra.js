const express = require('express');
const router = express.Router();
const Question = require('../models/Question');
const { verifyToken, isAdmin } = require('../middleware/auth');
const multer = require('multer');
const path = require('path');

// ✅ STEP 11 - Image upload setup (S33)
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, './uploads/'),
  filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname))
});
const upload = multer({ storage, limits: { fileSize: 5 * 1024 * 1024 } });

// ✅ STEP 9 - AI-5: Concept Similarity Detector
router.post('/ai-similarity', verifyToken, isAdmin, async (req, res) => {
  try {
    const { text, questionId } = req.body;
    if (!text) return res.status(400).json({ success: false, message: 'Text required' });

    const allQuestions = await Question.find(
      questionId ? { _id: { $ne: questionId } } : {}
    ).select('text hindiText _id subject chapter');

    // Tokenize function
    const tokenize = (str) => (str || '').toLowerCase()
      .replace(/[^a-z0-9\u0900-\u097f\s]/g, '')
      .split(/\s+/).filter(w => w.length > 3);

    const inputTokens = new Set(tokenize(text));
    const similarQuestions = [];

    allQuestions.forEach(q => {
      const qTokens = new Set(tokenize(q.text + ' ' + (q.hindiText || '')));
      const intersection = [...inputTokens].filter(t => qTokens.has(t));
      const union = new Set([...inputTokens, ...qTokens]);
      const similarity = union.size > 0 ? (intersection.length / union.size) * 100 : 0;

      if (similarity >= 40) {
        similarQuestions.push({
          _id: q._id,
          text: q.text.substring(0, 100) + '...',
          subject: q.subject,
          chapter: q.chapter,
          similarityPercent: Math.round(similarity)
        });
      }
    });

    similarQuestions.sort((a, b) => b.similarityPercent - a.similarityPercent);

    res.json({
      success: true,
      inputText: text.substring(0, 80) + '...',
      totalChecked: allQuestions.length,
      similarFound: similarQuestions.length,
      warning: similarQuestions.length > 0 ? 'Similar concept questions found!' : 'No similar concept found - safe to add!',
      similarQuestions: similarQuestions.slice(0, 5)
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ✅ STEP 10 - Duplicate Question Detector (S18)
router.post('/check-duplicate', verifyToken, isAdmin, async (req, res) => {
  try {
    const { text, questionId } = req.body;
    if (!text) return res.status(400).json({ success: false, message: 'Text required' });

    const normalize = (str) => (str || '').toLowerCase().trim()
      .replace(/\s+/g, ' ')
      .replace(/[?।!]/g, '');

    const normalizedInput = normalize(text);
    const query = questionId ? { _id: { $ne: questionId } } : {};
    const allQuestions = await Question.find(query).select('text hindiText _id subject chapter');

    const exactMatches = [];
    allQuestions.forEach(q => {
      const normalizedQ = normalize(q.text);
      if (normalizedQ === normalizedInput) {
        exactMatches.push({
          _id: q._id,
          text: q.text.substring(0, 120),
          subject: q.subject,
          chapter: q.chapter
        });
      }
    });

    res.json({
      success: true,
      isDuplicate: exactMatches.length > 0,
      message: exactMatches.length > 0
        ? '⚠️ DUPLICATE FOUND! Exactly same question already exists!'
        : '✅ No duplicate found - safe to add!',
      duplicates: exactMatches
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ✅ STEP 11 - Image Upload for Questions (S33)
router.post('/:id/upload-image', verifyToken, isAdmin, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, message: 'No image uploaded' });

    const question = await Question.findById(req.params.id);
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });

    question.image = `/uploads/${req.file.filename}`;
    await question.save();

    res.json({
      success: true,
      message: 'Image uploaded successfully!',
      imagePath: question.image,
      filename: req.file.filename
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ✅ STEP 12 - Question Tags & Advanced Search
router.get('/search', verifyToken, isAdmin, async (req, res) => {
  try {
    const { subject, chapter, topic, difficulty, type, tags, search, page = 1, limit = 20 } = req.query;
    let filter = {};

    if (subject) filter.subject = subject;
    if (chapter) filter.chapter = chapter;
    if (topic) filter.topic = topic;
    if (difficulty) filter.difficulty = difficulty;
    if (type) filter.type = type;
    if (tags) filter.tags = { $in: tags.split(',').map(t => t.trim()) };
    if (search) {
      filter.$or = [
        { text: { $regex: search, $options: 'i' } },
        { hindiText: { $regex: search, $options: 'i' } },
        { tags: { $in: [new RegExp(search, 'i')] } },
        { chapter: { $regex: search, $options: 'i' } },
        { topic: { $regex: search, $options: 'i' } }
      ];
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const total = await Question.countDocuments(filter);
    const questions = await Question.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    res.json({
      success: true,
      total,
      page: parseInt(page),
      totalPages: Math.ceil(total / parseInt(limit)),
      count: questions.length,
      questions
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Add tags to question
router.put('/:id/tags', verifyToken, isAdmin, async (req, res) => {
  try {
    const { tags } = req.body;
    if (!Array.isArray(tags)) return res.status(400).json({ success: false, message: 'Tags must be an array' });

    const question = await Question.findByIdAndUpdate(
      req.params.id,
      { tags },
      { new: true }
    );
    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });

    res.json({ success: true, message: 'Tags updated!', tags: question.tags });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ✅ STEP 13 - Question Usage Tracker (S35)
router.get('/:id/usage', verifyToken, isAdmin, async (req, res) => {
  try {
    const question = await Question.findById(req.params.id)
      .select('text subject chapter usageCount lastUsedIn usedInExams createdAt');

    if (!question) return res.status(404).json({ success: false, message: 'Question not found' });

    res.json({
      success: true,
      questionId: question._id,
      text: question.text ? question.text.substring(0, 100) : '',
      subject: question.subject,
      chapter: question.chapter,
      usageCount: question.usageCount || 0,
      usedInExams: question.usedInExams || [],
      lastUsedIn: question.lastUsedIn || null,
      createdAt: question.createdAt,
      message: question.usageCount > 0
        ? 'Question has been used in ' + question.usageCount + ' exam(s)'
        : 'Question not used in any exam yet'
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Get usage stats for all questions
router.get('/usage-stats', verifyToken, isAdmin, async (req, res) => {
  try {
    const stats = await Question.aggregate([
      {
        $group: {
          _id: '$subject',
          totalQuestions: { $sum: 1 },
          totalUsage: { $sum: '$usageCount' },
          avgUsage: { $avg: '$usageCount' },
          neverUsed: { $sum: { $cond: [{ $eq: ['$usageCount', 0] }, 1, 0] } }
        }
      },
      { $sort: { totalQuestions: -1 } }
    ]);

    const overall = await Question.countDocuments();
    const neverUsed = await Question.countDocuments({ usageCount: 0 });

    res.json({
      success: true,
      overall: {
        totalQuestions: overall,
        neverUsedCount: neverUsed,
        usedCount: overall - neverUsed
      },
      subjectWise: stats
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
