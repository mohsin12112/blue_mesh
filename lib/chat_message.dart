import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 0)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String senderName;

  @HiveField(2)
  final String text;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final bool isMe;

  @HiveField(5)
  final String? imagePath;

  @HiveField(6)
  final String type;

  @HiveField(7)
  final String? mediaPath;

  @HiveField(8)
  bool isDelivered;

  final List<String> routePath;

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.imagePath,
    this.type = 'text',
    this.mediaPath,
    this.isDelivered = true,
    this.routePath = const [],
  });
}