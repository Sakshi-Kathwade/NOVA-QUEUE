const mongoose = require('mongoose');
const Admin = require('../Models/adminmodel.js');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const Token = require('../Models/tokenmodel.js'); // Import Token model
const Register = require('../Models/registermodel.js'); // Import Register model (acting as Student)
const Queue = require('../Models/create_queue_model.js'); // Import Queue model for active queue details
const CompletedHistoryToken = require('../Models/completedHistoryTokenModel.js');
const PendingHistoryToken = require('../Models/pendingHistoryTokenModel.js');
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
    let { startDate, endDate, serviceId, status, counterId, search, filterType } = req.query;

    if (!mongoose.Types.ObjectId.isValid(adminId)) {
        return res.status(400).json({ success: false, message: "Invalid Admin ID" });
    }

    // 🔴 AUTO-ARCHIVE EXPIRED QUEUES
    // Before fetching history, ensure any expired queues are moved to history
    const now = new Date();
    const expiredQueues = await Queue.find({
        adminId: adminId,
        status: 'Active',
        endTime: { $lte: now }
    });

    if (expiredQueues.length > 0) {
        for (const queue of expiredQueues) {
             // 1. Copy Queue to QueueHistory
            await require('../Models/queueHistoryModel').create({
                adminId: queue.adminId,
                queueName: queue.queueName,
                department: queue.department,
                startTime: queue.startTime,
                endTime: queue.endTime,
                maxStudents: queue.maxStudents,
                status: "Expired",
                discardedAt: now
            });

            // 2. Archive Tokens
            const allTokens = await Token.find({ queueName: queue.queueName });
            const completedTokens = [];
            const pendingTokens = [];

            for (const token of allTokens) {
                const tokenData = token.toObject();
                tokenData.originalTokenId = token._id;
                delete tokenData._id; 
                tokenData.archivedAt = new Date();

                if (['completed', 'Completed'].includes(token.status)) {
                    completedTokens.push(tokenData);
                } else {
                    pendingTokens.push(tokenData);
                }
            }

            if (completedTokens.length > 0) await CompletedHistoryToken.insertMany(completedTokens);
            if (pendingTokens.length > 0) await PendingHistoryToken.insertMany(pendingTokens);

            // 3. Delete Active Data
            await Queue.findByIdAndDelete(queue._id);
            await Token.deleteMany({ queueName: queue.queueName });
        }
    }



    const matchStage = {
        adminId: new mongoose.Types.ObjectId(adminId)
    };

    // calculate EndDate based on filterType if provided
    if (startDate && filterType) {
        const start = new Date(startDate);
        if (!isNaN(start)) {
            if (filterType === 'weekly') {
                const end = new Date(start);
                end.setDate(start.getDate() + 6);
                endDate = end.toISOString().split('T')[0];
            } else if (filterType === 'monthly') {
                start.setDate(1); 
                startDate = start.toISOString().split('T')[0];
                const end = new Date(start);
                end.setMonth(start.getMonth() + 1);
                end.setDate(0); 
                endDate = end.toISOString().split('T')[0];
            } else if (filterType === 'yearly') {
                start.setMonth(0, 1); // Jan 1st
                startDate = start.toISOString().split('T')[0];
                const end = new Date(start);
                end.setFullYear(start.getFullYear(), 11, 31);
                endDate = end.toISOString().split('T')[0];
            }
        }
    }

    // Date Filter (generatedAt)
    if (startDate || endDate) {
        let dateFilter = {};
        if (startDate) {
            const start = new Date(startDate);
            if (!isNaN(start)) dateFilter.$gte = start;
        }
        if (endDate) {
            const end = new Date(endDate);
            const e = new Date(endDate);
            if (!isNaN(e)) {
                 e.setHours(23, 59, 59, 999);
                 dateFilter.$lte = e;
            }
        }
        if (Object.keys(dateFilter).length > 0) {
            matchStage.generatedAt = dateFilter;
        }
    }
    
    // Service Filter
     if (serviceId && serviceId !== 'All') {
        if (mongoose.Types.ObjectId.isValid(serviceId)) {
           matchStage.serviceId = new mongoose.Types.ObjectId(serviceId);
        }
    }

    // Determine which collections to query based on status
    let queryCompleted = true;
    let queryPending = true;

    // Status Filter (If 'completed', only query CompletedHistory. If 'pending', only query PendingHistory)
    if (status && status !== 'All') {
        // matchStage.status = { $regex: status, $options: 'i' }; // Applied in pipeline
        if (status.toLowerCase() === 'completed') {
            queryPending = false;
        } else if (['pending', 'waiting', 'cancelled', 'missed'].includes(status.toLowerCase())) {
            queryCompleted = false;
        }
    }

    // Common Pipeline Stages
    const createPipeline = (collectionMatch) => {
        const pipeline = [
            { $match: { ...matchStage, ...collectionMatch } },
            {
                $lookup: {
                    from: 'registers',
                    localField: 'studentId',
                    foreignField: '_id',
                    as: 'student'
                }
            },
            { $unwind: { path: '$student', preserveNullAndEmptyArrays: true } },
            {
                $lookup: {
                    from: 'counters',
                    localField: 'counterId',
                    foreignField: '_id',
                    as: 'counter'
                }
            },
            { $unwind: { path: '$counter', preserveNullAndEmptyArrays: true } },
             {
                $lookup: {
                    from: 'services',
                    localField: 'serviceId',
                    foreignField: '_id',
                    as: 'service'
                }
            },
            { $unwind: { path: '$service', preserveNullAndEmptyArrays: true } },
        ];

        // Search Filter
        if (search) {
            pipeline.push({
                $match: {
                    $or: [
                        { 'student.name': { $regex: search, $options: 'i' } },
                        { 'tokenNumber': parseInt(search) || -1 },
                        { 'queueName': { $regex: search, $options: 'i' } }
                    ]
                }
            });
        }
        
        // Specific Status Regex Filter (if not handled by collection split)
        if (status && status !== 'All') {
             pipeline.push({ $match: { status: { $regex: status, $options: 'i' } } });
        }

        // Project standardized structure
        pipeline.push({
            $project: {
                _id: 1,
                tokenNumber: 1,
                queueName: 1,
                department: 1,
                purpose: 1,
                status: 1,
                generatedAt: 1,
                completedAt: 1,
                student: { name: "$student.name", email: "$student.email" },
                counter: { counterName: "$counter.counterName" },
                service: { serviceName: "$service.serviceName" },
                collectionType: { $literal: collectionMatch.isCompleted ? 'completed' : 'pending' } // Helper tag
            }
        });

        return pipeline;
    };

    let history = [];

    // 1. Query Active Tokens (from 'tokens' collection)
    // We want to show live status too.
    const activePipeline = createPipeline({ isCompleted: false }); // Reuse structure but we'll fix collectionType manually
    // The createPipeline uses 'collectionMatch' which puts a hardcoded collectionType.
    // We need to differentiate active tokens.
    // Let's modify pipeline for active tokens slightly or post-process.
    
    // Custom pipeline builder for Active Tokens to handle dynamic status
    const createActivePipeline = () => {
         const pipeline = [
            { $match: { ...matchStage } }, // Match Admin ID and Date/Service filters
            {
                $lookup: { from: 'registers', localField: 'studentId', foreignField: '_id', as: 'student' }
            },
            { $unwind: { path: '$student', preserveNullAndEmptyArrays: true } },
            {
                $lookup: { from: 'counters', localField: 'counterId', foreignField: '_id', as: 'counter' }
            },
            { $unwind: { path: '$counter', preserveNullAndEmptyArrays: true } },
             {
                $lookup: { from: 'services', localField: 'serviceId', foreignField: '_id', as: 'service' }
            },
            { $unwind: { path: '$service', preserveNullAndEmptyArrays: true } },
        ];

        if (search) {
            pipeline.push({
                $match: {
                    $or: [
                        { 'student.name': { $regex: search, $options: 'i' } },
                        { 'tokenNumber': parseInt(search) || -1 },
                        { 'queueName': { $regex: search, $options: 'i' } }
                    ]
                }
            });
        }
        
        if (status && status !== 'All') {
             pipeline.push({ $match: { status: { $regex: status, $options: 'i' } } });
        }

        pipeline.push({
            $project: {
                _id: 1,
                tokenNumber: 1,
                queueName: 1,
                department: 1,
                purpose: 1,
                status: 1,
                generatedAt: 1,
                completedAt: 1,
                student: { name: "$student.name", email: "$student.email" },
                counter: { counterName: "$counter.counterName" },
                service: { serviceName: "$service.serviceName" },
                collectionType: { $literal: 'active' } 
            }
        });

        return pipeline;
    }

    // Always fetch active tokens unless status filter strictly excludes them (rare)
    const activeTokens = await Token.aggregate(createActivePipeline());
    history = history.concat(activeTokens);

    if (queryCompleted) {
        const completedPipeline = createPipeline({ isCompleted: true });
        const completedDocs = await CompletedHistoryToken.aggregate(completedPipeline);
        history = history.concat(completedDocs);
    }

    if (queryPending) {
        const pendingPipeline = createPipeline({ isCompleted: false });
        // pending pipeline marks type as 'pending' but that's fine for history
        const pendingDocs = await PendingHistoryToken.aggregate(pendingPipeline);
        history = history.concat(pendingDocs);
    }

    // Final Sort
    history.sort((a, b) => new Date(b.generatedAt) - new Date(a.generatedAt));

    // Summary Stats
    const totalTokens = history.length;
    const totalServed = history.filter(t => ['completed', 'Completed'].includes(t.status)).length;
    const pendingTokens = history.filter(t => !['completed', 'Completed'].includes(t.status)).length;

    return res.status(200).json({
        success: true,
        message: "Queue history data fetched successfully",
        history,
        summary: {
            totalTokens,
            totalServed,
            pendingTokens,
            averageWaitingTimeMinutes: 0,
            totalQueues: 0
        }
    });

  } catch (error) {
    console.error("History Error:", error);
      return res.status(500).json({ success: false, message: error.message });
  }
};

// ✅ GET HISTORY DATES (for Calendar Highlighting)
const getHistoryDates = async (req, res) => {
  try {
    const { adminId } = req.params;
    
    const pipeline = [
      { $match: { adminId: new mongoose.Types.ObjectId(adminId) } },
      { $project: { dateVal: { $ifNull: ["$completedAt", "$generatedAt"] } } },
      { $project: { day: { $dateToString: { format: "%Y-%m-%d", date: "$dateVal" } } } },
      { $group: { _id: "$day" } }
    ];

    const completedDates = await CompletedHistoryToken.aggregate(pipeline);
    const pendingDates = await PendingHistoryToken.aggregate(pipeline);

    const allDates = new Set([
        ...completedDates.map(d => d._id).filter(d => d), 
        ...pendingDates.map(d => d._id).filter(d => d)
    ]);

    return res.status(200).json({
      success: true,
      dates: Array.from(allDates).sort().reverse()
    });

  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// ✅ DELETE HISTORY TOKEN
const deleteHistoryToken = async (req, res) => {
    try {
        const { tokenId } = req.params;
        
        // Try deleting from Completed first
        let deleted = await CompletedHistoryToken.findByIdAndDelete(tokenId);
        
        if (!deleted) {
            // Try deleting from Pending if not found in Completed
            deleted = await PendingHistoryToken.findByIdAndDelete(tokenId);
        }

        if (!deleted) {
            return res.status(404).json({ success: false, message: "Token not found in history" });
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