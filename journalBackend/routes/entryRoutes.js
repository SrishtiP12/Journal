const express = require('express');
const router = express.Router();
const Entry = require('../models/Entry');

// POST /api/entries - Create a new journal entry
router.post('/entries', async (req, res) => {
  const { date, text, mood } = req.body;

  try {
    const existing = await Entry.findOne({ date });
    if (existing) {
      return res.status(400).json({ error: 'Entry already exists for this date.' });
    }

    const newEntry = new Entry({ date, text, mood });
    await newEntry.save();
    res.status(201).json(newEntry);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/entries - Get all journal entries
router.get('/entries', async (req, res) => {
  try {
    const entries = await Entry.find().sort({ date: -1 });
    res.json(entries);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
