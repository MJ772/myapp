import 'package:flutter/material.dart';
import 'package:myapp/screens/courier/available_jobs_screen.dart';

class CourierDashboard extends StatelessWidget {
  const CourierDashboard({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 1,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Courier'),
        bottom: const TabBar(tabs: [ Tab(text: 'Available') ]),
      ),
      body: const TabBarView(children: [ AvailableJobsScreen() ]),
    ),
  );
}
