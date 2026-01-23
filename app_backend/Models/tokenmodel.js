const mongoose = require("mongoose");

const tokenSchema = new mongoose.Schema({
  queueName: { type: String, required: true },
  department: String,
  purpose: { type: String, required: true },

  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Student",
    required: true, // ✅ MUST
  },

  tokenNumber: Number,
  studentsAhead: Number,
  estimatedWaitingTime: Number,
  status: {
    type: String,
    enum: ["waiting", "serving", "completed", "hold", "skipped"],
    default: "waiting",
  },
}, {
  timestamps: true, // ✅ Adds createdAt and updatedAt automatically
});

module.exports = mongoose.model("Token", tokenSchema);
