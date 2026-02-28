const jwt = require('jsonwebtoken');

const verifyToken = (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.status(401).json({ message: 'No token provided' });
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ message: 'Invalid token' });
  }
};

const isSuperAdmin = (req, res, next) => {
  if (req.user.role !== 'superadmin') return res.status(403).json({ message: 'SuperAdmin only' });
  next();
};

const isAdmin = (req, res, next) => {
  if (!['admin','superadmin'].includes(req.user.role)) return res.status(403).json({ message: 'Admin only' });
  next();
};

module.exports = { verifyToken, isSuperAdmin, isAdmin };
