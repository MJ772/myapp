
import 'package:flutter/material.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Approval')),
      body: const Center(
        child: Text(
            'Your account is pending approval. You will be notified once it is approved.'),
      ),
    );
  }
}
