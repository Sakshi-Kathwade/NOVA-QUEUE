const mongoose = require('mongoose');

const counterSchema = new mongoose.Schema({
  counterName: {
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
    enum: ['Active', 'Inactive', 'Break'],
    default: 'Inactive',
  },
  currentServingToken: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Token',
    default: null,
  },
  assignedStaff: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Staff',
    default: null,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.models.Counter || mongoose.model('Counter', counterSchema);
