const Token = require("../Models/tokenmodel");

// 🎫 CREATE TOKEN
exports.createToken = async (req, res) => {
  try {
    const { queueName, department, purpose } = req.body;

    if (!queueName || !purpose) {
      return res.status(400).json({
        success: false,
        message: "Queue name and purpose are required",
      });
    }

    const studentsAhead = await Token.countDocuments({
      queueName,
      status: "waiting",
    });

    const lastToken = await Token.findOne({ queueName }).sort({ tokenNumber: -1 });
    const tokenNumber = lastToken ? lastToken.tokenNumber + 1 : 1;

    const estimatedWaitingTime = studentsAhead * 5;

    const token = await Token.create({
      queueName,
      department,
      purpose,
      tokenNumber,
      studentsAhead,
      estimatedWaitingTime,
      status: "waiting",
    });

    res.status(201).json({
      success: true,
      data: token,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};

// 📄 GET CURRENT TOKEN BY QUEUE
exports.getTokensByQueue = async (req, res) => {
  try {
    const { queueName } = req.params;

    const token = await Token.findOne({
      queueName,
      status: "waiting",
    }).sort({ tokenNumber: -1 });

    if (!token) {
      return res.status(404).json({
        success: false,
        message: "No active token found",
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
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};

// ❌ DELETE TOKEN (UPDATED LOGIC)
exports.deleteToken = async (req, res) => {
  try {
    const { queueName, tokenNumber } = req.params;

    // 1️⃣ Find token to delete
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

    // 2️⃣ Update ONLY tokens AFTER the deleted token
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
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};
