
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedDevData() async {
  final db = FirebaseFirestore.instance;
  final now = FieldValue.serverTimestamp();

  // Rental
  final rentRef = db.collection('rentals').doc();
  await rentRef.set({
    'vendorId': 'TEST_VENDOR',
    'vehicle': {'make': 'VW', 'model': 'Golf'},
    'pricePerDay': 45,
    'type': 'selfDrive',
    'createdAt': now,
  });

  // Delivery job
  final jobRef = db.collection('delivery_jobs').doc();
  await jobRef.set({
    'status': 'open',
    'pickupAddress': {'postcode': 'E1'},
    'dropoffAddress': {'postcode': 'SW1'},
    'size': 'M',
    'vendorId': 'TEST_VENDOR',
    'customerId': 'TEST_CUSTOMER',
    'createdAt': now,
  });

  // Support ticket
  final ticketRef = db.collection('support_tickets').doc();
  await ticketRef.set({
    'openedBy': 'TEST_CUSTOMER',
    'targetType': 'rental',
    'status': 'open',
    'createdAt': now,
  });
}
