require('dotenv').config();
const mongoose = require('mongoose');

(async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);

    const Question = require('./src/models/Question');

    console.log("------ Stage 2.1 AI FULL TEST ------");

    // Create test question
    const q = await Question.create({
      text: "What is the unit of force?",
      subject: "Physics",
      options: ["Newton", "Joule", "Pascal", "Watt"],
      correct: [0],
      type: "SCQ"
    });

    console.log("✔ Question created");

    const fresh = await Question.findById(q._id);

    // AI-1 Difficulty
    if (fresh.difficulty)
      console.log("✔ AI-1 Difficulty present:", fresh.difficulty);
    else
      console.log("✖ AI-1 Difficulty missing");

    // AI-2 Subject Classification
    if (fresh.subject)
      console.log("✔ AI-2 Subject present:", fresh.subject);
    else
      console.log("✖ AI-2 Subject classification missing");

    // AI-5 Concept Similarity Field
    if (fresh.similarityScore !== undefined)
      console.log("✔ AI-5 Similarity field exists");
    else
      console.log("✖ AI-5 Similarity field missing");

    // AI-8 Translation
    if (fresh.hindiText || fresh.translatedText)
      console.log("✔ AI-8 Translation field exists");
    else
      console.log("✖ AI-8 Translation not implemented");

    // AI-10 Explanation
    if (fresh.explanation && fresh.explanation.length > 0)
      console.log("✔ AI-10 Explanation generated");
    else
      console.log("✖ AI-10 Explanation not auto-generated");

    console.log("------ AI TEST COMPLETE ------");

    process.exit();
  } catch (err) {
    console.error("ERROR:", err);
    process.exit(1);
  }
})();
