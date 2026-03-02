const express = require('express');
const router = express.Router();
const { verifyToken, isAdmin } = require('../middleware/auth');
const { generatePaper, getBankStats } = require('../controllers/paperGenerator');

// Phase 2.5 - Smart Question Paper Generator
router.post('/generate', verifyToken, isAdmin, generatePaper);
router.get('/stats', verifyToken, isAdmin, getBankStats);

module.exports = router;
