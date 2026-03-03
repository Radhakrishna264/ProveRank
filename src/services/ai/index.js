const { calculateDifficulty } = require('./difficultyService');
const { classify } = require('./classifierService');
const { translateToHindi } = require('./translationService');
const { generateExplanation } = require('./explanationService');
const { computeDBSimilarity } = require('./similarityService');

async function runAIPipeline(questionDoc) {
  questionDoc.difficulty = calculateDifficulty(questionDoc.text);
  questionDoc.subject = classify(questionDoc.text);
  questionDoc.hindiText = translateToHindi(questionDoc.text);
  questionDoc.explanation = generateExplanation(
    questionDoc.text,
    questionDoc.options[questionDoc.correct[0]]
  );

  
  const { highestScore, mostSimilarId } = await computeDBSimilarity(questionDoc.text, questionDoc._id);

  questionDoc.similarityScore = highestScore;
  questionDoc.similarQuestionId = mostSimilarId;

  return questionDoc;

}

module.exports = { runAIPipeline };
