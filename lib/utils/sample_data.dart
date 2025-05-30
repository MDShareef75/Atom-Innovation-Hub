import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:atoms_innovation_hub/models/app_model.dart';
import 'package:atoms_innovation_hub/models/blog_post_model.dart';
import 'package:atoms_innovation_hub/models/user_model.dart';

class SampleDataHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> addSampleData() async {
    try {
      // Add sample user (with authentication)
      await _addSampleUser();
      
      // Add sample app
      await _addSampleApp();
      
      // Add sample blog post
      await _addSampleBlogPost();
      
      print('Sample data added successfully!');
    } catch (e) {
      print('Error adding sample data: $e');
      rethrow;
    }
  }

  static Future<void> _addSampleUser() async {
    try {
      // Check if admin user already exists in Authentication
      final methods = await _auth.fetchSignInMethodsForEmail('admin@atomshub.com');
      
      if (methods.isEmpty) {
        // Create the authentication user
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: 'admin@atomshub.com',
          password: 'password123',
        );
        
        // Create the Firestore document
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': 'admin@atomshub.com',
          'name': 'Admin User',
          'photoUrl': '',
          'isAdmin': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
        
        print('Admin user created successfully!');
      } else {
        // User exists, just update the Firestore document to ensure admin privileges
        final existingUsers = await _firestore
            .collection('users')
            .where('email', isEqualTo: 'admin@atomshub.com')
            .get();
            
        if (existingUsers.docs.isNotEmpty) {
          await existingUsers.docs.first.reference.update({
            'isAdmin': true,
            'name': 'Admin User',
            'lastLogin': FieldValue.serverTimestamp(),
          });
          print('Admin privileges updated for existing user!');
        }
      }
    } catch (e) {
      print('Error creating admin user: $e');
      // If user already exists, that's okay
      if (!e.toString().contains('email-already-in-use')) {
        rethrow;
      }
    }
  }

  static Future<void> _addSampleApp() async {
    final appDoc = _firestore.collection('applications').doc('app_001');
    
    await appDoc.set({
      'name': 'Task Manager Pro',
      'description': 'A powerful task management application with real-time collaboration features',
      'imageUrl': '',
      'downloadUrl': 'https://github.com/example/task-manager/releases',
      'features': [
        'Real-time collaboration',
        'Task scheduling',
        'Progress tracking',
        'Team management'
      ],
      'version': '2.1.0',
      'downloadCount': 1250,
      'releaseDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 90))),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _addSampleBlogPost() async {
    // Get the admin user ID
    final adminUsers = await _firestore
        .collection('users')
        .where('email', isEqualTo: 'admin@atomshub.com')
        .get();
    
    String authorId = 'test_user_001'; // fallback
    if (adminUsers.docs.isNotEmpty) {
      authorId = adminUsers.docs.first.id;
    }
    
    final blogDoc = _firestore.collection('blog_posts').doc('post_001');
    
    await blogDoc.set({
      'title': 'Welcome to Atom\'s Innovation Hub',
      'content': '''# Welcome to Our Innovation Hub

We're excited to share our latest projects and insights with you.

## What You'll Find Here

- **Cutting-edge Applications**: Discover our latest software solutions
- **Technical Insights**: Deep dives into development processes
- **Innovation Stories**: Behind-the-scenes looks at our projects

## Getting Started

Explore our applications section to see what we've been building, or check out our latest blog posts for technical insights and project updates.

*Happy exploring!*''',
      'imageUrl': '',
      'authorId': authorId,
      'authorName': 'Admin User',
      'tags': ['welcome', 'introduction', 'innovation'],
      'viewCount': 42,
      'commentCount': 0,
      'comments': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Separate function to create admin user only
  static Future<void> createAdminUser() async {
    try {
      print('Starting admin user creation...');
      
      // First, check if user exists in Authentication
      final methods = await _auth.fetchSignInMethodsForEmail('admin@atomshub.com');
      print('Sign-in methods for admin@atomshub.com: $methods');
      
      if (methods.isEmpty) {
        print('Creating new admin user...');
        
        // Create the authentication user
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: 'admin@atomshub.com',
          password: 'password123',
        );
        
        print('Authentication user created with UID: ${userCredential.user!.uid}');
        
        // Create the Firestore document
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': 'admin@atomshub.com',
          'name': 'Admin User',
          'photoUrl': '',
          'isAdmin': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
        
        print('Firestore document created successfully!');
        print('Admin user created: admin@atomshub.com / password123');
      } else {
        print('User already exists in Authentication');
        
        // Get the user and update Firestore
        final user = await _auth.signInWithEmailAndPassword(
          email: 'admin@atomshub.com', 
          password: 'password123'
        );
        
        await _firestore.collection('users').doc(user.user!.uid).set({
          'email': 'admin@atomshub.com',
          'name': 'Admin User',
          'photoUrl': '',
          'isAdmin': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        // Sign out after updating
        await _auth.signOut();
        
        print('Admin privileges updated for existing user!');
      }
    } catch (e) {
      print('Detailed error creating admin user: $e');
      print('Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Function to clean up sample data (except users)
  static Future<void> deleteSampleData() async {
    try {
      print('Starting sample data cleanup...');
      
      // Delete sample applications
      final appsQuery = await _firestore.collection('applications').get();
      for (var doc in appsQuery.docs) {
        await doc.reference.delete();
        print('Deleted application: ${doc.id}');
      }
      
      // Delete sample blog posts
      final blogQuery = await _firestore.collection('blog_posts').get();
      for (var doc in blogQuery.docs) {
        await doc.reference.delete();
        print('Deleted blog post: ${doc.id}');
      }
      
      print('Sample data cleanup completed! Users and admin accounts preserved.');
    } catch (e) {
      print('Error deleting sample data: $e');
      rethrow;
    }
  }

  // Function to delete specific sample documents by ID
  static Future<void> deleteSpecificSampleData() async {
    try {
      print('Deleting specific sample documents...');
      
      // Delete specific sample app
      await _firestore.collection('applications').doc('app_001').delete();
      print('Deleted sample app: app_001');
      
      // Delete specific sample blog post
      await _firestore.collection('blog_posts').doc('post_001').delete();
      print('Deleted sample blog post: post_001');
      
      print('Specific sample data deleted successfully!');
    } catch (e) {
      print('Error deleting specific sample data: $e');
      // Don't rethrow - some documents might not exist
    }
  }
} 