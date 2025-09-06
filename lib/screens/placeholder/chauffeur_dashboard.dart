import 'package:flutter/material.dart';
import 'package:myapp/screens/chauffeur/availability_editor_screen.dart';
import 'package:myapp/screens/chauffeur/job_inbox_screen.dart';

class ChauffeurDashboard extends StatelessWidget {
  const ChauffeurDashboard({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Chauffeur'),
        bottom: const TabBar(tabs: [
          Tab(text: 'Inbox'),
          Tab(text: 'Availability'),
        ]),
      ),
      body: const TabBarView(children: [
        JobInboxScreen(),
        AvailabilityEditorScreen(),
      ]),
    ),
  );
}
