const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Add a root route handler
app.get('/', (req, res) => {
  res.json({ message: 'Journal API is running' });
});

// Routes
const entryRoutes = require('./routes/entryRoutes');
app.use('/api', entryRoutes);

// MongoDB Connection
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
}).then(() => {
  console.log('MongoDB connected successfully');
}).catch((err) => {
  console.error('MongoDB connection error:', err);
  // Don't exit process, allow API to work without DB
});

// Server Configuration
const PORT = process.env.PORT || 3000;

// Start Server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on port ${PORT}`);
  console.log('Environment:', process.env.NODE_ENV || 'development');
}).on('error', (err) => {
  console.error('Server failed to start:', err);
});
