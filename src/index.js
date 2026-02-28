require('dotenv').config();
const connectDB = require('./config/db');
const app = require('./app');

const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0';

// Connect to database
connectDB();

app.listen(PORT, HOST, () => {
    console.log(`ProveRank server running at http://${HOST}:${PORT}`);
});
