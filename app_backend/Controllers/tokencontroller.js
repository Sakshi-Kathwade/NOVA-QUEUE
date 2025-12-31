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

    // Count waiting students
    const studentsAhead = await Token.countDocuments({
      queueName,
      status: "waiting",
    });

    // Generate token number
    const lastToken = await Token.findOne({ queueName }).sort({ tokenNumber: -1 });
    const tokenNumber = lastToken ? lastToken.tokenNumber + 1 : 1;

    // Calculate waiting time
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
// ❌ DELETE TOKEN
exports.deleteToken = async (req, res) => {
  try {
    const { queueName, tokenNumber } = req.params;

    const deletedToken = await Token.findOneAndDelete({
      queueName,
      tokenNumber,
    });

    if (!deletedToken) {
      return res.status(404).json({
        success: false,
        message: "Token not found",
      });
    }

    // Recalculate remaining tokens
    const tokens = await Token.find({
      queueName,
      status: "waiting",
    }).sort({ tokenNumber: 1 });

    for (let i = 0; i < tokens.length; i++) {
      await Token.findByIdAndUpdate(tokens[i]._id, {
        studentsAhead: i,
        estimatedWaitingTime: i * 5,
      });
    }

    res.status(200).json({
      success: true,
      message: "Token deleted & queue updated",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};



