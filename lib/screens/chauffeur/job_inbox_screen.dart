import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobInboxScreen extends StatelessWidget {
  const JobInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final q = FirebaseFirestore.instance
        .collection('users').doc(uid).collection('chauffeur_jobs')
        .where('status', whereIn: ['offer','assigned']).orderBy('createdAt', descending: true);
    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No offers at the moment.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final ref = docs[i].reference;
              final d = docs[i].data();
              final status = d['status'];
              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text('Reservation: ${d['rentalReservationRef']?.toString() ?? '—'}'),
                  subtitle: Text('Status: $status'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (status == 'offer')
                      TextButton(onPressed: () => ref.update({'status': 'accepted'}), child: const Text('Accept')),
                    if (status == 'offer')
                      TextButton(onPressed: () => ref.update({'status': 'declined'}), child: const Text('Decline')),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
