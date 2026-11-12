import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_message.dart';
import 'bluetooth_repository.dart';
import 'local_storage_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final BluetoothRepository _btRepository;
  final LocalStorageRepository _storageRepository;

  StreamSubscription? _incomingMsgSubscription;
  StreamSubscription? _peerCountSubscription;

  ChatBloc({
    required BluetoothRepository btRepository,
    required LocalStorageRepository storageRepository,
  })  : _btRepository = btRepository,
        _storageRepository = storageRepository,

        super(ChatState(messages: storageRepository.getAllMessages())) {
    on<StartHostingRequested>(_onStartHosting);
    on<StartJoinerRequested>(_onStartJoiner);
    on<StopMeshRequested>(_onStopMesh);
    on<SendGroupMessageRequested>(_onSendTextMessage);
    on<SendGroupImageRequested>(_onSendImageMessage);
    on<SendGroupVoiceRequested>(_onSendVoiceMessage);
    on<MessageReceivedFromPeer>(_onMessageReceived);
    on<PeerCountUpdated>(_onPeerCountUpdated);

    _incomingMsgSubscription =
        _btRepository.incomingMessages.listen((dynamic rawData) async {
          final Map<String, dynamic> data = rawData is Map<String, dynamic>
              ? rawData
              : rawData is String
              ? (jsonDecode(rawData) as Map<String, dynamic>)
              : <String, dynamic>{};

          final String payloadType = data['type']?.toString() ?? 'text';
          final String? localMediaPath = data['localMediaPath']?.toString();
          final List<String> routePath =
          List<String>.from(data['routePath'] ?? []);

          add(MessageReceivedFromPeer(
            text: data['text']?.toString() ?? '',
            senderName: data['senderName']?.toString() ?? 'Mesh Peer',
            savedImagePath: payloadType == 'image' ? localMediaPath : null,
            savedVoicePath: payloadType == 'voice' ? localMediaPath : null,
            type: payloadType,
            routePath: routePath,
          ));
        });

    _peerCountSubscription =
        _btRepository.activePeerCount.listen((count) async {
          add(PeerCountUpdated(count));
          if (count > 0) {
            await _flushPendingOfflineQueue();
          }
        });
  }

  Future<void> _flushPendingOfflineQueue() async {
    final pendingMessages = _storageRepository.getPendingQueue();
    if (pendingMessages.isEmpty) return;

    final List<String> deliveredIds = [];

    for (var msg in pendingMessages) {
      bool success = false;

      if (msg.type == 'image' && msg.imagePath != null) {
        success = await _btRepository.broadcastFilePayload(
          filePath: msg.imagePath!,
          metadata: {
            'id': msg.id,
            'senderName': msg.senderName,
            'text': '',
            'mediaType': 'image',
            'extension': msg.imagePath!.split('.').last,
          },
        );
      } else if (msg.type == 'voice' && msg.mediaPath != null) {
        success = await _btRepository.broadcastFilePayload(
          filePath: msg.mediaPath!,
          metadata: {
            'id': msg.id,
            'senderName': msg.senderName,
            'text': msg.text,
            'mediaType': 'voice',
            'extension': msg.mediaPath!.split('.').last,
          },
        );
      } else {
        final payload = {
          'id': msg.id,
          'senderName': msg.senderName,
          'text': msg.text,
          'type': 'text',
        };
        success = await _btRepository.broadcastPayload(payload);
      }

      if (success) {
        deliveredIds.add(msg.id);
      }
    }

    await _storageRepository.markQueueAsDelivered(deliveredIds);
  }

  Future<void> _onStartHosting(
      StartHostingRequested event,
      Emitter<ChatState> emit,
      ) async {
    final String userName = _storageRepository.getUserName();
    emit(state.copyWith(isHost: true, isDiscovering: false));
    await _btRepository.startHosting(userName);
  }

  Future<void> _onStartJoiner(
      StartJoinerRequested event,
      Emitter<ChatState> emit,
      ) async {
    final String userName = _storageRepository.getUserName();
    emit(state.copyWith(isHost: false, isDiscovering: true));
    await _btRepository.startJoiner(userName);
  }

  Future<void> _onStopMesh(
      StopMeshRequested event,
      Emitter<ChatState> emit,
      ) async {
    await _btRepository.stopMesh();
    emit(state.copyWith(
      isHost: false,
      isDiscovering: false,
      connectedPeerCount: 0,
    ));
  }

  Future<void> _onSendTextMessage(
      SendGroupMessageRequested event,
      Emitter<ChatState> emit,
      ) async {
    final String myName = _storageRepository.getUserName();
    final String msgId = DateTime.now().millisecondsSinceEpoch.toString();

    final myMessage = ChatMessage(
      id: msgId,
      senderName: myName,
      text: event.text,
      timestamp: DateTime.now(),
      isMe: true,
      type: 'text',
      routePath: [myName],
    );

    final updatedList = List<ChatMessage>.from(state.messages)..add(myMessage);
    emit(state.copyWith(messages: updatedList));

    final payloadMap = {
      'id': msgId,
      'senderName': myName,
      'text': event.text,
      'type': 'text',
    };

    try {
      final bool isSent = await _btRepository.broadcastPayload(payloadMap);
      if (!isSent) {
        await _storageRepository.queuePendingMessage(myMessage);
      } else {
        await _storageRepository.saveMessage(myMessage);
      }
    } catch (e) {
      debugPrint('Error sending/saving text message: $e');
    }
  }

  Future<void> _onSendImageMessage(
      SendGroupImageRequested event,
      Emitter<ChatState> emit,
      ) async {
    final String myName = _storageRepository.getUserName();
    final String msgId = DateTime.now().millisecondsSinceEpoch.toString();

    final myImageMessage = ChatMessage(
      id: msgId,
      senderName: myName,
      text: '',
      timestamp: DateTime.now(),
      isMe: true,
      imagePath: event.imagePath,
      type: 'image',
      routePath: [myName],
    );

    final updatedList = List<ChatMessage>.from(state.messages)
      ..add(myImageMessage);
    emit(state.copyWith(messages: updatedList));

    try {
      final bool isSent = await _btRepository.broadcastFilePayload(
        filePath: event.imagePath,
        metadata: {
          'id': msgId,
          'senderName': myName,
          'text': '',
          'mediaType': 'image',
          'extension': event.imagePath.split('.').last,
        },
      );

      if (!isSent) {
        await _storageRepository.queuePendingMessage(myImageMessage);
      } else {
        await _storageRepository.saveMessage(myImageMessage);
      }
    } catch (e) {
      debugPrint('Error sending/saving image: $e');
    }
  }

  Future<void> _onSendVoiceMessage(
      SendGroupVoiceRequested event,
      Emitter<ChatState> emit,
      ) async {
    final String myName = _storageRepository.getUserName();
    final String msgId = DateTime.now().millisecondsSinceEpoch.toString();

    final myVoiceMessage = ChatMessage(
      id: msgId,
      senderName: myName,
      text: '🎤 Voice Note',
      timestamp: DateTime.now(),
      isMe: true,
      mediaPath: event.voicePath,
      type: 'voice',
      routePath: [myName],
    );

    final updatedList = List<ChatMessage>.from(state.messages)
      ..add(myVoiceMessage);
    emit(state.copyWith(messages: updatedList));

    try {
      final bool isSent = await _btRepository.broadcastFilePayload(
        filePath: event.voicePath,
        metadata: {
          'id': msgId,
          'senderName': myName,
          'text': '🎤 Voice Note',
          'mediaType': 'voice',
          'extension': event.voicePath.split('.').last,
        },
      );

      if (!isSent) {
        await _storageRepository.queuePendingMessage(myVoiceMessage);
      } else {
        await _storageRepository.saveMessage(myVoiceMessage);
      }
    } catch (e) {
      debugPrint('Error sending/saving voice note: $e');
    }
  }

  Future<void> _onMessageReceived(
      MessageReceivedFromPeer event,
      Emitter<ChatState> emit,
      ) async {
    final incomingMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderName: event.senderName,
      text: event.text,
      timestamp: DateTime.now(),
      isMe: false,
      imagePath: event.savedImagePath,
      mediaPath: event.savedVoicePath,
      type: event.type,
      routePath: event.routePath,
    );

    try {
      await _storageRepository.saveMessage(incomingMsg);
    } catch (e) {
      debugPrint('Error saving incoming message to Hive: $e');
    }

    final updatedList = List<ChatMessage>.from(state.messages)
      ..add(incomingMsg);
    emit(state.copyWith(messages: updatedList));
  }

  void _onPeerCountUpdated(
      PeerCountUpdated event,
      Emitter<ChatState> emit,
      ) {
    emit(state.copyWith(connectedPeerCount: event.count));
  }

  @override
  Future<void> close() {
    _incomingMsgSubscription?.cancel();
    _peerCountSubscription?.cancel();
    return super.close();
  }
}