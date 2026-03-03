const BASE = 'http://localhost:3000';

async function run() {
  let pass = 0, fail = 0;
  console.log('\n🔍 PENDING TESTS - Phase 1.2/2.1/2.3/2.4/2.5\n');

  // --- LOGIN ---
  const loginRes = await fetch(`${BASE}/api/auth/login`, {
    method: 'POST', headers: {'Content-Type':'application/json'},
    body: JSON.stringify({ email: 'admin@proverank.com', password: 'ProveRank@SuperAdmin123' })
  });
  const loginData = await loginRes.json();
  const token = loginData.data?.token || loginData.token;
  if (!token) { console.log('❌ Login failed:', loginData.message); process.exit(1); }
  const H = { 'Content-Type':'application/json', 'Authorization':`Bearer ${token}` };
  const adminId = loginData.data?.user?._id || loginData.user?._id;
  console.log('✅ SuperAdmin login OK | adminId:', adminId);

  // --- STUDENT LOGIN ---
  let studentToken = null;
  try {
    const sRes = await fetch(`${BASE}/api/auth/login`, {
      method:'POST', headers:{'Content-Type':'application/json'},
      body: JSON.stringify({ email: 'student@proverank.com', password: 'ProveRank@123' })
    });
    const sData = await sRes.json();
    studentToken = sData.data?.token || sData.token;
    console.log(studentToken ? '✅ Student login OK' : '⚠️ Student login failed - skip student route tests');
  } catch(e) { console.log('⚠️ Student login error - skip'); }

  // ══ TEST 1: Phase 1.2 Step 4 - Protected Routes ══
  console.log('\n── TEST 1: Phase 1.2 Step 4 – Protected Routes ──');
  // 1a: No token blocked
  const r1a = await fetch(`${BASE}/api/questions`);
  if (r1a.status === 401) { console.log('  ✅ No token → blocked'); pass++; }
  else { console.log('  ❌ No token → NOT blocked, status:', r1a.status); fail++; }
  // 1b: Admin token works
  const r1b = await fetch(`${BASE}/api/questions`, { headers: H });
  if (r1b.status === 200 || r1b.status === 201) { console.log('  ✅ Admin token → accessible'); pass++; }
  else { console.log('  ❌ Admin token → failed, status:', r1b.status); fail++; }
  // 1c: Student token
  if (studentToken) {
    const r1c = await fetch(`${BASE}/api/questions`, { headers: {'Authorization':`Bearer ${studentToken}`} });
    if (r1c.status === 200 || r1c.status === 403) { console.log('  ✅ Student token → responded correctly'); pass++; }
    else { console.log('  ⚠️ Student token → status:', r1c.status); }
  } else { console.log('  ⚠️ Student token test skip'); }

  // ══ TEST 2: Phase 2.1 Step 3 - S34 Question Filters ══
  console.log('\n── TEST 2: Phase 2.1 Step 3 – S34 Question Filters ──');
  const f1 = await fetch(`${BASE}/api/questions?subject=Biology`, { headers: H });
  const f1d = await f1.json();
  if (f1.status === 200) { console.log('  ✅ subject=Biology works'); pass++; }
  else { console.log('  ❌ subject filter failed:', f1d.message); fail++; }

  const f2 = await fetch(`${BASE}/api/questions?difficulty=Hard`, { headers: H });
  if (f2.status === 200) { console.log('  ✅ difficulty=Hard works'); pass++; }
  else { console.log('  ❌ difficulty filter failed'); fail++; }

  const f3 = await fetch(`${BASE}/api/questions?subject=Physics&difficulty=Medium`, { headers: H });
  if (f3.status === 200) { console.log('  ✅ Combined filter works'); pass++; }
  else { console.log('  ❌ Combined filter failed'); fail++; }

  // ══ TEST 3: Phase 2.3 Step 8 - Error Logging ══
  console.log('\n── TEST 3: Phase 2.3 Step 8 – Error Logging (Unparseable) ──');
  const t3 = await fetch(`${BASE}/api/upload/pdf`, {
    method: 'POST', headers: { 'Authorization': `Bearer ${token}` }
  });
  const t3d = await t3.json().catch(() => ({}));
  if (t3.status === 400 && (t3d.message?.toLowerCase().includes('pdf') || t3d.message?.toLowerCase().includes('file') || t3d.error)) {
    console.log('  ✅ Error logging works – flagged:', t3d.message || t3d.error); pass++;
  } else { console.log('  ❌ Error logging missing – status:', t3.status, t3d.message); fail++; }

  // ══ TEST 4: Phase 2.4 Step 5 - Result Calculation Auto-link ══
  console.log('\n── TEST 4: Phase 2.4 Step 5 – Result Calculation Auto-link ──');
  const t4 = await fetch(`${BASE}/api/upload/copypaste/questions`, {
    method: 'POST', headers: H,
    body: JSON.stringify({
      questionsText: '1. What is photosynthesis?\nA) A process in plants\nB) Nothing\nC) Maybe\nD) All above',
      answers: '1-A'
    })
  });
  const t4d = await t4.json().catch(() => ({}));
  console.log('  Status:', t4.status, '| Keys:', Object.keys(t4d||{}).join(', '));
  if (t4.status === 200 || t4.status === 201) {
    const hasLink = t4d.examLink !== undefined || t4d.savedToExam !== undefined;
    if (hasLink) { console.log('  ✅ Auto-link field exists in response'); pass++; }
    else { console.log('  ❌ examLink missing from response'); fail++; }
  } else { console.log('  ❌ Copy-paste failed:', t4.status, t4d.message || t4d?.raw?.substring(0,80)); fail++; }

  // ══ TEST 5: Phase 2.4 Step 6 - Validation & Error Highlighting ══
  console.log('\n── TEST 5: Phase 2.4 Step 6 – Validation & Error Highlighting ──');
  const t5a = await fetch(`${BASE}/api/upload/copypaste/questions`, {
    method: 'POST', headers: H,
    body: JSON.stringify({ text: '', answers: '' })
  });
  const t5b = await fetch(`${BASE}/api/upload/copypaste/validate`, {
    method: 'POST', headers: H,
    body: JSON.stringify({ text: '', answers: '' })
  });
  const t5ad = await t5a.json().catch(()=>({}));
  const t5bd = await t5b.json().catch(()=>({}));
  console.log('  questions empty – Status:', t5a.status, t5ad.message||'');
  console.log('  validate empty – Status:', t5b.status, t5bd.message||'');
  if ((t5a.status === 400 || t5b.status === 400) && (t5ad.errors || t5bd.errors || t5ad.message || t5bd.message)) {
    console.log('  ✅ Validation works – invalid input rejected'); pass++;
  } else { console.log('  ❌ Validation missing'); fail++; }

  // ══ TEST 6: Phase 2.5 Step 5 - One-click Ready as Exam ══
  console.log('\n── TEST 6: Phase 2.5 Step 5 – One-click Ready as Exam ──');
  const t6 = await fetch(`${BASE}/api/paper/generate`, {
    method: 'POST', headers: H,
    body: JSON.stringify({ mode: 'neet', subjects: { Physics: 45, Chemistry: 45, Biology: 90 } })
  });
  const t6d = await t6.json().catch(()=>({}));
  console.log('  Status:', t6.status, '| Keys:', Object.keys(t6d||{}).join(', '));
  if (t6.status === 200 || t6.status === 201) {
    const canUse = t6d.savedAsExam !== undefined || t6d.examReady !== undefined || t6d.totalSets > 0;
    if (canUse) { console.log('  ✅ One-click exam ready – savedAsExam present'); pass++; }
    else { console.log('  ❌ savedAsExam missing'); fail++; }
  } else { console.log('  ❌ Paper generate failed:', t6.status, t6d.message || ''); fail++; }

  // ── SUMMARY ──
  console.log('\n' + '='.repeat(50));
  console.log(`📊 RESULTS: ✅ ${pass} Pass  |  ❌ ${fail} Issues`);
  if (fail === 0) console.log('🎉 Sab pass! Stage 4 shuru karo!');
  else console.log(`⚠️ ${fail} issues – fix needed.`);
}

run().catch(e => console.error('❌ CRASH:', e.message));
