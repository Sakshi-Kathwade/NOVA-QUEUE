const express = require('express');
const router = express.Router();
const notificationController = require('../Controllers/notificationController');

// Get all notifications for a specific user
router.get('/notifications/:userId', notificationController.getUserNotifications);

// Mark a specific notification as read
router.put('/notifications/:id/read', notificationController.markAsRead);

// Permanently delete a single notification
router.delete('/notifications/:id', notificationController.deleteNotification);

// Permanently delete multiple notifications
router.post('/notifications/delete-multiple', notificationController.deleteMultipleNotifications);
router.delete('/notifications-bulk', notificationController.deleteMultipleNotifications);

// Permanently delete all notifications for a user
router.delete('/notifications/all/:userId', notificationController.clearAllNotifications);

module.exports = router;

