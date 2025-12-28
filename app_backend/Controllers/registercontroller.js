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
        id: user._id,
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
    const { id } = req.params;

    // 1️⃣ Check ID
    if (!id) {
      return res.status(400).json({
        error: "User ID is required",
      });
    }

    // 2️⃣ Find & Delete User
    const deletedUser = await User.findByIdAndDelete(id);

    // 3️⃣ User not found
    if (!deletedUser) {
      return res.status(404).json({
        error: "User not found",
      });
    }

    // 4️⃣ Success response
    return res.status(200).json({
      message: "User deleted successfully",
      user: {
        id: deletedUser._id,
        name: deletedUser.name,
        email: deletedUser.email,
        role: deletedUser.role,
      },
    });

  } catch (err) {
    return res.status(500).json({
      error: "Server error",
      details: err.message,
    });
  }
};


module.exports = { addstudent ,deleteStudent};
