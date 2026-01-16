const express = require('express');
const router = express.Router();
const { adminLogin, createAdmin, changeAdminPassword, deleteAdmin } = require('../Controllers/admincontroller');

router.post('/adminLogin', adminLogin);
router.post("/createAdmin", createAdmin);
router.put('/adminchangepassword/:adminId', changeAdminPassword);
router.delete('/deleteadmin/:adminId', deleteAdmin);

module.exports = router;
