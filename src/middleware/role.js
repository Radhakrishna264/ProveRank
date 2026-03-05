const isAdmin = (req, res, next) => {
  if (!req.user) return res.status(401).json({ message: 'Not authenticated' });
  if (req.user.role === 'admin' || req.user.role === 'superadmin') return next();
  return res.status(403).json({ message: 'Admin access required' });
};
const isSuperAdmin = (req, res, next) => {
  if (!req.user) return res.status(401).json({ message: 'Not authenticated' });
  if (req.user.role === 'superadmin') return next();
  return res.status(403).json({ message: 'SuperAdmin access required' });
};
const isStudent = (req, res, next) => {
  if (!req.user) return res.status(401).json({ message: 'Not authenticated' });
  if (req.user.role === 'student') return next();
  return res.status(403).json({ message: 'Student access required' });
};
module.exports = { isAdmin, isSuperAdmin, isStudent };
