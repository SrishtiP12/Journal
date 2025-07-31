const mongoose = require('mongoose');

const entrySchema = new mongoose.Schema({
  date: {
    type: String,
    required: true,
    unique: true // one entry per day
  },
  text: {
    type: String,
    required: true
  },
  mood: {
    type: String,
    required: true
  }
});

module.exports = mongoose.model('Entry', entrySchema);
