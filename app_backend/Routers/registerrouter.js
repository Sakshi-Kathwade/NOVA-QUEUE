const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Configure Multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadPath = path.join(__dirname, '../uploads/student_profiles');
    fs.mkdirSync(uploadPath, { recursive: true }); // Ensure directory exists
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    const id = req.params.studentID || 'new_register';
    cb(null, `${id}_${Date.now()}${path.extname(file.originalname)}`);
  },
});

const upload = multer({ storage }).single('profilePicture');

// Import controller correctly
const { addstudent, deleteStudent, changePassword, getStudentProfile, updateStudentProfile, uploadStudentProfilePicture, registerWithGoogle } = require('../Controllers/registercontroller');

// REGISTER USER
router.post('/register', upload, addstudent);

// REGISTER USER WITH GOOGLE OAUTH
router.post('/register/google', registerWithGoogle);

// DELETE USER BY ID
router.delete('/logout/:studentID', deleteStudent);

// 🔐 CHANGE PASSWORD ROUTE
router.put('/changepassword/:studentID', changePassword);

// STUDENT PROFILE ROUTES
router.get("/student/profile/:studentID", getStudentProfile);
router.put("/student/profile/:studentID", upload, updateStudentProfile);
router.post("/student/profile/picture/:studentID", upload, uploadStudentProfilePicture);

module.exports = router;
