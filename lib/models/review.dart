
import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final double rating;
  final String comment;
  final String customerId;
  final String garageId;
  final Timestamp timestamp;

  Review({
    required this.id,
    required this.rating,
    required this.comment,
    required this.customerId,
    required this.garageId,
    required this.timestamp,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      rating: data['rating'] as double,
      comment: data['comment'] as String,
      customerId: data['customerId'] as String,
      garageId: data['garageId'] as String,
      timestamp: data['timestamp'] as Timestamp,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rating': rating,
      'comment': comment,
      'customerId': customerId,
      'garageId': garageId,
      'timestamp': timestamp,
    };
  }
}
