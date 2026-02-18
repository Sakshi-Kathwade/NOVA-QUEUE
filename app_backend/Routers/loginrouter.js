const express = require('express');
const router = express.Router();
const { loginStudent, resetPassword, forgotPassword } = require('../Controllers/logincontroller');
 
// POST /api/login
router.post('/login', loginStudent);

// POST /api/reset-password
router.post('/reset-password', resetPassword);

// POST /api/forgot-password
router.post('/forgot-password', forgotPassword);


module.exports = router;
