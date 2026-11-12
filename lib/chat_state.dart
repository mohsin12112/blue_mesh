import 'chat_message.dart';

class ChatState {
  final List<ChatMessage> messages;
  final int connectedPeerCount;
  final bool isHost;
  final bool isDiscovering;

  ChatState({
    required this.messages,
    this.connectedPeerCount = 0,
    this.isHost = false,
    this.isDiscovering = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    int? connectedPeerCount,
    bool? isHost,
    bool? isDiscovering,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      connectedPeerCount: connectedPeerCount ?? this.connectedPeerCount,
      isHost: isHost ?? this.isHost,
      isDiscovering: isDiscovering ?? this.isDiscovering,
    );
  }
}