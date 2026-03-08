const mongoose = require('mongoose');

const sendAdminNotification = async (io, { type, title, message, relatedExamId, relatedStudentId, severity = 'info' }) => {
  try {
    const AdminNotification = mongoose.model('AdminNotification');
    const notification = await AdminNotification.create({
      type, title, message, relatedExamId, relatedStudentId, severity
    });

    // Real-time: superadmin room mein bhejo
    if (io) {
      io.to('admin_room').emit('new_admin_notification', {
        _id: notification._id,
        type, title, message, severity,
        createdAt: notification.createdAt
      });
    }

    return notification;
  } catch (err) {
    console.error('AdminNotifier error:', err.message);
  }
};

module.exports = { sendAdminNotification };
