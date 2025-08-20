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
  final List<Bid> bids;
  final Bid? acceptedBid;

  RepairRequest({
    required this.id,
    required this.userId,
    required this.description,
    required this.photoUrls,
    required this.location,
    required this.status,
    required this.createdAt,
    required this.acceptedBid,
    required this.bids,
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
      bids: (data['bids'] as List<dynamic>?)
              ?.map((bidData) => Bid.fromMap(bidData as Map<String, dynamic>)) // Assuming Bid has fromMap
              .toList() ??
          [], // Provide empty list if 'bids' is null or empty
      acceptedBid: (data['acceptedBid'] as Map<String, dynamic>?) != null
          ? Bid.fromMap(data['acceptedBid'] as Map<String, dynamic>) : null,
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
      'bids': bids.map((bid) => bid.toMap()).toList(), // Assuming Bid has a toMap method
      'acceptedBid': acceptedBid?.toMap(), // Assuming Bid has a toMap method
    };
  }
}