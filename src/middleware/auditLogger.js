const AuditLog = require('../models/AuditLog');

const auditLogger = async (req, res, next) => {

  res.on('finish', async () => {
    try {

      if (!req.user) return;

      // Only log login route for now
      if (req.originalUrl.includes('/api/auth/login') && res.statusCode === 200) {

        await AuditLog.create({
          action: 'LOGIN',
          performedBy: req.user.id,
          details: `User logged in`,
          ip: req.ip
        });

      }

    } catch (err) {
      console.error("Audit log error:", err.message);
    }
  });

  next();
};

module.exports = auditLogger;
