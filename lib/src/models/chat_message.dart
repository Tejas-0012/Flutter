class ChatMessage {
  final String userId;
  final String username;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.userId,
    required this.username,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      userId: json['userId'],
      username: json['username'],
      message: json['message'],
      timestamp: DateTime.parse(json['createdAt'] ?? json['timestamp']),
    );
  }
}
