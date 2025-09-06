
import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id;
  final String rentalId;
  final String customerId;
  final String vendorId; // Ensure this is here
  final String status;
  final Timestamp startDate;
  final Timestamp endDate;
  final bool agreedToTerms;
  final bool agreedToContract;
  final Map<String, dynamic> chauffeurAssignment;

  const Reservation({
    required this.id,
    required this.rentalId,
    required this.customerId,
    required this.vendorId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.agreedToTerms,
    required this.agreedToContract,
    this.chauffeurAssignment = const {},
  });

  factory Reservation.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Reservation(
      id: doc.id,
      rentalId: doc.reference.parent.parent?.id ?? '', // Get from path
      customerId: data['customerId'] ?? '',
      vendorId: data['vendorId'] ?? '',
      status: data['status'] ?? 'pending',
      startDate: data['startDate'] ?? Timestamp.now(),
      endDate: data['endDate'] ?? Timestamp.now(),
      agreedToTerms: data['agreedToTerms'] ?? false,
      agreedToContract: data['agreedToContract'] ?? false,
      chauffeurAssignment: data['chauffeurAssignment'] is Map ? Map<String, dynamic>.from(data['chauffeurAssignment']) : {},
    );
  }

  Map<String, dynamic> toMap({bool serverTime = false}) => {
    'customerId': customerId,
    'vendorId': vendorId, // Ensure this is saved
    'status': status,
    'startDate': startDate,
    'endDate': endDate,
    'agreedToTerms': agreedToTerms,
    'agreedToContract': agreedToContract,
    if (serverTime) 'createdAt': FieldValue.serverTimestamp(),
    if (chauffeurAssignment.isNotEmpty) 'chauffeurAssignment': chauffeurAssignment,
  };
}
