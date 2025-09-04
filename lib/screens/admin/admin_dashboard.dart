
import 'package:flutter/material.dart';
import 'package:myapp/screens/admin/approval_screen.dart';
import 'package:myapp/screens/admin/blacklist_screen.dart';
import 'package:myapp/screens/admin/support_tickets_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ApprovalScreen()),
                );
              },
              child: const Text('Approve Users'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BlacklistScreen()),
                );
              },
              child: const Text('Blacklist Users'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SupportTicketsScreen()),
                );
              },
              child: const Text('Support Tickets'),
            ),
          ],
        ),
      ),
    );
  }
}
