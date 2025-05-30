import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Log app download event
  Future<void> logAppDownload(String appId, String appName, String userId) async {
    try {
      // Log event to Firebase Analytics
      await _analytics.logEvent(
        name: 'app_download',
        parameters: {
          'app_id': appId,
          'app_name': appName,
          'user_id': userId,
        },
      );
      
      // Add download record to Firestore
      await _firestore.collection('app_downloads').add({
        'appId': appId,
        'appName': appName,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Log blog post view event
  Future<void> logBlogPostView(String postId, String postTitle, String userId) async {
    try {
      // Log event to Firebase Analytics
      await _analytics.logEvent(
        name: 'blog_post_view',
        parameters: {
          'post_id': postId,
          'post_title': postTitle,
          'user_id': userId,
        },
      );
      
      // Add view record to Firestore
      await _firestore.collection('blog_post_views').add({
        'postId': postId,
        'postTitle': postTitle,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Log user sign up event
  Future<void> logUserSignUp(String userId, String signUpMethod) async {
    try {
      await _analytics.logSignUp(signUpMethod: signUpMethod);
    } catch (e) {
      rethrow;
    }
  }

  // Log user login event
  Future<void> logUserLogin(String userId, String loginMethod) async {
    try {
      await _analytics.logLogin(loginMethod: loginMethod);
    } catch (e) {
      rethrow;
    }
  }

  // Test Firestore connectivity
  Future<bool> testFirestoreConnection() async {
    try {
      // Try a simple read operation
      await _firestore.collection('test').limit(1).get();
      return true;
    } catch (e) {
      print('Firestore connection test failed: $e');
      return false;
    }
  }

  // Get app download analytics
  Future<Map<String, dynamic>> getAppDownloadAnalytics() async {
    try {
      print('Fetching applications collection...');
      QuerySnapshot snapshot = await _firestore
          .collection('applications')
          .get();
      
      print('Applications query completed. Found ${snapshot.docs.length} documents');
      
      if (snapshot.docs.isEmpty) {
        print('No applications found, returning empty data');
        return {
          'apps': <Map<String, dynamic>>[],
          'totalDownloads': 0,
        };
      }
      
      List<Map<String, dynamic>> appDownloads = [];
      
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          appDownloads.add({
            'id': doc.id,
            'name': data['name'] ?? 'Unknown App',
            'downloadCount': data['downloadCount'] ?? 0,
          });
        } catch (e) {
          print('Error processing app document ${doc.id}: $e');
          continue;
        }
      }
      
      // Sort by download count
      appDownloads.sort((a, b) => (b['downloadCount'] as int).compareTo(a['downloadCount'] as int));
      
      int totalDownloads = appDownloads.fold(0, (sum, app) => sum + (app['downloadCount'] as int));
      
      print('App analytics processed successfully: ${appDownloads.length} apps, $totalDownloads total downloads');
      
      return {
        'apps': appDownloads,
        'totalDownloads': totalDownloads,
      };
    } catch (e) {
      print('Error getting app analytics: $e');
      return {
        'apps': <Map<String, dynamic>>[],
        'totalDownloads': 0,
      };
    }
  }

  // Get blog post engagement analytics
  Future<Map<String, dynamic>> getBlogPostEngagementAnalytics() async {
    try {
      print('Fetching blog_posts collection...');
      QuerySnapshot snapshot = await _firestore
          .collection('blog_posts')
          .get();
      
      print('Blog posts query completed. Found ${snapshot.docs.length} documents');
      
      if (snapshot.docs.isEmpty) {
        print('No blog posts found, returning empty data');
        return {
          'posts': <Map<String, dynamic>>[],
          'totalViews': 0,
          'totalComments': 0,
        };
      }
      
      List<Map<String, dynamic>> postEngagements = [];
      
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          postEngagements.add({
            'id': doc.id,
            'title': data['title'] ?? 'Unknown Post',
            'viewCount': data['viewCount'] ?? 0,
            'commentCount': data['commentCount'] ?? 0,
          });
        } catch (e) {
          print('Error processing blog post document ${doc.id}: $e');
          continue;
        }
      }
      
      // Sort by view count
      postEngagements.sort((a, b) => (b['viewCount'] as int).compareTo(a['viewCount'] as int));
      
      int totalViews = postEngagements.fold(0, (sum, post) => sum + (post['viewCount'] as int));
      int totalComments = postEngagements.fold(0, (sum, post) => sum + (post['commentCount'] as int));
      
      print('Blog analytics processed successfully: ${postEngagements.length} posts, $totalViews total views');
      
      return {
        'posts': postEngagements,
        'totalViews': totalViews,
        'totalComments': totalComments,
      };
    } catch (e) {
      print('Error getting blog analytics: $e');
      return {
        'posts': <Map<String, dynamic>>[],
        'totalViews': 0,
        'totalComments': 0,
      };
    }
  }

  // Get user analytics
  Future<Map<String, dynamic>> getUserAnalytics() async {
    try {
      print('Fetching users collection...');
      // Get all users with a simple query
      QuerySnapshot userSnapshot = await _firestore.collection('users').get();
      
      print('Users query completed. Found ${userSnapshot.docs.length} documents');
      
      if (userSnapshot.docs.isEmpty) {
        print('No users found, returning empty data');
        return {
          'totalCustomers': 0,
          'totalAdmins': 0,
          'totalUsers': 0,
          'newCustomers': 0,
          'activeCustomers': 0,
          'newUsers': 0,
          'activeUsers': 0,
        };
      }
      
      // Process all users in memory to avoid complex Firestore queries
      int totalCustomers = 0;
      int totalAdmins = 0;
      int newCustomers = 0;
      int activeCustomers = 0;
      
      DateTime now = DateTime.now();
      DateTime thirtyDaysAgo = now.subtract(const Duration(days: 30));
      DateTime sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      print('Processing ${userSnapshot.docs.length} user documents...');
      
      for (var doc in userSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          // Explicitly check for admin status - only true admins are excluded
          bool isAdmin = data['isAdmin'] == true;
          
          print('User ${doc.id}: email=${data['email']}, isAdmin field=${data['isAdmin']}, treated as admin=$isAdmin');
          
          if (isAdmin) {
            totalAdmins++;
            print('  -> Counted as admin (EXCLUDED from customers)');
          } else {
            totalCustomers++;
            print('  -> Counted as customer (INCLUDED in customer count)');
            
            // Check if user was created in the last 30 days
            if (data['createdAt'] != null) {
              try {
                DateTime createdAt = (data['createdAt'] as Timestamp).toDate();
                if (createdAt.isAfter(thirtyDaysAgo)) {
                  newCustomers++;
                  print('  -> New customer (created ${createdAt})');
                }
              } catch (e) {
                print('  -> Error parsing createdAt: $e');
              }
            }
            
            // Check if user was active in the last 7 days
            if (data['lastLogin'] != null) {
              try {
                DateTime lastLogin = (data['lastLogin'] as Timestamp).toDate();
                if (lastLogin.isAfter(sevenDaysAgo)) {
                  activeCustomers++;
                  print('  -> Active customer (last login ${lastLogin})');
                }
              } catch (e) {
                print('  -> Error parsing lastLogin: $e');
              }
            }
          }
        } catch (e) {
          // Skip this document if there's an error processing it
          print('Error processing user document ${doc.id}: $e');
          continue;
        }
      }
      
      print('Final counts: customers=$totalCustomers, admins=$totalAdmins, total=${totalCustomers + totalAdmins}');
      print('New customers: $newCustomers, Active customers: $activeCustomers');
      
      return {
        'totalCustomers': totalCustomers,
        'totalAdmins': totalAdmins,
        'totalUsers': totalCustomers + totalAdmins,
        'newCustomers': newCustomers,
        'activeCustomers': activeCustomers,
        'newUsers': newCustomers,
        'activeUsers': activeCustomers,
      };
    } catch (e) {
      print('Error getting user analytics: $e');
      // Return default values if there's any error
      return {
        'totalCustomers': 0,
        'totalAdmins': 0,
        'totalUsers': 0,
        'newCustomers': 0,
        'activeCustomers': 0,
        'newUsers': 0,
        'activeUsers': 0,
      };
    }
  }
} 