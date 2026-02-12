const Queue = require("../Models/create_queue_model.js");
const Token = require("../Models/tokenmodel"); 
const QueueHistory = require("../Models/queueHistoryModel");

// ✅ Expire Queue Logic
async function expireQueueIfNeeded(queueDoc) {
  try {
      if (!queueDoc) return null;
      const now = new Date();
      
      // Check if actually expired OR already marked expired but lingering
      const isTimeUp = queueDoc.endTime && queueDoc.endTime <= now;
      const isStatusExpired = queueDoc.status === "Expired";

      if (queueDoc.status === "Active" && isTimeUp) {
        console.log(`Expiring queue: ${queueDoc.queueName} (End: ${queueDoc.endTime}, Now: ${now})`);
        
        // 1️⃣ Copy to Queue History
        const historyExists = await QueueHistory.findOne({ queueName: queueDoc.queueName, adminId: queueDoc.adminId });
        if (!historyExists) {
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
        }

        // 2️⃣ Update waiting tokens to pending
        await Token.updateMany(
          { queueName: queueDoc.queueName, status: { $in: ["waiting", "hold"] } },
          { $set: { status: "pending", pendingAt: now } }
        );

        // 3️⃣ DELETE Queue from active database
        await Queue.findByIdAndDelete(queueDoc._id);

        return { expired: true, queueName: queueDoc.queueName };

      } else if (isStatusExpired || isTimeUp) {
          // Cleanup lingering expired queues
           const historyExists = await QueueHistory.findOne({ queueName: queueDoc.queueName, adminId: queueDoc.adminId });
           if (!historyExists) {
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
           }
           await Queue.findByIdAndDelete(queueDoc._id);
           return { expired: true, queueName: queueDoc.queueName };
      }

      return { expired: false };
  } catch(e) {
      console.error("Error in expireQueueIfNeeded:", e);
      return { expired: false, error: e };
  }
}

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

    // ✅ CLEANUP: Check ALL existing queues for expiry BEFORE checking limits
    const allQueues = await Queue.find({});
    for (const q of allQueues) {
        await expireQueueIfNeeded(q);
    }

    // ✅ System-wide limit: max 2 queues total (Count ONLY active ones now)
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

    if (end <= now) {
         return res.status(400).json({
           success: false,
           message: "End time must be in the future",
         });
    }

    if (end <= start) {
      return res.status(400).json({
        success: false,
        message: "End time must be after start time",
      });
    }

    // ✅ Enforce max 30 students minimum rule
    const max = Number(maxStudents);
    if (!Number.isFinite(max) || max <= 0) {
      return res.status(400).json({
        success: false,
        message: "Invalid maxStudents",
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

// ✅ GET ACTIVE QUEUE FOR ADMIN (with History Fallback)
const getActiveQueue = async (req, res) => {
  try {
    const { adminId } = req.params;
    if (!adminId) {
      return res.status(400).json({ success: false, message: "adminId is required" });
    }

    // Ensure adminId is ObjectId
    const mongoose = require("mongoose");
    let oid;
    try {
        oid = new mongoose.Types.ObjectId(adminId);
    } catch(e) {
        oid = adminId;
    }

    // 1️⃣ Try to find ACTIVE queue
    let activeQueue = await Queue.findOne({ 
        adminId: oid, 
        status: "Active" 
    }).sort({ createdAt: -1 });

    // Fallback: Check expired but not yet processed (if applicable)
     if (activeQueue) {
        // Check expiry
        const expiry = await expireQueueIfNeeded(activeQueue);
        if (expiry && expiry.expired) {
            // ✅ If expired, return NULL (No Active Queue), do NOT return history
             return res.status(200).json({
                success: false,
                message: "Queue expired",
                data: null
             });
        } else {
            // Active and valid
            return res.status(200).json({
                success: true,
                message: "Active queue fetched successfully",
                queueName: activeQueue.queueName,
                data: activeQueue,
            });
        }
    }

    // 2️⃣ If NO active queue, return null (Dashboard should show "No Active Queue")
    return res.status(200).json({
        success: false,
        message: "No queue found",
        data: null,
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: "Server error while fetching active queue" });
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
