const express = require("express");
const router = express.Router();
const tokenController = require("../Controllers/tokencontroller");

// Create Token
router.post("/token", tokenController.createToken);

// Get token by queueName & studentId
router.get("/tokenget/:queueName/:studentId", tokenController.getTokenByQueueAndStudent);

// Delete token
router.delete("/tokendelete/:queueName/:tokenNumber", tokenController.deleteToken);

router.get(
  "/currenttoken/:queueName",
  tokenController.getCurrentToken
);

router.get(
  "/remainingtoken/:queueName",
  tokenController.getRemainingStudents
);

// ✅ Token Actions
router.put("/completetoken", tokenController.completeToken);
router.put("/holdtoken", tokenController.holdToken);
router.put("/unholdtoken", tokenController.unholdToken);
router.put("/nexttoken", tokenController.nextToken);
router.get("/heldtokens/:queueName", tokenController.getHeldTokens);
router.get("/completedtokens", tokenController.getCompletedTokens);

module.exports = router;
