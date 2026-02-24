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
    phoneNumber: {
      type: String, 
      unique: true,
      sparse: true, // Allow multiple nulls if not provided initially
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
    missedTokenRetries: {
      type: Number,
      default: 3, // Default to 3 students to wait before recalling
    },
    missedTokenRecallWaitTimeMinutes: {
      type: Number,
      default: 10, // Default to 10 minutes wait before recalling
    },
    notificationThreshold: {
      type: Number,
      default: 2, // Default to 2 students before notifying
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Admin', adminSchema);
