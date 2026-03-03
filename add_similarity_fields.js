const fs = require('fs');
const path = './src/models/Question.js';

let content = fs.readFileSync(path, 'utf8');

if (!content.includes('similarityScore')) {

  const insert = `
  similarityScore: { type: Number, default: 0 },
  similarQuestionId: { type: require('mongoose').Schema.Types.ObjectId, ref: 'Question', default: null },
`;

  content = content.replace(
    /createdBy:[^}]+}/,
    match => match + "," + insert
  );

  fs.writeFileSync(path, content);
  console.log("✔ Similarity fields added to Question schema");
} else {
  console.log("Similarity fields already exist");
}
