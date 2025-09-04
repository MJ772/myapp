
import 'package:flutter/material.dart';
import 'package:myapp/screens/customer/rentals/rental_list_screen.dart';
import 'package:myapp/screens/customer/customer_submission_screen.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CustomerSubmissionScreen()),
                );
              },
              child: const Text('My Repair Requests'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RentalListScreen()),
                );
              },
              child: const Text('Rent a Car'),
            ),
          ],
        ),
      ),
    );
  }
}
