#!/bin/bash
cat > /tmp/fix_ai_qtype.js << 'JSEOF'
const fs = require('fs');

// ===== FIX 1: FRONTEND - add type:aiType in aiGF fetch =====
const feFile = '/home/runner/workspace/frontend/app/admin/x7k2p/page.tsx';
let fe = fs.readFileSync(feFile, 'utf8');

const oldFE = 'body:JSON.stringify({subject:aiGSub,chapter:ch,topic:tp,count:parseInt(aiGCnt)||10,difficulty:aiGDiff})';
const newFE = 'body:JSON.stringify({subject:aiGSub,chapter:ch,topic:tp,count:parseInt(aiGCnt)||10,difficulty:aiGDiff,type:aiType})';

if (fe.includes(oldFE)) {
  fe = fe.replace(oldFE, newFE);
  fs.writeFileSync(feFile, fe);
  console.log('✅ FIX 1 DONE: Frontend aiGF - type:aiType added');
} else {
  console.log('❌ FIX 1 SKIP: Frontend string not found (already fixed or spacing diff)');
}

// ===== FIX 2: BACKEND - add reqType to destructuring =====
const beFile = '/home/runner/workspace/src/routes/questionFeatures.js';
let be = fs.readFileSync(beFile, 'utf8');

const oldDestr = "const { subject, chapter, topic, count = 10, difficulty = 'medium' } = req.body";
const newDestr = "const { subject, chapter, topic, count = 10, difficulty = 'medium', type: reqType = 'SCQ' } = req.body";

if (be.includes(oldDestr)) {
  be = be.replace(oldDestr, newDestr);
  console.log('✅ FIX 2 DONE: Backend destructure - reqType added');
} else {
  console.log('❌ FIX 2 SKIP: Destructure string not found');
}

// ===== FIX 3: BACKEND - replace hardcoded type:'SCQ' + inject MSQ/Integer logic =====
// Replace from cIdx_gen line to end of generated.push
const oldBlock = `      const cIdx_gen = Math.floor(Math.random() * 4)
      const cLetter_gen = ['A','B','C','D'][cIdx_gen]
      const expMap = {
        Physics: opts[cIdx_gen] + ' is the correct answer. In ' + chapter + ', the concept of ' + topic + ' follows this fundamental Physics principle as per NCERT – frequently tested in NEET.',
        Chemistry: 'opts[cIdx_gen] + ' is correct. ' + topic + ' in ' + chapter + ' demonstrates this key chemical property as per NCERT. Chemistry concept.',
        Biology: opts[cIdx_gen] + ' is the correct answer. ' + topic + ' in ' + chapter + ' is a crucial Biology concept as per NCERT – frequently asked in NEET examination.',
      };
      const genExpl_ai = expMap[subject] || (opts[cIdx_gen] + ' is correct. ' + topic + ' in ' + chapter + ' – this Biology concept is essential for NEET preparation.');
      generated.push({
        text: qText,
        subject,
        chapter,
        topic,
        difficulty,
        type: 'SCQ',
        options: opts,
        correct: [cIdx_gen],
        correctAnswer: cLetter_gen,
        explanation: genExpl_ai,
        approvalStatus: 'pending'
      })`;

const newBlock = `      const cIdx_gen = Math.floor(Math.random() * 4)
      const cLetter_gen = ['A','B','C','D'][cIdx_gen]
      const expMap = {
        Physics: opts[cIdx_gen] + ' is the correct answer. In ' + chapter + ', the concept of ' + topic + ' follows this fundamental Physics principle as per NCERT – frequently tested in NEET.',
        Chemistry: opts[cIdx_gen] + ' is correct. ' + topic + ' in ' + chapter + ' demonstrates this key chemical property as per NCERT. Chemistry concept.',
        Biology: opts[cIdx_gen] + ' is the correct answer. ' + topic + ' in ' + chapter + ' is a crucial Biology concept as per NCERT – frequently asked in NEET examination.',
      };
      const genExpl_ai = expMap[subject] || (opts[cIdx_gen] + ' is correct. ' + topic + ' in ' + chapter + ' – this concept is essential for NEET preparation.');

      // Type-aware correct answer logic
      let qOptions = opts;
      let qCorrect = [cIdx_gen];
      let qCorrectAnswer = cLetter_gen;

      if (reqType === 'MSQ') {
        // MSQ: 2 correct answers
        const secondIdx = (cIdx_gen + 2) % 4;
        qCorrect = [cIdx_gen, secondIdx].sort((a, b) => a - b);
        qCorrectAnswer = qCorrect.map(i => ['A','B','C','D'][i]).join(',');
      } else if (reqType === 'Integer') {
        // Integer: numeric answer between 1-100, no standard options needed
        const intAns = Math.floor(Math.random() * 100) + 1;
        qOptions = [];
        qCorrect = [intAns];
        qCorrectAnswer = String(intAns);
      }

      generated.push({
        text: qText,
        subject,
        chapter,
        topic,
        difficulty,
        type: reqType,
        options: qOptions,
        correct: qCorrect,
        correctAnswer: qCorrectAnswer,
        explanation: genExpl_ai,
        approvalStatus: 'pending'
      })`;

if (be.includes(oldBlock)) {
  be = be.replace(oldBlock, newBlock);
  fs.writeFileSync(beFile, be);
  console.log('✅ FIX 3 DONE: Backend generate - reqType used, MSQ/Integer logic added');
} else {
  // Fallback: just replace the two targeted lines
  console.log('⚠️  FIX 3 fallback: trying targeted type field replace...');
  
  // Just fix the type field in generated.push (minimal safe fix)
  if (be.includes("        type: 'SCQ',")) {
    // Find the generate route section and replace only that type field
    const generateRouteStart = be.indexOf("// — AI GENERATE QUESTIONS");
    const generateRouteEnd = be.indexOf("// — BULK SAVE QUESTIONS");
    if (generateRouteStart > -1 && generateRouteEnd > -1) {
      let routeSection = be.substring(generateRouteStart, generateRouteEnd);
      routeSection = routeSection.replace("        type: 'SCQ',", "        type: reqType,");
      be = be.substring(0, generateRouteStart) + routeSection + be.substring(generateRouteEnd);
      fs.writeFileSync(beFile, be);
      console.log('✅ FIX 3 fallback DONE: type field replaced with reqType');
    }
  } else {
    console.log('❌ FIX 3 SKIP: Could not locate block');
    fs.writeFileSync(beFile, be); // still save destructure fix
  }
}

console.log('\n🎯 Done! Check results above.');
console.log('📋 Next: git add -A && git commit -m "fix: AI generator uses correct question type (MSQ/Integer/SCQ)" && git push');
JSEOF

node /tmp/fix_ai_qtype.js
