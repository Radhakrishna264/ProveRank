// ProveRank — Feature Flag Middleware (Phase 8.1 Step 8 — N21 Harden)
// Superadmin koi bhi feature ON/OFF kar sakta hai

const defaultFlags = {
  registration: true,
  examAttempt: true,
  leaderboard: true,
  certificates: true,
  notifications: true,
  aiFeatures: false,
  twoFactorAuth: false,
  parentPortal: false,
  pyqBank: false
};

// In-memory flag store (Production mein DB mein store karein)
let featureFlags = { ...defaultFlags };

// Get all flags
const getFlags = () => featureFlags;

// Toggle a flag (superadmin only)
const setFlag = (flagName, value) => {
  if (!(flagName in defaultFlags)) {
    throw new Error(`Unknown feature flag: ${flagName}`);
  }
  featureFlags[flagName] = Boolean(value);
  console.log(`🚩 Feature Flag: ${flagName} = ${value}`);
  return featureFlags;
};

// Reset all flags to default
const resetFlags = () => {
  featureFlags = { ...defaultFlags };
  return featureFlags;
};

// Middleware: Check if feature is enabled
const requireFeature = (flagName) => (req, res, next) => {
  if (!featureFlags[flagName]) {
    return res.status(403).json({
      success: false,
      message: `Feature '${flagName}' is currently disabled by admin.`
    });
  }
  next();
};

module.exports = { getFlags, setFlag, resetFlags, requireFeature, featureFlags };
