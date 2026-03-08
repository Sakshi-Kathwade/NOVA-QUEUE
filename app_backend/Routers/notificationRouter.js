const express = require('express');
const router = express.Router();
const notificationController = require('../Controllers/notificationController');

// Get all notifications for a specific user
router.get('/notifications/:userId', notificationController.getUserNotifications);

// Mark a specific notification as read
router.put('/notifications/:id/read', notificationController.markAsRead);

module.exports = router;
