const mongoose = require('mongoose');

const completedHistoryTokenSchema = new mongoose.Schema({
  originalTokenId: { type: mongoose.Schema.Types.ObjectId, required: false },
  queueId: { type: mongoose.Schema.Types.ObjectId, ref: 'Queue', required: false },
  adminId: { type: mongoose.Schema.Types.ObjectId, ref: 'Admin', required: false },
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Register',
    required: true,
  },
  tokenNumber: { type: Number, required: true },
  serviceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Service', required: false },
  serviceName: { type: String, required: false },
  counterId: { type: mongoose.Schema.Types.ObjectId, ref: 'Counter', required: false },
  counterName: { type: String, required: false },
  queueName: { type: String, required: false },
  department: { type: String, required: false },
  purpose: { type: String, required: false },
  studentsAhead: { type: Number, required: false },
  estimatedWaitingTime: { type: Number, required: false },
  status: {
    type: String,
    enum: ['completed', 'Completed'],
    default: 'completed',
  },
  generatedAt: { type: Date },
  calledAt: { type: Date },
  completedAt: { type: Date },
  archivedAt: { type: Date, default: Date.now },
}, { strict: false });

module.exports = mongoose.models.CompletedHistoryToken || mongoose.model('CompletedHistoryToken', completedHistoryTokenSchema);
