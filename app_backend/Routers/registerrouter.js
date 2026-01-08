const express = require('express');
const router = express.Router();

// Import controller correctly
const { addstudent } = require('../Controllers/registercontroller');
const { deleteStudent } = require('../Controllers/registercontroller');
const { changePassword } = require('../Controllers/registercontroller');
const { getStudentById } = require('../Controllers/registercontroller');

// REGISTER USER
router.post('/register', addstudent);

// DELETE USER BY ID
router.delete('/logout/:studentID', deleteStudent);

// 🔐 CHANGE PASSWORD ROUTE
router.put('/changepassword/:studentID', changePassword);

router.get("/studentget/:studentID", getStudentById);


module.exports = router;

