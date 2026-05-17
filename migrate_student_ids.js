require('dotenv').config();
const mongoose = require('mongoose');

const MONGO_URI = process.env.MONGO_URI;
if (!MONGO_URI) { console.error('MONGO_URI not found in .env'); process.exit(1); }

function generateStudentId(year) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let suffix = '';
  for (let i = 0; i < 4; i++) {
    suffix += chars[Math.floor(Math.random() * chars.length)];
  }
  return 'PR' + String(year).slice(-2) + suffix;
}

async function migrate() {
  await mongoose.connect(MONGO_URI);
  console.log('✅ MongoDB connected — DB:', mongoose.connection.db.databaseName);

  const col = mongoose.connection.db.collection('students');

  const students = await col.find({
    role: 'student',
    $or: [
      { studentId: { $exists: false } },
      { studentId: null },
      { studentId: '' }
    ]
  }).toArray();

  console.log(`Found ${students.length} students without studentId`);

  let updated = 0;
  for (const s of students) {
    const year = s.createdAt ? new Date(s.createdAt).getFullYear() : 2025;
    let studentId, isUnique = false, tries = 0;
    while (!isUnique && tries < 30) {
      studentId = generateStudentId(year);
      const exists = await col.findOne({ studentId });
      if (!exists) isUnique = true;
      tries++;
    }
    await col.updateOne({ _id: s._id }, { $set: { studentId } });
    console.log(`✅ ${s.email} → ${studentId}`);
    updated++;
  }

  console.log(`\nMigration done! ${updated} students updated.`);
  await mongoose.disconnect();
}

migrate().catch(e => { console.error('Error:', e.message); process.exit(1); });
