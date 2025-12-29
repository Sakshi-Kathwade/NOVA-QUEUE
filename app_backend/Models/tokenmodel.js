const mongoose = require("mongoose");

const tokenSchema = new mongoose.Schema(
  {
    queueName: {
      type: String,
      required: true,
      trim: true,
    },

    department: {
      type: String,
      default: null,
    },

    purpose: {
      type: String,
      required: true,
      trim: true,
    },

    tokenNumber: {
      type: Number,
      required: true,
    },

    // ✅ Students ahead of current student
    studentsAhead: {
      type: Number,
      default: 0,
    },

    // ✅ Estimated waiting time (in minutes)
    estimatedWaitingTime: {
      type: Number,
      default: 0,
    },

    status: {
      type: String,
      enum: ["waiting", "skipped", "hold", "completed"],
      default: "waiting",
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Token", tokenSchema);
