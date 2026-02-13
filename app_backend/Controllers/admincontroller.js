const Admin = require('../Models/adminmodel.js');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const Service = require('../Models/serviceModel.js');
const Token = require('../Models/tokenmodel.js'); // Import Token model
const Counter = require('../Models/counterModel.js'); // Import Counter model
const Staff = require('../Models/staffModel.js'); // Import Staff model
const Register = require('../Models/registermodel.js'); // Import Register model (acting as Student)
const Queue = require('../Models/create_queue_model.js'); // Import Queue model for active queue details

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
        name: admin.name,
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
      "estimatedServiceTimePerStudent missedTokenRecalls missedTokenRetries missedTokenRecallWaitTimeMinutes"
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
        missedTokenRetries: admin.missedTokenRetries,
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
    const { estimatedServiceTimePerStudent, missedTokenRecalls, missedTokenRetries, missedTokenRecallWaitTimeMinutes } = req.body;

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
    if (missedTokenRetries !== undefined) {
      admin.missedTokenRetries = missedTokenRetries;
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
        missedTokenRetries: admin.missedTokenRetries,
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

    // 1. Get Active Queue Details (For "Joined / Max" display)
    const activeQueue = await Queue.findOne({
      adminId,
      status: 'Active',
      endTime: { $gt: new Date() } // Not expired
    }).sort({ createdAt: -1 });

    let activeQueueMax = 0;
    let activeQueueJoined = 0;

    if (activeQueue) {
      activeQueueMax = activeQueue.maxStudents;
      activeQueueJoined = await Token.countDocuments({
        adminId,
        queueId: activeQueue._id
      });
    }

    // Total tokens generated (all time) - Existing logic
    const totalTokensGenerated = await Token.countDocuments({ adminId });

    // Completed services (today)
    const completedServicesToday = await Token.countDocuments({
      adminId,
      status: { $in: ['completed', 'Completed'] },
      completedAt: { $gte: startOfToday, $lte: endOfToday },
    });

    // Total students visited (unique studentIds across all time)
    const totalStudentsVisited = (await Token.distinct('studentId', { adminId })).length;

    // Waiting students (currently in queue)
    const waitingTokensCount = await Token.countDocuments({
      adminId,
      status: { $in: ['waiting', 'pending', 'Waiting', 'pending', 'hold', 'serving'] } // Added 'serving' and 'hold'
    });

    // Average waiting time (for completed tokens today)
    const completedTokens = await Token.find({
      adminId,
      status: { $in: ['completed', 'Completed'] },
      generatedAt: { $gte: startOfToday, $lte: endOfToday },
      completedAt: { $exists: true },
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
      totalStudentsVisited,
      waitingTokensCount,
      averageWaitingTimeMinutes,
      activeQueueMax,      // New field
      activeQueueJoined    // New field
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
    
    const performance = await Token.aggregate([
      { 
        $match: { 
          adminId: new mongoose.Types.ObjectId(adminId), 
          status: { $in: ['completed', 'Completed'] },
          completedAt: { $exists: true }, // Ensure completion time exists
          generatedAt: { $exists: true }  // Ensure generation time exists
        } 
      },
      {
        $project: {
          counterId: 1,
          waitTime: { $subtract: ["$completedAt", "$generatedAt"] } // Calculate wait time in ms
        }
      },
      { 
        $group: { 
          _id: "$counterId", 
          count: { $sum: 1 }, 
          totalWaitTime: { $sum: "$waitTime" }
        } 
      },
      { 
        $lookup: { 
          from: 'counters', 
          localField: '_id', 
          foreignField: '_id', 
          as: 'counter' 
        } 
      },
      { $unwind: { path: "$counter", preserveNullAndEmptyArrays: true } },
      { 
        $project: { 
          counterName: { $ifNull: ["$counter.counterName", "Unassigned"] }, 
          count: 1,
          avgWaitTimeMinutes: { 
            $cond: [ 
              { $eq: ["$count", 0] }, 
              0, 
              { $round: [ { $divide: [ { $divide: ["$totalWaitTime", "$count"] }, 60000 ] }, 0 ] } // Convert ms to min and round
            ] 
          }
        } 
      }
    ]);

    return res.status(200).json({ success: true, performance });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

const getBusyHours = async (req, res) => {
  try {
    const { adminId } = req.params;
    
    const busyHours = await Token.aggregate([
      { $match: { adminId: new mongoose.Types.ObjectId(adminId) } },
      { $project: { hour: { $hour: "$generatedAt" } } },
      { $group: { _id: "$hour", count: { $sum: 1 } } },
      { $sort: { _id: 1 } }
    ]);

    return res.status(200).json({ success: true, busyHours });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

const getServiceWiseData = async (req, res) => {
  try {
    const { adminId } = req.params;
    
    const serviceData = await Token.aggregate([
      { $match: { adminId: new mongoose.Types.ObjectId(adminId) } },
      { $group: { _id: "$serviceId", count: { $sum: 1 } } },
      { $lookup: { from: 'services', localField: '_id', foreignField: '_id', as: 'service' } },
      { $unwind: { path: "$service", preserveNullAndEmptyArrays: true } },
      { $project: { serviceName: { $ifNull: ["$service.serviceName", "General"] }, count: 1 } }
    ]);

    return res.status(200).json({ success: true, serviceData });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

const getDailyCrowdDetails = async (req, res) => {
  try {
    const { adminId } = req.params;
    const days = parseInt(req.query.days) || 7;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    startDate.setHours(0, 0, 0, 0);

    const dailyCrowd = await Token.aggregate([
      { 
        $match: { 
          adminId: new mongoose.Types.ObjectId(adminId), 
          generatedAt: { $gte: startDate } 
        } 
      },
      { 
        $project: { 
          date: { $dateToString: { format: "%Y-%m-%d", date: "$generatedAt" } },
          status: 1
        } 
      },
      { 
        $group: { 
          _id: "$date", 
          generated: { $sum: 1 },
          served: { 
            $sum: { 
              $cond: [ { $in: ["$status", ["completed", "Completed"]] }, 1, 0 ] 
            } 
          },
          pending: { 
            $sum: { 
              $cond: [ { $in: ["$status", ["pending", "waiting", "waiting", "serving", "hold"]] }, 1, 0 ] 
            } 
          }
        } 
      },
      { $sort: { _id: 1 } }
    ]);

    return res.status(200).json({ success: true, dailyCrowd });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// =================================== HISTORY FUNCTIONS ===================================
// =================================== HISTORY FUNCTIONS ===================================
// =================================== HISTORY FUNCTIONS ===================================
const getQueueHistory = async (req, res) => {
  try {
    const { adminId } = req.params;
    let { startDate, endDate, serviceId, status, counterId, search } = req.query;

    if (!mongoose.Types.ObjectId.isValid(adminId)) {
        return res.status(400).json({ success: false, message: "Invalid Admin ID" });
    }

    // 1. Context Match (For Summary Stats - Total, Served, Pending for the day/service)
    // This ignores the 'status' filter so that the summary cards show the BIG PICTURE.
    let contextMatch = {
      adminId: new mongoose.Types.ObjectId(adminId),
    };

    // Date Filter (Applies to both Summary and List)
    if (startDate || endDate) {
      let dateFilter = {};
      if (startDate) {
        const start = new Date(startDate);
        start.setHours(0, 0, 0, 0);
        if (!isNaN(start.getTime())) dateFilter.$gte = start;
      }
      if (endDate) {
        const end = new Date(endDate);
        end.setHours(23, 59, 59, 999);
         if (!isNaN(end.getTime())) dateFilter.$lte = end;
      }
      if (Object.keys(dateFilter).length > 0) {
          contextMatch.generatedAt = dateFilter;
      }
    }

    // Service Filter (Applies to both)
    if (serviceId && serviceId !== 'All') {
       if (mongoose.Types.ObjectId.isValid(serviceId)) {
           contextMatch.serviceId = new mongoose.Types.ObjectId(serviceId);
       }
    }

    // Counter Filter (Applies to both)
    if (counterId && counterId !== 'All') {
       if (mongoose.Types.ObjectId.isValid(counterId)) {
           contextMatch.counterId = new mongoose.Types.ObjectId(counterId);
       } else {
           // If not a valid ObjectId, assume it's a counterName
           // This will be matched later after lookup if we use pipeline, 
           // but for contextMatch (summary), we might need to lookup first or just use a regex on a joined field.
           // However, for simplicity, if it's "Exam", "Admission", "Fees", we can match by counterName in the pipeline.
       }
    }

    let counterNameFilter = null;
    if (counterId && !mongoose.Types.ObjectId.isValid(counterId) && counterId !== 'All') {
        // If not a valid ObjectId, find the counter by name first for efficiency
        const foundCounter = await mongoose.model('Counter').findOne({ 
            counterName: new RegExp(counterId, 'i'),
            adminId: new mongoose.Types.ObjectId(adminId)
        });
        if (foundCounter) {
            contextMatch.counterId = foundCounter._id;
        } else {
            // If no counter found by that name, force no results by using a fake ID
            contextMatch.counterId = new mongoose.Types.ObjectId();
        }
    }

    // 2. Calculate Summary Stats (Aggregation on Context Match)
    const summaryPipeline = [
        { $match: contextMatch },
        {
            $group: {
                _id: null,
                totalTokens: { $sum: 1 },
                totalServed: { 
                    $sum: { 
                        $cond: [{ $in: [{ $toLower: "$status" }, ["completed"]] }, 1, 0] 
                    } 
                },
                pendingTokens: { 
                    $sum: { 
                        $cond: [{ $in: [{ $toLower: "$status" }, ["pending", "waiting", "hold", "process"]] }, 1, 0] 
                    } 
                },
                uniqueQueues: { $addToSet: "$queueName" },
                totalWaitTimeMs: {
                    $sum: {
                        $cond: [
                            { $and: [
                                { $in: [{ $toLower: "$status" }, ["completed"]] },
                                { $ne: ["$generatedAt", null] },
                                { $ne: ["$completedAt", null] }
                            ]},
                            { $subtract: ["$completedAt", "$generatedAt"] },
                            0
                        ]
                    }
                },
                servedCountForAvg: {
                    $sum: {
                         $cond: [
                            { $and: [
                                { $in: [{ $toLower: "$status" }, ["completed"]] },
                                { $ne: ["$generatedAt", null] },
                                { $ne: ["$completedAt", null] }
                            ]},
                            1,
                            0
                        ]
                    }
                }
            }
        }
    ];

    const summaryResult = await Token.aggregate(summaryPipeline);
    const stats = summaryResult[0] || { 
        totalTokens: 0, 
        totalServed: 0, 
        pendingTokens: 0, 
        uniqueQueues: [], 
        totalWaitTimeMs: 0, 
        servedCountForAvg: 0 
    };

    const averageWaitingTimeMinutes = stats.servedCountForAvg > 0 
      ? Math.round((stats.totalWaitTimeMs / stats.servedCountForAvg) / 60000) 
      : 0;


    // 3. List Match (Applies Specific Status Filter)
    let listMatch = { ...contextMatch };
    
    // Apply Status Filter ONLY to the List
    if (status && status !== 'All') {
      if (status === 'Pending') {
         listMatch.status = { $in: ['pending', 'waiting', 'process', 'hold'] };
      } else if (status === 'Completed') {
         listMatch.status = { $in: ['completed', 'Completed'] };
      } else {
         listMatch.status = status;
      }
    }

    // 4. List Aggregation Pipeline
    const pipeline = [
      { $match: listMatch },
      // Lookup Student
      {
        $lookup: {
          from: 'registers',
          localField: 'studentId',
          foreignField: '_id',
          as: 'student'
        }
      },
      { $unwind: { path: '$student', preserveNullAndEmptyArrays: true } },
      
      // Lookup Service
      {
        $lookup: {
          from: 'services',
          localField: 'serviceId',
          foreignField: '_id',
          as: 'service'
        }
      },
      { $unwind: { path: '$service', preserveNullAndEmptyArrays: true } },

      // Lookup Queue
      {
        $lookup: {
          from: 'queues',
          localField: 'queueId',
          foreignField: '_id',
          as: 'queue'
        }
      },
      { $unwind: { path: '$queue', preserveNullAndEmptyArrays: true } },

      // Lookup Counter
      {
        $lookup: {
          from: 'counters',
          localField: 'counterId',
          foreignField: '_id',
          as: 'counter'
        }
      },
      { $unwind: { path: '$counter', preserveNullAndEmptyArrays: true } },
    ];

    // Search Filter
    if (search) {
      const searchRegex = new RegExp(search, 'i');
      pipeline.push({
        $match: {
          $or: [
            { 'student.name': searchRegex },
            { 'student.email': searchRegex },
            { 'queue.queueName': searchRegex },
            { 'queueName': searchRegex }, // Search by snapshotted name too
            { $expr: { $regexMatch: { input: { $toString: "$tokenNumber" }, regex: search, options: "i" } } }
          ]
        }
      });
    }

    // Sort
    pipeline.push({ $sort: { generatedAt: -1 } });

    // Execute List Query
    const history = await Token.aggregate(pipeline);

    // Post-process for permanent history (Fallback to snapshotted names)
    history.forEach(token => {
       if (!token.queue) token.queue = {};
       if (!token.queue.queueName) token.queue.queueName = token.queueName || "Deleted Queue";
       
       if (!token.service) token.service = {};
       if (!token.service.serviceName) token.service.serviceName = token.serviceName || token.department || "General";
    });

    return res.status(200).json({ 
      success: true, 
      message: "Queue history data fetched successfully", 
      history,
      summary: {
        totalTokens: stats.totalTokens,
        totalServed: stats.totalServed,
        pendingTokens: stats.pendingTokens,
        averageWaitingTimeMinutes,
        totalQueues: stats.uniqueQueues.length
      }
    });

  } catch (error) {
    console.error("History Error:", error);
    return res.status(500).json({
      success: false,
      message: `Server Error: ${error.message}`
    });
  }
};

// ✅ GET HISTORY DATES (for Calendar Highlighting)
const getHistoryDates = async (req, res) => {
  try {
    const { adminId } = req.params;
    
    // Aggregate to find unique dates from generatedAt or completedAt
    const dates = await Token.aggregate([
      { 
        $match: { 
          adminId: new mongoose.Types.ObjectId(adminId) 
        } 
      },
      {
        $project: {
          dateVal: { $ifNull: ["$completedAt", "$generatedAt"] }
        }
      },
      {
         $project: {
             // Format date as YYYY-MM-DD
            day: { $dateToString: { format: "%Y-%m-%d", date: "$dateVal" } }
         }
      },
      {
         $group: {
             _id: "$day"
         }
      },
      { $sort: { _id: -1 } }
    ]);

    // Extract just the date strings
    const dateList = dates.map(d => d._id).filter(d => d != null);

    return res.status(200).json({
      success: true,
      dates: dateList
    });

  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// ✅ DELETE HISTORY TOKEN
const deleteHistoryToken = async (req, res) => {
    try {
        const { tokenId } = req.params;
        const deleted = await Token.findByIdAndDelete(tokenId);
        
        if (!deleted) {
            return res.status(404).json({ success: false, message: "Token not found" });
        }

        return res.status(200).json({ success: true, message: "History record deleted successfully" });
    } catch(error) {
        return res.status(500).json({ success: false, message: error.message });
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
  getServiceWiseData,
  getDailyCrowdDetails,
  getHistoryDates,
  deleteHistoryToken
};