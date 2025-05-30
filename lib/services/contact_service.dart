import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:atoms_innovation_hub/models/contact_message_model.dart';

class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _messagesCollection = 'contact_messages';
  final String _contactInfoCollection = 'contact_info';

  // Send contact message
  Future<String> sendContactMessage({
    required String name,
    required String email,
    String? phone,
    required String subject,
    required String message,
    String? userId,
  }) async {
    try {
      DocumentReference docRef = await _firestore.collection(_messagesCollection).add({
        'name': name,
        'email': email,
        'phone': phone,
        'subject': subject,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'userId': userId,
      });
      
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Get all contact messages (for admin)
  Stream<List<ContactMessageModel>> getContactMessages() {
    return _firestore
        .collection(_messagesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ContactMessageModel.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore.collection(_messagesCollection).doc(messageId).update({
        'isRead': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Delete contact message
  Future<void> deleteContactMessage(String messageId) async {
    try {
      await _firestore.collection(_messagesCollection).doc(messageId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Get contact information
  Future<Map<String, dynamic>?> getContactInfo() async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_contactInfoCollection).doc('main').get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update contact information (for admin)
  Future<void> updateContactInfo({
    required String email,
    required String phone,
    required String address,
  }) async {
    try {
      await _firestore.collection(_contactInfoCollection).doc('main').set({
        'email': email,
        'phone': phone,
        'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // Initialize default contact info if it doesn't exist
  Future<void> initializeContactInfo() async {
    try {
      final doc = await _firestore.collection(_contactInfoCollection).doc('main').get();
      if (!doc.exists) {
        await _firestore.collection(_contactInfoCollection).doc('main').set({
          'email': 'atom.innovatex@gmail.com',
          'phone': '+91 9945546164',
          'address': 'Chikmagalur, Karnataka\nIndia',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get unread message count
  Stream<int> getUnreadMessageCount() {
    return _firestore
        .collection(_messagesCollection)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Reply to contact message (admin only)
  Future<void> replyToMessage({
    required String messageId,
    required String adminReply,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _firestore.collection(_messagesCollection).doc(messageId).update({
        'adminReply': adminReply,
        'repliedAt': FieldValue.serverTimestamp(),
        'repliedByAdminId': adminId,
        'repliedByAdminName': adminName,
        'isRead': true, // Mark as read when replied
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get messages for a specific user
  Stream<List<ContactMessageModel>> getUserMessages(String userId) {
    return _firestore
        .collection(_messagesCollection)
        .where('userId', isEqualTo: userId)
        // Temporarily removed orderBy until index is created
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      List<ContactMessageModel> messages = snapshot.docs.map((doc) {
        return ContactMessageModel.fromJson(doc.data(), doc.id);
      }).toList();
      
      // Sort in memory as a temporary solution
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return messages;
    });
  }

  // Get message by ID
  Future<ContactMessageModel?> getMessageById(String messageId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_messagesCollection).doc(messageId).get();
      if (doc.exists) {
        return ContactMessageModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
} 