// ProveRank - Admin Login Diagnostic + Fix Script
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const MONGO_URI = process.env.MONGODB_URI || process.env.MONGO_URI;

async function diagnose() {
  console.log('\n=== PROVERANK ADMIN LOGIN DIAGNOSTIC ===\n');
  
  try {
    await mongoose.connect(MONGO_URI);
    console.log('✅ MongoDB Connected\n');
    
    // Step 1: Find admin in students collection
    const db = mongoose.connection.db;
    const students = db.collection('students');
    
    const admin = await students.findOne({ email: 'admin@proverank.com' });
    
    if (!admin) {
      console.log('❌ Admin NOT FOUND in students collection!');
      console.log('Run seed script to create admin first.\n');
      await fixMissingAdmin(db);
      return;
    }
    
    console.log('✅ Admin found in DB');
    console.log('   email:', admin.email);
    console.log('   role:', admin.role);
    console.log('   verified:', admin.verified);
    console.log('   banned:', admin.banned);
    console.log('   adminFrozen:', admin.adminFrozen);
    console.log('   hash starts:', admin.password?.substring(0, 10));
    
    // Step 2: bcrypt verify
    const testPass = 'ProveRank@SuperAdmin123';
    const match = await bcrypt.compare(testPass, admin.password);
    console.log('\n🔑 bcrypt.compare result:', match);
    
    if (!match) {
      console.log('❌ Password hash is WRONG - fixing now...');
      const newHash = await bcrypt.hash(testPass, 12);
      await students.updateOne(
        { email: 'admin@proverank.com' },
        { 
          $set: { 
            password: newHash,
            verified: true,
            banned: false,
            adminFrozen: false,
            role: 'superadmin'
          } 
        }
      );
      console.log('✅ Password updated with fresh hash!');
    } else {
      console.log('✅ Password hash is CORRECT');
    }
    
    // Step 3: Check AuditLog model
    console.log('\n=== CHECKING FILES ===\n');
    const fs = require('fs');
    
    // Check auth.js
    const authPath = '/home/runner/workspace/src/routes/auth.js';
    if (fs.existsSync(authPath)) {
      const authContent = fs.readFileSync(authPath, 'utf8');
      
      // Check for AuditLog
      if (authContent.includes('AuditLog')) {
        console.log('⚠️  AuditLog found in auth.js - this may be crashing login!');
        console.log('   Checking if AuditLog is wrapped in try-catch...');
        
        if (authContent.includes('AuditLog.create') && !authContent.includes('try {')) {
          console.log('❌ AuditLog.create NOT in try-catch - THIS IS THE BUG!');
        }
      } else {
        console.log('✅ No AuditLog in auth.js');
      }
      
      // Check verified bypass
      if (authContent.includes('superadmin') && authContent.includes('verified')) {
        console.log('✅ Superadmin verified bypass exists in auth.js');
      } else {
        console.log('⚠️  Superadmin verified bypass may be missing in auth.js');
      }
      
      // Check LOGIN console.log
      if (authContent.includes("console.log('LOGIN:")) {
        console.log('✅ LOGIN console.log exists in auth.js');
      } else {
        console.log('⚠️  LOGIN console.log MISSING - adding it will help debug');
      }
    } else {
      console.log('❌ auth.js not found at:', authPath);
    }
    
  } catch (err) {
    console.error('❌ Error:', err.message);
  }
  
  await mongoose.disconnect();
  console.log('\n=== DIAGNOSTIC COMPLETE ===\n');
  console.log('Next step: Check output above and report findings!');
}

async function fixMissingAdmin(db) {
  const bcryptLib = require('bcryptjs');
  const hash = await bcryptLib.hash('ProveRank@SuperAdmin123', 12);
  const students = db.collection('students');
  
  await students.insertOne({
    name: 'Super Admin',
    email: 'admin@proverank.com',
    password: hash,
    role: 'superadmin',
    verified: true,
    banned: false,
    adminFrozen: false,
    phone: '9999999999',
    createdAt: new Date(),
    updatedAt: new Date()
  });
  console.log('✅ Admin created fresh in students collection!');
}

diagnose();
