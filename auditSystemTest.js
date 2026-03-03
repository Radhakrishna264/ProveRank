require('dotenv').config();
const mongoose = require('mongoose');
const axios = require('axios');
const User = require('./src/models/User');
const ActivityLog = require('./src/models/ActivityLog');
const AuditLog = require('./src/models/AuditLog');

const BASE_URL = "http://localhost:3000";

async function runTest() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log("✅ MongoDB Connected\n");

    const superAdmin = await User.findOne({ role: "superadmin" });

    const login = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: superAdmin.email,
      password: "ProveRank@SuperAdmin123"
    });

    const token = login.data.token;

    console.log("✅ SuperAdmin Login Success");

    // Trigger any admin route to generate logs
    await axios.get(`${BASE_URL}/api/health`, {
      headers: { Authorization: `Bearer ${token}` }
    });

    console.log("✅ Action triggered");

    // Check Activity Log
    const activityCount = await ActivityLog.countDocuments();
    console.log("Activity Logs Count:", activityCount);

    // Check Audit Log
    const auditCount = await AuditLog.countDocuments();
    console.log("Audit Logs Count:", auditCount);

    if (activityCount > 0) {
      console.log("✅ PASS: Activity logs recorded");
    } else {
      console.log("❌ FAIL: No activity logs");
    }

    if (auditCount > 0) {
      console.log("✅ PASS: Audit logs recorded");
    } else {
      console.log("❌ FAIL: No audit logs");
    }

    // Try tampering audit log
    const oneAudit = await AuditLog.findOne();
    try {
      oneAudit.action = "HACKED";
      await oneAudit.save();
      console.log("❌ FAIL: Audit log modified");
    } catch {
      console.log("✅ PASS: Audit log tamper-proof working");
    }

    console.log("\n🎯 ACTIVITY + AUDIT SYSTEM TEST COMPLETE");
    process.exit(0);

  } catch (err) {
    console.error("❌ ERROR:", err.message);
    process.exit(1);
  }
}

runTest();
