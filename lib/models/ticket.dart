
import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  final String id;
  final String userId;
  final String subject;
  final String message;
  final bool isResolved;
  final Timestamp createdAt;

  Ticket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.message,
    this.isResolved = false,
    required this.createdAt,
  });

  factory Ticket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('Missing ticket data for document ${doc.id}');
    }
    return Ticket(
      id: doc.id,
      userId: data['userId'] ?? '',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      isResolved: data['isResolved'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'subject': subject,
      'message': message,
      'isResolved': isResolved,
      'createdAt': createdAt,
    };
  }
}
