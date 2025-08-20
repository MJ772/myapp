import 'package:cloud_firestore/cloud_firestore.dart';

class Bid {
  final String id;
  final String requestId;
  final String garageId;
  final double price;
  final String availability;
  final String status; // e.g., 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  Bid({
    required this.id,
    required this.requestId,
    required this.garageId,
    required this.price,
    required this.availability,
    required this.status,
    required this.createdAt,
  });

  // From Firestore DocumentSnapshot
  factory Bid.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Bid(
      id: doc.id,
      requestId: data['requestId'] as String,
      garageId: data['garageId'] as String,
      price: (data['price'] as num).toDouble(),
      availability: data['availability'] as String,
      status: data['status'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // From Map (for nested data in RepairRequest)
  factory Bid.fromMap(Map<String, dynamic> map) {
    return Bid(
      id: map['id'] as String,
      requestId: map['requestId'] as String,
      garageId: map['garageId'] as String,
      price: (map['price'] as num).toDouble(),
      availability: map['availability'] as String,
      status: map['status'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Map (for Firestore operations)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestId': requestId,
      'garageId': garageId,
      'price': price,
      'availability': availability,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}