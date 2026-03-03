const express = require('express');
const router = express.Router();

const { verifyToken } = require('../middleware/auth');
const requirePermission = require('../middleware/permission');

router.get(
  '/create-exam-test',
  verifyToken,
  requirePermission('CREATE_EXAM'),
  (req, res) => {
    res.json({ message: "CREATE_EXAM permission granted" });
  }
);

module.exports = router;
