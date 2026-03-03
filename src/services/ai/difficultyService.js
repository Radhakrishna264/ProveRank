function calculateDifficulty(text) {
  const length = text.split(" ").length;

  if (length < 8) return "Easy";
  if (length < 15) return "Medium";
  return "Hard";
}

module.exports = { calculateDifficulty };
