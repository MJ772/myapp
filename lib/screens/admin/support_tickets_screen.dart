import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/ticket.dart';

class SupportTicketsScreen extends StatelessWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Support Tickets')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('support_tickets')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? const [];
          final tickets = docs.map((d) => Ticket.fromFirestore(d)).toList();

          if (tickets.isEmpty) {
            return const Center(child: Text('No tickets'));
          }

          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (_, i) {
              final t = tickets[i];
              return ListTile(
                title: Text(t.subject),
                subtitle: Text(t.openedBy),
                trailing: Icon(
                  t.isResolved ? Icons.check_circle : Icons.pending,
                  color: t.isResolved ? Colors.green : Colors.orange,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
