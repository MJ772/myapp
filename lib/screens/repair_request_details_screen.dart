import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/services/repair_request_service.dart';
import 'package:myapp/models/repair_request.dart'; // Correct model import
import 'package:myapp/models/bid.dart'; // Correct model import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:myapp/models/service.dart';

class RepairRequestDetailsScreen extends StatefulWidget {
  final String requestId;

  const RepairRequestDetailsScreen({super.key, required this.requestId});

  @override
  State<RepairRequestDetailsScreen> createState() => _RepairRequestDetailsScreenState();
}

class _RepairRequestDetailsScreenState extends State<RepairRequestDetailsScreen> {
  final RepairRequestService _repairRequestService = RepairRequestService();
  final TextEditingController _bidPriceController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();

  @override
  void dispose() {
    _bidPriceController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }

  Future<void> _acceptBid(String bidId, String requestId) async {
    final functions = FirebaseFunctions.instance;
    try {
      final result = await functions.httpsCallable('acceptBidAndProcessPayment').call({
        'bidId': bidId,
        'requestId': requestId,
      });

      if (kDebugMode) {
        debugPrint('Cloud Function result: ${result.data}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bid accepted successfully!')),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud Function error: ${e.code} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept bid: ${e.message}')),
        );
      }
    } catch (e) {
      debugPrint('An unexpected error occurred: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
        );
      }
    }
  }

  void _showBidDialog(BuildContext context, String requestId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Submit Bid'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _bidPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Bid Price (\$)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _availabilityController,
                  decoration: const InputDecoration(
                    labelText: 'Availability (e.g., next 24 hours)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                _bidPriceController.clear();
                _availabilityController.clear();
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Submit Bid'),
              onPressed: () async {
                final price = double.tryParse(_bidPriceController.text);
                final availability = _availabilityController.text;

                if (price != null && availability.isNotEmpty) {
                  try {
                    await _repairRequestService.addBid(
                      requestId: requestId,
                      garageId: currentUser.uid, // Use current user's UID
                      price: price,
                      availability: availability,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bid submitted successfully!')),
                      );
                    }
                    _bidPriceController.clear();
                    _availabilityController.clear();
                  } catch (e) {
                    debugPrint('Error submitting bid: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to submit bid: ${e.toString()}')),
                      );
                    }
                  }
                }
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair Request Details'),
      ),
      body: FutureBuilder<RepairRequest>(
        future: _repairRequestService.getRepairRequestById(widget.requestId),
        builder: (context, requestSnapshot) {
          if (requestSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (requestSnapshot.hasError) {
            return Center(child: Text('Error loading request: ${requestSnapshot.error}'));
          }

          if (!requestSnapshot.hasData) {
            return const Center(child: Text('Repair request not found.'));
          }

          final repairRequest = requestSnapshot.data!;
          final currentUser = FirebaseAuth.instance.currentUser;

          return FutureBuilder<DocumentSnapshot>(
            future: currentUser != null
                ? FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .get()
                : null,
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting &&
                  currentUser != null) {
                return const Center(child: CircularProgressIndicator());
              }

              final userRole = userSnapshot.data?.get('role') as String? ?? '';
              final isGarage = userRole == 'garage';

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        repairRequest.description,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16.0),
                      if (repairRequest.photoUrls.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: repairRequest.photoUrls.length,
                            itemBuilder: (ctx, i) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Image.network(
                                repairRequest.photoUrls[i],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16.0),
                      Text(
                        'Location: ${repairRequest.location.latitude.toStringAsFixed(4)}, '
                        '${repairRequest.location.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24.0),
                      const Text(
                        'Bids:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      StreamBuilder<List<Bid>>(
                        stream: _repairRequestService.fetchBidsForRequest(widget.requestId),
                        builder: (context, bidSnapshot) {
                          if (bidSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (bidSnapshot.hasError) {
                            return Center(
                                child: Text('Error loading bids: ${bidSnapshot.error}'));
                          }

                          if (!bidSnapshot.hasData || bidSnapshot.data!.isEmpty) {
                            return const Center(child: Text('No bids yet.'));
                          }

                          final bids = bidSnapshot.data!;

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: bids.length,
                            itemBuilder: (ctx, i) {
                              final bid = bids[i];
                              final isCustomer = userRole == 'customer';
                              final isUsersRequest = currentUser != null && 
                                  repairRequest.userId == currentUser.uid;

                              return ListTile(
                                title: Text('Bid: \$${bid.price.toStringAsFixed(2)}'),
                                subtitle: Text('Availability: ${bid.availability}'),
                                trailing: Visibility(
                                  visible: isCustomer && isUsersRequest && bid.status != 'accepted',
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _acceptBid(bid.id, widget.requestId);
                                      if (kDebugMode) {
                                        debugPrint('Accepting bid ${bid.id}');
                                      }
                                    },
                                    child: const Text('Accept Bid'),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      if (repairRequest.acceptedBid != null) ...[
                        const SizedBox(height: 24.0),
                        const Text(
                          'Services Offered by Accepted Garage:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8.0),
                        StreamBuilder<List<Service>>(
                          stream: _repairRequestService.fetchServicesByGarageId(repairRequest.acceptedBid!.garageId),
                          builder: (context, serviceSnapshot) {
                            if (serviceSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (serviceSnapshot.hasError || !serviceSnapshot.hasData) {
                              return const Text('No services available');
                            }
                            return Column(
                              children: serviceSnapshot.data!.map((service) => ListTile(
                                title: Text(service.title),
                                subtitle: Text('\$${service.price.toStringAsFixed(2)} - ${service.duration}'),
                              )).toList(),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 24.0),
                      Visibility(
                        visible: currentUser != null && isGarage,
                        child: ElevatedButton(
                          onPressed: () => _showBidDialog(context, widget.requestId),
                          child: const Text('Submit Your Bid'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}