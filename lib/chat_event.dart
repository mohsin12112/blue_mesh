abstract class ChatEvent {}

class StartHostingRequested extends ChatEvent {}

class StartJoinerRequested extends ChatEvent {}

class StopMeshRequested extends ChatEvent {}

class SendGroupMessageRequested extends ChatEvent {
  final String text;
  SendGroupMessageRequested(this.text);
}

class SendGroupImageRequested extends ChatEvent {
  final String imagePath;
  SendGroupImageRequested({required this.imagePath});
}

class SendGroupVoiceRequested extends ChatEvent {
  final String voicePath;
  SendGroupVoiceRequested({required this.voicePath});
}

class MessageReceivedFromPeer extends ChatEvent {
  final String text;
  final String senderName;
  final String? savedImagePath;
  final String? savedVoicePath;
  final String type;
  final List<String> routePath;

  MessageReceivedFromPeer({
    required this.text,
    required this.senderName,
    this.savedImagePath,
    this.savedVoicePath,
    this.type = 'text',
    this.routePath = const [],
  });
}

class PeerCountUpdated extends ChatEvent {
  final int count;
  PeerCountUpdated(this.count);
}