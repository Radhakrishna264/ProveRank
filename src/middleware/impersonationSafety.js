// ProveRank — M4 Impersonation Safety Middleware (Phase 8.1 Step 9)
// Admin student ka account view kar sakta hai but koi action nahi

const impersonationLogger = (req, res, next) => {
  // Check if admin is viewing as student (X-Impersonate-Student header)
  const impersonateId = req.headers['x-impersonate-student'];
  if (impersonateId) {
    const adminRole = req.user && req.user.role;

    // Only admin/superadmin can use impersonation
    if (adminRole !== 'admin' && adminRole !== 'superadmin') {
      return res.status(403).json({
        success: false,
        message: 'Impersonation not allowed for this role.'
      });
    }

    // Log the impersonation for audit trail
    console.log(`🔍 AUDIT: ${adminRole} (${req.user.id}) viewing as student ${impersonateId} | IP: ${req.ip} | ${new Date().toISOString()}`);

    // Block any write operations during impersonation (read-only)
    if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method)) {
      return res.status(403).json({
        success: false,
        message: 'Write operations not allowed in impersonation mode. View only.'
      });
    }
    req.impersonating = true;
    req.impersonateStudentId = impersonateId;
  }
  next();
};

module.exports = { impersonationLogger };
