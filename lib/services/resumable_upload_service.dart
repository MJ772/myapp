import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ResumableUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> saveUploadState(String uploadId, String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uploadId', uploadId);
    await prefs.setString('filePath', filePath);
    debugPrint('Saved upload state: uploadId=$uploadId, filePath=$filePath');
  }

  Future<void> clearUploadState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('uploadId');
    await prefs.remove('filePath');
    debugPrint('Cleared upload state');
  }

  Future<void> resumeUploads() async {
    final prefs = await SharedPreferences.getInstance();
    final uploadId = prefs.getString('uploadId');
    final imagePathsString = prefs.getString('filePath');

    if (uploadId != null && imagePathsString != null) {
      debugPrint('Resuming upload for: uploadId=$uploadId');
      final imagePaths = imagePathsString.split(',');
      final storageRef = _storage.ref();
      List<String> imageUrls = [];

      try {
        for (String imagePath in imagePaths) {
          final fileName = const Uuid().v4();
          final imageRef = storageRef.child('repair_images/$fileName.jpg');
          await imageRef.putFile(File(imagePath));
          final imageUrl = await imageRef.getDownloadURL();
          imageUrls.add(imageUrl);
        }

        // In a real app, you would likely notify the user or update the UI
        // with the newly uploaded image URLs.
        debugPrint('Successfully resumed and uploaded ${imageUrls.length} images.');

        await clearUploadState();
      } catch (e) {
        debugPrint('Error resuming upload: $e');
        // Optionally, you might want to retry or handle the error in another way
      }
    } else {
      debugPrint('No pending uploads to resume.');
    }
  }
}
