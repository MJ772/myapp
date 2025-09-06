import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  final String id;
  final String openedBy;          // <- standardized
  final String subject;
  final String message;
  final bool isResolved;
  final Timestamp createdAt;

  const Ticket({
    required this.id,
    required this.openedBy,
    required this.subject,
    required this.message,
    required this.isResolved,
    required this.createdAt,
  });

  factory Ticket.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Ticket(
      id: doc.id,
      openedBy: data['openedBy'] ?? '',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      isResolved: (data['isResolved'] ?? false) as bool,
      createdAt: (data['createdAt'] ?? Timestamp.now()) as Timestamp,
    );
  }

  Map<String, dynamic> toMap({bool serverTime = false}) => {
    'openedBy': openedBy,
    'subject': subject.trim(),
    'message': message.trim(),
    'isResolved': isResolved,
    'createdAt': serverTime ? FieldValue.serverTimestamp() : createdAt,
  };
}
