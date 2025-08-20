import 'package:flutter_test/flutter_test.dart';

class Bid {
  final String id;
  final String requestId;
  final String garageId;
  final double price;
  final String availability;
  final String status;

  Bid({
    required this.id,
    required this.requestId,
    required this.garageId,
    required this.price,
    required this.availability,
    required this.status,
  });
}

class GarageService {
  final String id;
  final String garageId;
  final String title;
  final double price; // This will represent the minimum price
  final String duration;

  GarageService({
    required this.id,
    required this.garageId,
    required this.title,
    required this.price,
    required this.duration,
  });
}

// Assuming you have a service or function to fetch the garage's minimum price
// For testing purposes, we'll use a mock function.
Future<double> getGarageMinimumPrice(String garageId, String serviceId) async {
  // In a real application, this would fetch data from Firestore or a backend.
  // For this test, we'll simulate fetching a minimum price.
  if (garageId == 'garage1' && serviceId == 'service1') {
    return 50.0; // Example minimum price for service1 by garage1
  }
  if (garageId == 'garage2' && serviceId == 'service2') {
    return 100.0; // Example minimum price for service2 by garage2
  }
  return 0.0; // Default or error case
}

// Function to validate a bid
Future<bool> isValidBid(Bid bid, String serviceId) async {
  final minimumPrice = await getGarageMinimumPrice(bid.garageId, serviceId);
  return bid.price >= minimumPrice;
}

void main() {
  group('Bid Validation Tests', () {
    test('should return true if bid price is greater than minimum price', () async {
      final bid = Bid(
        id: 'bid1',
        requestId: 'request1',
        garageId: 'garage1',
        price: 75.0,
        availability: 'Tomorrow',
        status: 'pending',
      );
      final serviceId = 'service1'; // Corresponds to garage1's service with min price 50.0

      final isValid = await isValidBid(bid, serviceId);

      expect(isValid, isTrue);
    });

    test('should return true if bid price is equal to minimum price', () async {
      final bid = Bid(
        id: 'bid2',
        requestId: 'request2',
        garageId: 'garage1',
        price: 50.0,
        availability: 'Today',
        status: 'pending',
      );
      final serviceId = 'service1'; // Corresponds to garage1's service with min price 50.0

      final isValid = await isValidBid(bid, serviceId);

      expect(isValid, isTrue);
    });

    test('should return false if bid price is less than minimum price', () async {
      final bid = Bid(
        id: 'bid3',
        requestId: 'request3',
        garageId: 'garage2',
        price: 90.0,
        availability: 'Next Week',
        status: 'pending',
      );
      final serviceId = 'service2'; // Corresponds to garage2's service with min price 100.0

      final isValid = await isValidBid(bid, serviceId);

      expect(isValid, isFalse);
    });

    test('should handle different garages and services correctly', () async {
      final bid = Bid(
        id: 'bid4',
        requestId: 'request4',
        garageId: 'garage2',
        price: 150.0,
        availability: 'Tomorrow',
        status: 'pending',
      );
      final serviceId = 'service2'; // Corresponds to garage2's service with min price 100.0

      final isValid = await isValidBid(bid, serviceId);

      expect(isValid, isTrue);
    });
  });
}