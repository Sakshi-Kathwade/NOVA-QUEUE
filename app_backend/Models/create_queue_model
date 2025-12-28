const mongoose = require("mongoose");

const QueueSchema = new mongoose.Schema({
  queueName: { type: String, required: true },
  department: { type: String, required: true },
  startTime: { type: Date, required: true }, // exact start timestamp
  endTime : { type: Date, required: true }, // exact end timestamp
  maxStudents: { type: Number, required: true },
   status: {
      type: String,
      enum: ["Active", "Inactive"],
      default: "Active", }
});

module.exports = mongoose.model("CreateQueue", QueueSchema);


  