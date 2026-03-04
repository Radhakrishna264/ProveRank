const express = require('express');
const router = express.Router();
const attemptController = require('../controllers/attemptController');
const { protect, studentOnly } = require('../middleware/authMiddleware');

router.get('/rank-prediction/:examId', protect, studentOnly, attemptController.getRankPrediction);
router.post('/waiting-room/:examId', protect, studentOnly, attemptController.joinWaitingRoom);
router.post('/accept-terms/:examId', protect, studentOnly, attemptController.acceptTerms);
router.post('/start/:examId', protect, studentOnly, attemptController.startAttempt);
router.post('/verify-admit-card/:examId', protect, studentOnly, attemptController.verifyAdmitCard);
router.post('/fullscreen-warning/:attemptId', protect, studentOnly, attemptController.logFullscreenWarning);
router.get('/status/:examId', protect, studentOnly, attemptController.getAttemptStatus);

module.exports = router;
