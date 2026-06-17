const XLSX = require('xlsx');

const parseQuestionExcel = (filePath) => {
  const workbook = XLSX.readFile(filePath);
  const sheetName = workbook.SheetNames[0];
  const sheet = workbook.Sheets[sheetName];
  const rows = XLSX.utils.sheet_to_json(sheet);

  const questions = [];
  const errors = [];

  rows.forEach((row, index) => {
    const rowNum = index + 2;
    if (!row['Question Text']) {
      errors.push({ row: rowNum, message: 'Question Text missing' });
      return;
    }
    if (!row['Option A'] || !row['Option B'] || !row['Option C'] || !row['Option D']) {
      errors.push({ row: rowNum, message: 'Options A/B/C/D required' });
      return;
    }
    if (!row['Correct Answer']) {
      errors.push({ row: rowNum, message: 'Correct Answer missing' });
      return;
    }
    const validAnswers = ['A', 'B', 'C', 'D'];
    if (!validAnswers.includes(String(row['Correct Answer']).toUpperCase())) {
      errors.push({ row: rowNum, message: 'Correct Answer must be A, B, C or D' });
      return;
    }
    const optionMap = {
      'A': row['Option A'],
      'B': row['Option B'],
      'C': row['Option C'],
      'D': row['Option D']
    };
    const correctLetter = String(row['Correct Answer']).toUpperCase();
    questions.push({
      text: String(row['Question Text']).trim(),
      hindiText: row['Hindi Text'] ? String(row['Hindi Text']).trim() : '',
      options: [
        { text: String(row['Option A']).trim(), isCorrect: correctLetter === 'A' },
        { text: String(row['Option B']).trim(), isCorrect: correctLetter === 'B' },
        { text: String(row['Option C']).trim(), isCorrect: correctLetter === 'C' },
        { text: String(row['Option D']).trim(), isCorrect: correctLetter === 'D' }
      ],
      subject: row['Subject'] ? String(row['Subject']).trim() : 'General',
      chapter: row['Chapter'] ? String(row['Chapter']).trim() : '',
      topic: row['Topic'] ? String(row['Topic']).trim() : '',
      difficulty: row['Difficulty'] ? String(row['Difficulty']).trim() : 'Medium',
      explanation: row['Explanation'] ? String(row['Explanation']).trim() : '',
      tags: row['Tags'] ? String(row['Tags']).split(',').map(t => t.trim()) : []
    });
  });

  return { questions, errors };
};

const parseStudentExcel = (filePath) => {
  const workbook = XLSX.readFile(filePath);
  const sheetName = workbook.SheetNames[0];
  const sheet = workbook.Sheets[sheetName];
  const rows = XLSX.utils.sheet_to_json(sheet);

  const students = [];
  const errors = [];

  rows.forEach((row, index) => {
    const rowNum = index + 2;
    if (!row['Name']) {
      errors.push({ row: rowNum, message: 'Name missing' });
      return;
    }
    if (!row['Email']) {
      errors.push({ row: rowNum, message: 'Email missing' });
      return;
    }
    if (!row['Phone']) {
      errors.push({ row: rowNum, message: 'Phone missing' });
      return;
    }
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(row['Email'])) {
      errors.push({ row: rowNum, message: 'Invalid email format' });
      return;
    }
    students.push({
      name: String(row['Name']).trim(),
      email: String(row['Email']).trim().toLowerCase(),
      phone: String(row['Phone']).trim(),
      group: row['Group'] ? String(row['Group']).trim() : 'General'
    });
  });

  return { students, errors };
};

module.exports = { parseQuestionExcel, parseStudentExcel };
