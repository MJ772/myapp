// lib/screens/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../utils/constants.dart';

import '../customer_submission_screen.dart';
import '../garage_dashboard.dart';
import '../admin/admin_dashboard.dart';
import 'pending_approval_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _nameCtl = TextEditingController();

  static const _visibleRoles = <String, String>{
    'customer' : 'Customer',
    'garage'   : 'Garage / Vendor',
    'chauffeur': 'Chauffeur',
    'courier'  : 'Courier',
  };

  String _role = 'customer';
  bool _loading = false;

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final email = _emailCtl.text.trim();

      // Admin role is hidden: applied automatically if allowlisted
      final effectiveRole = (kAdminEmails.contains(email)) ? 'admin' : _role;

      final cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: _passCtl.text,
        role: effectiveRole,
      );

      final user = cred.user!;
      if (kAdminUids.contains(user.uid)) {
        // Optionally force role=admin in Firestore if you also hard-allowlist by UID
        // await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'role': 'admin'});
      }

      if (effectiveRole == 'admin') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
          (_) => false,
        );
        return;
      }

      if (effectiveRole == 'customer') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CustomerSubmissionScreen()),
          (_) => false,
        );
        return;
      }

      // Garage / Chauffeur / Courier → admin approval required
      final label = _visibleRoles[effectiveRole] ?? 'your account';
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Signup Submitted'),
          content: Text(
            '$label requires manual approval by an administrator before you can use all features.\n\n'
            'We’ll notify you when approved.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          ],
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => PendingApprovalScreen(roleLabel: label)),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showError(_mapFirebaseError(e));
    } catch (e) {
      _showError('Sign up failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      default:
        return 'Authentication error: ${e.message ?? e.code}';
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: _nameCtl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty || !v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passCtl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) {
                    if ((v ?? '').length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(labelText: 'Account Type'),
                  items: _visibleRoles.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => _role = v ?? 'customer'),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _handleSignup,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Sign Up'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
