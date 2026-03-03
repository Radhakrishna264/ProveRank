require('dotenv').config();
const mongoose = require('mongoose');

(async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);

    const Exam = require('./src/models/Exam');
    const User = require('./src/models/User');

    console.log("----- Phase 1.3 FULL TEST -----");

    // Fetch SuperAdmin automatically
    const admin = await User.findOne({ role: 'superadmin' });
    if (!admin) {
      console.log("❌ SuperAdmin not found");
      process.exit(1);
    }

    console.log("✔ SuperAdmin auto-fetched");

    // Create Test Exam
    const exam = await Exam.create({
      title: "Phase 1.3 Test Exam",
      subject: "NEET",
      duration: 200,
      totalMarks: 720,

      sections: [
        { name: "Physics", subject: "Physics", questionCount: 45, timeLimit: 60, marks: 180 },
        { name: "Chemistry", subject: "Chemistry", questionCount: 45, timeLimit: 60, marks: 180 },
        { name: "Biology", subject: "Biology", questionCount: 90, timeLimit: 80, marks: 360 }
      ],

      markingScheme: {
        correct: 4,
        incorrect: -1,
        unattempted: 0,
        msqMode: "ALL_OR_NOTHING"
      },

      schedule: {
        startTime: new Date(Date.now() + 60000),
        endTime: new Date(Date.now() + 3600000)
      },

      status: "scheduled",
      batch: "Test Batch",
      category: "Full Mock",

      watermark: true,

      customInstructions: "Read all questions carefully.",

      reviewWindow: {
        enabled: true,
        durationMinutes: 30
      },

      template: "NEET",
      difficulty: "Mixed",
      type: "NEET",

      waitingRoomEnabled: true,
      waitingRoomMinutes: 10,

      maxAttempts: 2,

      whitelist: [admin._id],

      createdBy: admin._id
    });

    console.log("✔ Exam created successfully");

    // Validate Clone Capability
    const clone = await Exam.create({
      ...exam.toObject(),
      _id: undefined,
      title: "Phase 1.3 Clone Exam"
    });

    console.log("✔ Exam clone baseline works");

    // Validate Schedule Logic
    if (exam.schedule.startTime && exam.schedule.endTime) {
      console.log("✔ Schedule stored");
    } else {
      console.log("❌ Schedule missing");
    }

    // Validate Review Window
    if (exam.reviewWindow.enabled) {
      console.log("✔ Review Window enabled");
    }

    // Validate Re-attempt
    if (exam.maxAttempts === 2) {
      console.log("✔ Re-attempt config working");
    }

    console.log("----- Phase 1.3 FULL TEST COMPLETE -----");

    process.exit();
  } catch (err) {
    console.error("❌ ERROR:", err);
    process.exit(1);
  }
})();
