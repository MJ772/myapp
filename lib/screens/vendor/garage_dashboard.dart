
import 'package:flutter/material.dart';
import 'package:myapp/screens/vendor/rentals/my_rentals_screen.dart';
import 'package:myapp/screens/vendor/map_view_screen.dart';

class GarageDashboard extends StatelessWidget {
  const GarageDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garage Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings screen
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: <Widget>[
            _buildDashboardCard(
              context,
              icon: Icons.map,
              label: 'Open Requests',
              count: '5', // Dummy data
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapViewScreen()),
                );
              },
            ),
            _buildDashboardCard(
              context,
              icon: Icons.directions_car,
              label: 'My Rentals',
              count: '12', // Dummy data
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyRentalsScreen()),
                );
              },
            ),
            _buildDashboardCard(
              context,
              icon: Icons.attach_money,
              label: 'Earnings',
              count: '\$1,250', // Dummy data
              onTap: () {
                // TODO: Navigate to earnings screen
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required IconData icon, required String label, required String count, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 50, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              count,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
