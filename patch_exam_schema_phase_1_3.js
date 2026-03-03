const fs = require('fs');

const path = './src/models/Exam.js';
let content = fs.readFileSync(path, 'utf8');

const insertion = `

  reviewWindow: {
    enabled: { type: Boolean, default: false },
    durationMinutes: { type: Number, default: 0 }
  },

  template: { type: String, default: '' },

  difficulty: { type: String, default: 'Mixed' },

  type: { type: String, default: 'NEET' },

  waitingRoomEnabled: { type: Boolean, default: false },

  waitingRoomMinutes: { type: Number, default: 10 },
`;

if (!content.includes('reviewWindow')) {
  content = content.replace(
    /customInstructions:[^,]+,/,
    match => match + insertion
  );
  fs.writeFileSync(path, content);
  console.log("Exam schema patched successfully.");
} else {
  console.log("Schema already contains reviewWindow — manual check required.");
}
