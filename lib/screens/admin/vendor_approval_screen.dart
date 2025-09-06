import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VendorApprovalScreen extends StatefulWidget {
  const VendorApprovalScreen({super.key});

  @override
  State<VendorApprovalScreen> createState() => _VendorApprovalScreenState();
}

class _VendorApprovalScreenState extends State<VendorApprovalScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Approvals'),
      bottom: TabBar(controller: _tab, tabs: const [
        Tab(text: 'Vendors'),
        Tab(text: 'Chauffeurs'),
        Tab(text: 'Couriers'),
      ]),
    ),
    body: TabBarView(controller: _tab, children: const [
      _RoleList(role: 'garage', flag: 'vendorApproved', label: 'Vendor'),
      _RoleList(role: 'chauffeur', flag: 'chauffeurApproved', label: 'Chauffeur'),
      _RoleList(role: 'courier', flag: 'courierApproved', label: 'Courier'),
    ]),
  );
}

class _RoleList extends StatelessWidget {
  const _RoleList({required this.role, required this.flag, required this.label});
  final String role;
  final String flag;
  final String label;

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: role)
        .where(flag, isEqualTo: false);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return Center(child: Text('No pending $label approvals'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final ref = docs[i].reference;
            final d = docs[i].data();
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(d['displayName'] ?? d['email'] ?? 'User'),
              subtitle: Text('Email: ' + (d['email'] ?? '')),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                TextButton(onPressed: () => ref.update({flag: true}), child: const Text('Approve')),
                TextButton(onPressed: () => ref.delete(), child: const Text('Reject')),
              ]),
            );
          },
        );
      },
    );
  }
}
