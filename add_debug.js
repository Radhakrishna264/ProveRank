const fs = require('fs');
const WS = process.env.HOME + '/workspace';

// exam.js mein start-attempt ke andar debug log add karo
let exam = fs.readFileSync(WS + '/src/routes/exam.js', 'utf8');

// start-attempt handler mein pehli line ke baad debug add
exam = exam.replace(
  "const { examId } = req.params;",
  `const { examId } = req.params;
    console.log('DEBUG start-attempt hit, examId:', examId);
    console.log('DEBUG mongoose state:', require('mongoose').connection.readyState);
    const testExam = await require('../models/Exam').findOne({});
    console.log('DEBUG any exam in DB:', testExam ? testExam._id : 'NONE');
    const testById = await require('../models/Exam').findById(examId);
    console.log('DEBUG findById result:', testById ? 'FOUND' : 'NULL');`
);

fs.writeFileSync(WS + '/src/routes/exam.js', exam);
console.log('Debug added to exam.js');

// attemptRoutes mein save-answer debug
let ar = fs.readFileSync(WS + '/src/routes/attemptRoutes.js', 'utf8');
ar = ar.replace(
  "const attempt = await Attempt.findById(attemptId);",
  `console.log('DEBUG save-answer attemptId:', attemptId);
    console.log('DEBUG mongoose state:', require('mongoose').connection.readyState);
    const anyAttempt = await Attempt.findOne({});
    console.log('DEBUG any attempt:', anyAttempt ? anyAttempt._id : 'NONE');
    const attempt = await Attempt.findById(attemptId);`
);
fs.writeFileSync(WS + '/src/routes/attemptRoutes.js', ar);
console.log('Debug added to attemptRoutes.js');
