import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_bloc.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import 'chat_detail_screen.dart';

class MeshChatTab extends StatelessWidget {
  const MeshChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          final bool isConnected = state.connectedPeerCount > 0;
          final lastMessage =
          state.messages.isNotEmpty ? state.messages.last : null;

          final int imageCount =
              state.messages.where((m) => m.type == 'image').length;
          final int voiceCount =
              state.messages.where((m) => m.type == 'voice').length;
          final int queuedCount =
              state.messages.where((m) => m.isMe && !m.isDelivered).length;

          String subtitleText;
          if (lastMessage != null) {
            final prefix =
            lastMessage.isMe ? 'You: ' : '${lastMessage.senderName}: ';
            final content = lastMessage.type == 'image'
                ? '📷 Image attachment'
                : lastMessage.type == 'voice'
                ? '🎤 Voice transmission'
                : lastMessage.text;
            subtitleText = '$prefix$content';
          } else {
            subtitleText = 'No transmissions logged — Tap to open channel';
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isConnected
                        ? [const Color(0xFF0E2A22), const Color(0xFF141C24)]
                        : [const Color(0xFF1A1F29), const Color(0xFF141C24)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isConnected
                        ? const Color(0xFF00FF66).withValues(alpha: 0.45)
                        : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isConnected
                            ? const Color(0xFF00FF66)
                            : const Color(0xFF00E5FF))
                            .withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isConnected
                            ? Icons.wifi_tethering
                            : Icons.portable_wifi_off,
                        color: isConnected
                            ? const Color(0xFF00FF66)
                            : const Color(0xFF00E5FF),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isConnected
                                ? 'MESH LINK ACTIVE'
                                : 'STORE-AND-FORWARD STANDBY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.4,
                              color: isConnected
                                  ? const Color(0xFF00FF66)
                                  : const Color(0xFF00E5FF),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isConnected
                                ? '${state.connectedPeerCount} peer node(s) synced via P2P Cluster'
                                : 'Messages are cached locally in Hive and auto-relay on contact.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'ACTIVE CHANNELS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.6,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChatDetailScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141C24),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          const CircleAvatar(
                            radius: 26,
                            backgroundColor: Color(0xFF1E2A38),
                            child: Icon(
                              Icons.hub_rounded,
                              color: Color(0xFF00E5FF),
                              size: 28,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isConnected
                                    ? const Color(0xFF00FF66)
                                    : Colors.orangeAccent,
                                border: Border.all(
                                  color: const Color(0xFF141C24),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Bluetooth Group Mesh',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${state.messages.length} msgs',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF00E5FF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitleText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),
              const Text(
                'LOCAL CACHE & TELEMETRY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.6,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildStatTile(
                    icon: Icons.schedule_send_rounded,
                    label: 'Queued',
                    value: '$queuedCount',
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(width: 10),
                  _buildStatTile(
                    icon: Icons.mic_rounded,
                    label: 'Voice Notes',
                    value: '$voiceCount',
                    color: const Color(0xFF00E5FF),
                  ),
                  const SizedBox(width: 10),
                  _buildStatTile(
                    icon: Icons.image_rounded,
                    label: 'Images',
                    value: '$imageCount',
                    color: const Color(0xFF00FF66),
                  ),
                ],
              ),

              const SizedBox(height: 22),
              const Text(
                'QUICK FIELD BROADCASTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.6,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF2A5F),
                        side: BorderSide(
                          color: const Color(0xFFFF2A5F).withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        context.read<ChatBloc>().add(
                          SendGroupMessageRequested(
                            '🚨 SOS ALERT: Immediate assistance requested on mesh!',
                          ),
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ChatDetailScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.sos_rounded, size: 18),
                      label: const Text(
                        'Broadcast SOS',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00E5FF),
                        side: BorderSide(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        context.read<ChatBloc>().add(
                          SendGroupMessageRequested(
                            '📡 PING: Node online & checking mesh range.',
                          ),
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ChatDetailScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.cell_tower_rounded, size: 18),
                      label: const Text(
                        'Ping Mesh',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF141C24),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}