require('dotenv').config();
const mongoose = require('mongoose');

(async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    const Exam = require('./src/models/Exam');

    const schemaFields = Object.keys(Exam.schema.paths);

    const requiredFields = [
      "title",
      "subject",
      "duration",
      "sections",
      "markingScheme",
      "password",
      "schedule",
      "status",
      "batch",
      "category",
      "whitelist",
      "watermark",
      "customInstructions",
      "maxAttempts",
      "reviewWindow",
      "template",
      "difficulty",
      "type",
      "waitingRoomEnabled",
      "waitingRoomMinutes"
    ];

    console.log("----- Phase 1.3 Schema Audit -----");

    requiredFields.forEach(field => {
      if (schemaFields.includes(field)) {
        console.log("✔", field);
      } else {
        console.log("❌ MISSING:", field);
      }
    });

    process.exit();
  } catch (err) {
    console.error("Error:", err);
    process.exit(1);
  }
})();
