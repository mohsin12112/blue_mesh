import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'chat_bloc.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import 'chat_message.dart';
import 'peer_info_sheet.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _picker = ImagePicker();

  bool _isRecording = false;
  String? _currentlyPlayingPath;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _currentlyPlayingPath = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendTextMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatBloc>().add(SendGroupMessageRequested(text));
    _msgController.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  Future<void> _pickAndSendImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null && mounted) {
      context.read<ChatBloc>().add(
        SendGroupImageRequested(imagePath: image.path),
      );
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  Future<void> _toggleVoiceRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null && mounted) {
        context.read<ChatBloc>().add(
          SendGroupVoiceRequested(voicePath: path),
        );
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final filePath =
            '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
        });
      }
    }
  }

  Future<void> _playVoiceNote(String path) async {
    if (_currentlyPlayingPath == path) {
      await _audioPlayer.stop();
      setState(() {
        _currentlyPlayingPath = null;
      });
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(path));
      setState(() {
        _currentlyPlayingPath = path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141C24),
        elevation: 0,
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
          ),
        ),
        title: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFF141C24),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => const PeerInfoSheet(),
            );
          },
          child: BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              final bool isConnected = state.connectedPeerCount > 0;
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2A38),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isConnected
                            ? const Color(0xFF00FF66)
                            : const Color(0xFF00E5FF).withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.hub_rounded,
                      size: 18,
                      color: Color(0xFF00E5FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mesh Group Chat',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isConnected
                                    ? const Color(0xFF00FF66)
                                    : Colors.orangeAccent,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${state.connectedPeerCount} Peers Connected',
                              style: TextStyle(
                                fontSize: 11,
                                color: isConnected
                                    ? const Color(0xFF00FF66)
                                    : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0F14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'NODES',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: Color(0xFF00E5FF),
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Color(0xFF00E5FF),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ChatGridPainter(),
            ),
          ),

          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                color: const Color(0xFF141C24).withValues(alpha: 0.85),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 12,
                      color: Color(0xFF00FF66),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'END-TO-END AES-256 MESH CHANNEL • STORE & FORWARD READY',
                      style: TextStyle(
                        fontSize: 9.5,
                        letterSpacing: 0.9,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    if (state.messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cell_tower_rounded,
                              size: 48,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'NO TRANSMISSIONS ON CHANNEL',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.4,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Send a text, image, or voice note to broadcast.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final msg = state.messages[index];
                        return _buildMessageBubble(msg);
                      },
                    );
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141C24),
                  border: Border(
                    top: BorderSide(
                      color: _isRecording
                          ? const Color(0xFFFF2A5F).withValues(alpha: 0.6)
                          : Colors.white12,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: Row(
                      children: [
                        _buildMediaActionButton(
                          icon: Icons.image_outlined,
                          color: const Color(0xFF00E5FF),
                          onTap: _pickAndSendImage,
                        ),
                        const SizedBox(width: 6),

                        _buildMediaActionButton(
                          icon: _isRecording
                              ? Icons.stop_rounded
                              : Icons.mic_none_rounded,
                          color: _isRecording
                              ? const Color(0xFFFF2A5F)
                              : const Color(0xFF00FF66),
                          isHighlighted: _isRecording,
                          onTap: _toggleVoiceRecording,
                        ),
                        const SizedBox(width: 8),

                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B0F14),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _isRecording
                                    ? const Color(0xFFFF2A5F)
                                    .withValues(alpha: 0.5)
                                    : Colors.white12,
                              ),
                            ),
                            child: TextField(
                              controller: _msgController,
                              textCapitalization: TextCapitalization.sentences,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: _isRecording
                                    ? 'Recording audio transmission...'
                                    : 'Broadcast to mesh...',
                                hintStyle: TextStyle(
                                  color: _isRecording
                                      ? const Color(0xFFFF2A5F)
                                      : Colors.grey[500],
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                              ),
                              onSubmitted: (_) => _sendTextMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        GestureDetector(
                          onTap: _sendTextMessage,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Color(0xFF0B0F14),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isHighlighted
              ? color.withValues(alpha: 0.2)
              : const Color(0xFF0B0F14),
          shape: BoxShape.circle,
          border: Border.all(
            color: isHighlighted ? color : Colors.white12,
          ),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
  Widget _buildMessageBubble(ChatMessage msg) {
    final bool isMe = msg.isMe;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isMe
                ? [const Color(0xFF1A2D3D), const Color(0xFF142230)]
                : [const Color(0xFF16202A), const Color(0xFF111820)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 14),
          ),
          border: Border.all(
            color: isMe
                ? const Color(0xFF00E5FF).withValues(alpha: 0.45)
                : const Color(0xFF00FF66).withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isMe
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.08)
                  : Colors.black38,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isMe ? Icons.sensors : Icons.person_pin_circle_outlined,
                  size: 11,
                  color: isMe
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF00FF66),
                ),
                const SizedBox(width: 4),
                Text(
                  msg.senderName,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isMe
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF00FF66),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),

            if (msg.type == 'image')
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: msg.imagePath != null &&
                      File(msg.imagePath!).existsSync()
                      ? Image.file(
                    File(msg.imagePath!),
                    width: 210,
                    height: 160,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    width: 200,
                    height: 100,
                    color: Colors.black26,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported,
                            color: Colors.white54),
                        SizedBox(height: 4),
                        Text(
                          'Image attachment',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (msg.type == 'voice' && msg.mediaPath != null)
              VoiceWaveformWidget(
                isPlaying: _currentlyPlayingPath == msg.mediaPath,
                onTogglePlay: () => _playVoiceNote(msg.mediaPath!),
              ),

            if (msg.type == 'text' && msg.text.isNotEmpty)
              Text(
                msg.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 9.5, color: Colors.white54),
                ),
                if (isMe) ...[
                  const SizedBox(width: 5),
                  Icon(
                    msg.isDelivered ? Icons.done_all : Icons.access_time,
                    size: 13,
                    color: msg.isDelivered
                        ? const Color(0xFF00E5FF)
                        : Colors.orangeAccent,
                  ),
                ],
              ],
            ),

            if (!isMe && msg.routePath.length > 1) ...[
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'VIA ${msg.routePath.join(' ➔ ')} (${msg.routePath.length - 1} hop)',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF00E5FF),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class VoiceWaveformWidget extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTogglePlay;

  const VoiceWaveformWidget({
    super.key,
    required this.isPlaying,
    required this.onTogglePlay,
  });

  @override
  Widget build(BuildContext context) {
    final heights = [
      10.0,
      18.0,
      24.0,
      14.0,
      26.0,
      12.0,
      20.0,
      28.0,
      16.0,
      22.0,
      12.0,
      8.0
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: const Color(0xFF00E5FF),
              size: 30,
            ),
            onPressed: onTogglePlay,
          ),
          const SizedBox(width: 8),
          Row(
            children: List.generate(heights.length, (index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 150 + (index * 30)),
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                width: 3,
                height: isPlaying ? heights[index] : 10,
                decoration: BoxDecoration(
                  color: isPlaying ? const Color(0xFF00E5FF) : Colors.white54,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _ChatGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2A38).withValues(alpha: 0.25)
      ..strokeWidth = 1.0;

    const double step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}