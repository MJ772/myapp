
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    // Request permission from the user
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Get the device token
    final String? token = await _firebaseMessaging.getToken();
    developer.log('Firebase Messaging Token: $token', name: 'com.example.myapp.fcm');

    // Save the token to Firestore for the current user
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    // Listen for token refreshes
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

    // Handle incoming messages while the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('Got a message whilst in the foreground!', name: 'com.example.myapp.fcm');
      developer.log('Message data: ${message.data}', name: 'com.example.myapp.fcm');

      if (message.notification != null) {
        developer.log('Message also contained a notification: ${message.notification}', name: 'com.example.myapp.fcm');
        // Here you could display a local notification using a package like flutter_local_notifications
      }
    });

    // Handle messages that are opened from a terminated state
     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('A new onMessageOpenedApp event was published!', name: 'com.example.myapp.fcm');
      // You can navigate to a specific screen based on the message data
    });
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'fcmTokens': FieldValue.arrayUnion([token]),
        });
        developer.log('FCM token saved to Firestore.', name: 'com.example.myapp.fcm');
      } catch (e) {
        developer.log('Error saving FCM token: $e', name: 'com.example.myapp.fcm');
      }
    }
  }
}

// Handler for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log("Handling a background message: ${message.messageId}", name: 'com.example.myapp.fcm');
}
