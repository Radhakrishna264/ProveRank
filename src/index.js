require('dotenv').config();
const express = require('express');
const http = require('http');
const cors = require('cors');
const helmet = require('helmet');
const mongoose = require('mongoose');
const { initSocket } = require('./config/socket');

const app = express();
const server = http.createServer(app);
initSocket(server);

app.use(helmet());
app.use(cors());
app.use(express.json());

mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('MongoDB Connected:', mongoose.connection.host))
  .catch(err => console.log('MongoDB Error:', err));

const questionRoutes = require('./routes/question');
const uploadRoutes = require('./routes/upload');

app.use('/api/auth', require('./routes/auth'));
const questionAdvancedRoutes = require('./routes/questionAdvanced');
const questionAIRoutes = require('./routes/questionAI');
app.use('/api/questions-advanced', questionAdvancedRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/questions-advanced', questionAIRoutes);
const questionExtraRoutes = require('./routes/questionExtra');
app.use('/api/questions', questionExtraRoutes);
app.use('/api/questions', questionRoutes);
app.use('/api/exams', require('./routes/exam'));
app.use('/api/exams', require('./routes/examExtra'));
app.use('/api/admin', require('./routes/admin'));

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`ProveRank server running at http://0.0.0.0:${PORT}`);
});

// Phase 2.2 - Excel Upload Routes
const excelUploadRoutes = require('./routes/excelUpload');
app.use('/api/excel', excelUploadRoutes);
