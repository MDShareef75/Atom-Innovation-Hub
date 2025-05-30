import 'package:cloud_firestore/cloud_firestore.dart';

class AppModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String downloadUrl;
  final List<String> features;
  final String version;
  final int downloadCount;
  final DateTime releaseDate;
  final DateTime lastUpdated;
  final DateTime createdAt;
  final String authorId;
  final String authorName;
  final List<String> likes;
  final List<String> dislikes;
  final String? uploadedImageName;
  final String? uploadedApkName;
  final DateTime? imageUploadedAt;
  final DateTime? apkUploadedAt;

  AppModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.downloadUrl,
    required this.features,
    required this.version,
    this.downloadCount = 0,
    required this.releaseDate,
    required this.lastUpdated,
    required this.createdAt,
    required this.authorId,
    required this.authorName,
    this.likes = const [],
    this.dislikes = const [],
    this.uploadedImageName,
    this.uploadedApkName,
    this.imageUploadedAt,
    this.apkUploadedAt,
  });

  factory AppModel.fromJson(Map<String, dynamic> json) {
    return AppModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
      features: List<String>.from(json['features'] ?? []),
      version: json['version'] ?? '1.0.0',
      downloadCount: json['downloadCount'] ?? 0,
      releaseDate: json['releaseDate'] != null 
          ? (json['releaseDate'] as Timestamp).toDate() 
          : DateTime.now(),
      lastUpdated: json['lastUpdated'] != null 
          ? (json['lastUpdated'] as Timestamp).toDate() 
          : DateTime.now(),
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      likes: List<String>.from(json['likes'] ?? []),
      dislikes: List<String>.from(json['dislikes'] ?? []),
      uploadedImageName: json['uploadedImageName'],
      uploadedApkName: json['uploadedApkName'],
      imageUploadedAt: json['imageUploadedAt'] != null 
          ? (json['imageUploadedAt'] as Timestamp).toDate() 
          : null,
      apkUploadedAt: json['apkUploadedAt'] != null 
          ? (json['apkUploadedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'downloadUrl': downloadUrl,
      'features': features,
      'version': version,
      'downloadCount': downloadCount,
      'releaseDate': releaseDate,
      'lastUpdated': lastUpdated,
      'createdAt': createdAt,
      'authorId': authorId,
      'authorName': authorName,
      'likes': likes,
      'dislikes': dislikes,
      'uploadedImageName': uploadedImageName,
      'uploadedApkName': uploadedApkName,
      'imageUploadedAt': imageUploadedAt,
      'apkUploadedAt': apkUploadedAt,
    };
  }

  AppModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? downloadUrl,
    List<String>? features,
    String? version,
    int? downloadCount,
    DateTime? releaseDate,
    DateTime? lastUpdated,
    DateTime? createdAt,
    String? authorId,
    String? authorName,
    List<String>? likes,
    List<String>? dislikes,
    String? uploadedImageName,
    String? uploadedApkName,
    DateTime? imageUploadedAt,
    DateTime? apkUploadedAt,
  }) {
    return AppModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      features: features ?? this.features,
      version: version ?? this.version,
      downloadCount: downloadCount ?? this.downloadCount,
      releaseDate: releaseDate ?? this.releaseDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      uploadedImageName: uploadedImageName ?? this.uploadedImageName,
      uploadedApkName: uploadedApkName ?? this.uploadedApkName,
      imageUploadedAt: imageUploadedAt ?? this.imageUploadedAt,
      apkUploadedAt: apkUploadedAt ?? this.apkUploadedAt,
    );
  }
} 