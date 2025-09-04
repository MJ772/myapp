
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RentalCheckoutScreen extends StatefulWidget {
  final String rentalId;

  const RentalCheckoutScreen({super.key, required this.rentalId});

  @override
  State<RentalCheckoutScreen> createState() => _RentalCheckoutScreenState();
}

class _RentalCheckoutScreenState extends State<RentalCheckoutScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rental Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(_startDate?.toIso8601String() ?? 'Select Date'),
              onTap: () => _selectDate(context, true),
            ),
            ListTile(
              title: const Text('End Date'),
              subtitle: Text(_endDate?.toIso8601String() ?? 'Select Date'),
              onTap: () => _selectDate(context, false),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_startDate != null && _endDate != null) {
                  final rentalRef = FirebaseFirestore.instance
                      .collection('rentals')
                      .doc(widget.rentalId);
                  final rentalDoc = await rentalRef.get();
                  final rentalData = rentalDoc.data()!;

                  final booking = {
                    'startDate': _startDate,
                    'endDate': _endDate,
                    'price': rentalData['pricePerDay'] *
                        _endDate!.difference(_startDate!).inDays,
                    'userId': FirebaseAuth.instance.currentUser!.uid,
                  };

                  await rentalRef.collection('bookings').add(booking);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking successful')),
                  );

                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              },
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
