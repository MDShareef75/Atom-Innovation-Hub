import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:atoms_innovation_hub/services/blog_service.dart';
import 'package:atoms_innovation_hub/services/auth_service.dart';
import 'package:atoms_innovation_hub/models/blog_post_model.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class BlogPostScreen extends StatefulWidget {
  final String postId;

  const BlogPostScreen({super.key, required this.postId});

  @override
  State<BlogPostScreen> createState() => _BlogPostScreenState();
}

class _BlogPostScreenState extends State<BlogPostScreen> {
  late Future<BlogPostModel?> _postFuture;
  BlogPostModel? _currentPost;
  final TextEditingController _commentController = TextEditingController();
  final Map<String, TextEditingController> _replyControllers = {};
  final Map<String, bool> _replyingTo = {};
  bool _isSubmittingComment = false;
  bool _hasCommentText = false;

  @override
  void initState() {
    super.initState();
    _loadPost();
    
    // Add listener to comment controller for button styling
    _commentController.addListener(() {
      setState(() {
        _hasCommentText = _commentController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    // Dispose all reply controllers
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadPost() {
    _postFuture = Provider.of<BlogService>(context, listen: false).getBlogPostById(widget.postId);
    
    // Increment view count and log analytics
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final post = await _postFuture;
      if (post != null) {
        setState(() {
          _currentPost = post;
        });
        
        final blogService = Provider.of<BlogService>(context, listen: false);
        final authService = Provider.of<AuthService>(context, listen: false);
        
        // Increment view count
        await blogService.incrementViewCount(post.id);
        
        // Log view event if user is logged in
        // Removed analytics logging for now
      }
    });
  }

  Future<void> _handleLike(String userId) async {
    if (_currentPost == null) return;
    
    try {
      // Optimistically update UI
      setState(() {
        final likes = List<String>.from(_currentPost!.likes);
        final dislikes = List<String>.from(_currentPost!.dislikes);
        
        // Remove from dislikes if present
        dislikes.remove(userId);
        
        // Toggle like
        if (likes.contains(userId)) {
          likes.remove(userId);
        } else {
          likes.add(userId);
        }
        
        _currentPost = _currentPost!.copyWith(
          likes: likes,
          dislikes: dislikes,
        );
      });
      
      // Update in database
      await Provider.of<BlogService>(context, listen: false)
          .likeBlogPost(_currentPost!.id, userId);
    } catch (e) {
      // Revert optimistic update on error
      _loadPost();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _handleDislike(String userId) async {
    if (_currentPost == null) return;
    
    try {
      // Optimistically update UI
      setState(() {
        final likes = List<String>.from(_currentPost!.likes);
        final dislikes = List<String>.from(_currentPost!.dislikes);
        
        // Remove from likes if present
        likes.remove(userId);
        
        // Toggle dislike
        if (dislikes.contains(userId)) {
          dislikes.remove(userId);
        } else {
          dislikes.add(userId);
        }
        
        _currentPost = _currentPost!.copyWith(
          likes: likes,
          dislikes: dislikes,
        );
      });
      
      // Update in database
      await Provider.of<BlogService>(context, listen: false)
          .dislikeBlogPost(_currentPost!.id, userId);
    } catch (e) {
      // Revert optimistic update on error
      _loadPost();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) {
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to comment'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final blogService = Provider.of<BlogService>(context, listen: false);

      if (_currentPost != null) {
        final userModel = await authService.userModelStream(user.uid).first;
        if (userModel != null) {
          final comment = Comment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: user.uid,
            userName: userModel.name,
            userPhotoUrl: userModel.photoUrl ?? '',
            content: _commentController.text.trim(),
            createdAt: DateTime.now(),
            likes: [],
          );

          // Clear the text field immediately
          _commentController.clear();

          // Optimistically update UI first
          setState(() {
            final updatedComments = List<Comment>.from(_currentPost!.comments);
            updatedComments.add(comment);
            _currentPost = _currentPost!.copyWith(
              comments: updatedComments,
              commentCount: _currentPost!.commentCount + 1,
            );
          });

          // Then update in database
          await blogService.addComment(_currentPost!.id, comment);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment posted successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Revert optimistic update on error
      _loadPost();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  Future<void> _submitReply(String parentCommentId) async {
    final controller = _replyControllers[parentCommentId];
    if (controller == null || controller.text.trim().isEmpty) {
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to reply'),
        ),
      );
      return;
    }

    try {
      final blogService = Provider.of<BlogService>(context, listen: false);

      if (_currentPost != null) {
        final userModel = await authService.userModelStream(user.uid).first;
        if (userModel != null) {
          final reply = Comment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: user.uid,
            userName: userModel.name,
            userPhotoUrl: userModel.photoUrl ?? '',
            content: controller.text.trim(),
            createdAt: DateTime.now(),
            likes: [],
            parentId: parentCommentId,
          );

          // Clear the text field and hide reply form
          controller.clear();
          setState(() {
            _replyingTo[parentCommentId] = false;
          });

          // Optimistically update UI first - add reply to comments list
          setState(() {
            final updatedComments = List<Comment>.from(_currentPost!.comments);
            // Add the reply directly to the comments list (not nested in parent.replies)
            updatedComments.add(reply);
            
            _currentPost = _currentPost!.copyWith(
              comments: updatedComments,
              commentCount: _currentPost!.commentCount + 1,
            );
          });

          // Then update in database
          await blogService.replyToComment(_currentPost!.id, parentCommentId, reply);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reply posted successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Revert optimistic update on error
      _loadPost();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleReply(String commentId) {
    setState(() {
      _replyingTo[commentId] = !(_replyingTo[commentId] ?? false);
      if (_replyingTo[commentId] == true) {
        final controller = TextEditingController();
        _replyControllers[commentId] = controller;
        
        // Add listener for reply text changes
        controller.addListener(() {
          setState(() {
            // This will trigger rebuild for button styling
          });
        });
      }
    });
  }

  TextEditingController _getReplyController(String commentId) {
    return _replyControllers.putIfAbsent(commentId, () {
      final controller = TextEditingController();
      controller.addListener(() {
        setState(() {
          // This will trigger rebuild for button styling
        });
      });
      return controller;
    });
  }

  bool _hasReplyText(String commentId) {
    final controller = _replyControllers[commentId];
    return controller != null && controller.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog Post'),
      ),
      body: FutureBuilder<BlogPostModel?>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final post = snapshot.data;

          if (post == null) {
            return const Center(
              child: Text('Blog post not found'),
            );
          }

          // Use current post state if available, otherwise use snapshot data
          final displayPost = _currentPost ?? post;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post Image
                if (displayPost.imageUrl.isNotEmpty)
                  Container(
                    width: double.infinity,
                    height: 400,
                    margin: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: displayPost.imageUrl,
                        width: double.infinity,
                        height: 400,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: double.infinity,
                          height: 400,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: 400,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.article,
                                size: 64,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        displayPost.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Author and Date
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            child: Text(
                              displayPost.authorName.isNotEmpty ? displayPost.authorName[0] : 'A',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayPost.authorName,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  DateFormat('dd-MM-yyyy').format(displayPost.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Like/Dislike buttons
                      Consumer<AuthService>(
                        builder: (context, authService, child) {
                          final userId = authService.currentUser?.uid;
                          final isLiked = userId != null && displayPost.likes.contains(userId);
                          final isDisliked = userId != null && displayPost.dislikes.contains(userId);
                          
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final isMobile = constraints.maxWidth < 600;
                              
                              if (isMobile) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Like/Dislike buttons row
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: userId != null ? () async {
                                              await _handleLike(userId!);
                                            } : null,
                                            icon: Icon(
                                              isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                              size: 18,
                                            ),
                                            label: Text('${displayPost.likes.length}'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isLiked ? Colors.blue : null,
                                              foregroundColor: isLiked ? Colors.white : null,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: userId != null ? () async {
                                              await _handleDislike(userId!);
                                            } : null,
                                            icon: Icon(
                                              isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                                              size: 18,
                                            ),
                                            label: Text('${displayPost.dislikes.length}'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isDisliked ? Colors.red : null,
                                              foregroundColor: isDisliked ? Colors.white : null,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // View and comment counts
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.visibility, size: 20, color: Colors.blue),
                                                const SizedBox(width: 8),
                                                Column(
                                                  children: [
                                                    Text(
                                                      '${displayPost.viewCount}',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                    const Text(
                                                      'Views',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 1,
                                            height: 40,
                                            color: Colors.grey[300],
                                          ),
                                          Expanded(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.comment, size: 20, color: Colors.green),
                                                const SizedBox(width: 8),
                                                Column(
                                                  children: [
                                                    Text(
                                                      '${displayPost.commentCount}',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                    const Text(
                                                      'Comments',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return Row(
                                  children: [
                                    // Like button
                                    ElevatedButton.icon(
                                      onPressed: userId != null ? () async {
                                        await _handleLike(userId!);
                                      } : null,
                                      icon: Icon(
                                        isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                        size: 20,
                                      ),
                                      label: Text('${displayPost.likes.length}'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isLiked ? Colors.blue : null,
                                        foregroundColor: isLiked ? Colors.white : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Dislike button
                                    ElevatedButton.icon(
                                      onPressed: userId != null ? () async {
                                        await _handleDislike(userId!);
                                      } : null,
                                      icon: Icon(
                                        isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                                        size: 20,
                                      ),
                                      label: Text('${displayPost.dislikes.length}'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDisliked ? Colors.red : null,
                                        foregroundColor: isDisliked ? Colors.white : null,
                                      ),
                                    ),
                                    const Spacer(),
                                    // View and comment counts
                                    Row(
                                      children: [
                                        const Icon(Icons.visibility, size: 16),
                                        const SizedBox(width: 4),
                                        Text('${displayPost.viewCount}'),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.comment, size: 16),
                                        const SizedBox(width: 4),
                                        Text('${displayPost.commentCount}'),
                                      ],
                                    ),
                                  ],
                                );
                              }
                            },
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Tags
                      if (displayPost.tags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: displayPost.tags.map((tag) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Post Content
                      MarkdownBody(
                        data: displayPost.content,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          h1: Theme.of(context).textTheme.headlineLarge,
                          h2: Theme.of(context).textTheme.headlineMedium,
                          h3: Theme.of(context).textTheme.headlineSmall,
                          p: Theme.of(context).textTheme.bodyLarge,
                        ),
                        onTapLink: (text, href, title) {
                          if (href != null) {
                            launchUrl(Uri.parse(href));
                          }
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Comments Section
                      Text(
                        'Comments (${displayPost.commentCount})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Comment Form
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D3748), // Dark form background
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF4A5568)), // Dark border
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Consumer<AuthService>(
                              builder: (context, authService, child) {
                                final user = authService.currentUser;
                                return CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey[600],
                                  backgroundImage: user?.photoURL?.isNotEmpty == true 
                                      ? NetworkImage(user!.photoURL!) 
                                      : null,
                                  child: user?.photoURL?.isEmpty != false 
                                    ? Text(
                                        user?.displayName?.isNotEmpty == true 
                                          ? user!.displayName![0].toUpperCase()
                                          : user?.email?.isNotEmpty == true
                                            ? user!.email![0].toUpperCase()
                                            : 'A',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      )
                                    : null,
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  TextField(
                                    controller: _commentController,
                                    decoration: InputDecoration(
                                      hintText: 'Add a comment...',
                                      hintStyle: TextStyle(color: Colors.grey[400]), // Light hint text
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: const Color(0xFF4A5568)), // Dark border
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF1A202C), // Dark input background
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white, // White text
                                      fontSize: 14,
                                    ),
                                    minLines: 1,
                                    maxLines: 5,
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _isSubmittingComment ? null : _submitComment,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _hasCommentText 
                                        ? const Color(0xFF1565C0) // Darker blue
                                        : Colors.grey[600], // Dark disabled color
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      elevation: _hasCommentText ? 6 : 2,
                                      shadowColor: _hasCommentText 
                                        ? const Color(0xFF1565C0).withOpacity(0.4)
                                        : Colors.grey.withOpacity(0.2),
                                    ),
                                    child: _isSubmittingComment
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            'Post Comment',
                                            style: TextStyle(
                                              fontWeight: _hasCommentText ? FontWeight.bold : FontWeight.normal,
                                              fontSize: _hasCommentText ? 15 : 14,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Comments List
                      if (displayPost.comments.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D3748), // Dark background
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF4A5568)), // Dark border
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.comment_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No comments yet',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[300], // Light text on dark background
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Be the first to comment!',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[400], // Light text on dark background
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        // Show top-level comments with nested replies
                        ...displayPost.comments
                            .where((comment) => comment.parentId == null) // Only top-level comments
                            .map((comment) {
                              // Find all replies for this comment
                              final replies = displayPost.comments
                                  .where((c) => c.parentId == comment.id)
                                  .toList();
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: const Color(0xFF2D3748), // Dark card background
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Comment Header
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: Colors.grey[600],
                                              backgroundImage: comment.userPhotoUrl.isNotEmpty 
                                                  ? NetworkImage(comment.userPhotoUrl) 
                                                  : null,
                                              child: comment.userPhotoUrl.isEmpty 
                                                  ? Text(
                                                      comment.userName.isNotEmpty 
                                                          ? comment.userName[0].toUpperCase() 
                                                          : '?',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ) 
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    comment.userName,
                                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white, // White text on dark background
                                                    ),
                                                  ),
                                                  Text(
                                                    DateFormat('dd-MM-yyyy HH:mm').format(comment.createdAt),
                                                    style: TextStyle(
                                                      color: Colors.grey[400], // Light grey for timestamp
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 12),
                                        
                                        // Comment Content
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1A202C), // Darker content background
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFF4A5568), width: 1), // Dark border
                                          ),
                                          child: Text(
                                            comment.content,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.grey[100], // Light text
                                              height: 1.4,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 12),
                                        
                                        // Action buttons (Like and Reply)
                                        Consumer<AuthService>(
                                          builder: (context, authService, child) {
                                            final userId = authService.currentUser?.uid;
                                            final isLiked = userId != null && comment.likes.contains(userId);
                                            
                                            return Row(
                                              children: [
                                                // Like button
                                                GestureDetector(
                                                  onTap: userId != null ? () async {
                                                    try {
                                                      // Optimistically update UI first
                                                      setState(() {
                                                        final updatedComments = List<Comment>.from(_currentPost!.comments);
                                                        final commentIndex = updatedComments.indexWhere((c) => c.id == comment.id);
                                                        if (commentIndex != -1) {
                                                          final likes = List<String>.from(updatedComments[commentIndex].likes);
                                                          if (likes.contains(userId)) {
                                                            likes.remove(userId);
                                                          } else {
                                                            likes.add(userId);
                                                          }
                                                          updatedComments[commentIndex] = updatedComments[commentIndex].copyWith(likes: likes);
                                                          _currentPost = _currentPost!.copyWith(comments: updatedComments);
                                                        }
                                                      });
                                                      
                                                      // Then update in database
                                                      final blogService = Provider.of<BlogService>(context, listen: false);
                                                      await blogService.likeComment(_currentPost!.id, comment.id, userId);
                                                    } catch (e) {
                                                      // Revert optimistic update on error
                                                      _loadPost();
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Error: $e')),
                                                      );
                                                    }
                                                  } : null,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: isLiked ? Colors.blue.withOpacity(0.2) : const Color(0xFF4A5568), // Dark button background
                                                      borderRadius: BorderRadius.circular(20),
                                                      border: Border.all(
                                                        color: isLiked ? Colors.blue : const Color(0xFF718096), // Dark border
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                                          color: isLiked ? Colors.blue : Colors.grey[300], // Light icon
                                                          size: 16,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          '${comment.likes.length}',
                                                          style: TextStyle(
                                                            color: isLiked ? Colors.blue : Colors.grey[300], // Light text
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                
                                                const SizedBox(width: 12),
                                                
                                                // Reply button
                                                GestureDetector(
                                                  onTap: () => _toggleReply(comment.id),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: (_replyingTo[comment.id] ?? false) ? Colors.green.withOpacity(0.2) : const Color(0xFF4A5568), // Dark button background
                                                      borderRadius: BorderRadius.circular(20),
                                                      border: Border.all(
                                                        color: (_replyingTo[comment.id] ?? false) ? Colors.green : const Color(0xFF718096), // Dark border
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.reply,
                                                          color: (_replyingTo[comment.id] ?? false) ? Colors.green : Colors.grey[300], // Light icon
                                                          size: 16,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Reply',
                                                          style: TextStyle(
                                                            color: (_replyingTo[comment.id] ?? false) ? Colors.green : Colors.grey[300], // Light text
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                
                                                // Show replies count if any
                                                if (replies.isNotEmpty) ...[
                                                  const SizedBox(width: 16),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.withOpacity(0.2), // Dark blue background
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: Colors.blue.withOpacity(0.3)), // Dark border
                                                    ),
                                                    child: Text(
                                                      '${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                                                      style: TextStyle(
                                                        color: Colors.blue[300], // Light blue text
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            );
                                          },
                                        ),
                                        
                                        // Reply form
                                        if (_replyingTo[comment.id] ?? false) ...[
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1A202C), // Dark form background
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: const Color(0xFF4A5568)), // Dark border
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Reply to ${comment.userName}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green[300], // Light green text
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Consumer<AuthService>(
                                                      builder: (context, authService, child) {
                                                        final user = authService.currentUser;
                                                        return CircleAvatar(
                                                          radius: 16,
                                                          backgroundColor: Colors.grey[600],
                                                          backgroundImage: user?.photoURL?.isNotEmpty == true 
                                                              ? NetworkImage(user!.photoURL!) 
                                                              : null,
                                                          child: user?.photoURL?.isEmpty != false 
                                                            ? Text(
                                                                user?.displayName?.isNotEmpty == true 
                                                                  ? user!.displayName![0].toUpperCase()
                                                                  : user?.email?.isNotEmpty == true
                                                                    ? user!.email![0].toUpperCase()
                                                                    : 'A',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 14,
                                                                ),
                                                              )
                                                            : null,
                                                        );
                                                      },
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                        children: [
                                                          TextField(
                                                            controller: _getReplyController(comment.id),
                                                            decoration: InputDecoration(
                                                              hintText: 'Write a reply...',
                                                              hintStyle: TextStyle(color: Colors.grey[400]), // Light hint text
                                                              border: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(12),
                                                                borderSide: BorderSide(color: const Color(0xFF4A5568)), // Dark border
                                                              ),
                                                              focusedBorder: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(12),
                                                                borderSide: const BorderSide(color: Colors.green),
                                                              ),
                                                              filled: true,
                                                              fillColor: const Color(0xFF2D3748), // Dark input background
                                                              contentPadding: const EdgeInsets.all(12),
                                                            ),
                                                            style: const TextStyle(
                                                              color: Colors.white, // White text
                                                              fontSize: 14,
                                                            ),
                                                            minLines: 1,
                                                            maxLines: 3,
                                                          ),
                                                          const SizedBox(height: 12),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.end,
                                                            children: [
                                                              TextButton(
                                                                onPressed: () {
                                                                  setState(() {
                                                                    _replyingTo[comment.id] = false;
                                                                    _replyControllers[comment.id]?.clear();
                                                                  });
                                                                },
                                                                child: Text(
                                                                  'Cancel',
                                                                  style: TextStyle(color: Colors.grey[400]), // Light text
                                                                ),
                                                              ),
                                                              const SizedBox(width: 8),
                                                              ElevatedButton(
                                                                onPressed: _hasReplyText(comment.id) 
                                                                  ? () => _submitReply(comment.id)
                                                                  : null,
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: _hasReplyText(comment.id) 
                                                                    ? Colors.green 
                                                                    : Colors.grey[600], // Dark disabled color
                                                                  foregroundColor: Colors.white,
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(8),
                                                                  ),
                                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                                ),
                                                                child: const Text(
                                                                  'Reply',
                                                                  style: TextStyle(
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 13,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        
                                        // Show nested replies
                                        if (replies.isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          Container(
                                            margin: const EdgeInsets.only(left: 16),
                                            padding: const EdgeInsets.only(left: 16),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                left: BorderSide(
                                                  color: Colors.blue.withOpacity(0.4), // Slightly brighter border
                                                  width: 3,
                                                ),
                                              ),
                                            ),
                                            child: Column(
                                              children: replies.map((reply) => Container(
                                                margin: const EdgeInsets.only(bottom: 12),
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF1A202C), // Dark reply background
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: const Color(0xFF4A5568)), // Dark border
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 16,
                                                          backgroundColor: Colors.grey[600],
                                                          backgroundImage: reply.userPhotoUrl.isNotEmpty 
                                                              ? NetworkImage(reply.userPhotoUrl) 
                                                              : null,
                                                          child: reply.userPhotoUrl.isEmpty 
                                                              ? Text(
                                                                  reply.userName.isNotEmpty 
                                                                      ? reply.userName[0].toUpperCase() 
                                                                      : '?',
                                                                  style: const TextStyle(
                                                                    color: Colors.white,
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 12,
                                                                  ),
                                                                ) 
                                                              : null,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    reply.userName,
                                                                    style: const TextStyle(
                                                                      fontWeight: FontWeight.bold,
                                                                      fontSize: 13,
                                                                      color: Colors.white, // White username
                                                                    ),
                                                                  ),
                                                                  const SizedBox(width: 8),
                                                                  Icon(
                                                                    Icons.reply,
                                                                    size: 12,
                                                                    color: Colors.blue[400], // Light blue icon
                                                                  ),
                                                                  const SizedBox(width: 4),
                                                                  Text(
                                                                    comment.userName,
                                                                    style: TextStyle(
                                                                      fontSize: 12,
                                                                      color: Colors.blue[400], // Light blue text
                                                                      fontWeight: FontWeight.w600,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              Text(
                                                                DateFormat('dd-MM-yyyy HH:mm').format(reply.createdAt),
                                                                style: TextStyle(
                                                                  color: Colors.grey[400], // Light grey timestamp
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      reply.content,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white, // White reply text
                                                        height: 1.3,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    // Reply like button
                                                    Consumer<AuthService>(
                                                      builder: (context, authService, child) {
                                                        final userId = authService.currentUser?.uid;
                                                        final isReplyLiked = userId != null && reply.likes.contains(userId);
                                                        
                                                        return GestureDetector(
                                                          onTap: userId != null ? () async {
                                                            try {
                                                              // Optimistically update UI first
                                                              setState(() {
                                                                final updatedComments = List<Comment>.from(_currentPost!.comments);
                                                                final replyIndex = updatedComments.indexWhere((c) => c.id == reply.id);
                                                                if (replyIndex != -1) {
                                                                  final likes = List<String>.from(updatedComments[replyIndex].likes);
                                                                  if (likes.contains(userId)) {
                                                                    likes.remove(userId);
                                                                  } else {
                                                                    likes.add(userId);
                                                                  }
                                                                  updatedComments[replyIndex] = updatedComments[replyIndex].copyWith(likes: likes);
                                                                  _currentPost = _currentPost!.copyWith(comments: updatedComments);
                                                                }
                                                              });
                                                              
                                                              // Then update in database
                                                              final blogService = Provider.of<BlogService>(context, listen: false);
                                                              await blogService.likeComment(_currentPost!.id, reply.id, userId);
                                                            } catch (e) {
                                                              // Revert optimistic update on error
                                                              _loadPost();
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(content: Text('Error: $e')),
                                                              );
                                                            }
                                                          } : null,
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: isReplyLiked ? Colors.blue.withOpacity(0.2) : const Color(0xFF4A5568), // Dark button background
                                                              borderRadius: BorderRadius.circular(16),
                                                              border: Border.all(
                                                                color: isReplyLiked ? Colors.blue : const Color(0xFF718096), // Dark border
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Icon(
                                                                  isReplyLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                                                  color: isReplyLiked ? Colors.blue : Colors.grey[400], // Light icon
                                                                  size: 14,
                                                                ),
                                                                if (reply.likes.isNotEmpty) ...[
                                                                  const SizedBox(width: 4),
                                                                  Text(
                                                                    '${reply.likes.length}',
                                                                    style: TextStyle(
                                                                      color: isReplyLiked ? Colors.blue : Colors.grey[400], // Light text
                                                                      fontSize: 12,
                                                                      fontWeight: FontWeight.bold,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              )).toList(),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                        
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 