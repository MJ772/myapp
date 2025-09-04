
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
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapViewScreen()),
                );
              },
              child: const Text('View Open Requests'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyRentalsScreen()),
                );
              },
              child: const Text('My Rentals'),
            ),
          ],
        ),
      ),
    );
  }
}
