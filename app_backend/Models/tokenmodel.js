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
    default: "waiting",
  },
});

module.exports = mongoose.model("Token", tokenSchema);
