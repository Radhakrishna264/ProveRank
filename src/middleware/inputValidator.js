// ProveRank — Input Validator Middleware (Phase 8.1 Step 3)
const { body, param, validationResult } = require('express-validator');

// Validation result handler
const handleValidation = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array().map(e => ({ field: e.path, message: e.msg }))
    });
  }
  next();
};

// Login validation rules
const validateLogin = [
  body('email')
    .notEmpty().withMessage('Email required')
    .isEmail().withMessage('Valid email required')
    .normalizeEmail(),
  body('password')
    .notEmpty().withMessage('Password required')
    .isLength({ min: 6 }).withMessage('Password min 6 chars'),
  handleValidation
];

// Register validation rules
const validateRegister = [
  body('name')
    .notEmpty().withMessage('Name required')
    .isLength({ min: 2, max: 50 }).withMessage('Name 2-50 chars')
    .trim().escape(),
  body('email')
    .notEmpty().withMessage('Email required')
    .isEmail().withMessage('Valid email required')
    .normalizeEmail(),
  body('password')
    .notEmpty().withMessage('Password required')
    .isLength({ min: 8 }).withMessage('Password min 8 chars')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Password must have uppercase, lowercase and number'),
  handleValidation
];

// Exam ID param validation
const validateExamId = [
  param('examId')
    .notEmpty().withMessage('examId required')
    .isMongoId().withMessage('Invalid examId format'),
  handleValidation
];

// Question input validation
const validateQuestion = [
  body('subject')
    .notEmpty().withMessage('Subject required')
    .isIn(['Physics', 'Chemistry', 'Biology']).withMessage('Invalid subject'),
  body('questionText')
    .notEmpty().withMessage('Question text required')
    .isLength({ min: 5 }).withMessage('Question too short'),
  handleValidation
];

module.exports = {
  validateLogin,
  validateRegister,
  validateExamId,
  validateQuestion,
  handleValidation
};
