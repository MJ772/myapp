
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/review.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReviewSubmissionScreen extends StatefulWidget {
  final String garageId;
  final String repairRequestId;

  const ReviewSubmissionScreen({
    super.key,
    required this.garageId,
    required this.repairRequestId,
  });

  @override
  State<ReviewSubmissionScreen> createState() => _ReviewSubmissionScreenState();
}

class _ReviewSubmissionScreenState extends State<ReviewSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  double _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to leave a review.')),
        );
        return;
      }

      final review = Review(
        id: '', // Firestore will generate an ID
        rating: _rating,
        comment: _commentController.text,
        customerId: user.uid,
        garageId: widget.garageId,
        timestamp: Timestamp.now(),
      );

      try {
        await FirebaseFirestore.instance.collection('reviews').add(review.toFirestore());
        // Optionally, update the repair request to indicate a review has been left.
        await FirebaseFirestore.instance
            .collection('repair_requests')
            .doc(widget.repairRequestId)
            .update({'isReviewed': true});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave a Review'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rate your experience:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Leave a comment',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a comment.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (_isSubmitting)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submitReview,
                  child: const Text('Submit Review'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
