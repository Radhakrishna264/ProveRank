const socketIO = require('socket.io');

let io;

const initSocket = (server) => {
  io = socketIO(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST']
    }
  });

  io.on('connection', (socket) => {
    console.log('Socket connected:', socket.id);

    socket.on('join-exam', (examId) => {
      socket.join(examId);
      console.log(`Socket ${socket.id} joined exam: ${examId}`);
    });

    // F52-F57 v2 — Waiting Room live presence (F53 §2.1.6 live count, Rule 1.15.3 re-entry)
    socket.on('join-waiting-room', (examId) => {
      if (!examId) return;
      socket.join(`waiting-${examId}`);
      socket.data.waitingExamId = examId;
      const room = io.sockets.adapter.rooms.get(`waiting-${examId}`);
      const count = room ? room.size : 0;
      io.to(`waiting-${examId}`).emit('waiting-room-count', { examId, count });
    });

    socket.on('leave-waiting-room', (examId) => {
      if (!examId) return;
      socket.leave(`waiting-${examId}`);
      const room = io.sockets.adapter.rooms.get(`waiting-${examId}`);
      const count = room ? room.size : 0;
      io.to(`waiting-${examId}`).emit('waiting-room-count', { examId, count });
    });

    // F53 §5 — Waiting room chat relay (server also validates window via REST route)
    socket.on('waiting-room-chat', (payload) => {
      if (!payload || !payload.examId) return;
      io.to(`waiting-${payload.examId}`).emit('waiting-chat-message', payload.message);
    });

    socket.on('disconnect', () => {
      const examId = socket.data && socket.data.waitingExamId;
      if (examId) {
        const room = io.sockets.adapter.rooms.get(`waiting-${examId}`);
        const count = room ? room.size : 0;
        io.to(`waiting-${examId}`).emit('waiting-room-count', { examId, count });
      }
      console.log('Socket disconnected:', socket.id);
    });
  });

  return io;
};

const getIO = () => {
  if (!io) throw new Error('Socket not initialized');
  return io;
};

module.exports = { initSocket, getIO };
