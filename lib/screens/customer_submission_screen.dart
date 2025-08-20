import 'dart:io';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:myapp/services/repair_request_service.dart';

class CustomerSubmissionScreen extends StatefulWidget {
  const CustomerSubmissionScreen({super.key});

  @override
  State<CustomerSubmissionScreen> createState() => _CustomerSubmissionScreenState();
}

class _CustomerSubmissionScreenState extends State<CustomerSubmissionScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = <XFile>[];
  Position? _currentPosition;
  bool _isUploading = false;
  final RepairRequestService _repairRequestService = RepairRequestService();

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location retrieved!')),
        );
      }
    } catch (e) {
      developer.log('Error getting location: $e', name: 'Location');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: ${e.toString()}')),
        );
      }
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    final storageRef = FirebaseStorage.instance.ref();

    for (XFile image in _images) {
      final fileName = const Uuid().v4();
      final imageRef = storageRef.child('repair_images/$fileName.jpg');
      try {
        await imageRef.putFile(File(image.path));
        final imageUrl = await imageRef.getDownloadURL();
        imageUrls.add(imageUrl);
      } on FirebaseException catch (e) {
        developer.log('Firebase Storage Error uploading image ${image.path}: ${e.code} - ${e.message}', name: 'ImageUpload');
      } catch (e) {
        developer.log('Error uploading image: $e', name: 'ImageUpload');
      }
    }
    return imageUrls;
  }

  Future<void> _submitRequest() async {
    setState(() {
      _isUploading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
      }
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
      return;
    }

    if (_descriptionController.text.isEmpty ||
        _images.isEmpty ||
        _currentPosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill out all fields and get your location.')),
        );
      }
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
      return;
    }

    final imageUrls = await _uploadImages();

    if (imageUrls.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload images.')),
        );
      }
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
      return;
    }

    try {
      await _repairRequestService.submitRequest(
        userId: user.uid,
        description: _descriptionController.text,
        photoUrls: imageUrls,
        location: _currentPosition!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Repair request submitted successfully!')),
        );
      }

      if (mounted) {
        setState(() {
          _descriptionController.clear();
          _images.clear();
          _currentPosition = null;
        });
      }

    } catch (e) {
      developer.log('Error submitting request: $e', name: 'SubmitRequest');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting request: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _selectImages() async {
    final selectedImages = await _picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
      setState(() {
        _images = selectedImages;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Repair Request'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseAuth.instance.currentUser != null
            ? FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .get()
            : null,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userRole = userSnapshot.data?.get('role') as String? ?? '';
          final isCustomer = userRole == 'customer';
          final isAuthenticated = FirebaseAuth.instance.currentUser != null;

          if (isAuthenticated && isCustomer) {
            return _isUploading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(labelText: 'Issue Description'),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: _selectImages,
                            child: const Text('Select Photos'),
                          ),
                          if (_images.isNotEmpty) ...[
                            const SizedBox(height: 8.0),
                            Text('Selected ${_images.length} image(s)'),
                            const SizedBox(height: 8.0),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _images.length,
                                itemBuilder: (ctx, i) => Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Image.file(File(_images[i].path), width: 100, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: _getLocation,
                            child: const Text('Get Current Location'),
                          ),
                          if (_currentPosition != null) ...[
                            const SizedBox(height: 8.0),
                            Text('Location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'),
                          ],
                          const SizedBox(height: 24.0),
                          ElevatedButton(
                            onPressed: _submitRequest,
                            child: const Text('Submit Request'),
                          ),
                        ],
                      ),
                    ),
                  );
          } else {
            return const Center(
              child: Text(
                'This functionality is available only for customers.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            );
          }
        },
      ),
    );
  }
}