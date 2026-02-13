
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
    // Relaxed Start Time check to handle Timezone offsets
    // If status is Active, we assume Admin wants it open.
    // if (queue.startTime && now < queue.startTime) { ... } 

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

    // ✅ Capacity rule: max students allowed for the ENTIRE queue session
    const totalTokens = await Token.countDocuments({ queueName });
    
    // Use queue.maxStudents if available, otherwise default to 30.
    const capacity = Number(queue.maxStudents) || 30; 
    
    if (totalTokens >= capacity) {
      return res.status(409).json({
        success: false,
        message: "Queue is already full you are not join it", // ✅ Updated message as requested
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
      studentsAhead,
      estimatedWaitingTime: studentsAhead * 5,
      status: "waiting", // ✅ Start as waiting immediately
      adminId: queue.adminId, // ✅ Save Admin ID for reports
      serviceName: department || purpose, // ✅ Snapshot service name (department is often used as service)
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
      queueName: queueName,
      studentId: studentId,
      status: { $in: ["waiting", "serving", "hold"] },
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

// ✅ GET CURRENT TOKEN (Serving OR Next Waiting)
exports.getCurrentToken = async (req, res) => {
  try {
    const { queueName } = req.params;

    if (!queueName) {
      return res.status(400).json({
        success: false,
        message: "queueName missing",
      });
    }

    // 1️⃣ Priority: Get token currently being SERVED
    let token = await Token.findOne({
      queueName,
      status: "serving",
    });

    // 2️⃣ Fallback: If no one is serving, get the first WAITING token
    if (!token) {
      token = await Token.findOne({
        queueName,
        status: "waiting",
      }).sort({ tokenNumber: 1 }); // Get the first one in line
    }

    // ✅ Get counts
    const totalCount = await Token.countDocuments({ queueName });
    
    const completedCount = await Token.countDocuments({
      queueName,
      status: { $in: ["completed", "Completed"] },
      // generatedAt: { $gte: startOfDay }, // Optional: Ensure it belongs to today's session if queue names are reused
    });

    const pendingCount = await Token.countDocuments({
      queueName,
      status: "pending", // ✅ Only count actual pending (unserved/missed) tokens matching the separate box logic
    });

    if (!token) {
      return res.status(200).json({
        success: true,
        data: null, // No active token being served
        completedCount,
        pendingCount, // Now returns total incomplete tokens
        totalCount,
      });
    }

    // ✅ Get student name from studentId
    const Student = require("../Models/registermodel");
    const student = await Student.findById(token.studentId);
    const studentName = student ? student.name : "Unknown";

    res.status(200).json({
      success: true,
      data: {
        tokenId: token._id,
        tokenNumber: token.tokenNumber,
        studentName: studentName,
        purpose: token.purpose,
        status: token.status, // Return status so frontend knows if it's waiting or serving
        isRetried: token.isRetried || false, // Visual indicator for retried tokens
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
      { 
        status: "completed", 
        completedAt: Date.now(),
        isMissed: false 
      }, // ✅ Set completedAt and clear missed flag
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
// ✅ NEXT TOKEN (Move current to completed, pick next waiting/recalled)
exports.nextToken = async (req, res) => {
  try {
    const { queueName, currentTokenId, adminId } = req.body;

    if (!queueName || !adminId) {
      return res.status(400).json({
        success: false,
        message: "Queue name and Admin ID are required",
      });
    }

    // 1️⃣ Handle the CURRENT token (if one exists)
    if (currentTokenId) {
      const currentToken = await Token.findById(currentTokenId);
      
      if (currentToken) {
        // 🔴 Case A: The token was just WAITING (shown in dashboard preview). 
        // We do NOT complete it yet. We just move it to "serving".
        if (currentToken.status === "waiting") {
          const updated = await Token.findByIdAndUpdate(
            currentTokenId,
            { status: "serving", lastCalledAt: Date.now() },
            { new: true }
          );

           // Get student name
          const Student = require("../Models/registermodel.js");
          const student = await Student.findById(updated.studentId);
          const studentName = student ? student.name : "Unknown";

          return res.status(200).json({
            success: true,
            message: "Starting to serve token",
            data: {
              tokenId: updated._id,
              tokenNumber: updated.tokenNumber,
              studentName: studentName,
              purpose: updated.purpose,
              status: updated.status,
            },
          });
        }

        // 🟢 Case B: The token was ALREADY "serving" or "recalled". 
        // In this flow, clicking 'Next' while a token is serving means it was MISSED.
        if (currentToken.status === "serving" || currentToken.status === "recalled") {
          const Admin = require("../Models/adminmodel.js");
          const admin = await Admin.findById(adminId);
          const missedTokenRetries = admin?.missedTokenRetries || 3;
          const maxRecalls = admin?.missedTokenRecalls || 2;
          const currentAttempts = currentToken.recallAttempts || 0;

          if (currentAttempts < maxRecalls) {
            await Token.findByIdAndUpdate(currentTokenId, {
              status: "missed",
              isMissed: true,
              isRetried: true, 
              waitStudentsLeft: missedTokenRetries,
              recallAttempts: currentAttempts + 1,
              lastCalledAt: Date.now(),
            });
          } else {
            // Max recalls reached, cancel the token
            await Token.findByIdAndUpdate(currentTokenId, {
              status: "cancelled",
              cancelledAt: Date.now(),
              isMissed: false
            });
          }
        }
      }
    }

    // 2️⃣ FIND THE *NEXT* TOKEN TO SERVE
    // Decrement wait counter for all currently missed tokens in this queue
    await Token.updateMany(
      { queueName, isMissed: true, waitStudentsLeft: { $gt: 0 } },
      { $inc: { waitStudentsLeft: -1 } }
    );

    const now = Date.now();

    // Priority 1: Pick a missed token that is ready (waitStudentsLeft <= 0)
    let nextToken = await Token.findOne({
      queueName,
      isMissed: true,
      waitStudentsLeft: { $lte: 0 },
      status: "missed"
    }).sort({ lastCalledAt: 1 });

    if (!nextToken) {
      // Priority 2: Pick the next waiting token
      nextToken = await Token.findOne({
        queueName,
        status: "waiting",
      }).sort({ tokenNumber: 1 });
    }

    if (!nextToken) {
      // Priority 3: Fallback to old recall logic if still used
      const Admin = require("../Models/adminmodel.js");
      const admin = await Admin.findById(adminId);
      const waitTime = admin?.missedTokenRecallWaitTimeMinutes || 10;
      
      nextToken = await Token.findOne({
        queueName,
        status: "recalled",
        recalledAt: { $lte: new Date(now - waitTime * 60 * 1000) },
      }).sort({ tokenNumber: 1 });
    }

    if (!nextToken) {
      return res.status(404).json({
        success: false,
        message: "No more tokens in queue",
      });
    }

    // Mark next token as serving
    await Token.findByIdAndUpdate(nextToken._id, { 
      status: "serving", 
      lastCalledAt: Date.now(),
      isMissed: false // Clear missed status when they show up
    });

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
        status: nextToken.status,
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

    // 1️⃣ Find the first serving token
    const servingToken = await Token.findOne({
      queueName,
      status: "serving",
    });

    let remainingStudents = await Token.find({
      queueName,
      status: "waiting",
    }).sort({ tokenNumber: 1 });

    // ✅ If NO token is currently serving, the first waiting token is technically "Next/Current".
    // The requirement says: "current serving or current token does not display in waiting".
    // If dashboard shows Token 1 as "Current Token" (because it's next), we should HIDE it from Waiting List.
    if (!servingToken && remainingStudents.length > 0) {
       remainingStudents = remainingStudents.slice(1);
    }

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
      status: { $in: ['completed', 'cancelled', 'Completed', 'Cancelled', 'pending', 'hold'] },
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
      status: (t.status === 'completed' || t.status === 'Completed') ? 'Served' : (t.status === 'pending' ? 'Expired' : t.status),
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
// ✅ GET PENDING TOKENS (Unserved students after queue expiry)
exports.getPendingTokens = async (req, res) => {
  try {
    const { queueName } = req.params;

    if (!queueName) {
      return res.status(400).json({
        success: false,
        message: "Queue name is required",
      });
    }

    const pendingTokens = await Token.find({
      queueName,
      status: "pending", // ✅ Fetch only pending tokens
    }).sort({ tokenNumber: 1 });

    const Student = require("../Models/registermodel");
    const pendingList = await Promise.all(
      pendingTokens.map(async (t) => {
        const student = await Student.findById(t.studentId);
        return {
           _id: t._id,
          tokenNumber: t.tokenNumber,
          studentId: {
             name: student ? student.name : "Unknown",
             email: student ? student.email : "",
          },
          purpose: t.purpose,
          generatedAt: t.generatedAt,
          status: t.status
        };
      })
    );

    res.status(200).json({
      success: true,
      data: pendingList,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
};
    // Get today's date range (start and end of day)
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Get all completed tokens today
    const completedTokens = await Token.find({
      queueName,
      status: { $in: ["completed", "Completed"] },
      completedAt: { // ✅ Filter by completedAt for accuracy
        $gte: today,
        $lt: tomorrow,
      },
    }).sort({ completedAt: 1 }); // ✅ Sort by completedAt

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
          completedAt: token.completedAt, // ✅ Return completedAt
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

    // 🔹 Grace Period Check (4 hours)
    const Queue = require("../Models/create_queue_model");
    const QueueHistory = require("../Models/queueHistoryModel");

    // Try to find active queue first
    let queue = await Queue.findOne({ queueName: token.queueName }).sort({ createdAt: -1 });

    // If not active, check history (expired queue)
    if (!queue) {
      queue = await QueueHistory.findOne({ queueName: token.queueName }).sort({ createdAt: -1 });
    }

    if (queue && queue.endTime) {
      const endTime = new Date(queue.endTime);
      const now = new Date();
      const gracePeriodEnd = new Date(endTime.getTime() + 4 * 60 * 60 * 1000); // 4 hours after end time

      if (now > gracePeriodEnd) {
         return res.status(400).json({
           success: false,
           message: "Grace period expired. Cannot serve this token after 4 hours of queue end time.",
         });
      }
    } else {
        // If queue record lost, maybe allow? Or block?
        // Let's allow for now if queue is missing but token exists, or block?
        // Safest is to allow if we can't find end time, or block if strictly needed.
        // Given data retention, we should find it. If not, let's assume valid for manual override or token existence.
        // But for "smart" system, let's log warning and proceed or fail.
        // Let's proceed with a warning logic or just allow if queue missing (edge case).
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

// ✅ GET HISTORY BY DATE (From TokenHistory)
exports.getHistoryByDate = async (req, res) => {
  try {
    const { date, queueName } = req.query; // date in YYYY-MM-DD format

    if (!date || !queueName) {
      return res.status(400).json({
        success: false,
        message: "Date and Queue Name are required",
      });
    }

    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    const TokenHistory = require("../Models/tokenHistoryModel");
    const Student = require("../Models/registermodel");

    // Find tokens in history that match the queue and date (using created/generated or completed date)
    // We'll prioritize 'completedAt' if available, otherwise 'generatedAt'
    // BUT user wants to search by date. Let's assume we look for tokens completed OR archived on that date.
    // Ideally, history logs "Daily" activity.
    const historyTokens = await TokenHistory.find({
      queueName: queueName,
      $or: [
        { completedAt: { $gte: startOfDay, $lte: endOfDay } },
        { archivedAt: { $gte: startOfDay, $lte: endOfDay } } 
      ]
    }).sort({ tokenNumber: 1 });

    const results = await Promise.all(historyTokens.map(async (t) => {
        const student = await Student.findById(t.studentId);
        return {
            tokenNumber: t.tokenNumber,
            studentName: student ? student.name : "Unknown",
            purpose: t.purpose,
            status: t.status,
            completedAt: t.completedAt || t.archivedAt,
        };
    }));

    res.status(200).json({
      success: true,
      count: results.length,
      data: results,
    });

  } catch (err) {
    console.error("Error fetching history:", err);
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
};

// ✅ Get pending token count by Admin ID (when no active queue)
exports.getPendingCountByAdmin = async (req, res) => {
  try {
    const { adminId } = req.params;
    if (!adminId) return res.status(400).json({ success: false, message: "Admin ID required" });

    // Ensure adminId is treated as ObjectId to avoid mismatch if stored as ObjectId
    const mongoose = require("mongoose");
    let query = { status: "pending" };
    try {
        query.adminId = new mongoose.Types.ObjectId(adminId);
    } catch(e) {
        query.adminId = adminId;
    }

    // Try finding by ObjectId first, fallback to string if 0 (or just check carefully how tokens store adminId)
    // Tokens store adminId reference.
    let count = await Token.countDocuments(query);
    if (count === 0 && typeof query.adminId !== 'string') {
        // Fallback to string check just in case
        count = await Token.countDocuments({ adminId: adminId, status: "pending" });
    }

    res.status(200).json({ success: true, count });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};

// ✅ Get pending tokens list by Admin ID
exports.getPendingTokensByAdmin = async (req, res) => {
  try {
    const { adminId } = req.params;
    if (!adminId) return res.status(400).json({ success: false, message: "Admin ID required" });

    const mongoose = require("mongoose");
    let query = { status: "pending" };
    try {
        query.adminId = new mongoose.Types.ObjectId(adminId);
    } catch(e) {
        query.adminId = adminId;
    }

    let pendingTokens = await Token.find(query).sort({ generatedAt: 1 });
    
    // Fallback if empty and ID type might be issue
    if (pendingTokens.length === 0 && typeof query.adminId !== 'string') {
         pendingTokens = await Token.find({ adminId: adminId, status: "pending" }).sort({ generatedAt: 1 });
    }

    const Student = require("../Models/registermodel");
    const pendingList = await Promise.all(
      pendingTokens.map(async (t) => {
        const student = await Student.findById(t.studentId);
        return {
           _id: t._id,
          tokenNumber: t.tokenNumber,
          queueName: t.queueName,
          studentId: {
             name: student ? student.name : "Unknown",
             email: student ? student.email : "",
          },
          purpose: t.purpose,
          generatedAt: t.generatedAt,
          status: t.status
        };
      })
    );

    res.status(200).json({
      success: true,
      data: pendingList,
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};
