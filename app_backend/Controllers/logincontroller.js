const User = require('../Models/registermodel');
const Admin = require('../Models/adminmodel'); // Import Admin model

// LOGIN USER (STUDENT / ADMIN)
const loginStudent = async (req, res) => {
  try {
    const { email, password } = req.body;

    // 1️⃣ Validation
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email and password are required",
      });
    }

    // 2️⃣ Find user by email
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Invalid email",
      });
    }

    // 3️⃣ Password check
    if (user.password !== password) {
      return res.status(401).json({
        success: false,
        message: "Invalid password",
      });
    }

    // 4️⃣ SUCCESS RESPONSE (IMPORTANT)
    return res.status(200).json({
      success: true,
      message: "Login successful",
      role: user.role,          // ✅ admin / student
      userId: user._id,         // optional
      email: user.email,        // optional
    });

  } catch (err) {
    return res.status(500).json({
      success: false,
      error: err.message,
    });
  }
};

// RESET PASSWORD
const resetPassword = async (req, res) => {
  try {
    const { phoneNumber, newPassword } = req.body;

    if (!phoneNumber || !newPassword) {
      return res.status(400).json({ success: false, message: "Phone number and new password required" });
    }

    // Check Student
    let user = await User.findOne({ phoneNumber });
    let role = 'student';

    if (!user) {
      // Check Admin
      user = await Admin.findOne({ phoneNumber });
      role = 'admin';
    }

    if (!user) {
      return res.status(404).json({ success: false, message: "User with this phone number not found" });
    }

    // Update password
    user.password = newPassword;
    if (role === 'student' && user.confirmPassword !== undefined) {
        user.confirmPassword = newPassword; 
    }
    await user.save();

    return res.status(200).json({ success: true, message: "Password reset successfully" });

  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { loginStudent, resetPassword };
