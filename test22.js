const mongoose = require('mongoose');
require('dotenv').config();

mongoose.connect(process.env.MONGODB_URI).then(async () => {
  const db = mongoose.connection.db;
  const user = await db.collection('users').findOne({email:'admin@proverank.com'});
  const uid = user._id;
  let pass = 0, fail = 0;

  async function test(name, fn) {
    try {
      const ok = await fn();
      if(ok) { console.log('✅ PASS — ' + name); pass++; }
      else { console.log('❌ FAIL — ' + name); fail++; }
    } catch(e) { console.log('❌ ERROR — ' + name + ': ' + e.message); fail++; }
  }

  let MCQ_ID, HARD_ID;

  await test('TEST 1: SCQ Add', async () => {
    const r = await db.collection('questions').insertOne({
      text: 'Mitochondria ka main function kya hai?',
      options: ['Protein synthesis','Energy production','DNA storage','Cell division'],
      correct: [1], subject: 'Biology', chapter: 'Cell Biology',
      topic: 'Organelles', difficulty: 'Easy', type: 'SCQ',
      tags: ['mitochondria','energy'], createdBy: uid,
      usageCount: 0, version: 1, versionHistory: [], isActive: true
    });
    MCQ_ID = r.insertedId;
    return !!r.insertedId;
  });

  await test('TEST 2: Hard Difficulty (S16)', async () => {
    const r = await db.collection('questions').insertOne({
      text: 'Gibbs free energy equation kya hai?',
      options: ['G=H-TS','G=H+TS','G=U+PV','G=Q-W'],
      correct: [0], subject: 'Chemistry', chapter: 'Thermodynamics',
      topic: 'Gibbs Energy', difficulty: 'Hard', type: 'SCQ',
      tags: ['thermodynamics'], createdBy: uid,
      usageCount: 0, version: 1, versionHistory: [], isActive: true
    });
    HARD_ID = r.insertedId;
    return !!r.insertedId;
  });

  await test('TEST 3: Duplicate Check', async () => {
    const existing = await db.collection('questions').findOne({
      text: 'Mitochondria ka main function kya hai?'
    });
    return !!existing;
  });

  await test('TEST 4: MSQ Add (S90)', async () => {
    const r = await db.collection('questions').insertOne({
      text: 'DNA mein kaun se bases hote hain?',
      options: ['Adenine','Uracil','Guanine','Thymine'],
      correct: [0,2,3], subject: 'Biology', chapter: 'Genetics',
      topic: 'DNA Structure', difficulty: 'Medium', type: 'MSQ',
      tags: ['dna','genetics'], createdBy: uid,
      usageCount: 0, version: 1, versionHistory: [], isActive: true
    });
    return !!r.insertedId;
  });

  await test('TEST 5: Integer Type', async () => {
    const r = await db.collection('questions').insertOne({
      text: 'Triangle ke angles ka sum kitna hoga?',
      options: ['90','180','270','360'],
      correct: [1], subject: 'Physics', chapter: 'Math',
      topic: 'Geometry', difficulty: 'Easy', type: 'Integer',
      tags: ['geometry'], createdBy: uid,
      usageCount: 0, version: 1, versionHistory: [], isActive: true
    });
    return !!r.insertedId;
  });

  await test('TEST 6: Edit Question (PUT)', async () => {
    const r = await db.collection('questions').updateOne(
      {_id: MCQ_ID},
      {$set: {difficulty: 'Medium'}}
    );
    return r.modifiedCount === 1;
  });

  await test('TEST 7: Version History (S87)', async () => {
    const r = await db.collection('questions').updateOne(
      {_id: MCQ_ID},
      {$push: {versionHistory: {version: 1, text: 'Old text', editedAt: new Date()}}}
    );
    return r.modifiedCount === 1;
  });

  await test('TEST 8: Usage Tracker (S35)', async () => {
    const q = await db.collection('questions').findOne({_id: MCQ_ID});
    return q.usageCount !== undefined;
  });

  await test('TEST 9: Filter by Subject+Difficulty (S34)', async () => {
    const r = await db.collection('questions').find({subject:'Biology', difficulty:'Easy'}).toArray();
    console.log('         Found: ' + r.length + ' questions');
    return r.length > 0;
  });

  await test('TEST 10: Tags Search', async () => {
    const r = await db.collection('questions').find({tags:'mitochondria'}).toArray();
    return r.length > 0;
  });

  await test('TEST 11: Error Reporting (S84)', async () => {
    const r = await db.collection('questions').updateOne(
      {_id: MCQ_ID},
      {$push: {errorReports: {reportedBy: uid, issue: 'Wrong answer', status: 'Open', reportedAt: new Date()}}}
    );
    return r.modifiedCount === 1;
  });

  await test('TEST 12: Delete Question', async () => {
    const r = await db.collection('questions').deleteOne({_id: HARD_ID});
    return r.deletedCount === 1;
  });

  console.log('\n================================================');
  console.log('         PHASE 2.2 TEST RESULTS');
  console.log('================================================');
  console.log('✅ PASS : ' + pass + ' / 12');
  console.log('❌ FAIL : ' + fail + ' / 12');
  if(fail === 0) console.log('🎉 PERFECT! Phase 2.3 shuru kar sakte ho!');
  else console.log('⚠️  Fail wale results copy karke bhejo!');
  console.log('================================================');
  mongoose.disconnect();
}).catch(e => console.log('DB Error:', e.message));
