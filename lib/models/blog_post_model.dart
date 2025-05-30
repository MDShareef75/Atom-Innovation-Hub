import 'package:cloud_firestore/cloud_firestore.dart';

class BlogPostModel {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final String authorId;
  final String authorName;
  final List<String> tags;
  final int viewCount;
  final int commentCount;
  final List<Comment> comments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> likes;
  final List<String> dislikes;

  BlogPostModel({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl = '',
    required this.authorId,
    required this.authorName,
    this.tags = const [],
    this.viewCount = 0,
    this.commentCount = 0,
    this.comments = const [],
    required this.createdAt,
    required this.updatedAt,
    this.likes = const [],
    this.dislikes = const [],
  });

  factory BlogPostModel.fromJson(Map<String, dynamic> json) {
    var commentsList = <Comment>[];
    if (json['comments'] != null) {
      commentsList = List<Comment>.from(
        (json['comments'] as List).map((item) => Comment.fromJson(item)),
      );
    }

    return BlogPostModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      viewCount: json['viewCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      comments: commentsList,
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
      likes: List<String>.from(json['likes'] ?? []),
      dislikes: List<String>.from(json['dislikes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'authorId': authorId,
      'authorName': authorName,
      'tags': tags,
      'viewCount': viewCount,
      'commentCount': commentCount,
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'likes': likes,
      'dislikes': dislikes,
    };
  }

  BlogPostModel copyWith({
    String? id,
    String? title,
    String? content,
    String? imageUrl,
    String? authorId,
    String? authorName,
    List<String>? tags,
    int? viewCount,
    int? commentCount,
    List<Comment>? comments,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? likes,
    List<String>? dislikes,
  }) {
    return BlogPostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      tags: tags ?? this.tags,
      viewCount: viewCount ?? this.viewCount,
      commentCount: commentCount ?? this.commentCount,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
    );
  }
}

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String content;
  final DateTime createdAt;
  final List<String> likes;
  final String? parentId;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl = '',
    required this.content,
    required this.createdAt,
    this.likes = const [],
    this.parentId,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    var repliesList = <Comment>[];
    if (json['replies'] != null) {
      repliesList = List<Comment>.from(
        (json['replies'] as List).map((item) => Comment.fromJson(item)),
      );
    }

    return Comment(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userPhotoUrl: json['userPhotoUrl'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      likes: List<String>.from(json['likes'] ?? []),
      parentId: json['parentId'],
      replies: repliesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'createdAt': createdAt,
      'likes': likes,
      'parentId': parentId,
      'replies': replies.map((reply) => reply.toJson()).toList(),
    };
  }

  Comment copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? content,
    DateTime? createdAt,
    List<String>? likes,
    String? parentId,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      parentId: parentId ?? this.parentId,
      replies: replies ?? this.replies,
    );
  }
} 