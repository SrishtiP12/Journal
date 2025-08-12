const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();

// CORS Configuration
app.use(cors({
  origin: ['https://journal-app-a193c.web.app', 'http://localhost:3000'],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
}));

app.use(express.json());

// Add a root route handler
app.get('/', (req, res) => {
  res.json({ message: 'Journal API is running' });
});

// Routes
const entryRoutes = require('./routes/entryRoutes');
app.use('/api', entryRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ error: 'Internal Server Error', details: err.message });
});

// MongoDB Connection with retry logic
const connectWithRetry = () => {
  const mongoURI = process.env.MONGO_URI;
  if (!mongoURI) {
    console.error('MONGO_URI environment variable is not set!');
    return;
  }

  mongoose.connect(mongoURI, {
    useNewUrlParser: true,
    useUnifiedTopology: true
  }).then(() => {
    console.log('MongoDB connected successfully');
  }).catch((err) => {
    console.error('MongoDB connection error:', err);
    console.log('Retrying connection in 5 seconds...');
    setTimeout(connectWithRetry, 5000);
  });
};

connectWithRetry();

// Server Configuration
const PORT = process.env.PORT || 3000;

// Start Server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on port ${PORT}`);
  console.log('Environment:', process.env.NODE_ENV || 'development');
  console.log('CORS enabled for:', ['https://journal-app-a193c.web.app', 'http://localhost:3000']);
}).on('error', (err) => {
  console.error('Server failed to start:', err);
});
