
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/ticket.dart';
import 'package:myapp/screens/support/create_ticket_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class SupportOverviewScreen extends StatelessWidget {
  const SupportOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Tickets'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('support_tickets')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No support tickets found.'));
          }

          final tickets = snapshot.data!.docs
              .map((doc) => Ticket.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return ListTile(
                title: Text(ticket.subject),
                subtitle: Text(
                    'Opened ${timeago.format(ticket.createdAt.toDate())}'),
                trailing: Icon(
                  ticket.isResolved ? Icons.check_circle : Icons.pending,
                  color: ticket.isResolved ? Colors.green : Colors.orange,
                ),
                onTap: () {
                  // TODO: Navigate to ticket details screen
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTicketScreen()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Create Ticket',
      ),
    );
  }
}
