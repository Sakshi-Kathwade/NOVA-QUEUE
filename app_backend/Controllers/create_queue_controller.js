const Queue = require("../Models/create_queue_model.js");
const Token = require("../Models/tokenmodel"); 
const QueueHistory = require("../Models/queueHistoryModel");

// CREATE QUEUE CONTROLLER
const createQueue = async (req, res) => {
  try {
    const { adminId, queueName, department, maxStudents, startTime, endTime } =
      req.body;

    // 🔹 Validation
    if (
      !adminId ||
      !queueName ||
      !department ||
      !maxStudents ||
      !startTime ||
      !endTime
    ) {
      return res.status(400).json({
        success: false,
        message: "All fields are required",
      });
    }

    // ✅ System-wide limit: max 2 queues total
    const totalQueues = await Queue.countDocuments();
    if (totalQueues >= 2) {
      return res.status(409).json({
        success: false,
        message: "Already exist two queue. You can not create more queue.",
      });
    }

    // ✅ Per-admin: only one queue per admin
    const existingAdminQueue = await Queue.findOne({ adminId }).sort({
      createdAt: -1,
    });
    if (existingAdminQueue) {
      return res.status(409).json({
        success: false,
        message: "You already have a queue. You can not create another queue.",
      });
    }

    // ✅ Time validation
    const now = new Date();
    const start = new Date(startTime);
    const end = new Date(endTime);

    if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
      return res.status(400).json({
        success: false,
        message: "Invalid start or end time",
      });
    }

    // If admin is creating at 10AM, they cannot set start time to 9AM (past time)
    if (start < now) {
      return res.status(400).json({
        success: false,
        message: "Start time must be current time or future time",
      });
    }

    // End time must be after start time (reject 10AM -> 5AM)
    if (end <= start) {
      return res.status(400).json({
        success: false,
        message: "End time must be after start time",
      });
    }

    // ✅ Enforce max 30 students minimum rule from requirement (cap tokens by this)
    const max = Number(maxStudents);
    if (!Number.isFinite(max) || max <= 0) {
      return res.status(400).json({
        success: false,
        message: "Invalid maxStudents",
      });
    }
    if (max > 30) {
      return res.status(400).json({
        success: false,
        message: "Maximum students allowed is 30",
      });
    }

    // 🔹 Create Queue
    const newQueue = await Queue.create({
      adminId,
      queueName,
      department,
      maxStudents: max,
      startTime: start,
      endTime: end,
    });

    res.status(201).json({
      success: true,
      message: "Queue created successfully",
      data: newQueue,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Server error while creating queue",
    });
  }
};

const getAllQueues = async (req, res) => {
  try {
    const queues = await Queue.find().sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      message: "Queues fetched successfully",
      data: queues,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Server error while fetching queues",
    });
  }
};

async function expireQueueIfNeeded(queueDoc) {
  if (!queueDoc) return null;
  const now = new Date();
  if (queueDoc.status === "Active" && queueDoc.endTime && queueDoc.endTime <= now) {
    // 1️⃣ Copy to History
    await QueueHistory.create({
      adminId: queueDoc.adminId,
      queueName: queueDoc.queueName,
      department: queueDoc.department,
      startTime: queueDoc.startTime,
      endTime: queueDoc.endTime,
      maxStudents: queueDoc.maxStudents,
      status: "Expired",
      discardedAt: now
    });

    // 2️⃣ Delete from Active Queues
    await Queue.findByIdAndDelete(queueDoc._id);

    // 3️⃣ Delete associated tokens (as per existing logic)
    await Token.deleteMany({ queueName: queueDoc.queueName });
    
    return { expired: true };
  }
  return { expired: false };
}

// ✅ GET ACTIVE QUEUE FOR ADMIN (admin sees only their queue)
const getActiveQueue = async (req, res) => {
  try {
    const { adminId } = req.params;
    if (!adminId) {
      return res.status(400).json({
        success: false,
        message: "adminId is required",
      });
    }

    // First, try to find the latest Active queue for this admin
    let activeQueue = await Queue.findOne({ adminId, status: "Active" }).sort({
      createdAt: -1,
    });

    // If no Active queue exists for this admin, get the latest created queue for this admin
    if (!activeQueue) {
      activeQueue = await Queue.findOne({ adminId }).sort({ createdAt: -1 });
    }

    if (!activeQueue) {
      return res.status(404).json({
        success: false,
        message: "No queue found",
        data: null,
      });
    }

    // ✅ Expire queue automatically when end time passed
    const expiry = await expireQueueIfNeeded(activeQueue);
    if (expiry && expiry.expired) {
      return res.status(410).json({
        success: false,
        message: "Queue time is finished",
        data: null,
      });
    }

    res.status(200).json({
      success: true,
      message: "Active queue fetched successfully",
      queueName: activeQueue.queueName,
      data: activeQueue,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Server error while fetching active queue",
    });
  }
};



// UPDATE QUEUE STATUS
const updateQueueStatus = async (req, res) => {
  try {
    const { id } = req.params;        // queue id
    const { status } = req.body;      // Active / Inactive

    // 🔹 Validation
    if (!status) {
      return res.status(400).json({
        success: false,
        message: "Status is required",
      });
    }



    // 🔹 Update status
    const updatedQueue = await Queue.findByIdAndUpdate(
      id,
      { status },
      { new: true } // updated data return
    );

    if (!updatedQueue) {
      return res.status(404).json({
        success: false,
        message: "Queue not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Queue status updated successfully",
      data: updatedQueue,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: "Server error while updating status",
    });
  }
};



module.exports = {
  createQueue,
  getAllQueues,
  updateQueueStatus,
  getActiveQueue,
};
