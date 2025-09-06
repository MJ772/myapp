import 'package:flutter/material.dart';
import 'package:myapp/screens/auth/login_screen.dart';
import 'package:myapp/screens/auth/signup_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Welcome'), bottom: const TabBar(tabs: [
          Tab(text: 'Login'),
          Tab(text: 'Sign Up'),
        ])),
        body: const TabBarView(
          children: [
            LoginScreen(),
            SignupScreen(),
          ],
        ),
      ),
    );
  }
}
