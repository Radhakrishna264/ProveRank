const { calculateDifficulty } = require('./difficultyService');
const { classify } = require('./classifierService');
const { translateToHindi } = require('./translationService');
const { generateExplanation } = require('./explanationService');
const { computeDBSimilarity } = require('./similarityService');
const { translateQuestionToHindi } = require('./aiTranslationService');

async function runAIPipeline(questionDoc) {
  questionDoc.difficulty = calculateDifficulty(questionDoc.text);
  if(!questionDoc.subject||questionDoc.subject==="General")questionDoc.subject = classify(questionDoc.text);
  if(!questionDoc.explanation||!questionDoc.explanation.trim())questionDoc.explanation = await generateExplanation(
    questionDoc.text,
    questionDoc.options[questionDoc.correct[0]]
  );
  if(!questionDoc.hindiText || !questionDoc.hindiOptions || questionDoc.hindiOptions.length===0){
    try {
      const aiTrans = await translateQuestionToHindi(questionDoc.text, questionDoc.options, questionDoc.explanation);
      if(!questionDoc.hindiText) questionDoc.hindiText = aiTrans.hindiText || translateToHindi(questionDoc.text);
      if(!questionDoc.hindiOptions || questionDoc.hindiOptions.length===0) questionDoc.hindiOptions = aiTrans.hindiOptions || [];
      if(!questionDoc.hindiExplanation) questionDoc.hindiExplanation = aiTrans.hindiExplanation || '';
    } catch(e) {
      if(!questionDoc.hindiText) questionDoc.hindiText = translateToHindi(questionDoc.text);
      console.log('[AI-Hindi] translation failed: ' + e.message);
    }
  }

  
  const { highestScore, mostSimilarId } = await computeDBSimilarity(questionDoc.text, questionDoc._id);

  questionDoc.similarityScore = highestScore;
  questionDoc.similarQuestionId = mostSimilarId;

  return questionDoc;

}

module.exports = { runAIPipeline };
