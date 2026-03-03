function generateExplanation(question, correctOption) {
  return `The correct answer is "${correctOption}" because it directly satisfies the concept asked in the question.`;
}

module.exports = { generateExplanation };
