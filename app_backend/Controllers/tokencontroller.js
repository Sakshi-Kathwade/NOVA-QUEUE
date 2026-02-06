
const Token = require("../Models/tokenmodel");
const Queue = require("../Models/create_queue_model");
const QueueHistory = require("../Models/queueHistoryModel");

exports.createToken = async (req, res) => {
  try {
    const { queueName, department, purpose, studentId } = req.body;

    // 1️⃣ Validation
    if (!queueName || !purpose || !studentId) {
      return res.status(400).json({
        success: false,
        message: "Queue name, purpose and studentId are required",
      });
    }

    // 2️⃣ 🔴 CHECK: Student already has token in SAME queue
    const existingToken = await Token.findOne({
      queueName,
      studentId,
      status: "waiting",
    });

    if (existingToken) {
      return res.status(409).json({
        success: false,
        message: "You already have a token for this queue",
      });
    }

    // ✅ Queue must exist and be active and within time window
    const queue = await Queue.findOne({ queueName }).sort({ createdAt: -1 });
    if (!queue) {
      return res.status(404).json({
        success: false,
        message: "Queue not found",
      });
    }

    const now = new Date();
    if (queue.status !== "Active") {
      return res.status(400).json({
        success: false,
        message: "Queue is not active",
      });
    }
    if (queue.startTime && now < queue.startTime) {
      return res.status(400).json({
        success: false,
        message: "Queue has not started yet",
      });
    }
    if (queue.endTime && now >= queue.endTime) {
      // 1️⃣ Copy to History
      await QueueHistory.create({
        adminId: queue.adminId,
        queueName: queue.queueName,
        department: queue.department,
        startTime: queue.startTime,
        endTime: queue.endTime,
        maxStudents: queue.maxStudents,
        status: "Expired",
        discardedAt: now
      });

      // 2️⃣ Delete from Active Queues
      await Queue.findByIdAndDelete(queue._id);

      // 3️⃣ Delete associated tokens
      await Token.deleteMany({ queueName: queue.queueName });

      return res.status(410).json({
        success: false,
        message: "Queue time is finished",
      });
    }

    // ✅ Capacity rule: max 30 (or queue.maxStudents) active tokens
    const activeCount = await Token.countDocuments({
      queueName,
      status: { $in: ["waiting", "serving", "hold"] },
    });
    const capacity = Math.min(Number(queue.maxStudents || 30), 30);
    if (activeCount >= capacity) {
      return res.status(409).json({
        success: false,
        message: "Queue is full please wait",
      });
    }

    // 3️⃣ Count students ahead in SAME queue
    const studentsAhead = await Token.countDocuments({
      queueName,
      status: "waiting",
    });

    // 4️⃣ Generate next token number
    const lastToken = await Token.findOne({ queueName })
      .sort({ tokenNumber: -1 });

    const tokenNumber = lastToken ? lastToken.tokenNumber + 1 : 1;

    // 5️⃣ Create new token
    const token = await Token.create({
      queueName,
      department,
      purpose,
      studentId,
      tokenNumber,
      studentsAhead,
      estimatedWaitingTime: studentsAhead * 5,
      status: "pending", // ✅ Start as pending for admin approval
    });

    // 6️⃣ Success response
    res.status(201).json({
      success: true,
      message: "Token generated successfully",
      data: token,
    });

  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
};

exports.getTokenByQueueAndStudent = async (req, res) => {
  try {
    const { queueName, studentId } = req.params;

    // 🔹 Find student's token in THIS queue only
    const token = await Token.findOne({
      studentId: studentId,
      status: "waiting",
    });

    if (!token) {
      return res.status(404).json({
        success: false,
        message: "No token found for this student in this queue",
      });
    }

    // 🔹 Count students ahead in SAME queue
    const studentsAhead = await Token.countDocuments({
      queueName: queueName,
      status: "waiting",
      tokenNumber: { $lt: token.tokenNumber },
    });

    // 🔹 Calculate estimated waiting time
    const AVG_TIME_PER_STUDENT = 5; // minutes (adjust if needed)
    const estimatedWaitingTime = studentsAhead * AVG_TIME_PER_STUDENT;

    res.status(200).json({
      success: true,
      tokenNumber: token.tokenNumber,
      queueName: token.queueName,
      studentsAhead: studentsAhead,
      estimatedWaitingTime: estimatedWaitingTime,
      status: token.status,
    });

  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
};


// ✅ Delete Token
exports.deleteToken = async (req, res) => {
  try {
    const { queueName, tokenNumber } = req.params;

    const deletedToken = await Token.findOneAndDelete({
      queueName,
      tokenNumber,
      status: "waiting",
    });

    if (!deletedToken) {
      return res.status(404).json({
        success: false,
        message: "Token not found",
      });
    }

    // Update tokens after the deleted one
    const tokensAfter = await Token.find({
      queueName,
      status: "waiting",
      tokenNumber: { $gt: tokenNumber },
    });

    for (const token of tokensAfter) {
      await Token.findByIdAndUpdate(token._id, {
        studentsAhead: token.studentsAhead - 1,
        estimatedWaitingTime: token.estimatedWaitingTime - 5,
      });
    }

    res.status(200).json({
      success: true,
      message: "Token cancelled successfully. Queue updated.",
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};

// ✅ MARK TOKEN MISSED (for staff to mark a serving token as missed)
exports.markTokenMissed = async (req, res) => {
  try {
    const { tokenId, queueName } = req.body; // queueName to get admin settings

    if (!tokenId || !queueName) {
      return res.status(400).json({
        success: false,
        message: "Token ID and Queue Name are required",
      });
    }

    const token = await Token.findById(tokenId);
    if (!token) {
      return res.status(404).json({
        success: false,
        message: "Token not found",
      });
    }

    // Ensure token is in a state that can be marked missed (e.g., serving)
    if (token.status !== "serving") {
      return res.status(400).json({
        success: false,
        message: "Token is not currently serving and cannot be marked as missed",
      });
    }

    const Admin = require("../Models/adminmodel.js");
    const admin = await Admin.findById(token.adminId); // Get admin for settings

    if (!admin) {
      return res.status(404).json({
        success: false,
        message: "Admin for this queue not found",
      });
    }

    const maxRecalls = admin.missedTokenRecalls;

    if (token.recallAttempts < maxRecalls) {
      // Requeue the token for a recall
      // Find the last token in the queue to place this one after
      const lastToken = await Token.findOne({
        queueName: token.queueName,
        status: { $in: ["waiting", "serving", "hold", "recalled"] },
      }).sort({ tokenNumber: -1 });

      const newTokenNumber = lastToken ? lastToken.tokenNumber + 1 : 1;

      // Update the current token
      const updatedToken = await Token.findByIdAndUpdate(
        tokenId,
        {
          status: "recalled",
          recallAttempts: token.recallAttempts + 1,
          lastCalledAt: Date.now(),
          recalledAt: Date.now(),
          originalTokenNumberForRecall: token.originalTokenNumberForRecall || token.tokenNumber, // Store original if first recall
          tokenNumber: newTokenNumber, // Assign new token number at the end
        },
        { new: true }
      );

      return res.status(200).json({
        success: true,
        message: `Token A-${token.tokenNumber} marked as missed. Recalling after other students.`,
        data: updatedToken,
      });
    } else {
      // Max recalls reached, destroy/cancel the token
      const cancelledToken = await Token.findByIdAndUpdate(
        tokenId,
        { status: "cancelled", cancelledAt: Date.now() },
        { new: true }
      );

      return res.status(200).json({
        success: true,
        message: `Token A-${token.tokenNumber} cancelled due to multiple misses.`,
        data: cancelledToken,
      });
    }
  } catch (err) {
    console.error("Error marking token missed:", err);
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
};

exports.getCurrentToken = async (req, res) => {
  try {
    const { queueName } = req.params;

    if (!queueName) {
      return res.status(400).json({
        success: false,
        message: "queueName missing",
      });
    }

    // ✅ Get current token (serving status or first waiting token)
    let token = await Token.findOne({
      queueName,
      status: "serving",
    });

    // ✅ Get counts even if no token is found
    const totalCount = await Token.countDocuments({ queueName });
    const completedCount = await Token.countDocuments({
      queueName,
      status: { $in: ["completed", "Completed"] },
    });
    const pendingCount = await Token.countDocuments({
      queueName,
      status: "pending",
    });

    if (!token) {
      return res.status(200).json({
        success: true,
        data: null, // No active token, but return counts
        completedCount,
        pendingCount,
        totalCount,
      });
    }

    // ✅ Get student name from studentId
    const Student = require("../Models/registermodel");
    const student = await Student.findById(token.studentId);
    const studentName = student ? student.name : "Unknown";

    // No need to repeat counts here, they are calculated above

    res.status(200).json({
      success: true,
      data: {
        tokenId: token._id,
        tokenNumber: token.tokenNumber,
        studentName: studentName,
        purpose: token.purpose,
        completedCount,
        pendingCount,
        totalCount,
      },
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
};

// ✅ COMPLETE TOKEN
exports.completeToken = async (req, res) => {
  try {
    const { queueName, tokenId } = req.body;

    if (!queueName || !tokenId) {
      return res.status(400).json({
        success: false,
        message: "Queue name and token ID are required",
      });
    }

    // Update token status to completed
    const token = await Token.findByIdAndUpdate(
      tokenId,
      { status: "completed" },
      { new: true }
    );

    if (!token) {
      return res.status(404).json({
        success: false,
        message: "Token not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Token completed successfully",
      data: token,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
};

// ✅ HOLD TOKEN
exports.holdToken = async (req, res) => {
  try {
    const { queueName, tokenId } = req.body;

    if (!queueName || !tokenId) {
      return res.status(400).json({
        success: false,
        message: "Queue name and token ID are required",
      });
    }

    // Update token status to hold
    const token = await Token.findByIdAndUpdate(
      tokenId,
      { status: "hold" },
      { new: true }
    );

    if (!token) {
      return res.status(404).json({
        success: false,
        message: "Token not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Token put on hold successfully",
      data: token,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
};

// ✅ UNHOLD TOKEN (resume held token)
exports.unholdToken = async (req, res) => {
  try {
    const { queueName, tokenId } = req.body;

    if (!queueName || !tokenId) {
      return res.status(400).json({
        success: false,
        message: "Queue name and token ID are required",
      });
    }

    // Find the token
    const token = await Token.findById(tokenId);

    if (!token) {
      return res.status(404).json({
        success: false,
        message: "Token not found",
      });
    }

    // Check if token is on hold
    if (token.status !== "hold") {
      return res.status(400).json({
        success: false,
        message: "Token is not on hold",
      });
    }

    // Update token status back to waiting
    const updatedToken = await Token.findByIdAndUpdate(
      tokenId,
      { status: "waiting" },
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: "Token unheld successfully and returned to waiting queue",
      data: updatedToken,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
};

// ✅ GET HELD TOKENS
exports.getHeldTokens = async (req, res) => {
  try {
    const { queueName } = req.params;

    if (!queueName) {
      return res.status(400).json({
        success: false,
        message: "Queue name is required",
      });
    }

    // Find all held tokens
    const heldTokens = await Token.find({
      queueName,
      status: "hold",
    }).sort({ tokenNumber: 1 });

    // Get student names
    const Student = require("../Models/registermodel");
    const tokensWithNames = await Promise.all(
      heldTokens.map(async (token) => {
        const student = await Student.findById(token.studentId);
        return {
          tokenId: token._id,
          tokenNumber: token.tokenNumber,
          studentName: student ? student.name : "Unknown",
          purpose: token.purpose,
          department: token.department,
        };
      })
    );

    res.status(200).json({
      success: true,
      count: tokensWithNames.length,
      heldTokens: tokensWithNames,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
};

// ✅ NEXT TOKEN (skip hold tokens)
// ✅ NEXT TOKEN (handle recalled tokens)
exports.nextToken = async (req, res) => {
  try {
    const { queueName, currentTokenId, adminId } = req.body; // adminId is needed to fetch admin settings

    if (!queueName || !adminId) {
      return res.status(400).json({
        success: false,
        message: "Queue name and Admin ID are required",
      });
    }

    let currentTokenNumber = 0;

    // If current token exists, mark it as completed or update its status if recalled
    if (currentTokenId) {
      const currentToken = await Token.findById(currentTokenId);
      if (currentToken) {
        currentTokenNumber = currentToken.tokenNumber;
        if (currentToken.status === "serving" || currentToken.status === "waiting") {
          await Token.findByIdAndUpdate(currentTokenId, {
            status: "completed",
            completedAt: Date.now(),
          });
        }
        // If it was a recalled token and is now being served, mark completed
        if (currentToken.status === "recalled" && currentToken.recalledAt) {
          await Token.findByIdAndUpdate(currentTokenId, {
            status: "completed",
            completedAt: Date.now(),
          });
        }
      }
    }

    // Fetch admin settings for recall wait time
    const Admin = require("../Models/adminmodel.js");
    const admin = await Admin.findById(adminId);
    if (!admin) {
      return res.status(404).json({
        success: false,
        message: "Admin for this queue not found",
      });
    }
    const missedTokenRecallWaitTimeMinutes = admin.missedTokenRecallWaitTimeMinutes || 10; // Default 10 min

    const now = Date.now();

    // Find next available token: prioritize recalled tokens whose wait time has passed, then waiting tokens
    let nextToken = await Token.findOne({
      queueName,
      status: "recalled",
      tokenNumber: { $gt: currentTokenNumber }, // Find tokens after current
      recalledAt: { $lte: new Date(now - missedTokenRecallWaitTimeMinutes * 60 * 1000) }, // Wait time passed
    }).sort({ tokenNumber: 1 });

    if (!nextToken) {
      // If no recalled token ready, find the next waiting token
      nextToken = await Token.findOne({
        queueName,
        status: "waiting",
        tokenNumber: { $gt: currentTokenNumber }, // Find tokens after current
      }).sort({ tokenNumber: 1 });
    }

    if (!nextToken) {
      return res.status(404).json({
        success: false,
        message: "No more tokens in queue",
      });
    }

    // Mark next token as serving and update lastCalledAt
    await Token.findByIdAndUpdate(nextToken._id, { status: "serving", lastCalledAt: Date.now() });

    // Get student name
    const Student = require("../Models/registermodel.js");
    const student = await Student.findById(nextToken.studentId);
    const studentName = student ? student.name : "Unknown";

    res.status(200).json({
      success: true,
      message: "Next token loaded successfully",
      data: {
        tokenId: nextToken._id,
        tokenNumber: nextToken.tokenNumber,
        studentName: studentName,
        purpose: nextToken.purpose,
        status: nextToken.status, // Return the status (serving or recalled)
      },
    });
  } catch (err) {
    console.error("Error in nextToken:", err);
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
};





// ✅ Get all remaining waiting students in a queue
exports.getRemainingStudents = async (req, res) => {
  try {
    const { queueName } = req.params;

    if (!queueName) {
      return res.status(400).json({
        success: false,
        message: "queueName is required",
      });
    }

    // 1️⃣ Find the first token being served (current token)
    const currentToken = await Token.findOne({
      queueName,
      status: "waiting",
    }).sort({ tokenNumber: 1 });

    // 2️⃣ Get all remaining waiting students (including current)
    const remainingStudents = await Token.find({
      queueName,
      status: "waiting",
    }).sort({ tokenNumber: 1 });

    // 3️⃣ Get student names and map to response
    const Student = require("../Models/registermodel");
    const waitingList = await Promise.all(
      remainingStudents.map(async (s) => {
        const student = await Student.findById(s.studentId);
        return {
          tokenNumber: s.tokenNumber,
          studentId: s.studentId,
          studentName: student ? student.name : "Unknown",
          purpose: s.purpose,
          department: s.department,
        };
      })
    );

    res.status(200).json({
      success: true,
      queueName,
      waitingCount: waitingList.length,
      waiting: waitingList,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
};

// ✅ GET STUDENT QUEUE HISTORY (only logged-in student's personal history)
exports.getStudentHistory = async (req, res) => {
  try {
    const { studentId } = req.params;

    if (!studentId) {
      return res.status(400).json({
        success: false,
        message: "Student ID is required",
      });
    }

    const tokens = await Token.find({
      studentId,
      status: { $in: ['completed', 'cancelled', 'Completed', 'Cancelled'] },
    })
      .sort({ updatedAt: -1 })
      .limit(100);

    const history = tokens.map((t) => ({
      id: t._id,
      date: t.completedAt || t.cancelledAt || t.updatedAt || t.generatedAt,
      serviceTaken: t.purpose || t.department || 'N/A',
      queueName: t.queueName || 'N/A',
      tokenNumber: t.tokenNumber,
      waitingTimeMinutes: t.estimatedWaitingTime || 0,
      status: t.status === 'completed' || t.status === 'Completed' ? 'Served' : 'Cancelled',
    }));

    res.status(200).json({
      success: true,
      history,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
};

// ✅ GET COMPLETED TOKENS TODAY WITH HOURLY BREAKDOWN
exports.getCompletedToday = async (req, res) => {
  try {
    const { queueName } = req.params;

    if (!queueName) {
      return res.status(400).json({
        success: false,
        message: "queueName is required",
      });
    }

    // Get today's date range (start and end of day)
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Get all completed tokens today
    const completedTokens = await Token.find({
      queueName,
      status: { $in: ["completed", "Completed"] },
      updatedAt: {
        $gte: today,
        $lt: tomorrow,
      },
    }).sort({ updatedAt: 1 });

    // Get student names
    const Student = require("../Models/registermodel");
    const tokensWithDetails = await Promise.all(
      completedTokens.map(async (token) => {
        const student = await Student.findById(token.studentId);
        return {
          tokenId: token._id,
          tokenNumber: token.tokenNumber,
          studentName: student ? student.name : "Unknown",
          purpose: token.purpose,
          department: token.department,
          completedAt: token.updatedAt,
        };
      })
    );

    // Calculate hourly breakdown
    const hourlyBreakdown = {};
    for (let hour = 0; hour < 24; hour++) {
      hourlyBreakdown[hour] = 0;
    }

    tokensWithDetails.forEach((token) => {
      if (token.completedAt) {
        const hour = new Date(token.completedAt).getHours();
        hourlyBreakdown[hour] = (hourlyBreakdown[hour] || 0) + 1;
      }
    });

    // Format hourly data for frontend
    const hourlyData = [];
    const hourLabels = [
      "12-1 AM", "1-2 AM", "2-3 AM", "3-4 AM", "4-5 AM", "5-6 AM",
      "6-7 AM", "7-8 AM", "8-9 AM", "9-10 AM", "10-11 AM", "11-12 PM",
      "12-1 PM", "1-2 PM", "2-3 PM", "3-4 PM", "4-5 PM", "5-6 PM",
      "6-7 PM", "7-8 PM", "8-9 PM", "9-10 PM", "10-11 PM", "11-12 AM"
    ];

    for (let hour = 0; hour < 24; hour++) {
      if (hourlyBreakdown[hour] > 0) {
        hourlyData.push({
          hour: hour,
          label: hourLabels[hour],
          count: hourlyBreakdown[hour],
        });
      }
    }

    // Calculate max count for percentage calculation
    const maxCount = hourlyData.length > 0
      ? Math.max(...hourlyData.map((h) => h.count))
      : 1;

    res.status(200).json({
      success: true,
      data: {
        totalCompleted: tokensWithDetails.length,
        hourlyBreakdown: hourlyData.map((h) => ({
          ...h,
          percentage: (h.count / maxCount) * 100,
        })),
        completedTokens: tokensWithDetails,
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
};
// =================================== PENDING TOKEN FUNCTIONS ===================================

// ✅ Get all pending tokens for a queue (Admin)
exports.getPendingTokens = async (req, res) => {
  try {
    const { queueName } = req.params;
    const pendingTokens = await Token.find({
      queueName,
      status: "pending"
    }).populate('studentId', 'name email');

    res.status(200).json({
      success: true,
      data: pendingTokens
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};

// ✅ Get all pending tokens for a specific student
exports.getPendingTokensForStudent = async (req, res) => {
  try {
    const { studentId } = req.params;
    const pendingTokens = await Token.find({
      studentId,
      status: "pending"
    }).sort({ generatedAt: -1 });

    res.status(200).json({
      success: true,
      data: pendingTokens
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};

// ✅ Approve a token (Change pending -> waiting)
exports.approveToken = async (req, res) => {
  try {
    const { tokenId } = req.body;

    const token = await Token.findById(tokenId);
    if (!token) {
      return res.status(404).json({ success: false, message: "Token not found" });
    }

    if (token.status !== "pending") {
      return res.status(400).json({ success: false, message: "Token is not in pending state" });
    }

    // Update status to waiting
    token.status = "waiting";
    await token.save();

    res.status(200).json({
      success: true,
      message: "Token approved and added to active queue",
      data: token
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};

// ✅ Reject a token (Change pending -> cancelled)
exports.rejectToken = async (req, res) => {
  try {
    const { tokenId, reason } = req.body;

    const token = await Token.findById(tokenId);
    if (!token) {
      return res.status(404).json({ success: false, message: "Token not found" });
    }

    if (token.status !== "pending") {
      return res.status(400).json({ success: false, message: "Token is not in pending state" });
    }

    // Update status to cancelled
    token.status = "cancelled";
    token.cancelledAt = new Date();
    if (reason) token.rejectionReason = reason; // Optional: add rejectionReason to model if desired, or just use purpose/strict:false
    await token.save();

    res.status(200).json({
      success: true,
      message: "Token rejected",
      data: token
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};
