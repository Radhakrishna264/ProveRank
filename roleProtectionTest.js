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

    // SuperAdmin fetch
    const superAdmin = await User.findOne({ role: "superadmin" });
    if (!superAdmin) {
      console.log("❌ SuperAdmin not found");
      process.exit(1);
    }

    // Login SuperAdmin
    const loginRes = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: superAdmin.email,
      password: "ProveRank@SuperAdmin123"
    });

    const superToken = loginRes.data.token;
    console.log("✅ SuperAdmin Login Success\n");

    // Create Admin directly in DB
    const adminPassword = await bcrypt.hash("Admin@123", 12);

    await User.findOneAndUpdate(
      { email: "testadmin@proverank.com" },
      {
        name: "Test Admin",
        email: "testadmin@proverank.com",
        password: adminPassword,
        role: "admin",
        verified: true
      },
      { upsert: true }
    );

    console.log("✅ Test Admin Ready");

    // Create Student directly in DB
    const studentPassword = await bcrypt.hash("Student@123", 12);

    await User.findOneAndUpdate(
      { email: "teststudent@proverank.com" },
      {
        name: "Test Student",
        email: "teststudent@proverank.com",
        password: studentPassword,
        role: "student",
        verified: true
      },
      { upsert: true }
    );

    console.log("✅ Test Student Ready\n");

    // Login Student
    const studentLogin = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: "teststudent@proverank.com",
      password: "Student@123"
    });

    const studentToken = studentLogin.data.token;

    try {
      await axios.get(`${BASE_URL}/api/admin/students`, {
        headers: { Authorization: `Bearer ${studentToken}` }
      });
      console.log("❌ FAIL: Student accessed admin route");
    } catch {
      console.log("✅ PASS: Student blocked from admin route");
    }

    // Login Admin
    const adminLogin = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: "testadmin@proverank.com",
      password: "Admin@123"
    });

    const adminToken = adminLogin.data.token;

    try {
      await axios.get(`${BASE_URL}/api/admin/superadmin-only`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });
      console.log("❌ FAIL: Admin accessed SuperAdmin route");
    } catch {
      console.log("✅ PASS: Admin blocked from SuperAdmin route");
    }

    console.log("\n🎯 ROLE PROTECTION TEST COMPLETE");
    process.exit(0);

  } catch (err) {
    console.error("❌ ERROR:", err.response?.data || err.message);
    process.exit(1);
  }
}

runTest();
