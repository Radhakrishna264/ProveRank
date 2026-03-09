// ProveRank — Login Brute Force + JWT Expiry (Phase 8.1 Step 5, 6)
const jwt = require('jsonwebtoken');

// In-memory login attempt tracker (per IP)
// Production mein Redis use karein
const loginAttempts = new Map();

const MAX_ATTEMPTS = 5;
const LOCK_TIME_MS = 15 * 60 * 1000; // 15 minutes

const bruteForceProtection = (req, res, next) => {
  const ip = req.ip || req.connection.remoteAddress;
  const now = Date.now();

  if (loginAttempts.has(ip)) {
    const record = loginAttempts.get(ip);

    // Reset attempts after lock time
    if (now - record.firstAttempt > LOCK_TIME_MS) {
      loginAttempts.delete(ip);
    } else if (record.count >= MAX_ATTEMPTS) {
      const waitMinutes = Math.ceil((LOCK_TIME_MS - (now - record.firstAttempt)) / 60000);
      return res.status(429).json({
        success: false,
        message: `Account temporarily locked. Try again in ${waitMinutes} minutes.`,
        lockedUntil: new Date(record.firstAttempt + LOCK_TIME_MS).toISOString()
      });
    }
  }
  next();
};

const recordFailedAttempt = (ip) => {
  const now = Date.now();
  if (loginAttempts.has(ip)) {
    const record = loginAttempts.get(ip);
    record.count += 1;
    loginAttempts.set(ip, record);
  } else {
    loginAttempts.set(ip, { count: 1, firstAttempt: now });
  }
};

const clearAttempts = (ip) => {
  loginAttempts.delete(ip);
};

// Step 5: JWT expiry check middleware
const checkJWTExpiry = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) return next();

  const token = authHeader.split(' ')[1];
  if (!token) return next();

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'proverank_jwt_super_secret_key_2024');
    const now = Math.floor(Date.now() / 1000);
    const timeLeft = decoded.exp - now;

    // Token expires in < 1 hour — add warning header
    if (timeLeft < 3600) {
      res.setHeader('X-Token-Expiry-Warning', 'Token expires soon. Please re-login.');
    }
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Session expired. Please login again.',
        code: 'TOKEN_EXPIRED'
      });
    }
    next();
  }
};

module.exports = { bruteForceProtection, recordFailedAttempt, clearAttempts, checkJWTExpiry };
