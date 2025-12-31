const express = require("express");
const router = express.Router();

const {
  createToken,
  getTokensByQueue,
  deleteToken,
} = require("../Controllers/tokencontroller");

router.post("/token", createToken);
router.get("/tokenget/:queueName", getTokensByQueue);
router.delete("/tokendelete/:queueName/:tokenNumber", deleteToken);

module.exports = router;
