enum MessageType { user, bot, clarify, error }

class ChatMessage {
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final int? calories;

  ChatMessage({
    required this.text,
    required this.type,
    required this.timestamp,
    this.calories,
  });
}
