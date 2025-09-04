
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BlacklistScreen extends StatefulWidget {
  const BlacklistScreen({super.key});

  @override
  State<BlacklistScreen> createState() => _BlacklistScreenState();
}

class _BlacklistScreenState extends State<BlacklistScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Blacklist Users'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All Users'),
              Tab(text: 'Blacklisted'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAllUsersList(),
            _buildBlacklistedUsersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAllUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            final data = document.data()! as Map<String, dynamic>;
            final isBlacklisted = data['isBlacklisted'] ?? false;

            return ListTile(
              title: Text(data['email'] ?? ''),
              subtitle: Text(data['role'] ?? ''),
              trailing: IconButton(
                icon: Icon(
                  Icons.block, 
                  color: isBlacklisted ? Colors.red : Colors.grey,
                ),
                onPressed: () {
                  document.reference.update({'isBlacklisted': !isBlacklisted});
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBlacklistedUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('isBlacklisted', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No blacklisted users'));
        }

        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            final data = document.data()! as Map<String, dynamic>;

            return ListTile(
              title: Text(data['email'] ?? ''),
              subtitle: Text(data['role'] ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.block, color: Colors.red),
                onPressed: () {
                  document.reference.update({'isBlacklisted': false});
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
