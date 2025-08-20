import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/firebase_options.dart';
import 'package:myapp/screens/auth_screen.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Keep this import for Firestore
import 'package:myapp/screens/garage_dashboard.dart';
import 'package:cloud_functions/cloud_functions.dart'; // Keep this import for Functions
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:myapp/screens/customer_submission_screen.dart';
import 'package:myapp/screens/repair_request_details_screen.dart';
import 'package:flutter/foundation.dart'; // Comment out Firebase Messaging import

// Comment out the background message handler
/*
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {\
  await Firebase.initializeApp();\
  if (kDebugMode) {\
    debugPrint("Handling a background message: ${message.messageId}");\
  }\
}*/

// Global instance of FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Global key for navigator state
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    // Temporarily disable App Check for debugging with emulators as the compatible version
    // of firebase_app_check does not support AndroidProvider.none.
    /*
    await FirebaseAppCheck.instance.activate(
        // Set to none to disable App Check in debug builds
        androidProvider: AndroidProvider.none,
        // You can do the same for web if needed, though it might not be the cause of the current issue
        // webProvider: ReCaptchaV3Provider('YOUR_RECAPTCHA_SITE_KEY'), // Replace with your key if needed later
        // appleProvider: AppleProvider.appAttest, // Or .deviceCheck, .none
    ); */

    // Connect to Firebase emulators
    try {
      // Ensure you use the correct Firestore port from your emulator logs (8080 or 8082)
      FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
      // Use the correct Auth port from your emulator logs (usually 9099)
      await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
      // Use the correct Functions port from your emulator logs (usually 5001 or 5002)
      FirebaseFunctions.instance.useFunctionsEmulator('10.0.2.2', 5002); // This line is correctly placed and configured
      debugPrint('Connected to Firebase Emulators.');

      // *** Add the call to the new function here within the emulator block ***
       await _ensureGarageUserDataExists(); // Call the function to create user data if needed

    } catch (e) {
      // Catching exceptions for emulators that might not be running
      debugPrint('Error connecting to Firebase emulators: $e');
    }
  }
  // Commented out AppLinks initialization and handling
  /*
  // Initialize AppLinks
  final appLinks = AppLinks();

  // Define a helper function to handle deep links
  Future<void> handleDeepLink(Uri uri) async {
    if (kDebugMode) {
      debugPrint('Received deep link: $uri');
    }

    // Handle Stripe Connect redirect
    if (uri.scheme == 'MotorsApp' && uri.path == '/stripe-connect-redirect') {
      if (kDebugMode) {
        debugPrint('Handling Stripe Connect redirect');
      }
      final status = uri.queryParameters['status'];
      final accountId = uri.queryParameters['account_id'];

      if (kDebugMode) {
        debugPrint('Stripe status: $status, Account ID: $accountId');
      }

      if (status == 'success' && accountId != null) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .update({'stripeConnectedAccountId': accountId});
            if (kDebugMode) {
              debugPrint('Stripe onboarding successful, user profile updated.');
            }

            navigatorKey.currentState?.pushNamedAndRemoveUntil(
                '/garageDashboard', (Route<dynamic> route) => false);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error updating user profile: $e');
            }
          }
        } else {
          if (kDebugMode) {
            debugPrint('User not authenticated, cannot update profile with Stripe account ID');
          }
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/auth', (Route<dynamic> route) => false);
        }
      } else {
        if (kDebugMode) {
          debugPrint('Stripe onboarding not successful or accountId missing.');
        }
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/garageDashboard', (Route<dynamic> route) => false);
      }
    }
  }

  // Handle initial link (when app is terminated)
  final initialUri = await appLinks.getInitialLink();
  if (initialUri != null) {
    handleDeepLink(initialUri);
  }

  // Handle incoming links (when app is running)
  appLinks.uriLinks.listen(handleDeepLink);
  */

  // Comment out Firebase Messaging Initialization and handling
/*
  // Initialize Firebase Messaging\
  final fcmToken = await FirebaseMessaging.instance.getToken();\
  if (kDebugMode) {\
    debugPrint('FCM Token: $fcmToken');\
  }\

  // Request permission for notifications\
  await FirebaseMessaging.instance.requestPermission(\
    alert: true,\
    announcement: false,\
    badge: true,\
    carPlay: false,\
    criticalAlert: false,\
    provisional: false,\
    sound: true,\
  );\

  // Initialize Flutter Local Notifications\
  const AndroidInitializationSettings initializationSettingsAndroid =\
      AndroidInitializationSettings('@mipmap/ic_launcher');\
  const InitializationSettings initializationSettings =\
      InitializationSettings(android: initializationSettingsAndroid);\
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);\

  // Create a notification channel (for Android O and above)\
  const AndroidNotificationChannel channel = AndroidNotificationChannel(\
    'high_importance_channel',\
    'High Importance Notifications',\
    description: 'This channel is used for important notifications.',\
    importance: Importance.max,\
  );\
  await flutterLocalNotificationsPlugin\
      .resolvePlatformSpecificImplementation<\
          AndroidFlutterLocalNotificationsPlugin>()\
      ?.createNotificationChannel(channel);\

  // Handle notification taps when the app is terminated\
  final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();\
  if (initialMessage != null) {\
    if (initialMessage.data['screen'] == 'details' && initialMessage.data['requestId'] != null) {\
      Future.delayed(const Duration(milliseconds: 100), () {\
        navigatorKey.currentState?.pushNamed('/repairRequestDetails', \
            arguments: initialMessage.data['requestId']);\
      });\
    }\
  }\

  // Handle messages while the app is in the foreground\
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {\
    if (kDebugMode) {\
      debugPrint('Got a message whilst in the foreground!');\
      debugPrint('Message data: ${message.data}');\
    }\

    if (message.notification != null) {\
      if (kDebugMode) {\
        debugPrint('Message also contained a notification: ${message.notification}');\
      }\

      // Display local notification\
      flutterLocalNotificationsPlugin.show(\
        message.notification.hashCode,
        message.notification?.title,
        message.notification?.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  });

  // Handle interaction when the app is in the background or terminated\
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {\
    if (kDebugMode) {\
      debugPrint('A new onMessageOpenedApp event was published!');\
      debugPrint('Message data: ${message.data}');\
    }\
    if (message.data['screen'] == 'details' && message.data['requestId'] != null) {\
      navigatorKey.currentState?.pushNamed('/repairRequestDetails', \
          arguments: message.data['requestId']);\
    }\
  });\

  // Register the background handler\
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);\
*/

  runApp(const MyApp());
}

// Function to ensure the garage user's document exists in Firestore during debug with emulators
// This function is only called when kDebugMode is true.
Future<void> _ensureGarageUserDataExists() async {
  final user = FirebaseAuth.instance.currentUser;
  // Check if the user is authenticated and we are in debug mode
  if (user != null && kDebugMode) {
    final userId = user.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    try {
      final docSnapshot = await userRef.get();

      if (!docSnapshot.exists) {
        // Document doesn't exist, create it with the default garage role
        final userData = {
          'role': 'garage',
          'createdAt': FieldValue.serverTimestamp(),
          // Add any other default fields your app expects for a new garage user
          // For example: displayName: 'Garage User', photoURL: '...', etc.
        };
        await userRef.set(userData, SetOptions(merge: true));
        debugPrint('Created default garage user document for UID: $userId in Firestore emulator.');
      } else {
        // Document exists, check if it has the 'role' field
        final userData = docSnapshot.data();
        if (userData != null && !userData.containsKey('role')) {
           // Add the 'role' field if missing
           await userRef.set({'role': 'garage'}, SetOptions(merge: true));
           debugPrint('Added missing role field to user document for UID: $userId in Firestore emulator.');
        } else {
           // Check if the existing role is 'garage'
           final existingRole = userData?['role'];
           if (existingRole != 'garage') {
             debugPrint('User document exists for UID: $userId, but role is not garage. Role: $existingRole');
             // Optionally update the role to 'garage' if it's something else in debug
             // await userRef.update({'role': 'garage'});
             // debugPrint('Updated user role to garage for UID: $userId in Firestore emulator.');
           } else {
             debugPrint('Garage user document exists and has a role for UID: $userId in Firestore emulator.');
           }
        }
      }
    } catch (e) {
      debugPrint('Error ensuring garage user data exists: $e');
    }
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Motors App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/garageDashboard': (context) => const GarageDashboard(),
        '/repairRequestDetails': (context) => RepairRequestDetailsScreen(
              requestId: ModalRoute.of(context)!.settings.arguments as String,
            ),
      },
      debugShowCheckedModeBanner: false,
      home: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (userSnapshot.hasError) {
                return Center(child: Text('Error loading user data: ${userSnapshot.error}'));
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>?; // Make userData nullable
                if (userData != null) { // Check if userData is not null
                  final role = userData['role'];
                  if (role == 'garage') {
                    return const GarageDashboard();
                  } else {
                    // If role is not garage or missing, potentially navigate to a default screen
                    // or a screen indicating an issue with user role.
                    // For now, let's default to CustomerSubmissionScreen if role is not 'garage'
                     debugPrint('User has data but role is not garage or missing. Role: $role'); // Log the role
                    return const CustomerSubmissionScreen();
                  }
                } else {
                   // Log if userSnapshot has data and exists, but data() returns null (unlikely but for robustness)
                  debugPrint('User data exists but data() returned null.');
                  return const CustomerSubmissionScreen();
                }
              } else {
                // Log if the user document does not exist
                debugPrint('User document does not exist for UID: ${user.uid}');
                 return const CustomerSubmissionScreen();
              }

            },
          );
        }

        return const AuthScreen();
      },
    );
  }
}
