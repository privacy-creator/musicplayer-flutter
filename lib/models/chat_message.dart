class ChatMessage {
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isMine;

  const ChatMessage({
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isMine,
  });
}
