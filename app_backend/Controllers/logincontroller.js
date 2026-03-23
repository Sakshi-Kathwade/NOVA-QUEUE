const User = require('../Models/registermodel');
const Admin = require('../Models/adminmodel'); // Import Admin model
const notificationService = require('../utils/notificationService');

// LOGIN USER (STUDENT / ADMIN)
const loginStudent = async (req, res) => {
  try {
    const { email, password, fcmToken } = req.body;

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

    // 4️⃣ Update FCM Token if provided and send notification
    if (fcmToken) {
        user.fcmToken = fcmToken;
        await user.save();
        
        if (user.role === 'student') {
             await notificationService.sendNotification(
                fcmToken,
                user._id,
                "Welcome to Smart Queue Management",
                "🔔 Notifications are active. You will receive queue alerts.",
                { type: "login_alert" }
            );
        }
    }

    // 5️⃣ SUCCESS RESPONSE (IMPORTANT)
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

// FORGOT PASSWORD (Get Student ID)
const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ success: false, message: "Email is required" });
    }

    // Check Student
    let user = await User.findOne({ email });
    
    // If not found in User (Student), check Admin (optional, but requested for Student)
    if (!user) {
         // Assuming Admin also has email field if we want to support Admin forgot password
         // But the requirement says "display the studnet ID", so it implies Student focus.
         // Let's stick to User (Student) for now or check Admin too if needed.
         // user = await Admin.findOne({ email });
    }

    if (!user) {
      return res.status(404).json({ success: false, message: "Email not found" });
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Send the OTP via Push Notification if FCM Token exists
    if (user.fcmToken) {
      const notificationService = require('../utils/notificationService');
      await notificationService.sendNotification(
        user.fcmToken,
        user._id,
        "Password Reset OTP 🔐",
        `Your 6-digit OTP for resetting your password is: ${otp}`,
        { type: "otp_alert", otp: otp }
      );
    }

    return res.status(200).json({ 
      success: true, 
      message: "Email verified and OTP sent", 
      studentId: user._id,
      name: user.name,
      otp: otp // Return OTP for frontend validation
    });

  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// RESET PASSWORD (By Email/ID)
const resetPassword = async (req, res) => {
  try {
    const { email, studentId, newPassword, phoneNumber } = req.body;

    if (!newPassword) {
      return res.status(400).json({ success: false, message: "New password is required" });
    }

    let user;
    let role = 'student';

    // Find User
    if (studentId) {
      user = await User.findById(studentId);
    } else if (email) {
      user = await User.findOne({ email });
    } else if (phoneNumber) {
      user = await User.findOne({ phoneNumber });
      if (!user) {
         user = await Admin.findOne({ phoneNumber });
         role = 'admin';
      }
    }

    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    // Update password
    user.password = newPassword;
    if (user.role === 'student' || role === 'student') { // Check role field or inferred role
         // Assuming Register model has confirmPassword field
         if (user.confirmPassword !== undefined) {
             user.confirmPassword = newPassword;
         }
    }
    await user.save();

    return res.status(200).json({ success: true, message: "Password updated successfully" });

  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { loginStudent, resetPassword, forgotPassword };
