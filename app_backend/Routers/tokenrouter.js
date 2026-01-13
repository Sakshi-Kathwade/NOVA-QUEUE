const express = require("express");
const router = express.Router();
const tokenController = require("../Controllers/tokencontroller");

// Create Token
router.post("/token", tokenController.createToken);

// Get token by queueName & studentId
router.get("/tokenget/:queueName/:studentId", tokenController.getTokenByQueueAndStudent);

// Delete token
router.delete("/tokendelete/:queueName/:tokenNumber", tokenController.deleteToken);

router.get("/getAlltoken/:queueName", tokenController.getAllTokens);

module.exports = router;
