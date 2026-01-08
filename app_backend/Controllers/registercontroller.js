const User = require('../Models/registermodel');

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
const getStudentById = async (req, res) => {
  try {
    const { studentID } = req.params;

    // 🔴 Validation
    if (!studentID) {
      return res.status(400).json({
        success: false,
        message: "Student ID is required",
      });
    }

    // 🔎 Find student
    const student = await User.findById(studentID).select(
      "-password -confirmPassword"
    );

    if (!student) {
      return res.status(404).json({
        success: false,
        message: "Student not found",
      });
    }

    // ✅ Success response
    return res.status(200).json({
      success: true,
      data: {
        studentID: student._id,
        name: student.name,
        email: student.email,
        role: student.role,
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


module.exports = {
  addstudent,
  deleteStudent,
  changePassword,
  getStudentById
};
