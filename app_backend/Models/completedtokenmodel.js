const mongoose = require("mongoose");

const completedTokenSchema = new mongoose.Schema({
  tokenId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Token",
    required: true,
  },
  queueName: { type: String, required: true },
  tokenNumber: { type: Number, required: true },
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Student",
    required: true,
  },
  studentName: { type: String, required: true },
  serviceProvided: { type: String, required: true }, // This is the purpose from token
  counterNumber: { type: String, default: "Counter-1" }, // Can be configured
  servedTime: { type: Date, default: Date.now },
  completedBy: { type: String }, // Admin email or ID
}, {
  timestamps: true,
});

module.exports = mongoose.model("CompletedToken", completedTokenSchema);

