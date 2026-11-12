import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bluetooth_bloc.dart';
import 'bluetooth_event.dart';
import 'bluetooth_state.dart';
import 'main_home_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    context.read<BluetoothBloc>().add(CheckBluetoothPermissions());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    if (mounted && !_hasNavigated) {
      _hasNavigated = true;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainHomeWrapper(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BluetoothBloc, BluetoothState>(
      listener: (context, state) {
        if (state is BluetoothReadyState) {
          _navigateToHome();
        }
      },
      builder: (context, state) {
        if (state is BluetoothReadyState) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToHome());
        }

        final bool isDenied = state is BluetoothPermissionDeniedState;

        return Scaffold(
          backgroundColor: const Color(0xFF0B0F14),
          body: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TacticalGridPainter(),
                ),
              ),

              Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (isDenied
                            ? const Color(0xFFFF2A5F)
                            : const Color(0xFF00E5FF))
                            .withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _RadarBeaconPainter(
                                  progress: _pulseController.value,
                                  accentColor: isDenied
                                      ? const Color(0xFFFF2A5F)
                                      : const Color(0xFF00E5FF),
                                ),
                                child: child,
                              );
                            },
                            child: Center(
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF141C24),
                                  border: Border.all(
                                    color: isDenied
                                        ? const Color(0xFFFF2A5F)
                                        : const Color(0xFF00E5FF),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isDenied
                                          ? const Color(0xFFFF2A5F)
                                          : const Color(0xFF00E5FF))
                                          .withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isDenied
                                      ? Icons.bluetooth_disabled
                                      : Icons.hub_rounded,
                                  size: 36,
                                  color: isDenied
                                      ? const Color(0xFFFF2A5F)
                                      : const Color(0xFF00E5FF),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'BLUE MESH',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4.5,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Color(0x8000E5FF),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141C24),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF00FF66)
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 14,
                                color: Color(0xFF00FF66),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'OFFLINE P2P TACTICAL COMMS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                  color: Color(0xFF00FF66),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 2),
                        if (isDenied)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141C24),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFF2A5F)
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Color(0xFFFF2A5F),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'RADIO ACCESS REQUIRED',
                                      style: TextStyle(
                                        color: Color(0xFFFF2A5F),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Bluetooth & Nearby Location permissions are needed to establish local peer-to-peer mesh nodes.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00E5FF),
                                      foregroundColor: const Color(0xFF0B0F14),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      context
                                          .read<BluetoothBloc>()
                                          .add(CheckBluetoothPermissions());
                                    },
                                    icon: const Icon(Icons.security, size: 18),
                                    label: const Text(
                                      'INITIALIZE PERMISSIONS',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            children: [
                              SizedBox(
                                width: 180,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: const LinearProgressIndicator(
                                    minHeight: 3,
                                    backgroundColor: Color(0xFF1E2A38),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF00E5FF),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'CALIBRATING BLUETOOTH TRANSCEIVER...',
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 1.6,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RadarBeaconPainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  _RadarBeaconPainter({
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final double waveProgress = (progress + (i / 3)) % 1.0;
      final double currentRadius = 36 + (maxRadius - 36) * waveProgress;
      final double opacity = (1.0 - waveProgress).clamp(0.0, 1.0) * 0.45;

      final paint = Paint()
        ..color = accentColor.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;

      canvas.drawCircle(center, currentRadius, paint);
    }

    final arcPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final startAngle = progress * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxRadius - 6),
      startAngle,
      math.pi / 3,
      false,
      arcPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxRadius - 6),
      startAngle + math.pi,
      math.pi / 3,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarBeaconPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor;
  }
}

class _TacticalGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2A38).withValues(alpha: 0.35)
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