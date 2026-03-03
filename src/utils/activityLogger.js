const ActivityLog = require('../models/ActivityLog');
const crypto = require('crypto');

const logActivity = async ({ userId, userName, userRole, action, details, module, ipAddress, userAgent, status, isAudit }) => {
  try {
    // S93 — checksum for tamper proof
    const data = `${userId}${action}${details}${Date.now()}`;
    const checksum = crypto.createHash('sha256').update(data).digest('hex').slice(0, 16);

    await ActivityLog.create({
      userId, userName, userRole,
      action, details,
      module: module || 'general',
      ipAddress, userAgent,
      status: status || 'success',
      checksum,
      isAudit: isAudit || false
    });
  } catch (err) {
    console.error('Activity log error:', err.message);
  }
};

module.exports = { logActivity };
