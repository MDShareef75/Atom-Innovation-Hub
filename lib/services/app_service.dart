import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:atoms_innovation_hub/models/app_model.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

class AppService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'applications';

  // Get all applications
  Stream<List<AppModel>> getApps() {
    return _firestore
        .collection(_collection)
        .orderBy('releaseDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        
        // Ensure all required fields exist with default values
        data['likes'] = data['likes'] ?? [];
        data['dislikes'] = data['dislikes'] ?? [];
        data['downloadCount'] = data['downloadCount'] ?? 0;
        data['authorId'] = data['authorId'] ?? '';
        data['authorName'] = data['authorName'] ?? 'Unknown';
        
        // Handle date fields
        if (data['releaseDate'] == null) {
          data['releaseDate'] = Timestamp.now();
        }
        if (data['lastUpdated'] == null) {
          data['lastUpdated'] = Timestamp.now();
        }
        if (data['createdAt'] == null) {
          data['createdAt'] = Timestamp.now();
        }
        
        return AppModel.fromJson(data);
      }).toList();
    });
  }

  // Get application by ID
  Future<AppModel?> getAppById(String appId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(appId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        // Ensure all required fields exist with default values
        data['likes'] = data['likes'] ?? [];
        data['dislikes'] = data['dislikes'] ?? [];
        data['downloadCount'] = data['downloadCount'] ?? 0;
        data['authorId'] = data['authorId'] ?? '';
        data['authorName'] = data['authorName'] ?? 'Unknown';
        
        return AppModel.fromJson(data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Upload file using FilePicker result (supports both web and mobile)
  Future<String> uploadFileFromPicker(PlatformFile file, String path) async {
    try {
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask;
      
      if (kIsWeb) {
        // For web, use the bytes from FilePicker
        if (file.bytes != null) {
          uploadTask = ref.putData(file.bytes!);
        } else {
          throw Exception('No file data available for web upload');
        }
      } else {
        // For mobile/desktop, use the file path
        if (file.path != null) {
          File fileObj = File(file.path!);
          uploadTask = ref.putFile(fileObj);
        } else {
          throw Exception('No file path available for mobile upload');
        }
      }
      
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file from picker: $e');
      rethrow;
    }
  }

  // Add new application with full details and file metadata
  Future<String> addAppWithDetails({
    required String name,
    required String description,
    required String imageUrl,
    required String downloadUrl,
    required List<String> features,
    required String version,
    required String authorId,
    required String authorName,
    String? uploadedImageName,
    String? uploadedApkName,
  }) async {
    try {
      final now = FieldValue.serverTimestamp();
      
      // Create app document with file metadata
      DocumentReference docRef = await _firestore.collection(_collection).add({
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'downloadUrl': downloadUrl,
        'features': features,
        'version': version,
        'downloadCount': 0,
        'releaseDate': now,
        'lastUpdated': now,
        'createdAt': now,
        'authorId': authorId,
        'authorName': authorName,
        'likes': [],
        'dislikes': [],
        'uploadedImageName': uploadedImageName,
        'uploadedApkName': uploadedApkName,
        'imageUploadedAt': uploadedImageName != null ? now : null,
        'apkUploadedAt': uploadedApkName != null ? now : null,
      });
      
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Add new application (simplified for admin dashboard)
  Future<String> addApp({
    required String name,
    required String description,
    required String imageUrl,
    required String downloadUrl,
    required List<String> features,
    required String version,
  }) async {
    try {
      // Create app document
      DocumentReference docRef = await _firestore.collection(_collection).add({
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'downloadUrl': downloadUrl,
        'features': features,
        'version': version,
        'downloadCount': 0,
        'releaseDate': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'authorId': '',
        'authorName': 'Admin',
        'likes': [],
        'dislikes': [],
      });
      
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Update application with file metadata support
  Future<void> updateApp({
    required String appId,
    required String name,
    required String description,
    required String imageUrl,
    required String downloadUrl,
    required List<String> features,
    required String version,
    String? authorName,
    String? uploadedImageName,
    String? uploadedApkName,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'downloadUrl': downloadUrl,
        'features': features,
        'version': version,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Add author name if provided
      if (authorName != null) {
        updateData['authorName'] = authorName;
      }

      // Add file metadata if files were uploaded
      if (uploadedImageName != null) {
        updateData['uploadedImageName'] = uploadedImageName;
        updateData['imageUploadedAt'] = FieldValue.serverTimestamp();
      }

      if (uploadedApkName != null) {
        updateData['uploadedApkName'] = uploadedApkName;
        updateData['apkUploadedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection(_collection).doc(appId).update(updateData);
    } catch (e) {
      rethrow;
    }
  }

  // Delete application
  Future<void> deleteApp(String appId) async {
    try {
      await _firestore.collection(_collection).doc(appId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Increment download count
  Future<void> incrementDownloadCount(String appId) async {
    try {
      await _firestore.collection(_collection).doc(appId).update({
        'downloadCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing download count: $e');
    }
  }

  Future<void> likeApp(String appId, String userId) async {
    try {
      final docRef = _firestore.collection(_collection).doc(appId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return;
        
        final data = doc.data()!;
        final likes = List<String>.from(data['likes'] ?? []);
        final dislikes = List<String>.from(data['dislikes'] ?? []);
        
        // Remove from dislikes if present
        dislikes.remove(userId);
        
        // Toggle like
        if (likes.contains(userId)) {
          likes.remove(userId);
        } else {
          likes.add(userId);
        }
        
        transaction.update(docRef, {
          'likes': likes,
          'dislikes': dislikes,
        });
      });
    } catch (e) {
      print('Error liking app: $e');
      throw e;
    }
  }

  Future<void> dislikeApp(String appId, String userId) async {
    try {
      final docRef = _firestore.collection(_collection).doc(appId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return;
        
        final data = doc.data()!;
        final likes = List<String>.from(data['likes'] ?? []);
        final dislikes = List<String>.from(data['dislikes'] ?? []);
        
        // Remove from likes if present
        likes.remove(userId);
        
        // Toggle dislike
        if (dislikes.contains(userId)) {
          dislikes.remove(userId);
        } else {
          dislikes.add(userId);
        }
        
        transaction.update(docRef, {
          'likes': likes,
          'dislikes': dislikes,
        });
      });
    } catch (e) {
      print('Error disliking app: $e');
      throw e;
    }
  }

  // Upload file to Firebase Storage (supports both mobile and web)
  Future<String> uploadFile(File file, String path) async {
    try {
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask;
      
      if (kIsWeb) {
        // For web, read file as bytes
        Uint8List bytes = await file.readAsBytes();
        uploadTask = ref.putData(bytes);
      } else {
        // For mobile/desktop
        uploadTask = ref.putFile(file);
      }
      
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImage(File file, String path) async {
    try {
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }
} 