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
  },
  { timestamps: true }
);

module.exports = mongoose.model('Admin', adminSchema);
