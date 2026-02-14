const express = require('express');
const router = express.Router();
const { loginStudent, resetPassword } = require('../Controllers/logincontroller');

// POST /api/login
router.post('/login', loginStudent);

// POST /api/reset-password
router.post('/reset-password', resetPassword);


module.exports = router;
