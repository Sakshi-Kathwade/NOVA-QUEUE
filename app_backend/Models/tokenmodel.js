const mongoose = require('mongoose');

const tokenSchema = new mongoose.Schema({
  queueId: { type: mongoose.Schema.Types.ObjectId, ref: 'Queue', required: false },
  adminId: { type: mongoose.Schema.Types.ObjectId, ref: 'Admin', required: false },
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Register',
    required: true,
  },
  tokenNumber: { type: Number, required: true },
  serviceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Service', required: false },
  serviceName: { type: String, required: false }, // Snapshot for permanent history
  counterId: { type: mongoose.Schema.Types.ObjectId, ref: 'Counter', required: false },
  queueName: { type: String, required: false },
  department: { type: String, required: false },
  purpose: { type: String, required: false },
  studentsAhead: { type: Number, required: false },
  estimatedWaitingTime: { type: Number, required: false },
  status: {
    type: String,
    enum: ['pending', 'waiting', 'serving', 'hold', 'completed', 'cancelled', 'recalled', 'Waiting', 'Calling', 'Completed', 'Cancelled', 'missed'],
    default: 'pending',
  },
  isMissed: { type: Boolean, default: false },
  isRetried: { type: Boolean, default: false },
  waitStudentsLeft: { type: Number, default: 0 },
  generatedAt: { type: Date, default: Date.now },
  calledAt: { type: Date },
  completedAt: { type: Date },
  cancelledAt: { type: Date },
  recallAttempts: { type: Number, default: 0 },
  lastCalledAt: { type: Date },
  recalledAt: { type: Date },
  originalTokenNumberForRecall: { type: Number }, // To track original position for recall logic
}, { strict: false });

module.exports = mongoose.models.Token || mongoose.model('Token', tokenSchema);
