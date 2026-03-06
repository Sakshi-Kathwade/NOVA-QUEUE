const Queue = require("../Models/create_queue_model");
const Admin = require("../Models/adminmodel");
const Token = require("../Models/tokenmodel");

async function syncQueueRealTime(queueName) {
    try {
        const queue = await Queue.findOne({ queueName });
        if (!queue || queue.status !== "Active" || !queue.startTime) return queue;

        const admin = await Admin.findById(queue.adminId);
        let estimatedTime = admin ? (admin.estimatedServiceTimePerStudent || 5) : 5;

        let now = new Date();
        // If passed end time, lock it to end time
        if (queue.endTime && now > queue.endTime) {
            now = new Date(queue.endTime);
        }

        let start = new Date(queue.startTime);
        if (now < start) return queue; // Not started yet

        // Handle break time
        let breakStartTimeStr = admin ? admin.breakStartTime : null;
        let breakEndTimeStr = admin ? admin.breakEndTime : null;
        
        let breakStart = null;
        let breakEnd = null;

        if (breakStartTimeStr && breakEndTimeStr) {
            let [bStartH, bStartM] = breakStartTimeStr.split(':').map(Number);
            let [bEndH, bEndM] = breakEndTimeStr.split(':').map(Number);
            
            breakStart = new Date(start);
            breakStart.setHours(bStartH, bStartM, 0, 0);
            
            breakEnd = new Date(start);
            breakEnd.setHours(bEndH, bEndM, 0, 0);
        }

        // Calculate effective elapsed minutes from start to now
        let totalElapsedMs = now - start;
        let elapsedMinutes = totalElapsedMs / 60000;
        
        let breakMinutesToSubtract = 0;
        let isCurrentlyInBreak = false;

        if (breakStart && breakEnd) {
            let overlapStart = start > breakStart ? start : breakStart;
            let overlapEnd = now < breakEnd ? now : breakEnd;
            if (overlapEnd > overlapStart) {
                breakMinutesToSubtract = (overlapEnd - overlapStart) / 60000;
            }

            // check if 'now' is within the break time
            if (now >= breakStart && now < breakEnd) {
                isCurrentlyInBreak = true;
            }
        }
        
        let effectiveMinutes = elapsedMinutes - breakMinutesToSubtract;
        if (effectiveMinutes < 0) effectiveMinutes = 0;

        // Current serving token calculation
        let tokensFinished = Math.floor(effectiveMinutes / estimatedTime);
        let currentServingTokenNumber = tokensFinished + 1;

        // Ensure we don't exceed max tokens possible
        if (queue.maxStudents && currentServingTokenNumber > queue.maxStudents) {
             currentServingTokenNumber = queue.maxStudents;
        }

        // 1. Mark tokens strictly less than currentServingTokenNumber as completed
        await Token.updateMany(
            { 
               queueName: queue.queueName, 
               tokenNumber: { $lt: currentServingTokenNumber }, 
               status: { $in: ["waiting", "serving", "pending", "hold"] } 
            },
            { $set: { status: "completed", completedAt: new Date() } }
        );

        // 2. Mark the current token as serving if not in break, or waiting if in break
        let currentStatus = isCurrentlyInBreak ? "waiting" : "serving"; 
        
        // Let's actually keep the token updated
        await Token.updateOne(
            { queueName: queue.queueName, tokenNumber: currentServingTokenNumber },
            { $set: { status: currentStatus, lastCalledAt: new Date() } }
        );
        
        // Also update queue.currentTurn if we have that field
        await Queue.updateOne({ _id: queue._id }, { $set: { currentTurn: currentServingTokenNumber } });

        return queue;
    } catch (e) {
        console.error("Error in syncQueueRealTime:", e);
        return null; // silently continue
    }
}

module.exports = { syncQueueRealTime };
