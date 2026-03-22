import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../services/api_config.dart';

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initNotifications(String userId) async {
    // 1. Request Permission (For Android 13+ & iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
      return;
    }

    // 2. Define the High Importance Channel for Pop-Ups
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id (MUST MATCH THE ONE IN ANDROID MANIFEST)
      'High Importance Notifications', // title
      description: 'This channel is used for pop-up notifications.',
      importance: Importance.max, // MAXIMUM importance makes it Pop-Up!
    );

    // Create the channel on the device
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Setup Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Initialize local notifications
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        print("Notification clicked: ${details.payload}");
      },
    );

    // 4. Get FCM Token and save it to backend
    try {
      String? token = await _firebaseMessaging.getToken();

      if (token != null) {
        print("FCM Token: $token");
        await _sendTokenToBackend(userId, token);
      }

      // Listen for Token Refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _sendTokenToBackend(userId, newToken);
      });
    } catch (e) {
      print("Error getting FCM token: $e");
    }

    // 5. FOREGROUND: Manually show Notification Pop-Up
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.data}');

      if (message.notification != null) {
        _localNotifications.show(
          id: message.notification.hashCode,
          title: message.notification!.title,
          body: message.notification!.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max, // Force Pop Up
              priority: Priority.high,    // Force Head-Up
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // 6. BACKGROUND: Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Send Token to Backend
  static Future<void> _sendTokenToBackend(String userId, String token) async {
    try {
      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/fcm-token/$userId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"fcmToken": token}),
      );

      if (response.statusCode == 200) {
        print("FCM Token updated on server");
      } else {
        print("Failed to update FCM Token: ${response.body}");
      }
    } catch (e) {
      print("Error sending FCM token: $e");
    }
  }
}
