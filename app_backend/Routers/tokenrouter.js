const express = require("express");
const router = express.Router();

const {
  createToken,
  getTokensByQueue,
   deleteToken
} = require("../Controllers/tokencontroller");

// 🎫 TAKE TOKEN
router.post("/token", createToken);

// 📄 GET TOKENS BY QUEUE NAME
router.get("/tokenget/:queueName", getTokensByQueue);

router.delete("/tokendelete/:queueName/:tokenNumber", deleteToken);



module.exports = router;
