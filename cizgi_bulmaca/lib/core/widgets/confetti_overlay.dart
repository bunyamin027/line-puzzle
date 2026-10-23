import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Çizgi Bulmaca — Konfeti Patlaması
/// Ekranın üst ortasından iki yöne saçılan, yerçekimiyle düşen ve dönen
/// konfeti parçacıkları. Dokunmaları engellemez (IgnorePointer).
class ConfettiOverlay extends StatefulWidget {
  final int particleCount;
  final Duration duration;

  const ConfettiOverlay({
    super.key,
    this.particleCount = 90,
    this.duration = const Duration(milliseconds: 2600),
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)..forward();
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(widget.particleCount, (i) {
      // Sol ve sağ "top"lardan çapraz yukarı fırlat
      final fromLeft = i.isEven;
      final angle = (fromLeft ? -pi / 3 : -2 * pi / 3) + (rng.nextDouble() - 0.5) * 0.9;
      final speed = 0.9 + rng.nextDouble() * 0.9;
      return _Particle(
        origin: Offset(fromLeft ? 0.1 : 0.9, 0.55),
        velocity: Offset(cos(angle), sin(angle)) * speed,
        color: AppColors.confetti[rng.nextInt(AppColors.confetti.length)],
        size: 6 + rng.nextDouble() * 6,
        spin: (rng.nextDouble() - 0.5) * 18,
        isCircle: rng.nextDouble() < 0.3,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_particles, _controller),
        ),
      ),
    );
  }
}

class _Particle {
  final Offset origin;   // Normalize başlangıç (0-1)
  final Offset velocity; // Normalize hız (ekran/sn)
  final Color color;
  final double size;
  final double spin;
  final bool isCircle;

  const _Particle({
    required this.origin,
    required this.velocity,
    required this.color,
    required this.size,
    required this.spin,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final Animation<double> progress;

  _ConfettiPainter(this.particles, this.progress) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value * 2.6; // saniye
    const gravity = 1.1;
    final fade = progress.value < 0.7 ? 1.0 : (1 - (progress.value - 0.7) / 0.3);
    final paint = Paint();

    for (final p in particles) {
      final x = p.origin.dx + p.velocity.dx * t * 0.55;
      final y = p.origin.dy + p.velocity.dy * t + 0.5 * gravity * t * t;
      if (y > 1.1) continue;
      final pos = Offset(x * size.width, y * size.height);
      paint.color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size * 0.4, paint);
      } else {
        // Yaprak gibi dönme hissi için genişliği zamanla salınır
        final w = p.size * (0.35 + 0.65 * cos(p.spin * t * 0.7).abs());
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w, height: p.size * 0.55),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
