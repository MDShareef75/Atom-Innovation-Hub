class Rating {
  final String appId;
  final String userId;
  final double rating;
  final String? comment;
  final DateTime timestamp;

  Rating({
    required this.appId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'appId': appId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Rating.fromMap(Map<String, dynamic> map) {
    return Rating(
      appId: map['appId'] as String,
      userId: map['userId'] as String,
      rating: (map['rating'] as num).toDouble(),
      comment: map['comment'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
} 