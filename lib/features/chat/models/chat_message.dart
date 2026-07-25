class ChatMessage {
  final String id;
  final String packageId;
  final String senderId;
  final String text;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.packageId,
    required this.senderId,
    required this.text,
    this.createdAt,
  });

  /// Handles both the REST history shape and the live socket payload
  /// (both expose `_id`, `packageId`, `senderId`, `text`, `createdAt`).
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    return ChatMessage(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      packageId: (json['packageId'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      createdAt: created is String ? DateTime.tryParse(created)?.toLocal() : null,
    );
  }
}
