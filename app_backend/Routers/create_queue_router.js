const express = require("express");
const router = express.Router();

const { createQueue, getAllQueues, updateQueueStatus, getActiveQueue } = require("../Controllers/create_queue_controller.js");

// Routes

router.post("/createqueue", createQueue);
router.get("/queue", getAllQueues);
router.get("/activequeue", getActiveQueue); // ✅ New endpoint for active queue
router.put("/queuestatus/:id", updateQueueStatus);

module.exports = router;
