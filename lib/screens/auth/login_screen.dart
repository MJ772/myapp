// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../utils/constants.dart';

import '../customer_submission_screen.dart';
import '../garage_dashboard.dart';
import '../admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  bool _loading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final cred = await auth.signInWithEmailAndPassword(
        email: _emailCtl.text.trim(),
        password: _passCtl.text,
      );

      final user = cred.user!;
      String? role = await auth.getUserRole(user.uid);

      if (kAdminEmails.contains(user.email) || kAdminUids.contains(user.uid)) {
        role = 'admin';
      }

      if (role == 'admin') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
          (_) => false,
        );
      } else if (role == 'garage') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const GarageDashboard()),
          (_) => false,
        );
      } else {
        // default → customer (chauffeur/courier support pending screens can be added later)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CustomerSubmissionScreen()),
          (_) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(_mapFirebaseError(e));
    } catch (e) {
      _showError('Login failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return 'No user found for that email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'invalid-email':  return 'Invalid email address.';
      default:               return 'Authentication error: ${e.message ?? e.code}';
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: _emailCtl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passCtl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => ((v ?? '').length < 6) ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _handleLogin,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Log In'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  child: const Text('Need an account? Sign up'),
                  onPressed: () => Navigator.of(context).pushNamed('/signup'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
