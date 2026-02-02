const Admin = require('../Models/adminmodel.js');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const Service = require('../Models/serviceModel.js');
const Queue = require('../Models/queueModel.js'); // Import Queue model
const Token = require('../Models/tokenModel.js'); // Import Token model
const Counter = require('../Models/counterModel.js'); // Import Counter model
const Staff = require('../Models/staffModel.js'); // Import Staff model
const Register = require('../Models/registermodel.js'); // Import Register model (acting as Student)

const adminLogin = async (req, res) => {
  try {
    const { email, password } = req.body;

    // 1️⃣ Validation
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email and password are required",
      });
    }

    // 2️⃣ Find admin by email
    const admin = await Admin.findOne({ email });

    if (!admin) {
      return res.status(404).json({
        success: false,
        message: "Admin not found",
      });
    }

    // 3️⃣ Password check (plain text for now)
    if (admin.password !== password) {
      return res.status(401).json({
        success: false,
        message: "Invalid password",
      });
    }

    // 4️⃣ Success
    return res.status(200).json({
      success: true,
      message: "Admin login successful",
      role: "admin",
      adminId: admin._id,
      email: admin.email,
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

const createAdmin = async (req, res) => {
  try {
    const { email, password } = req.body;

    // 1️⃣ Validate required fields
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email and password are required",
      });
    }

    // 2️⃣ Password strength check
    const strongPassword =
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;

    if (!strongPassword.test(password)) {
      return res.status(400).json({
        success: false,
        message:
          "Password must be at least 8 characters and include uppercase, lowercase, number, and special character",
      });
    }

    // 3️⃣ Check existing admin
    const existingAdmin = await Admin.findOne({ email });
    if (existingAdmin) {
      return res.status(409).json({
        success: false,
        message: "Admin with this email already exists",
      });
    }

    // 4️⃣ Create admin (role auto set to admin)
    const newAdmin = await Admin.create({
      email,
      password,
      role: "admin", // ✅ explicit role
    });

    // 5️⃣ Success response
    return res.status(201).json({
      success: true,
      message: "Admin created successfully",
      admin: {
        adminId: newAdmin._id,
        email: newAdmin.email,
        role: newAdmin.role, // ✅ send role to frontend
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// 🔐 CHANGE ADMIN PASSWORD
const changeAdminPassword = async (req, res) => {
  try {
    const { adminId } = req.params;
    const { currentPassword, password, confirmPassword } = req.body;

    // 1️⃣ Validation
    if (!adminId || !currentPassword || !password || !confirmPassword) {
      return res.status(400).json({
        success: false,
        message: "All fields are required",
      });
    }

    // 2️⃣ Find admin by ID
    const admin = await Admin.findById(adminId);
    if (!admin) {
      return res.status(404).json({
        success: false,
        message: "Admin not found",
      });
    }

    // 3️⃣ Check current password
    if (admin.password !== currentPassword) {
      return res.status(400).json({
        success: false,
        message: "Current password is incorrect",
      });
    }

    // 4️⃣ New password match check
    if (password !== confirmPassword) {
      return res.status(400).json({
        success: false,
        message: "New password and confirm password do not match",
      });
    }

    // 5️⃣ Strong password validation
    const strongPasswordRegex =
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;

    if (!strongPasswordRegex.test(password)) {
      return res.status(400).json({
        success: false,
        message:
          "Password must be at least 8 characters and include uppercase, lowercase, number, and special character",
      });
    }

    // 6️⃣ Update password
    admin.password = password;
    await admin.save();

    // 7️⃣ Success response
    return res.status(200).json({
      success: true,
      message: "Password changed successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ✅ GET ADMIN PROFILE (email, role, profilePicture)
const getAdminProfile = async (req, res) => {
  try {
    const { adminId } = req.params;

    if (!adminId) {
      return res.status(400).json({
        success: false,
        message: "Admin ID is required",
      });
    }

    const admin = await Admin.findById(adminId).select("-password");

    if (!admin) {
      return res.status(404).json({
        success: false,
        message: "Admin not found",
      });
    }

    return res.status(200).json({
      success: true,
      admin: {
        adminId: admin._id,
        email: admin.email,
        role: admin.role || "Admin",
        profilePicture: admin.profilePicture,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Multer config for admin profile picture
const adminProfileStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadPath = path.join(__dirname, '../uploads/admin_profiles');
    fs.mkdirSync(uploadPath, { recursive: true });
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    cb(null, `${req.params.adminId}_${Date.now()}${path.extname(file.originalname)}`);
  },
});
const uploadAdminProfile = multer({ storage: adminProfileStorage }).single('profilePicture');

// ✅ UPDATE ADMIN PROFILE (with optional profile picture upload)
const updateAdminProfile = async (req, res) => {
  try {
    const { adminId } = req.params;
    const { email, name } = req.body || {};

    if (!adminId) {
      return res.status(400).json({
        success: false,
        message: "Admin ID is required",
      });
    }

    const admin = await Admin.findById(adminId);
    if (!admin) {
      return res.status(404).json({
        success: false,
        message: "Admin not found",
      });
    }

    if (email) admin.email = email;

    if (req.file) {
      admin.profilePicture = `/uploads/admin_profiles/${req.file.filename}`;
    }

    await admin.save();

    return res.status(200).json({
      success: true,
      message: "Profile updated successfully",
      admin: {
        adminId: admin._id,
        email: admin.email,
        role: admin.role || "Admin",
        profilePicture: admin.profilePicture,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ✅ GET ADMIN QUEUE SETTINGS
const getAdminQueueSettings = async (req, res) => {
  try {
    const { adminId } = req.params;

    if (!adminId) {
      return res.status(400).json({
        success: false,
        message: "Admin ID is required",
      });
    }

    const admin = await Admin.findById(adminId).select(
      "estimatedServiceTimePerStudent missedTokenRecalls missedTokenRecallWaitTimeMinutes"
    );

    if (!admin) {
      return res.status(404).json({
        success: false,
        message: "Admin not found",
      });
    }

    return res.status(200).json({
      success: true,
      settings: {
        estimatedServiceTimePerStudent: admin.estimatedServiceTimePerStudent,
        missedTokenRecalls: admin.missedTokenRecalls,
        missedTokenRecallWaitTimeMinutes: admin.missedTokenRecallWaitTimeMinutes,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ✅ UPDATE ADMIN QUEUE SETTINGS
const updateAdminQueueSettings = async (req, res) => {
  try {
    const { adminId } = req.params;
    const { estimatedServiceTimePerStudent, missedTokenRecalls, missedTokenRecallWaitTimeMinutes } = req.body;

    if (!adminId) {
      return res.status(400).json({
        success: false,
        message: "Admin ID is required",
      });
    }

    const admin = await Admin.findById(adminId);
    if (!admin) {
      return res.status(404).json({
        success: false,
        message: "Admin not found",
      });
    }

    if (estimatedServiceTimePerStudent !== undefined) {
      admin.estimatedServiceTimePerStudent = estimatedServiceTimePerStudent;
    }
    if (missedTokenRecalls !== undefined) {
      admin.missedTokenRecalls = missedTokenRecalls;
    }
    if (missedTokenRecallWaitTimeMinutes !== undefined) {
      admin.missedTokenRecallWaitTimeMinutes = missedTokenRecallWaitTimeMinutes;
    }

    await admin.save();

    return res.status(200).json({
      success: true,
      message: "Queue settings updated successfully",
      settings: {
        estimatedServiceTimePerStudent: admin.estimatedServiceTimePerStudent,
        missedTokenRecalls: admin.missedTokenRecalls,
        missedTokenRecallWaitTimeMinutes: admin.missedTokenRecallWaitTimeMinutes,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ✅ DELETE ADMIN ACCOUNT
const deleteAdmin = async (req, res) => {
  try {
    const { adminId } = req.params;

    // 1️⃣ Validation
    if (!adminId) {
      return res.status(400).json({
        success: false,
        message: "Admin ID is required",
      });
    }

    // 2️⃣ Find and delete admin by ID
    const deletedAdmin = await Admin.findByIdAndDelete(adminId);

    if (!deletedAdmin) {
      return res.status(404).json({
        success: false,
        message: "Admin not found",
      });
    }

    // 3️⃣ Success response
    return res.status(200).json({
      success: true,
      message: "Admin account deleted successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// =================================== REPORTS FUNCTIONS ===================================
const getReportsSummary = async (req, res) => {
  try {
    const { adminId } = req.params;

    // Get today's date for filtering
    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);
    const endOfToday = new Date();
    endOfToday.setHours(23, 59, 59, 999);

    // Total tokens generated (all time)
    const totalTokensGenerated = await Token.countDocuments({ adminId });

    // Completed services (today)
    const completedServicesToday = await Token.countDocuments({
      adminId,
      status: 'Completed',
      completedAt: { $gte: startOfToday, $lte: endOfToday },
    });

    // Average waiting time (for completed tokens today)
    const completedTokens = await Token.find({
      adminId,
      status: 'Completed',
      generatedAt: { $gte: startOfToday, $lte: endOfToday },
      completedAt: { $exists: true }, // Ensure completedAt is set
    }).select('generatedAt completedAt');

    let totalWaitingTime = 0;
    completedTokens.forEach(token => {
      if (token.generatedAt && token.completedAt) {
        totalWaitingTime += (token.completedAt.getTime() - token.generatedAt.getTime());
      }
    });

    const averageWaitingTimeMs = completedTokens.length > 0 ? totalWaitingTime / completedTokens.length : 0;
    const averageWaitingTimeMinutes = Math.round(averageWaitingTimeMs / (1000 * 60));

    return res.status(200).json({
      success: true,
      message: "Reports summary data fetched successfully",
      totalTokensGenerated,
      completedServicesToday,
      averageWaitingTimeMinutes,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

const getCounterPerformance = async (req, res) => {
  try {
    const { adminId } = req.params;
    // TODO: Implement logic to fetch counter-wise performance
    return res.status(200).json({ success: true, message: "Counter performance data (TODO)", adminId });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

const getBusyHours = async (req, res) => {
  try {
    const { adminId } = req.params;
    // TODO: Implement logic to fetch busy hours data
    return res.status(200).json({ success: true, message: "Busy hours data (TODO)", adminId });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// =================================== HISTORY FUNCTIONS ===================================
const getQueueHistory = async (req, res) => {
  try {
    const { adminId } = req.params;
    const { date } = req.query; // Optional date filter

    let filter = { adminId, status: { $in: ['Completed', 'Cancelled'] } };

    if (date) {
      const selectedDate = new Date(date);
      const startOfDay = new Date(selectedDate);
      startOfDay.setHours(0, 0, 0, 0);
      const endOfDay = new Date(selectedDate);
      endOfDay.setHours(23, 59, 59, 999);
      filter.$or = [
        { completedAt: { $gte: startOfDay, $lte: endOfDay } },
        { cancelledAt: { $gte: startOfDay, $lte: endOfDay } },
      ];
    }

    const history = await Token.find(filter)
      .populate('serviceId', 'serviceName') // Populate service details
      .populate('queueId', 'queueName') // Populate queue details
      .populate('counterId', 'counterName') // Populate counter details
      .populate('staffId', 'name email') // Populate staff details
      .populate('studentId', 'name email') // Populate student (Register) details
      .sort({ generatedAt: -1 });

    return res.status(200).json({ success: true, message: "Queue history data fetched successfully", history });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// =================================== SETTINGS - SERVICES FUNCTIONS ===================================
const getServices = async (req, res) => {
  try {
    const { adminId } = req.params;
    const services = await Service.find({ adminId });
    return res.status(200).json({ success: true, services });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

const createService = async (req, res) => {
  try {
    const { adminId } = req.params;
    const { serviceName, description } = req.body;

    if (!serviceName) {
      return res.status(400).json({
        success: false,
        message: "Service name is required",
      });
    }

    const newService = await Service.create({ adminId, serviceName, description });
    return res.status(201).json({ success: true, message: "Service created successfully", service: newService });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

const updateService = async (req, res) => {
  try {
    const { serviceId, adminId } = req.params;
    const { serviceName, description } = req.body;

    const updatedService = await Service.findOneAndUpdate(
      { _id: serviceId, adminId: adminId },
      { serviceName, description },
      { new: true }
    );

    if (!updatedService) {
      return res.status(404).json({
        success: false,
        message: "Service not found or not authorized to update",
      });
    }
    return res.status(200).json({ success: true, message: "Service updated successfully", service: updatedService });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

const deleteService = async (req, res) => {
  try {
    const { serviceId, adminId } = req.params;

    const deletedService = await Service.findOneAndDelete({ _id: serviceId, adminId: adminId });

    if (!deletedService) {
      return res.status(404).json({
        success: false,
        message: "Service not found or not authorized to delete",
      });
    }
    return res.status(200).json({ success: true, message: "Service deleted successfully" });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// =================================== SETTINGS - COUNTER FUNCTIONS ===================================
const getCounters = async (req, res) => {
  try {
    const { adminId } = req.params;
    const counters = await Counter.find({ adminId }).populate('assignedStaff', 'name email');
    return res.status(200).json({ success: true, counters });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

const createCounter = async (req, res) => {
  try {
    const { adminId } = req.params;
    const { counterName } = req.body;

    if (!counterName) {
      return res.status(400).json({
        success: false,
        message: "Counter name is required",
      });
    }

    const newCounter = await Counter.create({ adminId, counterName });
    return res.status(201).json({ success: true, message: "Counter created successfully", counter: newCounter });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

const updateCounter = async (req, res) => {
  try {
    const { counterId, adminId } = req.params;
    const { counterName, status, assignedStaff } = req.body;

    const updatedCounter = await Counter.findOneAndUpdate(
      { _id: counterId, adminId: adminId },
      { counterName, status, assignedStaff },
      { new: true }
    ).populate('assignedStaff', 'name email');

    if (!updatedCounter) {
      return res.status(404).json({
        success: false,
        message: "Counter not found or not authorized to update",
      });
    }
    return res.status(200).json({ success: true, message: "Counter updated successfully", counter: updatedCounter });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

const deleteCounter = async (req, res) => {
  try {
    const { counterId, adminId } = req.params;

    const deletedCounter = await Counter.findOneAndDelete({ _id: counterId, adminId: adminId });

    if (!deletedCounter) {
      return res.status(404).json({
        success: false,
        message: "Counter not found or not authorized to delete",
      });
    }
    return res.status(200).json({ success: true, message: "Counter deleted successfully" });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

module.exports = {
  adminLogin,
  createAdmin,
  changeAdminPassword,
  deleteAdmin,
  getAdminProfile,
  updateAdminProfile,
  uploadAdminProfile,
  getAdminQueueSettings,
  updateAdminQueueSettings,
  getReportsSummary,
  getCounterPerformance,
  getBusyHours,
  getQueueHistory,
  getServices,
  createService,
  updateService,
  deleteService,
  getCounters,
  createCounter,
  updateCounter,
  deleteCounter,
};