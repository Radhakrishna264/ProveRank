const jwt = require('jsonwebtoken');
const User = require('../models/User');

const activeSessions = {};

const sessionControl = async (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.status(401).json({ message: 'No token' });
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    if (activeSessions[decoded.id] && activeSessions[decoded.id] !== token) {
      return res.status(403).json({ message: 'Logged in on another device' });
    }
    activeSessions[decoded.id] = token;
    req.user = decoded;
    next();
  } catch {
    res.status(401).json({ message: 'Invalid token' });
  }
};

const setSession = (userId, token) => {
  activeSessions[userId] = token;
};

const clearSession = (userId) => {
  delete activeSessions[userId];
};

module.exports = { sessionControl, setSession, clearSession };
