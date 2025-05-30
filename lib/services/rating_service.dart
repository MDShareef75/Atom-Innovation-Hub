import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'ratings';

  Future<void> submitRating(Rating rating) async {
    try {
      final query = await _firestore.collection(_collection)
        .where('appId', isEqualTo: rating.appId)
        .where('userId', isEqualTo: rating.userId)
        .get();
      if (query.docs.isNotEmpty) {
        // Update the existing rating
        await _firestore.collection(_collection).doc(query.docs.first.id).update(rating.toMap());
      } else {
        // Add a new rating
        await _firestore.collection(_collection).add(rating.toMap());
      }
    } catch (e) {
      throw Exception('Failed to submit rating: $e');
    }
  }

  Future<double> getAverageRating(String appId) async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection(_collection)
        .where('appId', isEqualTo: appId)
        .get();
      if (snapshot.docs.isEmpty) return 0.0;

      double totalRating = 0;
      for (var doc in snapshot.docs) {
        totalRating += (doc.data() as Map<String, dynamic>)['rating'] as double;
      }
      return totalRating / snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get average rating: $e');
    }
  }

  Stream<List<Rating>> getRatings(String appId) {
    return _firestore
        .collection(_collection)
        .where('appId', isEqualTo: appId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Rating.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Rating?> getUserRating(String appId, String userId) async {
    final query = await _firestore
        .collection(_collection)
        .where('appId', isEqualTo: appId)
        .where('userId', isEqualTo: userId)
        .get();
    if (query.docs.isNotEmpty) {
      return Rating.fromMap(query.docs.first.data() as Map<String, dynamic>);
    }
    return null;
  }
} 