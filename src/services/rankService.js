const Attempt = require('../models/Attempt');

async function calculateRankAndPercentile(attemptId) {
  const attempt = await Attempt.findById(attemptId);
  if (!attempt) throw new Error('Attempt not found');

  const allAttempts = await Attempt.find({
    examId: attempt.examId,
    status: { $in: ['submitted', 'timeout'] },
    resultCalculated: true
  }).select('score studentId');

  const sorted = allAttempts
    .filter(a => a.score !== undefined && a.score !== null)
    .sort((a, b) => b.score - a.score);

  const totalStudents = sorted.length;
  const rank = sorted.findIndex(
    a => a.studentId.toString() === attempt.studentId.toString()
  ) + 1;

  const below = sorted.filter(a => a.score < attempt.score).length;
  const percentile = totalStudents > 1
    ? parseFloat(((below / (totalStudents - 1)) * 100).toFixed(2))
    : 100;

  attempt.rank = rank || 1;
  attempt.percentile = percentile;
  await attempt.save();

  return { rank: attempt.rank, percentile, totalStudents };
}

async function broadcastLiveRank(examId, studentId, rank, score, percentile) {
  try {
    const { getIO } = require('../config/socket');
    const io = getIO();
    if (!io) return;

    io.to(`exam_${examId}`).emit('rank_update', {
      studentId,
      rank,
      score,
      percentile,
      updatedAt: new Date()
    });
  } catch (err) {
    console.error('Socket broadcast error:', err.message);
  }
}

module.exports = { calculateRankAndPercentile, broadcastLiveRank };
