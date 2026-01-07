const express = require('express');
const router = express.Router();

// Import controller correctly
const { addstudent } = require('../Controllers/registercontroller');
const { deleteStudent } = require('../Controllers/registercontroller');
const { changePassword } = require('../Controllers/registercontroller');

// REGISTER USER
router.post('/register', addstudent);

// DELETE USER BY ID
router.delete('/logout/:studentID', deleteStudent);

// 🔐 CHANGE PASSWORD ROUTE
router.put('/changepassword/:studentID', changePassword);

module.exports = router;

