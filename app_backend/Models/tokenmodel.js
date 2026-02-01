const mongoose = require('mongoose');

const tokenSchema = new mongoose.Schema({
  queueId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Queue',
    required: true,
  },
  adminId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
    required: true,
  },
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Register', // Reference to the Register model (acting as Student)
    required: true,
  },
  tokenNumber: {
    type: Number,
    required: true,
  },
  serviceId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Service', // Reference to the Service model
    required: true,
  },
  counterId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Counter', // Assuming a Counter model exists
    required: false, // Counter might be assigned later
  },
  status: {
    type: String,
    enum: ['Waiting', 'Calling', 'Completed', 'Cancelled'],
    default: 'Waiting',
  },
  generatedAt: {
    type: Date,
    default: Date.now,
  },
  calledAt: {
    type: Date,
  },
  completedAt: {
    type: Date,
  },
  cancelledAt: {
    type: Date,
  },
});

module.exports = mongoose.models.Token || mongoose.model('Token', tokenSchema);
