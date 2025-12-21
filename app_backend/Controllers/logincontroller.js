const User = require('../Models/registermodel'); // ✅ SAME MODEL AS REGISTER

// LOGIN USER
const loginStudent = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({
        message: "Email and password are required",
      });
    }

    // Find registered user
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({
        message: "Invalid email ",
      });
    }

    // Match password
    if (user.password !== password) {
      return res.status(401).json({
        message: "Invalid  password",
      });
    }

    // SUCCESS
    return res.status(200).json({
      message: "Login successful",
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};

module.exports = { loginStudent };
