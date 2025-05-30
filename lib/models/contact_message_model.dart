import 'package:cloud_firestore/cloud_firestore.dart';

class ContactMessageModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String subject;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? userId;
  final String? adminReply;
  final DateTime? repliedAt;
  final String? repliedByAdminId;
  final String? repliedByAdminName;

  ContactMessageModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.subject,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.userId,
    this.adminReply,
    this.repliedAt,
    this.repliedByAdminId,
    this.repliedByAdminName,
  });

  bool get hasReply => adminReply != null && adminReply!.isNotEmpty;

  factory ContactMessageModel.fromJson(Map<String, dynamic> json, String id) {
    return ContactMessageModel(
      id: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      userId: json['userId'],
      adminReply: json['adminReply'],
      repliedAt: json['repliedAt'] != null 
          ? (json['repliedAt'] as Timestamp).toDate() 
          : null,
      repliedByAdminId: json['repliedByAdminId'],
      repliedByAdminName: json['repliedByAdminName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'subject': subject,
      'message': message,
      'createdAt': createdAt,
      'isRead': isRead,
      'userId': userId,
      'adminReply': adminReply,
      'repliedAt': repliedAt,
      'repliedByAdminId': repliedByAdminId,
      'repliedByAdminName': repliedByAdminName,
    };
  }

  ContactMessageModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? subject,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? userId,
    String? adminReply,
    DateTime? repliedAt,
    String? repliedByAdminId,
    String? repliedByAdminName,
  }) {
    return ContactMessageModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      userId: userId ?? this.userId,
      adminReply: adminReply ?? this.adminReply,
      repliedAt: repliedAt ?? this.repliedAt,
      repliedByAdminId: repliedByAdminId ?? this.repliedByAdminId,
      repliedByAdminName: repliedByAdminName ?? this.repliedByAdminName,
    );
  }
} 