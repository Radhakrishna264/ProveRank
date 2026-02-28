require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const mongoose = require('mongoose');

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json());

mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('MongoDB Connected:', mongoose.connection.host))
  .catch(err => console.log('MongoDB Error:', err));

// Routes
const authRoutes = require('./routes/auth');
app.use('/api/auth', authRoutes);

// Health Check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`ProveRank server running at http://0.0.0.0:${PORT}`);
});
