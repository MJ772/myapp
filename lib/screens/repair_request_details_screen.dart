import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card; // << hide Card
import 'package:myapp/services/repair_request_service.dart';
import 'package:myapp/models/repair_request.dart';
import 'package:myapp/models/bid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class RepairRequestDetailsScreen extends StatefulWidget {
  final String requestId;

  const RepairRequestDetailsScreen({super.key, required this.requestId});

  @override
  State<RepairRequestDetailsScreen> createState() =>
      _RepairRequestDetailsScreenState();
}

class _RepairRequestDetailsScreenState extends State<RepairRequestDetailsScreen> {
  final RepairRequestService _repairRequestService = RepairRequestService();
  final TextEditingController _bidPriceController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();
  bool _isAcceptingBid = false;
  late Stream<RepairRequest> _requestStream;

  @override
  void initState() {
    super.initState();
    _requestStream = _repairRequestService.getRepairRequestStream(widget.requestId);
  }

  @override
  void dispose() {
    _bidPriceController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }

  Future<void> _acceptBid(String bidId, String requestId, double amount) async {
    setState(() {
      _isAcceptingBid = true;
    });

    try {
      final functions = FirebaseFunctions.instance;
      final result = await functions
          .httpsCallable('acceptBidAndProcessPayment')
          .call({'bidId': bidId, 'requestId': requestId});

      final clientSecret = result.data['client_secret'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Motors App',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      await FirebaseFirestore.instance.collection('bids').doc(bidId).update({
        'status': 'accepted',
      });
      await FirebaseFirestore.instance.collection('repair_requests').doc(requestId).update({
        'status': 'in_progress',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bid accepted and payment processed successfully!')),
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
    } finally {
      if (mounted) {
        setState(() {
          _isAcceptingBid = false;
        });
      }
    }
  }

  Future<void> _markAsComplete(String requestId) async {
    try {
      final functions = FirebaseFunctions.instance;
      await functions.httpsCallable('markRepairAsCompleted').call({'requestId': requestId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Repair marked as complete!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _payNow(String requestId, String bidId) async {
    try {
      final functions = FirebaseFunctions.instance;
      final result = await functions
          .httpsCallable('createPaymentIntent')
          .call({'requestId': requestId, 'bidId': bidId});

      final clientSecret = result.data['clientSecret'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Motors App',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showBidDialog(BuildContext context, String requestId) {
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
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Submit'),
              onPressed: () async {
                final price = double.tryParse(_bidPriceController.text);
                final availability = _availabilityController.text;

                if (price != null && availability.isNotEmpty) {
                  try {
                    await _repairRequestService.addBid(
                      requestId: requestId,
                      garageId: currentUser.uid,
                      price: price,
                      availability: availability,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bid submitted successfully!')),
                      );
                      _bidPriceController.clear();
                      _availabilityController.clear();
                      Navigator.of(dialogContext).pop();
                    }
                  } catch (e) {
                    debugPrint('Error submitting bid: $e');
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showAcceptBidConfirmation(BuildContext context, Bid bid, String requestId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Accept Bid'),
          content: _isAcceptingBid
              ? const Center(child: CircularProgressIndicator())
              : Text(
                  'You are about to accept this bid for \$${bid.price.toStringAsFixed(2)}. Do you want to proceed with the payment?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              onPressed: _isAcceptingBid
                  ? null
                  : () {
                      Navigator.of(dialogContext).pop();
                      _acceptBid(bid.id, requestId, bid.price);
                    },
              child: const Text('Accept & Pay'),
            ),
          ],
        );
      },
    );
  }

  Bid? _findAcceptedBid(List<Bid> bids) {
    try {
      return bids.firstWhere((bid) => bid.status == 'accepted');
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: StreamBuilder<RepairRequest>(
        stream: _requestStream,
        builder: (context, requestSnapshot) {
          if (requestSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (requestSnapshot.hasError || !requestSnapshot.hasData) {
            return const Center(child: Text('Request not found.'));
          }

          final repairRequest = requestSnapshot.data!;
          final currentUser = FirebaseAuth.instance.currentUser;

          return FutureBuilder<DocumentSnapshot>(
            future: currentUser != null
                ? FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get()
                : null,
            builder: (context, userSnapshot) {
              final userRole = userSnapshot.data?.get('role') as String? ?? '';
              final isGarage = userRole == 'garage';
              final isCustomer = userRole == 'customer';
              final isOwner = repairRequest.userId == currentUser?.uid;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildRequestInfoCard(repairRequest),
                    const SizedBox(height: 24),
                    if (isOwner)
                      Text('Bids on Your Request', style: Theme.of(context).textTheme.headlineSmall),
                    if (isOwner)
                      StreamBuilder<List<Bid>>(
                        stream: _repairRequestService.fetchBidsForRequest(widget.requestId),
                        builder: (context, bidSnapshot) {
                          if (bidSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!bidSnapshot.hasData || bidSnapshot.data!.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 20.0),
                              child: Center(child: Text('No bids have been placed yet.')),
                            );
                          }

                          final bids = bidSnapshot.data!;
                          final acceptedBid = _findAcceptedBid(bids);

                          return Column(
                            children: [
                              _buildBidsList(repairRequest, isCustomer, isOwner, isGarage, bids),
                              if (isOwner && repairRequest.status == 'completed' && acceptedBid != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.payment),
                                    label: const Text('Pay Now'),
                                    onPressed: () => _payNow(widget.requestId, acceptedBid.id),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    if (isGarage && !isOwner)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.gavel),
                          label: const Text('Submit Your Bid'),
                          onPressed: () => _showBidDialog(context, widget.requestId),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestInfoCard(RepairRequest repairRequest) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(repairRequest.description, style: Theme.of(context).textTheme.titleLarge),
                ),
                if (repairRequest.status == 'paid')
                  const Chip(
                    label: Text('Paid'),
                    backgroundColor: Colors.lightGreen,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (repairRequest.photoUrls.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: repairRequest.photoUrls.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(repairRequest.photoUrls[i], width: 100, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBidsList(
      RepairRequest repairRequest, bool isCustomer, bool isOwner, bool isGarage, List<Bid> bids) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bids.length,
      itemBuilder: (ctx, i) {
        final bid = bids[i];
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(bid.garageId).get(),
          builder: (context, garageSnapshot) {
            String garageName = 'Loading...';
            if (garageSnapshot.hasData) {
              garageName = garageSnapshot.data!.get('displayName') ?? 'Garage';
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(garageName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Availability: ${bid.availability}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${bid.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (isCustomer && isOwner && repairRequest.status == 'open')
                      ElevatedButton(
                        onPressed: () => _showAcceptBidConfirmation(context, bid, widget.requestId),
                        child: const Text('Accept'),
                      ),
                    if (bid.status == 'accepted')
                      const Chip(label: Text('Accepted'), backgroundColor: Colors.green),
                    if (repairRequest.status == 'paid' && bid.status == 'accepted')
                      const Chip(label: Text('Paid'), backgroundColor: Colors.lightGreen),
                    if (bid.status == 'accepted' && isGarage && bid.garageId == currentUser?.uid && repairRequest.status == 'in_progress')
                      ElevatedButton(
                        onPressed: () => _markAsComplete(repairRequest.id),
                        child: const Text('Mark as Complete'),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

