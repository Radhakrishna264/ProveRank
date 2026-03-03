require('dotenv').config();
const mongoose = require('mongoose');

(async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);

    const Question = require('./src/models/Question');
    const User = require('./src/models/User');

    console.log("------ Stage 2.1 AI FULL TEST ------");

    const admin = await User.findOne({ role: 'superadmin' });
    if (!admin) {
      console.log("✖ No SuperAdmin found");
      process.exit(1);
    }

    const q = await Question.create({
      text: "What is the unit of force?",
      subject: "Physics",
      options: ["Newton", "Joule", "Pascal", "Watt"],
      correct: [0],
      type: "SCQ",
      createdBy: admin._id
    });

    console.log("✔ Question created");

    const fresh = await Question.findById(q._id);

    // AI-1
    console.log(fresh.difficulty ? 
      "✔ AI-1 Difficulty present: " + fresh.difficulty :
      "✖ AI-1 Difficulty missing");

    // AI-2
    console.log(fresh.subject ?
      "✔ AI-2 Subject present: " + fresh.subject :
      "✖ AI-2 Subject classification missing");

    // AI-5
    console.log(fresh.similarityScore !== undefined ?
      "✔ AI-5 Similarity field exists" :
      "✖ AI-5 Similarity field missing");

    // AI-8
    console.log(fresh.hindiText || fresh.translatedText ?
      "✔ AI-8 Translation field exists" :
      "✖ AI-8 Translation not implemented");

    // AI-10
    console.log(fresh.explanation && fresh.explanation.length > 0 ?
      "✔ AI-10 Explanation generated" :
      "✖ AI-10 Explanation not auto-generated");

    console.log("------ AI TEST COMPLETE ------");

    process.exit();
  } catch (err) {
    console.error("ERROR:", err);
    process.exit(1);
  }
})();
