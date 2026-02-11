const express = require('express');
const router = express.Router();
const { loginStudent } = require('../Controllers/logincontroller');

// POST /api/login
router.post('/login', loginStudent);


module.exports = router;
module.exports = router;
