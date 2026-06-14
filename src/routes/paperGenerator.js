// ProveRank — Smart Paper Generator Routes (Feature 17, S101)
const express = require('express');
const router  = express.Router();
const { verifyToken, isAdmin } = require('../middleware/auth');
const ctrl = require('../controllers/paperGenerator');

// 17.8  — Generate paper from QB
router.post('/generate',         verifyToken, isAdmin, ctrl.generatePaper);
// 17.11 — One-click Use as Exam
router.post('/use-as-exam',      verifyToken, isAdmin, ctrl.useAsExam);
// 17.18 — Save generated set as template
router.post('/save-template',    verifyToken, isAdmin, ctrl.saveTemplate);
router.get('/saved-templates',   verifyToken, isAdmin, ctrl.getSavedTemplates);
// 17.19 — Export as PDF / Excel
router.post('/export',           verifyToken, isAdmin, ctrl.exportSet);
// Bank stats (enhanced with formatWise + chaptersBySubject)
router.get('/stats',             verifyToken, isAdmin, ctrl.getBankStats);

module.exports = router;
