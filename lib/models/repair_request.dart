import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/bid.dart'; // Assuming bid.dart will be created

class RepairRequest {
  final String id;
  final String userId;
  final String description;
  final List<String> photoUrls;
  final GeoPoint location;
  final String status;
  final DateTime createdAt;
  final String? garageId;
  final List<Bid>? bids;
  final Bid? acceptedBid;
  final bool isReviewed;

  RepairRequest({
    required this.id,
    required this.userId,
    required this.description,
    required this.photoUrls,
    required this.location,
    required this.status,
    required this.createdAt,
    this.garageId,
    this.acceptedBid,
    this.bids,
    this.isReviewed = false,
  });

factory RepairRequest.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RepairRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      description: data['description'] ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      location: data['location'] ?? const GeoPoint(0, 0),
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      garageId: data['garageId'] as String?,
      bids: (data['bids'] as List<dynamic>?)
              ?.map((bidData) => Bid.fromMap(bidData as Map<String, dynamic>)) // Assuming Bid has fromMap
              .toList() ??
          [], // Provide empty list if 'bids' is null or empty
      acceptedBid: (data['acceptedBid'] as Map<String, dynamic>?) != null
          ? Bid.fromMap(data['acceptedBid'] as Map<String, dynamic>) : null,
      isReviewed: data['isReviewed'] ?? false,
    );
  }


  // Optional: Method to convert to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'description': description,
      'photoUrls': photoUrls,
      'location': location,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'garageId': garageId,
      'bids': bids?.map((bid) => bid.toMap()).toList(), // Assuming Bid has a toMap method
      'acceptedBid': acceptedBid?.toMap(), // Assuming Bid has a toMap method
      'isReviewed': isReviewed,
    };
  }
}