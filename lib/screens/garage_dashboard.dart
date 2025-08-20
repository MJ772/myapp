import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart'; // Keep this import
import 'package:url_launcher/url_launcher.dart';
import 'package:myapp/services/repair_request_service.dart';
import 'package:myapp/models/repair_request.dart';

class GarageDashboard extends StatefulWidget {
  const GarageDashboard({super.key});

  @override
  State<GarageDashboard> createState() => _GarageDashboardState();
}

class _GarageDashboardState extends State<GarageDashboard> {
  final LatLng _garageLocation = const LatLng(51.5074, -0.1278);
  final RepairRequestService _repairRequestService = RepairRequestService();
  final double _searchRadius = 10.0;

  double _calculateDistance(LatLng point1, LatLng point2) {
    const R = 6371;
    final lat1 = point1.latitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLon = (point2.longitude - point1.longitude) * pi / 180;

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Garage Dashboard')),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseAuth.instance.currentUser != null
                ? FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .snapshots()
                : Stream.empty(),
            builder: (context, snapshot) {
              bool showButton = true;

              if (snapshot.hasData && snapshot.data!.exists) {
                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                if (userData != null) {
                  final stripeAccountId = userData['stripeConnectedAccountId'];
                  if (stripeAccountId != null && stripeAccountId.isNotEmpty) {
                    showButton = false;
                  }
                }
              }

              return Visibility(
                visible: showButton,
                child: ElevatedButton(
                  onPressed: () => _connectStripeAccount(context),
                  child: const Text('Connect Stripe Account'),
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<RepairRequest>>(
              stream: _repairRequestService.fetchRepairRequests(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allRequests = snapshot.data;

                if (allRequests == null || allRequests.isEmpty) {
                  return const Center(child: Text('No open repair requests found.'));
                }

                // Filter requests
                final openRequestsWithinRadius = allRequests.where((request) {
                  return request.status == 'open' &&
                    _calculateDistance(
                      _garageLocation,
                      LatLng(request.location.latitude, request.location.longitude)
                    ) <= _searchRadius;
                }).toList();

                if (openRequestsWithinRadius.isEmpty) {
                  return const Center(child: Text('No open repair requests found within the 10km radius.'));
                }

                return ListView.builder(
                  itemCount: openRequestsWithinRadius.length,
                  itemBuilder: (ctx, i) {
                    final request = openRequestsWithinRadius[i];

                    return ListTile(
                      title: Text(request.description),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Photos: ${request.photoUrls.length}'),
                          Text('Distance: ${_calculateDistance(_garageLocation, LatLng(request.location.latitude, request.location.longitude)).toStringAsFixed(2)} km'),
                        ],
                      ),
                      leading: request.photoUrls.isNotEmpty
                          ? Image.network(
                              request.photoUrls[0],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.error),
                            )
                          : const Icon(Icons.broken_image),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/repairRequestDetails',
                          arguments: request.id
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connectStripeAccount(BuildContext context) async {
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      developer.log('User is not authenticated when trying to connect Stripe.');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: User not authenticated.')),
         );
      }
      return;
    } else {
       developer.log('User is authenticated (UID: ${user.uid}) when trying to connect Stripe.');
    }

    try {
      // Get the user's ID token explicitly (this line can be kept for debugging or other purposes,
      // but the token should NOT be passed in the callable function payload for authentication)
      final idToken = await user.getIdToken();
      developer.log('User ID Token obtained');

      // Call the callable function.
      // The emulator host/port is set in main.dart, so no change needed here.
      // Explicitly specify the region and potentially the emulator host/port
      final HttpsCallable callable =
          FirebaseFunctions.instanceFor(region: 'us-central1') // Specify the region
             .httpsCallable('initiateStripeConnectOnboarding');

      // If the above still gives unauthenticated, try this (less likely needed with callable functions but for testing)
      // final HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'us-central1')
      // .useFunctionsEmulator('10.0.2.2', 5002) // Explicitly set emulator host/port
      // .httpsCallable('initiateStripeConnectOnboarding');

      // *** REMOVE the idToken from the data payload ***
      // The callable function framework handles authentication automatically based on the context.
      final result = await callable.call(); // Call without explicit data payload for authentication


      final data = result.data;

      if (data != null && data['success'] == true && data['url'] != null) {
        final url = Uri.parse(data['url']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $url';
        }
      } else {
        String message = data != null && data['message'] != null
            ? data['message']
            : 'Failed to initiate Stripe Connect onboarding.';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    } on FirebaseFunctionsException catch (e) {
      developer.log('Firebase Functions Error: ${e.code} - ${e.message}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    } catch (e) {
      developer.log('General Error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred.')),
        );
      }
    }
  }
}
