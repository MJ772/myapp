import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AvailableJobsScreen extends StatelessWidget {
  const AvailableJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('delivery_jobs')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true);
    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No delivery jobs available.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final ref = docs[i].reference;
              final d = docs[i].data();
              final pickup = (d['pickupAddress'] ?? const {})['postcode'] ?? 'TBC';
              final dropoff = (d['dropoffAddress'] ?? const {})['postcode'] ?? 'TBC';
              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  leading: const Icon(Icons.local_shipping),
                  title: Text('Pickup: ' + pickup),
                  subtitle: Text('Dropoff: ' + dropoff),
                  trailing: Text(d['size']?.toString() ?? 'S'),
                  onTap: () async {
                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    await ref.update({
                      'assignedCourierId': uid,
                      'status': 'assigned',
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
