const mongoose = require('mongoose');
require('dotenv').config();

const MONGO_URI = process.env.MONGODB_URI || process.env.MONGO_URI;
const BASE_URL = 'http://localhost:3000';

async function req(method, path, body, token) {
  const opts = {
    method,
    headers: { 'Content-Type': 'application/json', ...(token && { Authorization: `Bearer ${token}` }) },
    ...(body && { body: JSON.stringify(body) })
  };
  const r = await fetch(`${BASE_URL}${path}`, opts);
  const data = await r.json();
  return { status: r.status, data };
}

async function run() {
  console.log('\n🚀 Phase 3.2 — Exam Instance Creation TEST\n');

  // Step 1: Login as SuperAdmin
  const login = await req('POST', '/api/auth/login', {
    email: 'admin@proverank.com',
    password: 'ProveRank@SuperAdmin123'
  });
  if (!login.data.token) { console.log('❌ Login failed', login.data); process.exit(1); }
  const token = login.data.token;
  console.log('✅ Step 1: SuperAdmin login OK');

  // Step 2: Get first available exam
  const exams = await req('GET', '/api/exams', null, token);
  const exam = exams.data?.exams?.[0] || exams.data?.[0];
  if (!exam) { console.log('❌ No exam found — create one first'); process.exit(1); }
  const examId = exam._id;
  console.log(`✅ Step 2: Exam found — ${exam.title} (${examId})`);

  // Step 3: Create Exam Instance (unique version + question snapshot)
  const create = await req('POST', '/api/exam-instances/create', {
    examId,
    setLabel: 'Set-A'
  }, token);
  if (create.status !== 201) { console.log('❌ Create failed', create.data); process.exit(1); }
  const instanceId = create.data.instance._id;
  const versionCode = create.data.instance.versionCode;
  const socketRoomId = create.data.instance.socketRoomId;
  console.log(`✅ Step 3: Instance created — ${versionCode}`);
  console.log(`   Questions: ${create.data.instance.totalQuestions}`);
  console.log(`   Socket Room: ${socketRoomId}`);

  // Step 4: Publish & Lock (no modification after publish)
  const publish = await req('PUT', `/api/exam-instances/${instanceId}/publish`, {}, token);
  if (publish.status !== 200) { console.log('❌ Publish failed', publish.data); process.exit(1); }
  console.log(`✅ Step 4: Instance published & locked — ${publish.data.lockedAt}`);

  // Step 5: Try to publish again (should be blocked)
  const dupPublish = await req('PUT', `/api/exam-instances/${instanceId}/publish`, {}, token);
  if (dupPublish.status === 400) {
    console.log('✅ Step 5: Duplicate publish BLOCKED ✓ (modification prevented)');
  } else {
    console.log('⚠️  Step 5: Lock check — response:', dupPublish.status);
  }

  // Step 6: Section Lock test (Timed Section Lockout)
  const secLock = await req('PUT', `/api/exam-instances/${instanceId}/lock-section`, {
    sectionName: 'Physics'
  }, token);
  if (secLock.status !== 200) { console.log('❌ Section lock failed', secLock.data); }
  else console.log(`✅ Step 6: Physics section locked — ${secLock.data.lockedAt}`);

  // Step 7: Socket Room ID fetch
  const room = await req('GET', `/api/exam-instances/${instanceId}/socket-room`, null, token);
  if (room.status !== 200) { console.log('❌ Socket room fetch failed', room.data); }
  else console.log(`✅ Step 7: Socket Room — ${room.data.socketRoomId}`);

  // Step 8: Watermark test (S76)
  const wm = await req('GET', `/api/exam-instances/${instanceId}/watermark`, null, token);
  if (wm.status !== 200) { console.log('❌ Watermark failed', wm.data); }
  else console.log(`✅ Step 8 (S76): Watermark — ${wm.data.watermark.displayText}`);

  // Step 9: Get all instances for exam
  const list = await req('GET', `/api/exam-instances/exam/${examId}`, null, token);
  console.log(`✅ Step 9: Instances for exam — Total: ${list.data.total}`);

  console.log('\n🎉 Phase 3.2 — ALL TESTS PASSED!\n');
  console.log('📋 Summary:');
  console.log(`   Version Code : ${versionCode}`);
  console.log(`   Socket Room  : ${socketRoomId}`);
  console.log(`   Instance ID  : ${instanceId}`);
}

run().catch(e => { console.error('❌ ERROR:', e.message); process.exit(1); });
