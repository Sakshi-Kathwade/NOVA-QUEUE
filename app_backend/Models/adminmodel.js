const mongoose = require('mongoose');

const adminSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: true,
      unique: true,
    },
    password: {
      type: String,
      required: true,
    },
    role: {
      type: String,
      default: "admin", // ✅ added role
    },
    profilePicture: {
      type: String,
      default: null, // Default to null, can be a URL or file path
    },
    estimatedServiceTimePerStudent: {
      type: Number,
      default: 5, // Default to 5 minutes per student
    },
    missedTokenRecalls: {
      type: Number,
      default: 2, // Default to 2 retries for missed tokens
    },
    missedTokenRecallWaitTimeMinutes: {
      type: Number,
      default: 10, // Default to 10 minutes wait before recalling
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Admin', adminSchema);
