require('dotenv').config();
const mongoose = require('mongoose');
const axios = require('axios');
const bcrypt = require('bcrypt');
const User = require('./src/models/User');

const BASE_URL = "http://localhost:3000";

async function runTest() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log("✅ MongoDB Connected\n");

    // Get SuperAdmin
    const superAdmin = await User.findOne({ role: "superadmin" });
    const superLogin = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: superAdmin.email,
      password: "ProveRank@SuperAdmin123"
    });
    const superToken = superLogin.data.token;
    console.log("✅ SuperAdmin Login Success\n");

    // Create Admin (no permissions)
    const adminPassword = await bcrypt.hash("Admin@123", 12);

    const admin = await User.findOneAndUpdate(
      { email: "permadmin@proverank.com" },
      {
        name: "Permission Admin",
        email: "permadmin@proverank.com",
        password: adminPassword,
        role: "admin",
        verified: true,
        permissions: {},
        adminFrozen: false
      },
      { upsert: true, new: true }
    );

    console.log("✅ Admin Created (No Permissions)");

    // Login Admin
    const adminLogin = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: "permadmin@proverank.com",
      password: "Admin@123"
    });
    const adminToken = adminLogin.data.token;

    // 1️⃣ Try Access without permission
    try {
      await axios.get(`${BASE_URL}/api/permission/create-exam-test`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });
      console.log("❌ FAIL: Access granted without permission");
    } catch {
      console.log("✅ PASS: Access denied without permission");
    }

    // 2️⃣ Grant Permission
    admin.permissions.set("CREATE_EXAM", true);
    await admin.save();

    console.log("✅ CREATE_EXAM permission granted");

    // Try again
    try {
      await axios.get(`${BASE_URL}/api/permission/create-exam-test`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });
      console.log("✅ PASS: Access granted with permission");
    } catch {
      console.log("❌ FAIL: Access denied even with permission");
    }

    // 3️⃣ Freeze Admin
    admin.adminFrozen = true;
    await admin.save();
    console.log("✅ Admin Frozen");

    try {
      await axios.get(`${BASE_URL}/api/permission/create-exam-test`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });
      console.log("❌ FAIL: Frozen admin still accessed route");
    } catch {
      console.log("✅ PASS: Frozen admin blocked");
    }

    // 4️⃣ SuperAdmin Bypass Test
    try {
      await axios.get(`${BASE_URL}/api/permission/create-exam-test`, {
        headers: { Authorization: `Bearer ${superToken}` }
      });
      console.log("✅ PASS: SuperAdmin bypass working");
    } catch {
      console.log("❌ FAIL: SuperAdmin blocked (wrong)");
    }

    console.log("\n🎯 ENTERPRISE PERMISSION ENGINE TEST COMPLETE");
    process.exit(0);

  } catch (err) {
    console.error("❌ ERROR:", err.message);
    process.exit(1);
  }
}

runTest();
