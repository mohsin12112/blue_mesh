import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_bloc.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import 'peer_info_sheet.dart';

class DiscoveryTab extends StatefulWidget {
  const DiscoveryTab({super.key});

  @override
  State<DiscoveryTab> createState() => _DiscoveryTabState();
}

class _DiscoveryTabState extends State<DiscoveryTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          final bool isScanning = state.isHost || state.isDiscovering;
          final Color statusColor = state.isHost
              ? const Color(0xFF00E5FF)
              : state.isDiscovering
              ? const Color(0xFF00FF66)
              : Colors.grey;

          return Column(
            children: [
              const SizedBox(height: 12),

              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => const PeerInfoSheet(),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141C24),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isScanning
                          ? statusColor.withValues(alpha: 0.55)
                          : Colors.white12,
                    ),
                    boxShadow: [
                      if (isScanning)
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.12),
                          blurRadius: 12,
                        ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              state.isHost
                                  ? Icons.router_rounded
                                  : isScanning
                                  ? Icons.radar_rounded
                                  : Icons.sensors_off_rounded,
                              color: statusColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.isHost
                                      ? 'HOST HUB ACTIVE'
                                      : state.isDiscovering
                                      ? 'SCANNING FOR PEERS'
                                      : 'TRANSCEIVER STANDBY',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1.3,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Connected Nodes: ${state.connectedPeerCount}  •  Tap for topology',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'P2P CLUSTER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _sweepController,
                            builder: (context, child) {
                              return SizedBox.expand(
                                child: CustomPaint(
                                  painter: TacticalGreenRadarPainter(
                                    sweepAngle:
                                    _sweepController.value * 2 * math.pi,
                                    isScanning: isScanning,
                                    peerCount: state.connectedPeerCount,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Positioned(
                            top: 6,
                            child: _CompassLabel('N'),
                          ),
                          const Positioned(
                            bottom: 6,
                            child: _CompassLabel('S'),
                          ),
                          const Positioned(
                            left: 8,
                            child: _CompassLabel('W'),
                          ),
                          const Positioned(
                            right: 8,
                            child: _CompassLabel('E'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: _buildMicroTag(
                        icon: Icons.bluetooth_audio,
                        label: 'BLE 5.0 + Wi-Fi Direct',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _buildMicroTag(
                        icon: Icons.lock_outline,
                        label: 'AES-256 Encrypted',
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: state.isHost
                              ? const Color(0xFFFF2A5F)
                              : const Color(0xFF0E7C47),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (state.isHost) {
                            context.read<ChatBloc>().add(StopMeshRequested());
                          } else {
                            context
                                .read<ChatBloc>()
                                .add(StartHostingRequested());
                          }
                        },
                        icon: Icon(
                          state.isHost ? Icons.stop_rounded : Icons.wifi_tethering,
                          size: 20,
                        ),
                        label: Text(
                          state.isHost ? 'Stop Host' : 'Host Group',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: state.isDiscovering
                              ? const Color(0xFFFF2A5F)
                              : const Color(0xFF141C24),
                          foregroundColor: state.isDiscovering
                              ? Colors.white
                              : const Color(0xFF00FF66),
                          side: BorderSide(
                            color: state.isDiscovering
                                ? const Color(0xFFFF2A5F)
                                : const Color(0xFF00FF66).withValues(alpha: 0.6),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (state.isDiscovering) {
                            context.read<ChatBloc>().add(StopMeshRequested());
                          } else {
                            context
                                .read<ChatBloc>()
                                .add(StartJoinerRequested());
                          }
                        },
                        icon: Icon(
                          state.isDiscovering ? Icons.stop_rounded : Icons.radar,
                          size: 20,
                        ),
                        label: Text(
                          state.isDiscovering ? 'Stop Scan' : 'Join Group',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMicroTag({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey[500]),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ),
      ],
    );
  }
}

class _CompassLabel extends StatelessWidget {
  final String text;
  const _CompassLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF33D133).withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF45FF45),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
class TacticalGreenRadarPainter extends CustomPainter {
  final double sweepAngle;
  final bool isScanning;
  final int peerCount;

  TacticalGreenRadarPainter({
    required this.sweepAngle,
    required this.isScanning,
    required this.peerCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = const Color(0xFF091A10).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final circlePaint = Paint()
      ..color = const Color(0xFF33D133).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final outerCirclePaint = Paint()
      ..color = const Color(0xFF45FF45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final axisPaint = Paint()
      ..color = const Color(0xFFC7FFC7).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const ringCount = 6;
    for (int i = 1; i <= ringCount; i++) {
      final r = (radius / ringCount) * i;
      canvas.drawCircle(
        center,
        r,
        i == ringCount ? outerCirclePaint : circlePaint,
      );
    }

    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi) / 4;
      final dx = radius * math.cos(angle);
      final dy = radius * math.sin(angle);

      canvas.drawLine(
        Offset(center.dx - dx, center.dy - dy),
        Offset(center.dx + dx, center.dy + dy),
        axisPaint,
      );
    }

    if (isScanning) {
      final double progress = (sweepAngle / (2 * math.pi)).clamp(0.0, 1.0);
      final pulsePaint = Paint()
        ..color = const Color(0xFF00FF66)
            .withValues(alpha: (1.0 - progress) * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(center, radius * progress, pulsePaint);

      final sweepPaint = Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: 0.0,
          endAngle: math.pi * 2,
          colors: [
            const Color(0xFF33D133).withValues(alpha: 0.0),
            const Color(0xFF33D133).withValues(alpha: 0.45),
          ],
          transform: GradientRotation(sweepAngle),
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawCircle(center, radius, sweepPaint);

      final linePaint = Paint()
        ..color = const Color(0xFFC7FFC7)
        ..strokeWidth = 2.5;

      final lineX = center.dx + radius * math.cos(sweepAngle);
      final lineY = center.dy + radius * math.sin(sweepAngle);
      canvas.drawLine(center, Offset(lineX, lineY), linePaint);
    }

    final selfPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, selfPaint);

    final blipPaint = Paint()
      ..color = const Color(0xFFFF2A5F)
      ..style = PaintingStyle.fill;

    final blipGlowPaint = Paint()
      ..color = const Color(0xFFFF2A5F).withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final int countToDraw = math.min(peerCount, 8);
    for (int i = 0; i < countToDraw; i++) {
      final double angle =
          (2 * math.pi / (countToDraw == 0 ? 1 : countToDraw)) * i;
      final double distance = radius * 0.55;
      final pos = Offset(
        center.dx + distance * math.cos(angle),
        center.dy + distance * math.sin(angle),
      );

      canvas.drawCircle(pos, 10, blipGlowPaint);
      canvas.drawCircle(pos, 6, blipPaint);
    }
  }

  @override
  bool shouldRepaint(covariant TacticalGreenRadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.isScanning != isScanning ||
        oldDelegate.peerCount != peerCount;
  }
}