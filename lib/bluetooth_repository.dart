import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';

class BluetoothRepository {
  final Strategy _strategy = Strategy.P2P_CLUSTER;
  final String _serviceId = "com.example.blue_mesh";
  static const int _maxHops = 5;
  static const int _maxSeenCacheSize = 500;

  final List<String> _connectedEndpoints = [];
  String _localNodeName = "Node_${DateTime.now().millisecondsSinceEpoch % 1000}";

  final LinkedHashSet<String> _seenPacketIds = LinkedHashSet<String>();

  final Map<int, String> _incomingFileUris = {};
  final Map<int, Map<String, dynamic>> _incomingFileMetadata = {};

  final StreamController<dynamic> _incomingMessageController =
  StreamController<dynamic>.broadcast();
  Stream<dynamic> get incomingMessages => _incomingMessageController.stream;

  final StreamController<int> _peerCountController =
  StreamController<int>.broadcast();
  Stream<int> get activePeerCount => _peerCountController.stream;

  bool isDuplicateOrMarkSeen(String? packetId) {
    if (packetId == null || packetId.isEmpty) return false;
    if (_seenPacketIds.contains(packetId)) {
      return true;
    }
    if (_seenPacketIds.length >= _maxSeenCacheSize) {
      _seenPacketIds.remove(_seenPacketIds.first);
    }
    _seenPacketIds.add(packetId);
    return false;
  }

  Future<bool> isBluetoothEnabled() async {
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

  Stream<bool> get adapterStateStream {
    return FlutterBluePlus.adapterState.map(
          (state) => state == BluetoothAdapterState.on,
    );
  }

  Future<void> startHosting([String? customUserName]) async {
    if (customUserName != null && customUserName.trim().isNotEmpty) {
      _localNodeName = customUserName.trim();
    }

    await Nearby().startAdvertising(
      _localNodeName,
      _strategy,
      onConnectionInitiated: _onConnectionInitiated,
      onConnectionResult: (endpointId, status) {
        if (status == Status.CONNECTED) {
          if (!_connectedEndpoints.contains(endpointId)) {
            _connectedEndpoints.add(endpointId);
            _peerCountController.add(_connectedEndpoints.length);
          }
        }
      },
      onDisconnected: (endpointId) {
        _connectedEndpoints.remove(endpointId);
        _peerCountController.add(_connectedEndpoints.length);
      },
      serviceId: _serviceId,
    );
  }

  Future<void> startJoiner([String? customUserName]) async {
    if (customUserName != null && customUserName.trim().isNotEmpty) {
      _localNodeName = customUserName.trim();
    }

    await Nearby().startDiscovery(
      _localNodeName,
      _strategy,
      onEndpointFound: (endpointId, name, serviceId) async {
        await Nearby().requestConnection(
          _localNodeName,
          endpointId,
          onConnectionInitiated: _onConnectionInitiated,
          onConnectionResult: (id, status) {
            if (status == Status.CONNECTED) {
              if (!_connectedEndpoints.contains(id)) {
                _connectedEndpoints.add(id);
                _peerCountController.add(_connectedEndpoints.length);
              }
            }
          },
          onDisconnected: (id) {
            _connectedEndpoints.remove(id);
            _peerCountController.add(_connectedEndpoints.length);
          },
        );
      },
      onEndpointLost: (endpointId) {},
      serviceId: _serviceId,
    );
  }

  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: (senderEndpointId, payload) {
        if (payload.type == PayloadType.BYTES && payload.bytes != null) {
          try {
            final rawText = utf8.decode(payload.bytes!);
            final dynamic decoded = jsonDecode(rawText);

            if (decoded is Map<String, dynamic>) {
              final String? packetId = decoded['id']?.toString();

              if (decoded['type'] == 'file_meta') {

                if (isDuplicateOrMarkSeen(packetId)) return;
                final int linkedPayloadId = decoded['payloadId'];
                _incomingFileMetadata[linkedPayloadId] = decoded;
              } else {
                if (isDuplicateOrMarkSeen(packetId)) return;

                final List<String> routePath =
                List<String>.from(decoded['routePath'] ?? []);
                if (routePath.isEmpty && decoded['senderName'] != null) {
                  routePath.add(decoded['senderName'].toString());
                }

                final enrichedPayload = {
                  ...decoded,
                  'routePath': routePath,
                };

                _incomingMessageController.add(enrichedPayload);
                _relayMessageToOthers(senderEndpointId, enrichedPayload);
              }
            }
          } catch (e) {
            final rawText = utf8.decode(payload.bytes!);
            _incomingMessageController.add({'text': rawText, 'type': 'text'});
          }
        } else if (payload.type == PayloadType.FILE && payload.uri != null) {
          _incomingFileUris[payload.id] = payload.uri!;
        }
      },
      onPayloadTransferUpdate: (senderEndpointId, update) async {
        if (update.status == PayloadStatus.SUCCESS &&
            _incomingFileUris.containsKey(update.id)) {
          final String uri = _incomingFileUris.remove(update.id)!;
          final meta = _incomingFileMetadata.remove(update.id) ?? {};

          final String mediaType = meta['mediaType'] ?? 'image';
          final String ext =
              meta['extension'] ?? (mediaType == 'voice' ? 'm4a' : 'jpg');
          final String fileId =
              meta['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

          final List<String> routePath =
          List<String>.from(meta['routePath'] ?? []);
          if (routePath.isEmpty && meta['senderName'] != null) {
            routePath.add(meta['senderName'].toString());
          }

          final dir = await getApplicationDocumentsDirectory();
          final String finalPath = '${dir.path}/mesh_$fileId.$ext';

          await Nearby().copyFileAndDeleteOriginal(uri, finalPath);

          final completedPayload = {
            'id': fileId,
            'senderName': meta['senderName'] ?? 'Mesh Peer',
            'text': meta['text'] ?? '',
            'type': mediaType,
            'localMediaPath': finalPath,
            'routePath': routePath,
          };

          _incomingMessageController.add(completedPayload);

          _relayFileToOthers(senderEndpointId, finalPath, {
            ...meta,
            'routePath': routePath,
          });
        }
      },
    );
  }

  Future<bool> broadcastPayload(Map<String, dynamic> dataMap) async {
    final String? packetId = dataMap['id']?.toString();
    isDuplicateOrMarkSeen(packetId);

    if (_connectedEndpoints.isEmpty) return false;

    try {
      final String sender =
          dataMap['senderName']?.toString() ?? _localNodeName;
      final enrichedMap = {
        ...dataMap,
        'hopCount': 0,
        'routePath': [sender],
      };

      final String jsonString = jsonEncode(enrichedMap);
      final Uint8List bytes = Uint8List.fromList(utf8.encode(jsonString));

      for (String endpointId in _connectedEndpoints) {
        await Nearby().sendBytesPayload(endpointId, bytes);
      }
      return true;
    } catch (e) {
      debugPrint('Broadcast bytes failed: $e');
      return false;
    }
  }

  Future<bool> broadcastFilePayload({
    required String filePath,
    required Map<String, dynamic> metadata,
  }) async {
    final String? packetId = metadata['id']?.toString();
    isDuplicateOrMarkSeen(packetId);

    if (_connectedEndpoints.isEmpty) return false;

    try {
      final String sender =
          metadata['senderName']?.toString() ?? _localNodeName;

      for (String endpointId in _connectedEndpoints) {
        final int payloadId =
        await Nearby().sendFilePayload(endpointId, filePath);

        await Future.delayed(const Duration(milliseconds: 50));

        final metaPacket = {
          ...metadata,
          'type': 'file_meta',
          'payloadId': payloadId,
          'hopCount': 0,
          'routePath': [sender],
        };
        final Uint8List metaBytes =
        Uint8List.fromList(utf8.encode(jsonEncode(metaPacket)));

        await Nearby().sendBytesPayload(endpointId, metaBytes);
      }
      return true;
    } catch (e) {
      debugPrint('Broadcast file failed: $e');
      return false;
    }
  }

  void _relayMessageToOthers(
      String senderId,
      Map<String, dynamic> decodedPayload,
      ) {
    final int currentHops = (decodedPayload['hopCount'] as int?) ?? 0;
    if (currentHops >= _maxHops) return;

    final List<String> updatedPath =
    List<String>.from(decodedPayload['routePath'] ?? []);
    if (!updatedPath.contains(_localNodeName)) {
      updatedPath.add(_localNodeName);
    }

    final relayedPacket = {
      ...decodedPayload,
      'hopCount': currentHops + 1,
      'routePath': updatedPath,
    };

    final Uint8List uint8bytes =
    Uint8List.fromList(utf8.encode(jsonEncode(relayedPacket)));

    for (String endpointId in _connectedEndpoints) {
      if (endpointId != senderId) {
        Nearby().sendBytesPayload(endpointId, uint8bytes);
      }
    }
  }

  Future<void> _relayFileToOthers(
      String senderId,
      String filePath,
      Map<String, dynamic> metadata,
      ) async {
    final int currentHops = (metadata['hopCount'] as int?) ?? 0;
    if (currentHops >= _maxHops) return;

    final List<String> updatedPath =
    List<String>.from(metadata['routePath'] ?? []);
    if (!updatedPath.contains(_localNodeName)) {
      updatedPath.add(_localNodeName);
    }

    for (String endpointId in _connectedEndpoints) {
      if (endpointId != senderId) {
        final int payloadId =
        await Nearby().sendFilePayload(endpointId, filePath);
        await Future.delayed(const Duration(milliseconds: 50));

        final metaPacket = {
          ...metadata,
          'type': 'file_meta',
          'payloadId': payloadId,
          'hopCount': currentHops + 1,
          'routePath': updatedPath,
        };
        final Uint8List metaBytes =
        Uint8List.fromList(utf8.encode(jsonEncode(metaPacket)));
        await Nearby().sendBytesPayload(endpointId, metaBytes);
      }
    }
  }

  Future<void> stopMesh() async {
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    await Nearby().stopAllEndpoints();
    _connectedEndpoints.clear();
    _peerCountController.add(0);
  }

  Future<void> stopAll() async {
    await stopMesh();
    await _incomingMessageController.close();
    await _peerCountController.close();
  }
}