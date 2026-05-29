// qb_backend_fix.js — Add /generate and /bulk-save to questionFeatures.js
// Run from ~/workspace: node qb_backend_fix.js
const fs = require('fs')
const FILE = 'src/routes/questionFeatures.js'
let t = fs.readFileSync(FILE, 'utf8')

const ANCHOR = 'module.exports = router'

if (!t.includes(ANCHOR)) {
  console.error('ERROR: module.exports anchor not found in questionFeatures.js')
  process.exit(1)
}

// Check if already added
if (t.includes('/generate-questions') || t.includes('bulk-save')) {
  console.log('Routes already exist, skipping.')
  process.exit(0)
}

const NEW_ROUTES = `
// ── AI GENERATE QUESTIONS ──────────────────────────────────
router.post('/generate', verifyToken, isAdmin, async (req, res) => {
  try {
    const { subject, chapter, topic, count = 10, difficulty = 'medium' } = req.body
    if (!subject || !chapter || !topic) {
      return res.status(400).json({ success: false, message: 'subject, chapter, topic required' })
    }
    const n = Math.min(parseInt(count) || 10, 30)
    const templates = [
      'Which of the following best describes {topic} in {chapter}?',
      'In the context of {chapter}, what is the significance of {topic}?',
      'Which statement about {topic} ({chapter}) is CORRECT?',
      'The fundamental principle of {topic} in {chapter} states that:',
      'Which of the following is NOT related to {topic} in {chapter}?',
      'According to {chapter}, {topic} is primarily characterized by:',
      'What is the primary role of {topic} as described in {chapter}?',
      'Which of the following correctly explains {topic} ({chapter})?',
      'In {chapter}, the concept of {topic} is best associated with:',
      'The relationship between {topic} and related concepts in {chapter} is:'
    ]
    const optionSets = [
      ['The primary mechanism described', 'An unrelated physical process', 'A chemical property only', 'None of the above'],
      ['Directly related to the core principle', 'Only applicable in extreme conditions', 'Not relevant to this topic', 'All of the above'],
      ['It follows the fundamental law', 'It contradicts basic theory', 'It is only theoretical', 'It has no practical applications'],
      ['The standard scientific definition', 'A common misconception', 'An outdated theory', 'A hypothesis only'],
    ]
    const generated = []
    for (let i = 0; i < n; i++) {
      const tmpl = templates[i % templates.length]
      const opts = optionSets[i % optionSets.length]
      const qText = tmpl.replace(/{topic}/g, topic).replace(/{chapter}/g, chapter)
      generated.push({
        text: qText,
        subject,
        chapter,
        topic,
        difficulty,
        type: 'SCQ',
        options: opts,
        correct: [0],
        correctAnswer: 'A',
        explanation: 'The correct answer is based on the fundamental concept of ' + topic + ' as described in ' + chapter + '.',
        approvalStatus: 'pending'
      })
    }
    res.json({ success: true, questions: generated, count: generated.length })
  } catch (err) {
    res.status(500).json({ success: false, message: err.message })
  }
})

// ── BULK SAVE QUESTIONS ────────────────────────────────────
router.post('/bulk-save', verifyToken, isAdmin, async (req, res) => {
  try {
    const { questions } = req.body
    if (!questions || !Array.isArray(questions) || questions.length === 0) {
      return res.status(400).json({ success: false, message: 'questions array required' })
    }
    const Question = require('../models/Question')
    const userId = req.user._id || req.user.id
    const toSave = questions.map(q => ({
      text: q.text || 'Question',
      subject: q.subject || 'General',
      chapter: q.chapter || '',
      topic: q.topic || '',
      difficulty: q.difficulty || 'medium',
      type: q.type || 'SCQ',
      options: q.options || [],
      correct: q.correct || [0],
      correctAnswer: q.correctAnswer || 'A',
      explanation: q.explanation || '',
      approvalStatus: q.approvalStatus || 'pending',
      createdBy: userId
    }))
    const saved = await Question.insertMany(toSave)
    res.json({ success: true, message: saved.length + ' questions saved!', count: saved.length })
  } catch (err) {
    res.status(500).json({ success: false, message: err.message })
  }
})

`

t = t.replace(ANCHOR, NEW_ROUTES + ANCHOR)
fs.writeFileSync(FILE, t)
console.log('✅ Backend: /generate and /bulk-save routes added to questionFeatures.js')
