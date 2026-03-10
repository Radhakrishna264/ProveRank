const suspiciousIPs = new Set();
const flagSuspiciousIP = (ip) => { suspiciousIPs.add(ip); console.warn(`IP flagged: ${ip}`); };
const ipLockCheck = (req, res, next) => {
  const ip = req.ip || req.connection.remoteAddress;
  if (suspiciousIPs.has(ip)) return res.status(403).json({ success: false, message: 'Access blocked from this IP.', code: 'IP_BLOCKED' });
  next();
};
module.exports = { flagSuspiciousIP, ipLockCheck };
