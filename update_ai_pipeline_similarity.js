const fs = require('fs');
const path = './src/services/ai/index.js';

let content = fs.readFileSync(path, 'utf8');

if (!content.includes('computeDBSimilarity')) {

  content = content.replace(
    "const { generateExplanation } = require('./explanationService');",
    `const { generateExplanation } = require('./explanationService');
const { computeDBSimilarity } = require('./similarityService');`
  );

  content = content.replace(
    "return questionDoc;",
    `
  const { highestScore, mostSimilarId } = await computeDBSimilarity(questionDoc.text, questionDoc._id);

  questionDoc.similarityScore = highestScore;
  questionDoc.similarQuestionId = mostSimilarId;

  return questionDoc;
`
  );

  fs.writeFileSync(path, content);
  console.log("✔ AI pipeline updated with DB similarity");
} else {
  console.log("Similarity already integrated");
}
