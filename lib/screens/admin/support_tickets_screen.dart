
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/ticket.dart';

class SupportTicketsScreen extends StatelessWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Support Tickets'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Open'),
              Tab(text: 'Resolved'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTicketsList(false),
            _buildTicketsList(true),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsList(bool isResolved) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tickets')
          .where('isResolved', isEqualTo: isResolved)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No ${isResolved ? 'resolved' : 'open'} tickets'));
        }

        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            final ticket = Ticket.fromFirestore(document);

            return ListTile(
              title: Text(ticket.subject),
              subtitle: Text(ticket.message),
              trailing: !isResolved
                  ? ElevatedButton(
                      onPressed: () {
                        document.reference.update({'isResolved': true});
                      },
                      child: const Text('Resolve'),
                    )
                  : null,
            );
          }).toList(),
        );
      },
    );
  }
}
