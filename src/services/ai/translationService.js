const dictionary = {
  force: "बल",
  mass: "द्रव्यमान",
  energy: "ऊर्जा",
  cell: "कोशिका",
  reaction: "प्रतिक्रिया"
};

function translateToHindi(text) {
  let words = text.toLowerCase().split(" ");
  let translated = words.map(w => dictionary[w] || w);
  return translated.join(" ");
}

module.exports = { translateToHindi };
