const mongoose = require("mongoose");

const QueueSchema = new mongoose.Schema({
  adminId: { type: mongoose.Schema.Types.ObjectId, required: true, index: true },
  queueName: { type: String, required: true },
  department: { type: String, required: true },
  startTime: { type: Date, required: true }, // exact start timestamp
  endTime : { type: Date, required: true }, // exact end timestamp
  maxStudents: { type: Number, required: true },
   status: {
      type: String,
      enum: ["Active", "Inactive", "Paused"],
      default: "Active", },
  lastPausedAt: { type: Date, default: null },
  totalPausedMs: { type: Number, default: 0 }
}, { timestamps: true });

module.exports = mongoose.model("Queue", QueueSchema);
