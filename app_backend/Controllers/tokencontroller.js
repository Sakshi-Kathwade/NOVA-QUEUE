const Token = require("../Models/tokenmodel");

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
      status: "waiting",
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

    // If no serving token, get first waiting token (skip hold tokens)
    if (!token) {
      token = await Token.findOne({
        queueName,
        status: "waiting",
      }).sort({ tokenNumber: 1 });
    }

    if (!token) {
      return res.status(404).json({
        success: false,
        message: "No active token",
      });
    }

    // ✅ Get student name from studentId
    const Student = require("../Models/registermodel");
    const student = await Student.findById(token.studentId);
    const studentName = student ? student.name : "Unknown";

    const totalCount = await Token.countDocuments({ queueName });
    const completedCount = await Token.countDocuments({
      queueName,
      status: "completed",
    });

    res.status(200).json({
      success: true,
      data: {
        tokenId: token._id,
        tokenNumber: token.tokenNumber,
        studentName: studentName,
        purpose: token.purpose,
        completedCount,
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
exports.nextToken = async (req, res) => {
  try {
    const { queueName, currentTokenId } = req.body;

    if (!queueName) {
      return res.status(400).json({
        success: false,
        message: "Queue name is required",
      });
    }

    let currentTokenNumber = 0;

    // If current token exists, mark it as completed
    if (currentTokenId) {
      const currentToken = await Token.findById(currentTokenId);
      if (currentToken) {
        currentTokenNumber = currentToken.tokenNumber;
        if (currentToken.status === "serving" || currentToken.status === "waiting") {
          await Token.findByIdAndUpdate(currentTokenId, {
            status: "completed",
          });
        }
      }
    }

    // Find next waiting token (skip hold tokens and completed tokens)
    const nextToken = await Token.findOne({
      queueName,
      status: "waiting",
      tokenNumber: { $gt: currentTokenNumber },
    }).sort({ tokenNumber: 1 });

    if (!nextToken) {
      return res.status(404).json({
        success: false,
        message: "No more tokens in queue",
      });
    }

    // Mark next token as serving
    await Token.findByIdAndUpdate(nextToken._id, { status: "serving" });

    // Get student name
    const Student = require("../Models/registermodel");
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
      },
    });
  } catch (err) {
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

    // 2️⃣ Get all remaining waiting students after current token
    const remainingStudents = await Token.find({
      queueName,
      status: "waiting",
      tokenNumber: { $gt: currentToken ? currentToken.tokenNumber : 0 },
    }).sort({ tokenNumber: 1 });

    // 3️⃣ Map data to return only needed fields
    const waitingList = remainingStudents.map((s) => ({
      tokenNumber: s.tokenNumber,
      studentId: s.studentId,
      studentName: s.studentName,
      purpose: s.purpose,
      department: s.department,
    }));

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
