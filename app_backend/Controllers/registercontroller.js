const User = require('../Models/registermodel');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Configure Multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadPath = path.join(__dirname, '../uploads/student_profiles');
    fs.mkdirSync(uploadPath, { recursive: true }); // Ensure directory exists
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    cb(null, `${req.params.studentID}_${Date.now()}${path.extname(file.originalname)}`);
  },
});

const upload = multer({ storage }).single('profilePicture');

// REGISTER USER
const addstudent = async (req, res) => {
  try {
    const { name, email, password, confirmPassword, role } = req.body;

    // 1️⃣ Check empty fields
    if (!name || !email || !password || !confirmPassword || !role) {
      return res.status(400).json({
        error: "All fields are required",
      });
    }

    // 2️⃣ Password match check
    if (password !== confirmPassword) {
      return res.status(400).json({
        error: "Passwords do not match",
      });
    }

    // 3️⃣ Strong password validation
    const strongPasswordRegex =
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;

    if (!strongPasswordRegex.test(password)) {
      return res.status(400).json({
        error:
          "Create a strong password. It must contain at least 8 characters, including uppercase, lowercase, number, and special symbol.",
      });
    }

    // 4️⃣ Check existing user
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({
        error: "Email already registered",
      });
    }

    // 5️⃣ Save user
    const user = new User({
      name,
      email,
      password,
      confirmPassword, // (later hash it)
      role,
      profilePicture: req.file ? `/uploads/student_profiles/${req.file.filename}` : null,
    });

    await user.save();

    // 6️⃣ Success response
    return res.status(201).json({
      message: "Registration successful",
      user: {
           studentID: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    });

  } catch (err) {
    return res.status(500).json({
      error: "Server error",
      details: err.message,
    });
  }
};

const deleteStudent = async (req, res) => {
  try {
    const { studentID } = req.params;

    // 🔴 Validation
    if (!studentID) {
      return res.status(400).json({
        success: false,
        message: "Student ID is required",
      });
    }

    // ✅ Delete student by MongoDB _id
    const deletedStudent = await User.findByIdAndDelete(studentID);

    if (!deletedStudent) {
      return res.status(404).json({
        success: false,
        message: "Student not found",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Student deleted successfully",
      data: {
        studentID: deletedStudent._id,
        name: deletedStudent.name,
      },
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};

// 🔐 CHANGE PASSWORD API
const changePassword = async (req, res) => {
  try {
    const { studentID } = req.params;
    const { currentPassword, password, confirmPassword } = req.body;

    // 🔴 Validation
    if (!studentID || !currentPassword || !password || !confirmPassword) {
      return res.status(400).json({
        success: false,
        message: "All fields are required",
      });
    }

    // 🔎 Find student by ID
    const student = await User.findById(studentID);
    if (!student) {
      return res.status(404).json({
        success: false,
        message: "Student not found",
      });
    }

    // 🔐 Check current password
    if (student.password !== currentPassword) {
      return res.status(400).json({
        success: false,
        message: "Current password is incorrect",
      });
    }

    // 🔁 New password match check
    if (password !== confirmPassword) {
      return res.status(400).json({
        success: false,
        message: "New password and confirm password do not match",
      });
    }

    // 💪 Strong password validation
    const strongPasswordRegex =
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;

    if (!strongPasswordRegex.test(password)) {
      return res.status(400).json({
        success: false,
        message:
          "Password must be at least 8 characters and include uppercase, lowercase, number, and special character",
      });
    }

    // ✅ Update password
    student.password = password;
    student.confirmPassword = password;
    await student.save();

    // 🎉 Success
    return res.status(200).json({
      success: true,
      message: "Password changed successfully",
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

// 📥 GET STUDENT DETAILS BY ID
const getStudentProfile = async (req, res) => {
  try {
    const { studentID } = req.params;

    if (!studentID) {
      return res.status(400).json({
        success: false,
        message: "Student ID is required",
      });
    }

    console.log("getStudentProfile called for ID:", studentID);
    const student = await User.findById(studentID).select(
      "-password -confirmPassword"
    );
    console.log("getStudentProfile found student:", student ? student._id : "null");
    if (student) console.log("getStudentProfile pic:", student.profilePicture);

    if (!student) {
      return res.status(404).json({
        success: false,
        message: "Student not found",
      });
    }

    return res.status(200).json({
      success: true,
      student: {
        studentID: student._id,
        name: student.name,
        email: student.email,
        role: student.role,
        profilePicture: student.profilePicture, // Include profile picture
      },
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

// 🔄 UPDATE STUDENT PROFILE
const updateStudentProfile = async (req, res) => {
  try {
    const { studentID } = req.params;
    const { name, email } = req.body; // Password changes handled by changePassword

    if (!studentID) {
      return res.status(400).json({ success: false, message: "Student ID is required" });
    }

    console.log("updateStudentProfile called for:", studentID);
    console.log("Req Body:", req.body);
    console.log("Req File:", req.file);

    const student = await User.findById(studentID);
    if (!student) {
      return res.status(404).json({ success: false, message: "Student not found" });
    }

    student.name = name || student.name;
    // Student email is typically not editable, but if it were, add validation
    // student.email = email || student.email;

    if (req.file) {
      const newPath = `/uploads/student_profiles/${req.file.filename}`;
      console.log("Setting new profile picture path:", newPath);
      student.profilePicture = newPath;
    }

    const savedStudent = await student.save();
    console.log("Saved Student Profile Pic:", savedStudent.profilePicture);

    return res.status(200).json({
      success: true,
      message: "Student profile updated successfully",
      student: {
        studentID: student._id,
        name: student.name,
        email: student.email,
        role: student.role,
        profilePicture: student.profilePicture,
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: "Server error", error: error.message });
  }
};

// 🖼️ UPLOAD STUDENT PROFILE PICTURE
const uploadStudentProfilePicture = async (req, res) => {
  try {
    const { studentID } = req.params;

    if (!req.file) {
      return res.status(400).json({ success: false, message: "No file uploaded" });
    }

    const student = await User.findById(studentID);
    if (!student) {
      return res.status(404).json({ success: false, message: "Student not found" });
    }

    // Update profile picture URL
    student.profilePicture = `/uploads/student_profiles/${req.file.filename}`;
    await student.save();

    return res.status(200).json({
      success: true,
      message: "Profile picture uploaded successfully",
      profilePicture: student.profilePicture,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: "Server error", error: error.message });
  }
};

// 🔐 GOOGLE OAUTH REGISTRATION
const registerWithGoogle = async (req, res) => {
  try {
    const { name, email, role } = req.body;

    // 1️⃣ Check required fields
    if (!name || !email || !role) {
      return res.status(400).json({
        error: "Name, email, and role are required",
      });
    }

    // 2️⃣ Check existing user
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      // If user exists, return success (they can login)
      return res.status(200).json({
        message: "User already exists. Please login.",
        user: {
          studentID: existingUser._id,
          name: existingUser.name,
          email: existingUser.email,
          role: existingUser.role,
        },
        alreadyExists: true,
      });
    }

    // 3️⃣ Create new user with Google OAuth
    const user = new User({
      name,
      email,
      password: "GOOGLE_OAUTH_USER", // Placeholder for Google OAuth users
      confirmPassword: "GOOGLE_OAUTH_USER", // Placeholder for Google OAuth users
      role: role.toLowerCase(),
      isGoogleAuth: true,
    });

    await user.save();

    // 4️⃣ Success response
    return res.status(201).json({
      message: "Registration successful with Google",
      user: {
        studentID: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
      alreadyExists: false,
    });

  } catch (err) {
    // Handle duplicate email error
    if (err.code === 11000) {
      return res.status(400).json({
        error: "Email already registered",
      });
    }
    
    return res.status(500).json({
      error: "Server error",
      details: err.message,
    });
  }
};

module.exports = {
  addstudent,
  deleteStudent,
  changePassword,
  getStudentProfile,
  updateStudentProfile,
  uploadStudentProfilePicture,
  registerWithGoogle
};
