const User = require('../models/User');

const requirePermission = (permissionName) => {
  return async (req, res, next) => {
    try {
      const user = await User.findById(req.user.id);

      if (!user) {
        return res.status(401).json({ message: "User not found" });
      }

      // SuperAdmin bypass
      if (user.role === 'superadmin') {
        return next();
      }

      // Freeze check (S72)
      if (user.role === 'admin' && user.adminFrozen) {
        return res.status(403).json({ message: "Admin account frozen by SuperAdmin" });
      }

      // Permission check
      if (user.role === 'admin') {
        const hasPermission = user.permissions.get(permissionName);
        if (hasPermission) {
          return next();
        } else {
          return res.status(403).json({ message: "Permission denied" });
        }
      }

      return res.status(403).json({ message: "Access denied" });

    } catch (err) {
      return res.status(500).json({ message: "Permission middleware error" });
    }
  };
};

module.exports = requirePermission;
