import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AvailabilityEditorScreen extends StatelessWidget {
  const AvailabilityEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('availability');

    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: col.orderBy('start').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No availability slots. Tap + to add.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data();
              final start = (d['start'] as Timestamp?)?.toDate();
              final end = (d['end'] as Timestamp?)?.toDate();
              return ListTile(
                leading: const Icon(Icons.event_available),
                title: Text('Slot: ${start ?? '-'} → ${end ?? '-'}}'),
                subtitle: Text(d['source']?.toString() ?? 'manual'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => docs[i].reference.delete(),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final now = DateTime.now();
          final start = DateTime(now.year, now.month, now.day, now.hour + 1);
          final end = start.add(const Duration(hours: 2));
          await col.add({'start': start, 'end': end, 'source': 'manual'});
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
