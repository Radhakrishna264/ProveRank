require('dotenv').config();
const mongoose = require('mongoose');

(async () => {
  await mongoose.connect(process.env.MONGODB_URI);
  const Exam = require('./src/models/Exam');

  const update = {
    $set: {
      reviewWindow: { enabled: false, durationMinutes: 0 },
      template: '',
      difficulty: 'Mixed',
      type: 'NEET',
      waitingRoomEnabled: false,
      waitingRoomMinutes: 10
    }
  };

  await Exam.updateMany(
    { reviewWindow: { $exists: false } },
    update
  );

  console.log("Phase 1.3 schema upgrade baseline values inserted.");
  process.exit();
})();
