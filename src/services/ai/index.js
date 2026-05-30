const { calculateDifficulty } = require('./difficultyService');
const { classify } = require('./classifierService');
const { translateToHindi } = require('./translationService');
const { generateExplanation } = require('./explanationService');
const { computeDBSimilarity } = require('./similarityService');

async function runAIPipeline(questionDoc) {
  questionDoc.difficulty = calculateDifficulty(questionDoc.text);
  if(!questionDoc.subject||questionDoc.subject==="General")questionDoc.subject = classify(questionDoc.text);
  if(!questionDoc.hindiText)questionDoc.hindiText = translateToHindi(questionDoc.text);
  if(!questionDoc.explanation||!questionDoc.explanation.trim())questionDoc.explanation = await generateExplanation(
    questionDoc.text,
    questionDoc.options[questionDoc.correct[0]]
  );

  
  const { highestScore, mostSimilarId } = await computeDBSimilarity(questionDoc.text, questionDoc._id);

  questionDoc.similarityScore = highestScore;
  questionDoc.similarQuestionId = mostSimilarId;

  return questionDoc;

}

module.exports = { runAIPipeline };
