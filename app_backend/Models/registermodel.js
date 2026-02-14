const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    phoneNumber: { type: String, unique: true, sparse: true }, // Keep sparse for optional initially
    password: { type: String, required: function() { return !this.isGoogleAuth; } },
    studentId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Student",
        //  required: true, // ✅ MUST
       
      },
    confirmPassword: { type: String, required: function() { return !this.isGoogleAuth; } },
    role: { type: String, required: true },
    profilePicture: { type: String, default: null }, // Added profilePicture field
    fcmToken: { type: String, default: null }, // ✅ Store FCM Device Token
    isGoogleAuth: { type: Boolean, default: false }, // Track Google OAuth users
})

// Export the model
module.exports = mongoose.models.Register || mongoose.model('Register', userSchema);
