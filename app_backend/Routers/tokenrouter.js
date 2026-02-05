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
router.get("/student/history/:studentId", tokenController.getStudentHistory);

// ✅ Token Actions
router.put("/completetoken", tokenController.completeToken);
router.put("/holdtoken", tokenController.holdToken);
router.put("/unholdtoken", tokenController.unholdToken);
router.put("/nexttoken", tokenController.nextToken);
router.put("/markmissedtoken", tokenController.markTokenMissed);
router.get("/heldtokens/:queueName", tokenController.getHeldTokens);
router.get("/completedtoday/:queueName", tokenController.getCompletedToday);

// ✅ Pending & Approval Routes
router.get("/pendingtokens/:queueName", tokenController.getPendingTokens);
router.get("/student/pending/:studentId", tokenController.getPendingTokensForStudent);
router.put("/approvetoken", tokenController.approveToken);
router.put("/rejecttoken", tokenController.rejectToken);

module.exports = router;
