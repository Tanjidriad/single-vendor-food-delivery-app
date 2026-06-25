/// A single chat message on an order thread (customer ↔ rider).
class ChatMessage {
  final String id;
  final String senderId;

  /// Sender role as stored server-side: `CUSTOMER`, `RIDER`, `OWNER`, etc.
  /// Clients align bubbles by comparing this to their own role.
  final String senderRole;
  final String body;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.body,
    required this.createdAt,
  });

  bool get isFromRider => senderRole == 'RIDER';
  bool get isFromCustomer => senderRole == 'CUSTOMER';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal(),
    );
  }
}
