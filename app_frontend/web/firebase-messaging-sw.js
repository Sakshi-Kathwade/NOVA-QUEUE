importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

// Initialize Firebase in the service worker
firebase.initializeApp({
  apiKey: "AIzaSyBLOr8XON3i-lMJYkDQH79XWgfb5jxJDOU",
  authDomain: "smartqueuemanagemnt.firebaseapp.com",
  projectId: "smartqueuemanagemnt",
  storageBucket: "smartqueuemanagemnt.firebasestorage.app",
  messagingSenderId: "924772821592",
  appId: "YOUR_WEB_APP_ID"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification ? payload.notification.title : 'Nova Queue Notification';
  const notificationOptions = {
    body: payload.notification ? payload.notification.body : '',
    icon: '/favicon.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
