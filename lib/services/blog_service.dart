import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:atoms_innovation_hub/models/blog_post_model.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:atoms_innovation_hub/services/fcm_service.dart';

class BlogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'blog_posts';
  final FCMService _fcmService = FCMService();

  // Get all blog posts
  Stream<List<BlogPostModel>> getBlogPosts() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        
        // Ensure all required fields exist with default values
        data['likes'] = data['likes'] ?? [];
        data['dislikes'] = data['dislikes'] ?? [];
        data['viewCount'] = data['viewCount'] ?? 0;
        data['commentCount'] = data['commentCount'] ?? 0;
        data['comments'] = data['comments'] ?? [];
        data['tags'] = data['tags'] ?? [];
        data['imageUrl'] = data['imageUrl'] ?? '';
        
        // Handle createdAt field
        if (data['createdAt'] == null) {
          data['createdAt'] = Timestamp.now();
        }
        
        return BlogPostModel.fromJson(data);
      }).toList();
    });
  }

  // Get blog post by ID
  Future<BlogPostModel?> getBlogPostById(String postId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(postId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        // Ensure all required fields exist with default values
        data['likes'] = data['likes'] ?? [];
        data['dislikes'] = data['dislikes'] ?? [];
        data['viewCount'] = data['viewCount'] ?? 0;
        data['commentCount'] = data['commentCount'] ?? 0;
        data['comments'] = data['comments'] ?? [];
        data['tags'] = data['tags'] ?? [];
        data['imageUrl'] = data['imageUrl'] ?? '';
        
        // Handle createdAt field
        if (data['createdAt'] == null) {
          data['createdAt'] = Timestamp.now();
        }
        
        return BlogPostModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting blog post by ID: $e');
      rethrow;
    }
  }

  // Add new blog post
  Future<String> addBlogPost({
    String? title,
    String? content,
    String? imageUrl,
    String? authorId,
    String? authorName,
    List<String>? tags,
    BlogPostModel? post,
    File? imageFile,
    Uint8List? webImageBytes,
    String? imageName,
  }) async {
    try {
      String finalImageUrl = imageUrl ?? post?.imageUrl ?? '';
      
      // Upload image if provided
      if (imageFile != null) {
        finalImageUrl = await _uploadImage(imageFile, 'blog_images/${DateTime.now().millisecondsSinceEpoch}');
      } else if (webImageBytes != null) {
        finalImageUrl = await _uploadWebImage(webImageBytes, 'blog_images/${DateTime.now().millisecondsSinceEpoch}_${imageName ?? 'image'}');
      }
      
      // Create blog post document
      DocumentReference docRef = await _firestore.collection(_collection).add({
        'title': title ?? post!.title,
        'content': content ?? post!.content,
        'imageUrl': finalImageUrl,
        'authorId': authorId ?? post!.authorId,
        'authorName': authorName ?? post!.authorName,
        'tags': tags ?? post!.tags,
        'likes': [],
        'dislikes': [],
        'viewCount': 0,
        'commentCount': 0,
        'comments': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to all users
      await _fcmService.sendNotificationToAllUsers(
        title: 'New Blog Post',
        body: '${title ?? post!.title} - Check out the latest post from ${authorName ?? post!.authorName}!',
        type: 'new_blog',
        contentId: docRef.id,
        additionalData: {
          'postTitle': title ?? post!.title,
          'authorName': authorName ?? post!.authorName,
          'tags': tags ?? post!.tags,
        },
      );
      
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Update blog post
  Future<void> updateBlogPost({
    String? postId,
    String? title,
    String? content,
    String? imageUrl,
    List<String>? tags,
    BlogPostModel? post,
    File? imageFile,
    Uint8List? webImageBytes,
    String? imageName,
  }) async {
    try {
      String finalImageUrl = imageUrl ?? post?.imageUrl ?? '';
      String finalPostId = postId ?? post!.id;
      
      // Upload new image if provided
      if (imageFile != null) {
        finalImageUrl = await _uploadImage(imageFile, 'blog_images/${DateTime.now().millisecondsSinceEpoch}');
      } else if (webImageBytes != null) {
        finalImageUrl = await _uploadWebImage(webImageBytes, 'blog_images/${DateTime.now().millisecondsSinceEpoch}_${imageName ?? 'image'}');
      }
      
      // Update blog post document
      await _firestore.collection(_collection).doc(finalPostId).update({
        'title': title ?? post!.title,
        'content': content ?? post!.content,
        'imageUrl': finalImageUrl,
        'tags': tags ?? post!.tags,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Delete blog post
  Future<void> deleteBlogPost(String postId) async {
    try {
      await _firestore.collection(_collection).doc(postId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Increment view count
  Future<void> incrementViewCount(String postId) async {
    try {
      await _firestore.collection(_collection).doc(postId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  // Add comment to blog post
  Future<void> addComment(String postId, Comment comment) async {
    try {
      await _firestore.collection(_collection).doc(postId).update({
        'comments': FieldValue.arrayUnion([comment.toJson()]),
        'commentCount': FieldValue.increment(1),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get blog posts by tag
  Future<List<BlogPostModel>> getBlogPostsByTag(String tag) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('tags', arrayContains: tag)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return BlogPostModel.fromJson(data);
      }).toList();
    } catch (e) {
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

  // Upload web image to Firebase Storage
  Future<String> _uploadWebImage(Uint8List imageBytes, String path) async {
    try {
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putData(imageBytes);
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> likeBlogPost(String postId, String userId) async {
    try {
      final docRef = _firestore.collection(_collection).doc(postId);
      
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
      print('Error liking blog post: $e');
      throw e;
    }
  }

  Future<void> dislikeBlogPost(String postId, String userId) async {
    try {
      final docRef = _firestore.collection(_collection).doc(postId);
      
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
      print('Error disliking blog post: $e');
      throw e;
    }
  }

  // Delete a comment (Admin only)
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      final docRef = _firestore.collection(_collection).doc(postId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return;
        
        final data = doc.data()!;
        final comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
        
        // Remove the comment and its replies
        comments.removeWhere((comment) => 
          comment['id'] == commentId || comment['parentCommentId'] == commentId);
        
        transaction.update(docRef, {
          'comments': comments,
          'commentCount': comments.length,
        });
      });
    } catch (e) {
      print('Error deleting comment: $e');
      throw e;
    }
  }

  // Reply to a comment
  Future<void> replyToComment(String postId, String parentCommentId, Comment reply) async {
    try {
      await _firestore.collection(_collection).doc(postId).update({
        'comments': FieldValue.arrayUnion([reply.toJson()]),
        'commentCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error replying to comment: $e');
      throw e;
    }
  }

  // Dislike a comment
  Future<void> dislikeComment(String postId, String commentId, String userId) async {
    try {
      final docRef = _firestore.collection(_collection).doc(postId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return;
        
        final data = doc.data()!;
        final comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
        
        // Find and update the specific comment
        for (int i = 0; i < comments.length; i++) {
          if (comments[i]['id'] == commentId) {
            final commentLikes = List<String>.from(comments[i]['likes'] ?? []);
            final commentDislikes = List<String>.from(comments[i]['dislikes'] ?? []);
            
            // Remove from likes if present
            commentLikes.remove(userId);
            
            // Toggle dislike
            if (commentDislikes.contains(userId)) {
              commentDislikes.remove(userId);
            } else {
              commentDislikes.add(userId);
            }
            
            comments[i]['likes'] = commentLikes;
            comments[i]['dislikes'] = commentDislikes;
            break;
          }
        }
        
        transaction.update(docRef, {
          'comments': comments,
        });
      });
    } catch (e) {
      print('Error disliking comment: $e');
      throw e;
    }
  }

  // Get comments with replies organized
  List<Comment> organizeComments(List<dynamic> commentsData) {
    final List<Comment> allComments = commentsData.map((data) {
      final commentData = Map<String, dynamic>.from(data);
      return Comment.fromJson(commentData);
    }).toList();

    // Separate top-level comments and replies
    final Map<String, Comment> commentMap = {};
    final List<Comment> topLevelComments = [];
    final List<Comment> replies = [];

    // First pass: categorize comments
    for (final comment in allComments) {
      commentMap[comment.id] = comment;
      if (comment.parentId == null) {
        topLevelComments.add(comment);
      } else {
        replies.add(comment);
      }
    }

    // Second pass: attach replies to their parent comments
    final Map<String, List<Comment>> replyMap = {};
    for (final reply in replies) {
      if (reply.parentId != null) {
        replyMap.putIfAbsent(reply.parentId!, () => []).add(reply);
      }
    }

    // Create final comment list with nested replies
    final List<Comment> organizedComments = [];
    for (final comment in topLevelComments) {
      final commentReplies = replyMap[comment.id] ?? [];
      // Sort replies by creation date
      commentReplies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      organizedComments.add(comment.copyWith(replies: commentReplies));
    }

    // Sort top-level comments by creation date (newest first)
    organizedComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return organizedComments;
  }

  // Like a comment
  Future<void> likeComment(String postId, String commentId, String userId) async {
    try {
      final docRef = _firestore.collection(_collection).doc(postId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return;
        
        final data = doc.data()!;
        final comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
        
        // Find and update the specific comment
        for (int i = 0; i < comments.length; i++) {
          if (comments[i]['id'] == commentId) {
            final commentLikes = List<String>.from(comments[i]['likes'] ?? []);
            final commentDislikes = List<String>.from(comments[i]['dislikes'] ?? []);
            
            // Remove from dislikes if present
            commentDislikes.remove(userId);
            
            // Toggle like
            if (commentLikes.contains(userId)) {
              commentLikes.remove(userId);
            } else {
              commentLikes.add(userId);
            }
            
            comments[i]['likes'] = commentLikes;
            comments[i]['dislikes'] = commentDislikes;
            break;
          }
        }
        
        transaction.update(docRef, {
          'comments': comments,
        });
      });
    } catch (e) {
      print('Error liking comment: $e');
      throw e;
    }
  }

  // Upload file using FilePicker result (supports both web and mobile)
  Future<String> uploadFileFromPicker(PlatformFile file, String path) async {
    try {
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask;
      if (kIsWeb) {
        if (file.bytes != null) {
          uploadTask = ref.putData(file.bytes!);
        } else {
          throw Exception('No file data available for web upload');
        }
      } else {
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
} 