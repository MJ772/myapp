
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/screens/garage/manage_services_screen.dart';

class GarageDashboardScreen extends StatelessWidget {
  const GarageDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Garage Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Welcome, Garage Owner!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            _buildDashboardCard(
              context,
              title: 'Open Rentals',
              stream: FirebaseFirestore.instance
                  .collectionGroup('reservations')
                  .where('vendorId', isEqualTo: user.uid)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              icon: Icons.car_rental,
            ),
            const SizedBox(height: 16),
            _buildDashboardCard(
              context,
              title: 'Manage Services',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageServicesScreen()),
                );
              },
              icon: Icons.build,
              count: -1, // No count for this card
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {
    required String title,
    IconData? icon,
    Stream<QuerySnapshot>? stream,
    int count = 0,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: <Widget>[
              if (icon != null)
                Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (stream != null)
                StreamBuilder<QuerySnapshot>(
                  stream: stream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    return Text(
                      snapshot.data!.docs.length.toString(),
                      style: Theme.of(context).textTheme.headlineMedium,
                    );
                  },
                )
              else if (count != -1)
                Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
