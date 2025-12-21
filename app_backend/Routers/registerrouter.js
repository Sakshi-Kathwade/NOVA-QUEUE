const express = require('express');
const router = express.Router();
const registerController = require('../Controllers/registercontroller');

// POST /api/register
router.post('/register', registerController.addstudent);

module.exports = router;
