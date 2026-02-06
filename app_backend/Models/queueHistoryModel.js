const mongoose = require("mongoose");

const QueueHistorySchema = new mongoose.Schema({
  adminId: { type: mongoose.Schema.Types.ObjectId, required: true },
  queueName: { type: String, required: true },
  department: { type: String, required: true },
  startTime: { type: Date, required: true },
  endTime : { type: Date, required: true },
  maxStudents: { type: Number, required: true },
  status: { type: String, default: "Expired" },
  discardedAt: { type: Date, default: Date.now }
}, { timestamps: true });

module.exports = mongoose.model("QueueHistory", QueueHistorySchema);
