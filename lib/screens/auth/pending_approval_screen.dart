// lib/screens/auth/pending_approval_screen.dart
import 'package:flutter/material.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key, this.roleLabel = 'your account'});
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Approval')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_top, size: 64),
              const SizedBox(height: 16),
              Text('Thanks for signing up!', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                'An administrator needs to approve $roleLabel before you can use all features.\n'
                'We’ll notify you once it’s ready.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
