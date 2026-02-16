const mongoose = require('mongoose');

const pendingHistoryTokenSchema = new mongoose.Schema({
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
  queueName: { type: String, required: false },
  department: { type: String, required: false },
  purpose: { type: String, required: false },
  studentsAhead: { type: Number, required: false },
  estimatedWaitingTime: { type: Number, required: false },
  status: {
    type: String,
    // pending includes: pending, waiting, serving (if expired while serving), hold, missed, cancelled
    default: 'pending',
  },
  generatedAt: { type: Date },
  calledAt: { type: Date },
  cancelledAt: { type: Date },
  archivedAt: { type: Date, default: Date.now },
}, { strict: false });

module.exports = mongoose.models.PendingHistoryToken || mongoose.model('PendingHistoryToken', pendingHistoryTokenSchema);
