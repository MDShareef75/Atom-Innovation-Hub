import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'notifications';

  // Stream of notifications for the current user, ordered by timestamp desc
  Stream<List<Map<String, dynamic>>> getUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection(_collection).doc(notificationId).update({'isRead': true});
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection(_collection).doc(notificationId).delete();
  }

  // Mark all notifications as read for the current user
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final query = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();
    for (var doc in query.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  // Delete all notifications for the current user
  Future<void> clearAllNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final query = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .get();
    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  // Stream of all notifications (for admin)
  Stream<List<Map<String, dynamic>>> getAllNotifications() {
    return _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }
} 