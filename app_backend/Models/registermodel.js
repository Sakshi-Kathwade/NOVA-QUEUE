const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    confirmPassword: { type: String, required: true },
     role: {
    type: String,
    enum: ['staff', 'student'],
    default: '',
  },
}, { timestamps: true });

// Export the model
module.exports = mongoose.models.Register || mongoose.model('Register', userSchema);
