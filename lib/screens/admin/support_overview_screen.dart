import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupportOverviewScreen extends StatelessWidget {
  const SupportOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('support_tickets')
        .orderBy('createdAt', descending: true)
        .limit(50);
    return Scaffold(
      appBar: AppBar(title: const Text('Support Queue')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No tickets'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final ref = docs[i].reference;
              final d = docs[i].data();
              return ListTile(
                leading: const Icon(Icons.support_agent),
                title: Text(d['targetType'] ?? 'ticket'),
                subtitle: Text('Status: ' + (d['status'] ?? 'open')),
                trailing: TextButton(
                  onPressed: () => ref.update({'status': 'assigned'}),
                  child: const Text('Take'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
