const express = require('express');
const router = express.Router();
const { adminLogin } = require('../Controllers/admincontroller');
const { createAdmin } = require('../Controllers/admincontroller');


router.post('/adminLogin', adminLogin);
router.post("/createAdmin", createAdmin);

module.exports = router;
