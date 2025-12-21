const User = require('../Models/registermodel');

// Add new student
const addstudent = async (req, res) => {
  try {
    const { name, email, password, confirmPassword, role } = req.body;

    // ✅ GOOGLE LOGIN CASE
    if (password === "google_login") {
      const existingUser = await User.findOne({ email });

      if (existingUser) {
        return res.status(200).json({ message: "Google login success", user: existingUser });
      }

      // If Google user not exists → create new user
      const user = new User({
        name,
        email,
        password: "google_login",
        confirmPassword: "google_login",
        role
      });

      await user.save();
      return res.status(201).json({ message: "Google signup success", user });
    }

    // ✅ NORMAL REGISTRATION
    if (!name || !email || !password || !confirmPassword) {
      return res.status(400).json({ message: "All fields are required" });
    }

    if (password !== confirmPassword) {
      return res.status(400).json({ message: "Passwords do not match" });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: "Email already registered" });
    }

    const user = new User({ name, email, password, confirmPassword, role });
    await user.save();

    res.status(201).json({ message: "Student added successfully", student: user });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

module.exports = { addstudent };
