const Queue = require("../Models/create_queue_model");
const Admin = require("../Models/adminmodel");
const Token = require("../Models/tokenmodel");

async function syncQueueRealTime(queueName) {
    try {
        const queue = await Queue.findOne({ queueName });
        // We no longer auto-move tokens based on estimated time.
        // Tokens must be manually completed by the admin.
        return queue;
    } catch (e) {
        console.error("Error in syncQueueRealTime:", e);
        return null; // silently continue
    }
}

module.exports = { syncQueueRealTime };
