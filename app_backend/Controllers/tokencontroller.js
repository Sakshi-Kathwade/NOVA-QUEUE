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

    // Find token for this student in this queue
    const token = await Token.findOne({
      queueName,
      studentId,
      status: "waiting",
    });

    if (!token) {
      return res.status(404).json({
        success: false,
        message: "No token found for this student",
      });
    }

    res.status(200).json({
      success: true,
      tokenNumber: token.tokenNumber,
      queueName: token.queueName,
      studentsAhead: token.studentsAhead,
      estimatedWaitingTime: token.estimatedWaitingTime,
      status: token.status,
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
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