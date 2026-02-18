
const admin = require('firebase-admin');

// 🔴 IMPORTANT: You need to replace this with your actual Service Account Key JSON
// If not present, notifications will be skipped.
let serviceAccount;
try {
  // Try to load from a file if it exists, otherwise use a placeholder or env vars
  serviceAccount = require('../serviceAccountKey.json');
} catch (e) {
  console.log("⚠️ Firebase Service Account Key not found. Notifications will be disabled until configured.");
}

if (serviceAccount) {
  try {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
      console.log("✅ Firebase Admin Initialized");
  } catch(e) {
      console.log("❌ Error initializing Firebase Admin: ", e.message);
  }
}

/**
 * Send a push notification to a specific device token
 * @param {string} fcmToken - The device token
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} data - Optional data payload
 */
exports.sendNotification = async (fcmToken, title, body, data = {}) => {
  if (!serviceAccount || !fcmToken) {
     if(!fcmToken) console.log("⚠️ No FCM Token provided for notification");
     return;
  }

  const message = {
    notification: {
      title: title,
      body: body,
    },
    data: data, // Custom data
    token: fcmToken,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('✅ Notification sent successfully:', response);
  } catch (error) {
    console.error('❌ Error sending notification:', error);
  }
};
