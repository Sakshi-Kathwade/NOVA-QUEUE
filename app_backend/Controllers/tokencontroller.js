const Token = require("../Models/tokenmodel");

const TIME_PER_STUDENT = 5; // minutes

// 🎫 CREATE TOKEN (JOIN QUEUE)
exports.createToken = async (req, res) => {
  try {
    const { queueName, department, purpose } = req.body;

    // 🔴 VALIDATION
    if (!queueName || !purpose) {
      return res.status(400).json({
        success: false,
        message: "Queue name and purpose are required",
      });
    }

    // 🔢 AUTO TOKEN NUMBER (per queue)
    const lastToken = await Token.findOne({ queueName })
      .sort({ tokenNumber: -1 });

    const nextTokenNumber = lastToken ? lastToken.tokenNumber + 1 : 1;

    // 👥 COUNT STUDENTS AHEAD (only waiting)
    const studentsAhead = await Token.countDocuments({
      queueName,
      status: "waiting",
    });

    // ⏳ ESTIMATED WAITING TIME
    const estimatedWaitingTime = studentsAhead * TIME_PER_STUDENT;

    // ✅ CREATE TOKEN
    const token = await Token.create({
      queueName,
      department,
      purpose,
      tokenNumber: nextTokenNumber,
      studentsAhead,
      estimatedWaitingTime,
    });

    res.status(201).json({
      success: true,
      message: "Token created successfully",
      data: token,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

// 📄 GET TOKENS BY QUEUE (recalculate live)
exports.getTokensByQueue = async (req, res) => {
  try {
    const { queueName } = req.params;

    const tokens = await Token.find({ queueName }).sort({ tokenNumber: 1 });

    // 🔁 UPDATE studentsAhead & estimated time dynamically
    let waitingCount = 0;

    const updatedTokens = await Promise.all(
      tokens.map(async (token) => {
        if (token.status === "waiting") {
          const updated = await Token.findByIdAndUpdate(
            token._id,
            {
              studentsAhead: waitingCount,
              estimatedWaitingTime: waitingCount * TIME_PER_STUDENT,
            },
            { new: true }
          );
          waitingCount++;
          return updated;
        }
        return token;
      })
    );

    res.status(200).json({
      success: true,
      data: updatedTokens,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server error",
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

    res.status(200).json({
      success: true,
      message: "Token deleted successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Server error",
    });
  }
};
