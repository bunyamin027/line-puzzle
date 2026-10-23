import 'dart:math';
import 'package:flutter/material.dart';

/// Çizgi Bulmaca — Hareketli Takımyıldız Arka Planı
/// Yavaşça süzülen noktalar ve yakın noktalar arasında beliren ince çizgiler.
/// Oyunun "düğüm + çizgi" diline uygun, dikkat dağıtmayan ambiyans katmanı.
class ConstellationBackground extends StatefulWidget {
  final Color color;
  final int pointCount;
  final double opacity;

  const ConstellationBackground({
    super.key,
    required this.color,
    this.pointCount = 22,
    this.opacity = 1.0,
  });

  @override
  State<ConstellationBackground> createState() => _ConstellationBackgroundState();
}

class _ConstellationBackgroundState extends State<ConstellationBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  )..repeat();
  late final List<_Drifter> _points;

  @override
  void initState() {
    super.initState();
    final rng = Random(7);
    _points = List.generate(widget.pointCount, (_) {
      return _Drifter(
        base: Offset(rng.nextDouble(), rng.nextDouble()),
        radius: 0.02 + rng.nextDouble() * 0.05,
        phase: rng.nextDouble() * 2 * pi,
        speed: 1 + rng.nextInt(3).toDouble(),
        size: 1.5 + rng.nextDouble() * 2.0,
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
          painter: _ConstellationPainter(
            points: _points,
            progress: _controller,
            color: widget.color,
            opacity: widget.opacity,
          ),
        ),
      ),
    );
  }
}

class _Drifter {
  final Offset base;
  final double radius;
  final double phase;
  final double speed;
  final double size;

  const _Drifter({
    required this.base,
    required this.radius,
    required this.phase,
    required this.speed,
    required this.size,
  });

  Offset at(double t) {
    final a = phase + t * 2 * pi * speed;
    return base + Offset(cos(a) * radius, sin(a * 0.8) * radius);
  }
}

class _ConstellationPainter extends CustomPainter {
  final List<_Drifter> points;
  final Animation<double> progress;
  final Color color;
  final double opacity;

  _ConstellationPainter({
    required this.points,
    required this.progress,
    required this.color,
    required this.opacity,
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final positions = [
      for (final p in points) Offset(p.at(t).dx * size.width, p.at(t).dy * size.height),
    ];
    final linkDistance = size.shortestSide * 0.32;
    final linePaint = Paint()..strokeWidth = 1.0;

    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final d = (positions[i] - positions[j]).distance;
        if (d < linkDistance) {
          linePaint.color =
              color.withValues(alpha: 0.16 * opacity * (1 - d / linkDistance));
          canvas.drawLine(positions[i], positions[j], linePaint);
        }
      }
    }

    final dotPaint = Paint()..color = color.withValues(alpha: 0.35 * opacity);
    for (int i = 0; i < positions.length; i++) {
      canvas.drawCircle(positions[i], points[i].size, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter old) =>
      old.color != color || old.opacity != opacity;
}
