import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String garageId;
  final String title;
  final double price;
  final String duration;

  Service({
    required this.id,
    required this.garageId,
    required this.title,
    required this.price,
    required this.duration,
  });

  // Factory constructor for creating a Service from a Firestore document
  factory Service.fromDocument(DocumentSnapshot doc) {
   final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('Missing service data for document ${doc.id}');
    }
    
    return Service(
      id: doc.id,
      garageId: data['garageId'] ?? '',
      title: data['title'] ?? '',
      price: (data['price'] ?? 0).toDouble(), // Ensure price is double
      duration: data['duration'] ?? '',
    );
  }

  // Method to convert a Service to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'garageId': garageId,
      'title': title,
      'price': price,
      'duration': duration,
    };
  }
}