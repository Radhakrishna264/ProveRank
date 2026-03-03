const SUBJECT_KEYWORDS = {
  Physics: ["force", "velocity", "mass", "energy", "newton"],
  Chemistry: ["mole", "reaction", "acid", "base", "bond"],
  Biology: ["cell", "organ", "dna", "photosynthesis", "respiration"]
};

function classify(text) {
  const lower = text.toLowerCase();
  let bestMatch = "General";
  let score = 0;

  for (let subject in SUBJECT_KEYWORDS) {
    let matches = SUBJECT_KEYWORDS[subject].filter(word =>
      lower.includes(word)
    ).length;

    if (matches > score) {
      score = matches;
      bestMatch = subject;
    }
  }

  return bestMatch;
}

module.exports = { classify };
