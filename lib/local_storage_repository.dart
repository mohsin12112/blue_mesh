import 'package:hive_flutter/hive_flutter.dart';
import 'chat_message.dart';

class LocalStorageRepository {
  static const String _chatBoxName = 'blue_mesh_history';
  static const String _profileBoxName = 'user_profile_box';
  static const String _offlineQueueBoxName = 'offline_message_queue';

  Box<ChatMessage> get _chatBox => Hive.box<ChatMessage>(_chatBoxName);
  Box get _profileBox => Hive.box(_profileBoxName);
  Box<ChatMessage> get _queueBox => Hive.box<ChatMessage>(_offlineQueueBoxName);

  Future<void> saveMessage(ChatMessage message) async {
    await _chatBox.put(message.id, message);
  }

  List<ChatMessage> getAllMessages() {
    return _chatBox.values.toList();
  }

  Future<void> deleteMessage(String id) async {
    await _chatBox.delete(id);
  }

  Future<void> clearAllHistory() async {
    await _chatBox.clear();
  }

  Future<void> queuePendingMessage(ChatMessage message) async {
    message.isDelivered = false;
    await _chatBox.put(message.id, message);
    await _queueBox.put(message.id, message);
  }

  List<ChatMessage> getPendingQueue() {
    return _queueBox.values.toList();
  }

  Future<void> markQueueAsDelivered(List<String> ids) async {
    for (String id in ids) {
      await _queueBox.delete(id);
      final msg = _chatBox.get(id);
      if (msg != null) {
        msg.isDelivered = true;
        await msg.save();
      }
    }
  }

  Future<void> saveUserProfile({required String name, String? imagePath}) async {
    await _profileBox.put('user_name', name);
    if (imagePath != null) {
      await _profileBox.put('user_avatar', imagePath);
    } else {
      await _profileBox.delete('user_avatar');
    }
  }

  String getUserName() {
    return _profileBox.get(
      'user_name',
      defaultValue: 'User_${DateTime.now().millisecondsSinceEpoch % 1000}',
    );
  }

  String? getUserAvatar() {
    return _profileBox.get('user_avatar') as String?;
  }
}