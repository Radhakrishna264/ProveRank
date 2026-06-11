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
