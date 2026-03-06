const Queue = require("../Models/create_queue_model.js");
const Token = require("../Models/tokenmodel"); 
const QueueHistory = require("../Models/queueHistoryModel");
const CompletedHistoryToken = require("../Models/completedHistoryTokenModel");
const PendingHistoryToken = require("../Models/pendingHistoryTokenModel");
const { syncQueueRealTime } = require("../utils/queueRealTimeSync");

    // ✅ Expire Queue Logic
async function expireQueueIfNeeded(queueDoc) {
  try {
      if (!queueDoc) return null;
      const now = new Date();
      
      const isTimeUp = queueDoc.endTime && queueDoc.endTime <= now;
      const isStatusExpired = queueDoc.status === "Expired";

      if (isTimeUp || isStatusExpired) {
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

        // 2️⃣ Archive Tokens
        const allTokens = await Token.find({ queueName: queueDoc.queueName });
        const completedTokens = [];
        const pendingTokens = [];

        for (const token of allTokens) {
          const tokenData = token.toObject();
          tokenData.originalTokenId = token._id;
          delete tokenData._id; // Let Mongo generate new ID for history
          tokenData.archivedAt = now;

          if (token.status === 'completed' || token.status === 'Completed') {
            completedTokens.push(tokenData);
          } else {
            // Any other status -> Pending History
            tokenData.status = 'pending';
            tokenData.pendingAt = now;
            pendingTokens.push(tokenData);
          }
        }

        if (completedTokens.length > 0) {
          await CompletedHistoryToken.insertMany(completedTokens);
        }
        if (pendingTokens.length > 0) {
          await PendingHistoryToken.insertMany(pendingTokens);
        }

        // 3️⃣ DELETE Queue from active database AND Delete Tokens
        await Queue.findByIdAndDelete(queueDoc._id);
        await Token.deleteMany({ queueName: queueDoc.queueName });

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

    // ✅ FORCE CLEANUP: Ensure NO leftover ghost tokens for this admin or queueName exists 
    // This absolutely guarantees that the newly created queue will start at token #1
    await Token.deleteMany({ queueName });

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
        if (mongoose.Types.ObjectId.isValid(adminId)) {
             oid = new mongoose.Types.ObjectId(adminId);
        } else {
             oid = adminId;
        }
    } catch(e) {
        oid = adminId;
    }

    // 1️⃣ Try to find ACTIVE queue
    let activeQueue = await Queue.findOne({ 
        adminId: oid
    }).sort({ createdAt: -1 });

    if (activeQueue) {
        await syncQueueRealTime(activeQueue.queueName);
        
        // Check expiry
        const now = new Date();
        const endTime = activeQueue.endTime ? new Date(activeQueue.endTime) : null;
        
        // Expiry logic
        const isTimeUp = endTime && endTime <= now;
        const isStatusExpired = activeQueue.status === "Expired";

        if (isTimeUp || isStatusExpired) {
            // Check if within 30 hours of expiry
            // If we don't have endTime (e.g. status forced expired), use updatedAt or createdAt?
            // Fallback to createdAt if endTime missing
            const referenceTime = endTime || activeQueue.updatedAt || activeQueue.createdAt;
            const hoursSinceExpiry = (now - referenceTime) / (1000 * 60 * 60);

            if (hoursSinceExpiry > 30) {
                 // > 30 hours: Force Expire and Return NULL
                 await expireQueueIfNeeded(activeQueue);
                 return res.status(200).json({
                    success: false,
                    message: "Queue expired and archived",
                    data: null
                 });
            } else {
                 // < 30 hours: Return queue but mark as 'Closed' for UI if previously Active
                 // Do NOT expire fully yet (keep in DB for viewing)
                 // But wait, if we don't expire it, tokens remain in 'Token' collection.
                 // This is GOOD for "Pending Box" visibility.
                 
                 // However, we should probably update status to 'Inactive' or 'Closed' if not already
                 if (activeQueue.status === 'Active') {
                      activeQueue.status = 'Closed';
                      await activeQueue.save(); 
                 }
                 
                 return res.status(200).json({
                    success: true,
                    message: "Queue finished (view only)",
                    queueName: activeQueue.queueName,
                    data: activeQueue,
                });
            }
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

    // 2️⃣ If NO active queue, look in HISTORY?
    // The request said: "after finishing queue... for 30 hours... then pending empty".
    // This implies we look at the one we just finished.
    // If we already archived it, we can't show "pending" easily (unless we query PendingHistoryToken).
    // Better to KEEP it in Queue collection for 30h.

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
