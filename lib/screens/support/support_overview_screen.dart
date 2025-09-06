import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/ticket.dart';
import 'package:myapp/screens/support/create_ticket_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class SupportOverviewScreen extends StatelessWidget {
  const SupportOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please sign in.')));
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final role = (userSnap.data()?.data() ?? const {})['role'] as String?;
        final isSupportOrAdmin = role == 'support' || role == 'admin';

        final query = isSupportOrAdmin
            ? FirebaseFirestore.instance
                .collection('support_tickets')
                .orderBy('createdAt', descending: true)
            : FirebaseFirestore.instance
                .collection('support_tickets')
                .where('openedBy', isEqualTo: uid)
                .orderBy('createdAt', descending: true);

        return Scaffold(
          appBar: AppBar(title: const Text('Support Tickets')),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final tickets = snapshot.data?.docs
                      .map((doc) => Ticket.fromFirestore(doc))
                      .toList() ??
                  const <Ticket>[];

              if (tickets.isEmpty) {
                return const Center(child: Text('No tickets yet.'));
              }

              return ListView.builder(
                itemCount: tickets.length,
                itemBuilder: (context, i) {
                  final t = tickets[i];
                  return ListTile(
                    title: Text(t.subject),
                    subtitle: Text('Opened ${timeago.format(t.createdAt.toDate())}'),
                    trailing: Icon(
                      t.isResolved ? Icons.check_circle : Icons.pending,
                      color: t.isResolved ? Colors.green : Colors.orange,
                    ),
                    onTap: () {
                      // TODO: Push to ticket detail screen
                    },
                  );
                },
              );
            },
          ),
          floatingActionButton: isSupportOrAdmin
              ? null
              : FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
                    );
                  },
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }
}
