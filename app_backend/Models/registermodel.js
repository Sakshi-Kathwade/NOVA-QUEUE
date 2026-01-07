const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    studentId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Student",
        //  required: true, // ✅ MUST
       
      },
    confirmPassword: { type: String, required: true },
     role: {type: String , required: true },})

// Export the model
module.exports = mongoose.models.Register || mongoose.model('Register', userSchema);
