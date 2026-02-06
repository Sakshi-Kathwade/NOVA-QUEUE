const express = require('express');
const router = express.Router();
const { adminLogin, createAdmin, changeAdminPassword, deleteAdmin, getAdminProfile, updateAdminProfile, uploadAdminProfile, getAdminQueueSettings, updateAdminQueueSettings, getReportsSummary, getCounterPerformance, getBusyHours, getQueueHistory, getServices, createService, updateService, deleteService, getCounters, createCounter, updateCounter, deleteCounter, getServiceWiseData, getDailyCrowdDetails } = require('../Controllers/admincontroller');

// Admin Authentication Routes
router.post('/adminLogin', adminLogin);
router.post("/createAdmin", createAdmin);
router.put('/adminchangepassword/:adminId', changeAdminPassword);
router.delete('/deleteadmin/:adminId', deleteAdmin);
router.get('/admin/profile/:adminId', getAdminProfile);
router.put('/admin/profile/:adminId', uploadAdminProfile, updateAdminProfile);

// Admin Reports Routes
router.get('/admin/reports/summary/:adminId', getReportsSummary);
router.get('/admin/reports/counter-performance/:adminId', getCounterPerformance);
router.get('/admin/reports/busy-hours/:adminId', getBusyHours);
router.get('/admin/reports/service-wise/:adminId', getServiceWiseData);
router.get('/admin/reports/daily-crowd/:adminId', getDailyCrowdDetails);

// Admin History Routes
router.get('/admin/history/:adminId', getQueueHistory);

// Admin Settings - Queue Configuration
router.get('/admin/settings/queue/:adminId', getAdminQueueSettings);
router.put('/admin/settings/queue/:adminId', updateAdminQueueSettings);

// Admin Settings - Services Routes
router.get('/admin/settings/services/:adminId', getServices);
router.post('/admin/settings/services/:adminId', createService);
router.put('/admin/settings/services/:serviceId/:adminId', updateService);
router.delete('/admin/settings/services/:serviceId/:adminId', deleteService);

// Admin Settings - Counter Routes
router.get('/admin/settings/counters/:adminId', getCounters);
router.post('/admin/settings/counters/:adminId', createCounter);
router.put('/admin/settings/counters/:counterId/:adminId', updateCounter);
router.delete('/admin/settings/counters/:counterId/:adminId', deleteCounter);

// TODO: Add routes for Staff, Working Hours, Token Limits, Notifications, Queue Rules


module.exports = router;
