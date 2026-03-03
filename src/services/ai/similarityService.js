const natural = require("natural");
const cosineSimilarity = require("cosine-similarity");

async function computeDBSimilarity(newText, currentId) {

  // Lazy load to avoid circular dependency
  const Question = require("../../models/Question");

  const existing = await Question.find({ _id: { $ne: currentId } });

  let highestScore = 0;
  let mostSimilarId = null;

  for (let q of existing) {

    const tfidf = new natural.TfIdf();
    tfidf.addDocument(newText);
    tfidf.addDocument(q.text);

    const vec1 = [];
    const vec2 = [];

    tfidf.listTerms(0).forEach(item => vec1.push(item.tfidf));
    tfidf.listTerms(1).forEach(item => vec2.push(item.tfidf));

    const score = cosineSimilarity(vec1, vec2) || 0;

    if (score > highestScore) {
      highestScore = score;
      mostSimilarId = q._id;
    }
  }

  return { highestScore, mostSimilarId };
}

module.exports = { computeDBSimilarity };
