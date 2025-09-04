
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/service.dart';
import 'package:myapp/models/repair_request.dart';
import 'package:myapp/models/bid.dart';

class RepairRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<RepairRequest> getRepairRequestById(String requestId) async {
    try {
      final doc = await _firestore.collection('repair_requests').doc(requestId).get();
      if (!doc.exists) {
        throw Exception('Repair request with ID $requestId not found.');
      }
      return RepairRequest.fromDocument(doc);
    } catch (e) {
      debugPrint('Error fetching repair request by ID: $e');
      rethrow;
    }
  }

  Stream<RepairRequest> getRepairRequestStream(String requestId) {
    return _firestore
        .collection('repair_requests')
        .doc(requestId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        throw Exception('Repair request with ID $requestId not found.');
      }
      return RepairRequest.fromDocument(doc);
    });
  }

  Future<void> submitRequest({
    required String userId,
    required String description,
    required List<String> photoUrls,
    required Position location,
  }) async {
    try {
      await _firestore.collection('repair_requests').add({
        'userId': userId,
        'description': description,
        'photoUrls': photoUrls,
        'location': GeoPoint(location.latitude, location.longitude),
        'status': 'open',
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error creating repair request: $e');
      rethrow;
    }
  }

  Stream<List<RepairRequest>> fetchRepairRequests() {
    return _firestore.collection('repair_requests').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => RepairRequest.fromDocument(doc))
          .toList();
    });
  }

  Future<void> addBid({
    required String requestId,
    required String garageId,
    required double price,
    required String availability,
  }) async {
    try {
      await _firestore.collection('repair_requests').doc(requestId).collection('bids').add({
        'garageId': garageId,
        'price': price,
        'availability': availability,
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'requestId': requestId,
      });
    } catch (e) {
      debugPrint('Error adding bid: $e');
      rethrow;
    }
  }

  Future<void> acceptBid({
    required String requestId,
    required String bidId,
  }) async {
    try {
      await _firestore.collection('repair_requests').doc(requestId).collection('bids').doc(bidId).update({
        'status': 'accepted',
      });
    } catch (e) {
      debugPrint('Error accepting bid: $e');
      rethrow;
    }
  }

  Stream<List<Bid>> fetchBidsForRequest(String requestId) {
    return _firestore
        .collection('repair_requests')
        .doc(requestId)
        .collection('bids')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map<Bid>((doc) => Bid.fromDocumentSnapshot(doc)).toList();
    });
  }

  Stream<QuerySnapshot> getBidsForRequest(String requestId) {
    return _firestore
        .collection('repair_requests')
        .doc(requestId)
        .collection('bids')
        .orderBy('price')
        .snapshots();
  }

  Stream<List<Bid>> fetchBidsByGarageId(String garageId) {
    return _firestore
        .collectionGroup('bids')
        .where('garageId', isEqualTo: garageId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Bid.fromDocumentSnapshot(doc)).toList();
    });
  }

  Future<void> addService({
    required String garageId,
    required String title,
    required double price,
    required String duration,
  }) async {
    try {
      await _firestore.collection('services').add({
        'garageId': garageId,
        'title': title,
        'price': price,
        'duration': duration,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error adding service: $e');
      rethrow;
    }
  }

  Stream<List<Service>> fetchServicesByGarageId(String garageId) {
    return _firestore
        .collection('services')
        .where('garageId', isEqualTo: garageId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Service.fromDocument(doc)).toList();
    });
  }

  Future<void> updateService({
    required String serviceId,
    required String title,
    required double price,
    required String duration,
  }) async {
    try {
      await _firestore.collection('services').doc(serviceId).update({
        'title': title,
        'price': price,
        'duration': duration,
      });
    } catch (e) {
      debugPrint('Error updating service: $e');
      rethrow;
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await _firestore.collection('services').doc(serviceId).delete();
    } catch (e) {
      debugPrint('Error deleting service: $e');
      rethrow;
    }
  }
}
