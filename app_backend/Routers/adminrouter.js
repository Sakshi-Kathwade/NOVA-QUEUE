const express = require('express');
const router = express.Router();
const { adminLogin } = require('../Controllers/admincontroller');


router.post('/adminLogin', adminLogin);

module.exports = router;
