const express  = require('express');
const router   = express.Router();
const jwt      = require('jsonwebtoken');
const Material = require('../models/Material');

function getAdmin(req) {
  try {
    const tok = (req.headers.authorization || '').replace('Bearer ', '');
    if (!tok) return null;
    return jwt.verify(tok, process.env.JWT_SECRET);
  } catch { return null; }
}

// GET all materials (list, no content)
router.get('/', async (req, res) => {
  const user = getAdmin(req);
  if (!user) return res.status(401).json({ message: 'Unauthorized' });
  try {
    const mats = await Material.find({ adminId: user.id || user._id })
      .sort({ createdAt: -1 })
      .select('_id title fileType fileSize createdAt');
    res.json(mats);
  } catch(e) { res.status(500).json({ message: e.message }); }
});

// GET single material with content
router.get('/:id', async (req, res) => {
  const user = getAdmin(req);
  if (!user) return res.status(401).json({ message: 'Unauthorized' });
  try {
    const mat = await Material.findOne({ _id: req.params.id, adminId: user.id || user._id });
    if (!mat) return res.status(404).json({ message: 'Not found' });
    res.json(mat);
  } catch(e) { res.status(500).json({ message: e.message }); }
});

// POST save new material
router.post('/', async (req, res) => {
  const user = getAdmin(req);
  if (!user) return res.status(401).json({ message: 'Unauthorized' });
  try {
    const { title, content, fileType, fileSize } = req.body;
    if (!title || !content) return res.status(400).json({ message: 'title and content required' });
    const mat = await Material.create({
      title: title.trim(), content,
      fileType: fileType || 'txt',
      fileSize: fileSize || 0,
      adminId: user.id || user._id
    });
    res.json({ _id: mat._id, title: mat.title, fileType: mat.fileType, fileSize: mat.fileSize, createdAt: mat.createdAt });
  } catch(e) { res.status(500).json({ message: e.message }); }
});

// DELETE material
router.delete('/:id', async (req, res) => {
  const user = getAdmin(req);
  if (!user) return res.status(401).json({ message: 'Unauthorized' });
  try {
    const result = await Material.findOneAndDelete({ _id: req.params.id, adminId: user.id || user._id });
    if (!result) return res.status(404).json({ message: 'Not found' });
    res.json({ success: true });
  } catch(e) { res.status(500).json({ message: e.message }); }
});

module.exports = router;

// POST /api/materials/extract — extract text from PDF/DOCX/TXT
router.post('/extract', async (req, res) => {
  const user = getAdmin(req);
  if (!user) return res.status(401).json({ message: 'Unauthorized' });
  try {
    const { base64, fileName, isText, textContent } = req.body;
    if (isText) return res.json({ content: textContent || '' });
    if (!base64) return res.status(400).json({ message: 'base64 required' });

    const buffer = Buffer.from(base64, 'base64');
    const ext = (fileName || '').split('.').pop().toLowerCase();
    let content = '';

    if (ext === 'pdf') {
      const pdfParse = require('pdf-parse');
      const data = await pdfParse(buffer);
      content = data.text || '';
    } else if (ext === 'docx') {
      const mammoth = require('mammoth');
      const result = await mammoth.extractRawText({ buffer });
      content = result.value || '';
    } else {
      // fallback: treat as text
      content = buffer.toString('utf8');
    }

    if (!content.trim()) return res.status(422).json({ message: 'No text extracted from file' });
    res.json({ content: content.trim() });
  } catch(e) {
    res.status(500).json({ message: e.message });
  }
});

// POST /api/materials/generate — generate questions from material using Groq
router.post('/generate', async (req, res) => {
  const user = getAdmin(req);
  if (!user) return res.status(401).json({ message: 'Unauthorized' });
  try {
    const { materialId, count, difficulty, examLevel, formats } = req.body;
    const mat = await Material.findOne({ _id: materialId, adminId: user.id || user._id });
    if (!mat) return res.status(404).json({ message: 'Material not found' });

    const fmt = (formats && formats.length) ? 'Format types: ' + formats.join(', ') + '.' : '';
    const lvl = examLevel ? 'Exam level: ' + examLevel + '.' : '';
    const prompt = `You are an expert NEET question generator. Based ONLY on the following educational content, generate ${count || 5} high-quality multiple choice questions.\n\n${lvl} ${fmt}\nDifficulty: ${difficulty || 'medium'}.\n\nEDUCATIONAL CONTENT:\n${mat.content.substring(0, 6000)}\n\nRULES:\n- Generate exactly ${count || 5} questions\n- Each question must have exactly 4 options (A, B, C, D)\n- Only use information from the provided content\n- Return ONLY a valid JSON array, no other text, no markdown:\n[{"text":"question","options":["option A","option B","option C","option D"],"correctAnswer":"A","explanation":"brief reason","difficulty":"${difficulty || 'medium'}","type":"SCQ","chapter":"${mat.title}"}]`;

    // Try Groq API
    const groqKey = process.env.GROQ_API_KEY;
    if (!groqKey) return res.status(500).json({ message: 'AI API key not configured' });

    const groqRes = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + groqKey },
      body: JSON.stringify({
        model: 'llama3-8b-8192',
        messages: [{ role: 'user', content: prompt }],
        max_tokens: 4000,
        temperature: 0.7
      })
    });

    const data = await groqRes.json();
    const text = (data.choices && data.choices[0] && data.choices[0].message && data.choices[0].message.content) || '';
    const match = text.match(/\[[\s\S]*\]/);
    if (!match) return res.status(500).json({ message: 'AI could not generate questions. Try again.' });

    const questions = JSON.parse(match[0]);
    res.json(questions);
  } catch(e) {
    res.status(500).json({ message: e.message || 'Generation failed' });
  }
});
