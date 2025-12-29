const Queue = require("../Models/create_queue_model.js");

// CREATE QUEUE CONTROLLER
const createQueue = async (req, res) => {
  try {
    const { queueName, department, maxStudents, startTime, endTime,  } = req.body;

    // 🔹 Validation
    if (!queueName || !department || !maxStudents || !startTime || !endTime ) {
      return res.status(400).json({
        success: false,
        message: "All fields are required",
      });
    }

    // 🔹 Create Queue
    const newQueue = await Queue.create({
      queueName,
      department,
      maxStudents,
      startTime,
      endTime,
        
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
};
