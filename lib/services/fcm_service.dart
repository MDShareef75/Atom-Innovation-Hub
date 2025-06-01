import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initFCM() async {
    if (!kIsWeb) {
      // Initialize local notifications
      const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettingsIOS = DarwinInitializationSettings();
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      await _localNotifications.initialize(initializationSettings);

      // Request permissions
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('User granted permission: [32m[1m[4m[7m${settings.authorizationStatus}[0m');

      // Get FCM token
      String? token = await _fcm.getToken();

      if (token != null) {
        print('FCM Token: $token');
        await saveTokenToFirestore(token);
      }

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        print('FCM Token refreshed: $newToken');
        saveTokenToFirestore(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
          _showLocalNotification(message);
        }
      });

      // Handle when app is opened from terminated state
      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          print('App opened from terminated state with message: ${message.messageId}');
          // Handle the message as needed
        }
      });

      // Handle when app is in background and opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App opened from background state with message: ${message.messageId}');
        // Handle the message as needed
      });
    } else {
      print('FCM is not supported on web. Skipping FCM initialization.');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  Future<void> saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // First check if the user document exists
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        
        if (!userDoc.exists) {
          // Create the user document if it doesn't exist
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
          print('Created new user document with FCM token for user: ${user.uid}');
        } else {
          // Update existing user document
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });
          print('Updated FCM token for existing user: ${user.uid}');
        }
        
        // Verify the token was saved correctly
        await verifyTokenStorage(user.uid, token);
      } catch (e) {
        print('Error saving FCM token to Firestore: $e');
        rethrow;
      }
    } else {
      print('No user logged in, cannot save FCM token');
    }
  }

  // Method to verify token storage
  Future<bool> verifyTokenStorage(String userId, String expectedToken) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        print('Error: User document not found for verification');
        return false;
      }

      final storedToken = userDoc.data()?['fcmToken'] as String?;
      final lastUpdate = userDoc.data()?['lastTokenUpdate'] as Timestamp?;

      if (storedToken == null) {
        print('Error: No FCM token found in user document');
        return false;
      }

      if (storedToken != expectedToken) {
        print('Error: Stored token does not match expected token');
        print('Stored: $storedToken');
        print('Expected: $expectedToken');
        return false;
      }

      print('Token verification successful:');
      print('User ID: $userId');
      print('Token: $storedToken');
      print('Last Updated: ${lastUpdate?.toDate()}');
      return true;
    } catch (e) {
      print('Error verifying token storage: $e');
      return false;
    }
  }

  // Method to get all users with FCM tokens
  Future<List<Map<String, dynamic>>> getAllUsersWithTokens() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('fcmToken', isNotEqualTo: null)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'fcmToken': data['fcmToken'],
          'lastTokenUpdate': data['lastTokenUpdate'],
        };
      }).toList();
    } catch (e) {
      print('Error getting users with tokens: $e');
      return [];
    }
  }

  // Method to check if current user has a valid token
  Future<bool> checkCurrentUserToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in');
      return false;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final storedToken = userDoc.data()?['fcmToken'] as String?;
      final currentToken = await _fcm.getToken();

      if (storedToken == null) {
        print('No token found for current user');
        return false;
      }

      if (storedToken != currentToken) {
        print('Stored token is different from current token');
        print('Stored: $storedToken');
        print('Current: $currentToken');
        return false;
      }

      print('Current user has valid token: $storedToken');
      return true;
    } catch (e) {
      print('Error checking current user token: $e');
      return false;
    }
  }

  // Method to send a test notification
  Future<void> sendTestNotification() async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Test Notification',
        'body': 'This is a test notification',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'test',
      });
      print('Test notification sent');
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }

  // Method to send notification to all users
  Future<void> sendNotificationToAllUsers({
    required String title,
    required String body,
    required String type,
    String? contentId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Get all users with FCM tokens
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('fcmToken', isNull: false)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        print('No users found with FCM tokens');
        return;
      }

      // Create notification document
      final notificationRef = await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'body': body,
        'type': type,
        'contentId': contentId,
        'additionalData': additionalData,
        'timestamp': FieldValue.serverTimestamp(),
        'sentTo': usersSnapshot.docs.length,
      });

      // Send to each user
      for (var userDoc in usersSnapshot.docs) {
        final fcmToken = userDoc.data()['fcmToken'] as String;
        if (fcmToken.isNotEmpty) {
          // Add user-specific notification
          await FirebaseFirestore.instance.collection('notifications').add({
            'title': title,
            'body': body,
            'type': type,
            'contentId': contentId,
            'additionalData': additionalData,
            'timestamp': FieldValue.serverTimestamp(),
            'userId': userDoc.id,
            'isRead': false,
            'parentNotificationId': notificationRef.id,
          });
        }
      }

      print('Notification sent to ${usersSnapshot.docs.length} users');
    } catch (e) {
      print('Error sending notification to all users: $e');
      rethrow;
    }
  }
} 