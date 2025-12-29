const express = require("express");
const router = express.Router();

const { createQueue } = require("../Controllers/create_queue_controller.js");
const { getAllQueues } = require("../Controllers/create_queue_controller.js"); 
const { updateQueueStatus } = require("../Controllers/create_queue_controller.js");


// Routes

router.post("/createqueue", createQueue);
router.get("/queue", getAllQueues);    
router.put("/queuestatus/:id", updateQueueStatus);
  

module.exports = router;
