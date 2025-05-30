class Comment {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final List<String> likes;
  final List<String> dislikes;
  final String? parentCommentId; // For replies
  final List<Comment> replies; // Nested replies
  final String? authorProfilePicture;

  Comment({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.likes = const [],
    this.dislikes = const [],
    this.parentCommentId,
    this.replies = const [],
    this.authorProfilePicture,
  });

  factory Comment.fromJson(Map<String, dynamic> json, String docId) {
    return Comment(
      id: docId,
      content: json['content'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? 'Anonymous',
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      likes: List<String>.from(json['likes'] ?? []),
      dislikes: List<String>.from(json['dislikes'] ?? []),
      parentCommentId: json['parentCommentId'],
      replies: [], // Replies will be loaded separately
      authorProfilePicture: json['authorProfilePicture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt,
      'likes': likes,
      'dislikes': dislikes,
      'parentCommentId': parentCommentId,
      'authorProfilePicture': authorProfilePicture,
    };
  }

  Comment copyWith({
    String? id,
    String? content,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    List<String>? likes,
    List<String>? dislikes,
    String? parentCommentId,
    List<Comment>? replies,
    String? authorProfilePicture,
  }) {
    return Comment(
      id: id ?? this.id,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replies: replies ?? this.replies,
      authorProfilePicture: authorProfilePicture ?? this.authorProfilePicture,
    );
  }
} 