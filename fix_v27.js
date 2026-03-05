const fs = require('fs');
const WS = process.env.HOME + '/workspace';

// --- STEP 1: index.js ka actual mount section dikhao ---
const idx = fs.readFileSync(WS + '/src/index.js', 'utf8');
console.log('=== Current /api/exams mount lines ===');
idx.split('\n').forEach((l,i) => {
  if(l.includes('api/exams') || l.includes('api/attempt')) 
    console.log((i+1)+': '+l.trim());
});

// --- STEP 2: attemptRoutes findById check ---
const ar = fs.readFileSync(WS + '/src/routes/attemptRoutes.js', 'utf8');
console.log('\n=== attemptRoutes findById lines ===');
ar.split('\n').forEach((l,i) => {
  if(l.includes('findById') || l.includes('Attempt.find'))
    console.log((i+1)+': '+l.trim());
});

// --- FIX A: index.js mount order force fix ---
// examRoutes ko examFeaturesRoutes se PEHLE laana hai
const lines = idx.split('\n');
let featIdx = -1, examIdx = -1, patchIdx = -1;

lines.forEach((l,i) => {
  if(l.includes('examFeaturesRoutes') && l.includes('app.use')) featIdx = i;
  if(l.includes('examPatchRoutes') && l.includes('app.use')) patchIdx = i;
  if(l.includes("examRoutes)") && l.includes('app.use') && !l.includes('Patch') && !l.includes('Features') && !l.includes('Extra')) examIdx = i;
});

console.log('\nfeatIdx:'+featIdx+' examIdx:'+examIdx+' patchIdx:'+patchIdx);

if(featIdx > -1 && examIdx > -1 && examIdx > featIdx) {
  // examRoutes line nikaalo
  const examLine = lines[examIdx];
  lines.splice(examIdx, 1); // remove from current pos
  // featIdx ke PEHLE daalo
  const newFeatIdx = featIdx < examIdx ? featIdx : featIdx - 1;
  lines.splice(newFeatIdx, 0, examLine);
  fs.writeFileSync(WS + '/src/index.js', lines.join('\n'));
  console.log('\nFIX A DONE: examRoutes moved BEFORE examFeaturesRoutes');
} else if(examIdx < featIdx) {
  console.log('\nMount order already correct!');
}

// --- FIX B: attemptRoutes mein ObjectId fix ---
let ar2 = fs.readFileSync(WS + '/src/routes/attemptRoutes.js', 'utf8');
const mongoose_import = ar2.includes("require('mongoose')") || ar2.includes('require("mongoose")');
console.log('\nmongoose imported in attemptRoutes:', mongoose_import);

if(!mongoose_import) {
  ar2 = "const mongoose = require('mongoose');\n" + ar2;
  console.log('FIX B1: mongoose import added');
}

// findById mein ObjectId wrap
const before = ar2;
ar2 = ar2.replace(
  /Attempt\.findById\(req\.params\.(attemptId|id)\)/g,
  'Attempt.findById(new mongoose.Types.ObjectId(req.params.$1))'
);
if(ar2 !== before) {
  console.log('FIX B2: ObjectId wrap added in all Attempt.findById calls');
} else {
  console.log('FIX B2: Already wrapped OR different pattern');
}
fs.writeFileSync(WS + '/src/routes/attemptRoutes.js', ar2);

// --- FIX C: exam_patch.js mein Exam.findById ObjectId wrap ---
let ep = fs.readFileSync(WS + '/src/routes/exam_patch.js', 'utf8');
if(!ep.includes("require('mongoose')") && !ep.includes('require("mongoose")')) {
  ep = "const mongoose = require('mongoose');\n" + ep;
}
ep = ep.replace(
  /Exam\.findById\(req\.params\.examId\)/g,
  'Exam.findById(new mongoose.Types.ObjectId(req.params.examId))'
);
fs.writeFileSync(WS + '/src/routes/exam_patch.js', ep);
console.log('FIX C: exam_patch.js ObjectId fix done');

// --- VERIFY: index.js new order ---
const newIdx = fs.readFileSync(WS + '/src/index.js', 'utf8');
console.log('\n=== NEW mount order ===');
newIdx.split('\n').forEach((l,i) => {
  if(l.includes('api/exams') || l.includes('api/attempt'))
    console.log((i+1)+': '+l.trim());
});

console.log('\n=== ALL FIXES DONE - Ab test chalaao ===');
