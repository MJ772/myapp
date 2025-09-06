import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RentalDetailScreen extends StatelessWidget {
  final String rentalId;
  const RentalDetailScreen({super.key, required this.rentalId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rental Details')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('rentals').doc(rentalId).get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Rental not found'));
          }
          final data = snap.data!.data()!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(data['title'] ?? 'Vehicle', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Price per day: £${(data['pricePerDay'] ?? 0).toString()}'),
              const SizedBox(height: 8),
              Text('Make: ${data['make'] ?? '-'}  Model: ${data['model'] ?? '-'}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to checkout with this rentalId
                },
                child: const Text('Book now'),
              )
            ],
          );
        },
      ),
    );
  }
}
