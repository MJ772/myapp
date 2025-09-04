
import 'dart:io';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myapp/services/resumable_upload_service.dart';
import 'package:uuid/uuid.dart';
import 'package:myapp/services/repair_request_service.dart';
import 'package:shimmer/shimmer.dart';

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
  double _uploadProgress = 0.0;
  final RepairRequestService _repairRequestService = RepairRequestService();
  final ResumableUploadService _resumableUploadService = ResumableUploadService();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollTopButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _showScrollTopButton = _scrollController.offset >= 200;
        });
      }
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

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
    final uploadId = const Uuid().v4();
    final imagePaths = _images.map((image) => image.path).join(',');

    await _resumableUploadService.saveUploadState(uploadId, imagePaths);

    final totalImages = _images.length;
    var uploadedImages = 0;

    for (var image in _images) {
      final fileName = const Uuid().v4();
      final imageRef = storageRef.child('repair_images/$fileName.jpg');
      final uploadTask = imageRef.putFile(File(image.path));

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) {
          setState(() {
            _uploadProgress = (uploadedImages + (snapshot.bytesTransferred / snapshot.totalBytes)) / totalImages;
          });
        }
      });

      try {
        final snapshot = await uploadTask;
        final imageUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(imageUrl);
        uploadedImages++;
      } on FirebaseException catch (e) {
        developer.log('Firebase Storage Error uploading image ${image.path}: ${e.code} - ${e.message}', name: 'ImageUpload');
        return [];
      } catch (e) {
        developer.log('Error uploading image: $e', name: 'ImageUpload');
        return [];
      }
    }

    await _resumableUploadService.clearUploadState();
    return imageUrls;
  }

  Future<void> _submitRequest() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
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

    if (imageUrls.isEmpty && _images.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload images. The upload will be automatically resumed later.')),
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
          _uploadProgress = 0.0;
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Repair Request'),
      ),
      floatingActionButton: _showScrollTopButton
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              child: const Icon(Icons.arrow_upward),
            )
          : null,
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
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50.0),
                          child: LinearProgressIndicator(
                            value: _uploadProgress,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0), // Add padding for FAB
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStep(
                          context,
                          icon: Icons.description,
                          title: 'Describe the Issue',
                          content: TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              hintText: 'e.g., Engine making strange noises',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildStep(
                          context,
                          icon: Icons.camera_alt,
                          title: 'Upload Photos',
                          content: Column(
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.add_a_photo),
                                label: const Text('Select Images'),
                                onPressed: _selectImages,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                              if (_images.isNotEmpty)
                                _buildImagePreview(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildStep(
                          context,
                          icon: Icons.location_on,
                          title: 'Share Your Location',
                          content: Column(
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.my_location),
                                label: const Text('Get Current Location'),
                                onPressed: _getLocation,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                              if (_currentPosition != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lon: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _submitRequest,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                            child: const Text('Submit Request', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ],
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

  Widget _buildStep(BuildContext context, {required IconData icon, required String title, required Widget content}) {
    return Card(
      elevation: 4.0,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
                const SizedBox(width: 15),
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 130,
      margin: const EdgeInsets.only(top: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Image.file(
                  File(_images[index].path),
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
