
import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  final String id;
  final String userId;
  final String subject;
  final String message;
  final bool isResolved;

  Ticket({required this.id, required this.userId, required this.subject, required this.message, this.isResolved = false});

  factory Ticket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Ticket(
      id: doc.id,
      userId: data['userId'] ?? '',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      isResolved: data['isResolved'] ?? false,
    );
  }
}
