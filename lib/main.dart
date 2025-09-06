import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:myapp/firebase_options.dart';
import 'package:myapp/screens/auth/login_screen.dart';
import 'package:myapp/screens/auth/pending_approval_screen.dart';
import 'package:myapp/screens/auth/signup_screen.dart';
import 'package:myapp/screens/admin/admin_dashboard.dart';
import 'package:myapp/screens/placeholder/chauffeur_dashboard.dart';
import 'package:myapp/screens/placeholder/courier_dashboard.dart';
import 'package:myapp/screens/placeholder/customer_submission_screen.dart';
import 'package:myapp/screens/placeholder/support_overview_screen.dart';
import 'package:myapp/screens/vendor/garage_dashboard.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motors App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
      },
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        return FutureBuilder<DocumentSnapshot?>(
          future: AuthService().getUserDoc(snapshot.data!.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.hasData || userSnapshot.data == null || !userSnapshot.data!.exists) {
              return const LoginScreen(); // Should not happen
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final String role = userData['role'];

            Widget pendingOr(Widget screen, bool isApproved) {
              return kBypassRoleApprovals || isApproved
                  ? screen
                  : const PendingApprovalScreen();
            }

            switch (role) {
              case 'admin':
                return const AdminDashboard();
              case 'garage':
                return pendingOr(
                    const GarageDashboard(), userData['vendorApproved']);
              case 'chauffeur':
                return pendingOr(
                    const ChauffeurDashboard(), userData['chauffeurApproved']);
              case 'courier':
                return pendingOr(
                    const CourierDashboard(), userData['courierApproved']);
              case 'support':
                return const SupportOverviewScreen();
              default:
                return const CustomerSubmissionScreen();
            }
          },
        );
      },
    );
  }
}
