const jwt = require('jsonwebtoken');

const verifyToken = async (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.status(401).json({ message: 'No token provided' });
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    // Frozen admin check
    if(req.user.role !== 'superadmin'){
      const mongoose = require('mongoose')
      const u = await mongoose.connection.db.collection('students').findOne({_id: require('mongoose').Types.ObjectId.createFromHexString(req.user.id)})
      if(u && u.frozen) return res.status(403).json({ message: 'Your account has been frozen by SuperAdmin.' })
      if(u && u.archived) return res.status(403).json({ message: 'Your account has been removed by SuperAdmin.' })
    }
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
