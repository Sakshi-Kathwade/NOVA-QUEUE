const mongoose = require('mongoose');

const queueSchema = new mongoose.Schema({
  queueName: {
    type: String,
    required: true,
    unique: true,
    trim: true,
  },
  adminId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
    required: true,
  },
  status: {
    type: String,
    enum: ['Active', 'Inactive', 'Closed', 'Paused', 'Expired'],
    default: 'Inactive',
  },
  currentTurn: {
    type: Number,
    default: 0,
  },
  totalTokens: {
    type: Number,
    default: 0,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Queue', queueSchema);
