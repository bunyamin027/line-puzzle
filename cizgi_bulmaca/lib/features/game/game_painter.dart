import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Normalize (0-1) düğüm koordinatlarını tuval piksellerine çevirir.
/// Hem dokunma algılama hem de çizim aynı geometriyi kullanır.
class BoardGeometry {
  final Size canvasSize;

  const BoardGeometry(this.canvasSize);

  double get side => min(canvasSize.width, canvasSize.height) * 0.85;

  Offset toPixel(Offset node) {
    final offsetX = (canvasSize.width - side) / 2;
    final offsetY = (canvasSize.height - side) / 2;
    return Offset(offsetX + node.dx * side, offsetY + node.dy * side);
  }
}

enum GameEffectKind { connect, invalid }

/// Kısa ömürlü görsel efekt (bağlantı dalgası, hatalı hamle darbesi)
class GameEffect {
  final int node;
  final double startTime; // saniye
  final GameEffectKind kind;

  const GameEffect(this.node, this.startTime, this.kind);

  static const double lifetime = 0.6;
}

/// Oyun alanı çizici — tüm düğüm, kenar ve efektleri çizer.
class GamePainter extends CustomPainter {
  final List<Offset> nodes;
  final List<List<int>> edges;
  final List<List<int>> drawnEdges;
  final List<double> drawnTimes;
  final List<int>? lastHintEdge;
  final int? activeNode;
  final List<int> visitedNodes;
  final bool isDragging;
  final Offset? dragPosition;
  final bool isDark;
  final double pulseValue;
  final double time;
  final double introProgress;
  final double? completedAt;
  final List<GameEffect> effects;
  final List<List<int>>? ghostEdges;
  final List<int> startNodes; // Boşsa başlangıç halkası gösterilmez
  final Color pathStartColor;
  final Color pathEndColor;
  final double nodeRadius;

  GamePainter({
    required this.nodes,
    required this.edges,
    required this.drawnEdges,
    required this.drawnTimes,
    this.lastHintEdge,
    this.activeNode,
    required this.visitedNodes,
    required this.isDragging,
    this.dragPosition,
    required this.isDark,
    required this.pulseValue,
    required this.time,
    required this.introProgress,
    this.completedAt,
    required this.effects,
    this.ghostEdges,
    required this.startNodes,
    required this.pathStartColor,
    required this.pathEndColor,
    required this.nodeRadius,
  });

  static const double _edgeGrowDuration = 0.16;
  static const double _waveDuration = 0.9;

  @override
  void paint(Canvas canvas, Size size) {
    final geo = BoardGeometry(size);
    final px = [for (final n in nodes) geo.toPixel(n)];

    _paintBackdrop(canvas, size, geo);
    _paintUndrawnEdges(canvas, px);
    _paintDrawnEdges(canvas, px);
    _paintGhostEdges(canvas, px);
    _paintDragLine(canvas, px);
    _paintEffects(canvas, px);
    _paintNodes(canvas, px);
  }

  // ─── Arka Plan: nokta ızgarası + merkez ışıması ─────────────

  void _paintBackdrop(Canvas canvas, Size size, BoardGeometry geo) {
    final center = Offset(size.width / 2, size.height / 2);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          pathStartColor.withValues(alpha: isDark ? 0.14 : 0.07),
          pathStartColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: geo.side * 0.7));
    canvas.drawCircle(center, geo.side * 0.7, glow);

    final dot = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05);
    const step = 26.0;
    for (double y = step / 2; y < size.height; y += step) {
      for (double x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.1, dot);
      }
    }
  }

  // ─── Kenarlar ───────────────────────────────────────────────

  void _paintUndrawnEdges(Canvas canvas, List<Offset> px) {
    final drawn = {for (final e in drawnEdges) _key(e[0], e[1])};
    final paint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF6B6B8D))
          .withValues(alpha: (isDark ? 0.18 : 0.2) * introProgress)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < edges.length; i++) {
      final e = edges[i];
      if (drawn.contains(_key(e[0], e[1]))) continue;
      // Açılışta kenarlar düğümlerden dışa doğru uzar
      final grow = Curves.easeOutCubic.transform(
        ((introProgress * 1.4) - 0.4 * i / max(1, edges.length)).clamp(0.0, 1.0),
      );
      final a = px[e[0]], b = px[e[1]];
      final mid = (a + b) / 2;
      canvas.drawLine(
        Offset.lerp(mid, a, grow)!,
        Offset.lerp(mid, b, grow)!,
        paint,
      );
    }
  }

  Color _pathColor(int index) {
    final total = edges.length;
    return Color.lerp(pathStartColor, pathEndColor, total <= 1 ? 1 : index / (total - 1))!;
  }

  void _paintDrawnEdges(Canvas canvas, List<Offset> px) {
    final waveT = completedAt == null ? null : time - completedAt!;
    final glowPaint = Paint()
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    final corePaint = Paint()
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < drawnEdges.length; i++) {
      final e = drawnEdges[i];
      final from = px[e[0]], to = px[e[1]];
      final startedAt = i < drawnTimes.length ? drawnTimes[i] : -10.0;
      final grow = Curves.easeOutCubic
          .transform(((time - startedAt) / _edgeGrowDuration).clamp(0.0, 1.0));
      final end = Offset.lerp(from, to, grow)!;

      final isHint = lastHintEdge != null &&
          _key(e[0], e[1]) == _key(lastHintEdge![0], lastHintEdge![1]);
      final color = isHint ? AppColors.accent : _pathColor(i);

      // Tamamlanma dalgası: yol boyunca ilerleyen parlak ışık
      double wave = 0;
      if (waveT != null) {
        final head = waveT / _waveDuration * (drawnEdges.length + 2) - 1;
        wave = exp(-pow(i - head, 2) / 2.0).toDouble();
        if (waveT > _waveDuration) wave = max(wave, 0.25 + 0.25 * pulseValue);
      }

      glowPaint.color = color.withValues(alpha: 0.38 + 0.5 * wave);
      glowPaint.strokeWidth = 13 + 10 * wave;
      canvas.drawLine(from, end, glowPaint);

      corePaint.color = Color.lerp(color, Colors.white, wave * 0.6)!;
      canvas.drawLine(from, end, corePaint);
    }
  }

  void _paintGhostEdges(Canvas canvas, List<Offset> px) {
    final ghosts = ghostEdges;
    if (ghosts == null || ghosts.isEmpty) return;

    final dashPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.9)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.25 + 0.15 * pulseValue)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (int i = 0; i < ghosts.length; i++) {
      final from = px[ghosts[i][0]], to = px[ghosts[i][1]];
      canvas.drawLine(from, to, glow);
      _drawMarchingDash(canvas, from, to, dashPaint);
      _drawStepBadge(canvas, (from + to) / 2, i + 1);
    }
  }

  /// Hareket yönünde akan kesikli çizgi (yönü gösterir)
  void _drawMarchingDash(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dash = 10.0, gap = 8.0;
    final length = (to - from).distance;
    if (length == 0) return;
    final dir = (to - from) / length;
    var d = -((time * 36) % (dash + gap));
    while (d < length) {
      final s = max(0.0, d), e = min(length, d + dash);
      if (e > s) canvas.drawLine(from + dir * s, from + dir * e, paint);
      d += dash + gap;
    }
  }

  void _drawStepBadge(Canvas canvas, Offset center, int number) {
    canvas.drawCircle(center, 11, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      11,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: '$number',
        style: AppTextStyles.labelSmall.copyWith(
          color: Colors.black87,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _paintDragLine(Canvas canvas, List<Offset> px) {
    if (!isDragging || activeNode == null || dragPosition == null) return;
    final from = px[activeNode!];
    final color = _pathColor(drawnEdges.length);

    canvas.drawLine(
      from,
      dragPosition!,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawLine(
      from,
      dragPosition!,
      Paint()
        ..color = color.withValues(alpha: 0.75)
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );
    // Parmak ucu ışığı
    canvas.drawCircle(
      dragPosition!,
      14 + 4 * pulseValue,
      Paint()..color = color.withValues(alpha: 0.18),
    );
    canvas.drawCircle(dragPosition!, 5, Paint()..color = color);
  }

  // ─── Efektler ───────────────────────────────────────────────

  void _paintEffects(Canvas canvas, List<Offset> px) {
    for (final fx in effects) {
      final t = (time - fx.startTime) / GameEffect.lifetime;
      if (t < 0 || t > 1) continue;
      final pos = px[fx.node];
      final ease = Curves.easeOutCubic.transform(t);
      final fade = 1 - t;

      if (fx.kind == GameEffectKind.connect) {
        // Genişleyen halka
        canvas.drawCircle(
          pos,
          nodeRadius + 26 * ease,
          Paint()
            ..color = pathEndColor.withValues(alpha: 0.7 * fade)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3 * fade + 0.5,
        );
        // Kıvılcımlar
        final spark = Paint()..color = AppColors.accent.withValues(alpha: fade);
        for (int k = 0; k < 8; k++) {
          final a = k * pi / 4 + fx.node;
          final r = nodeRadius + 4 + 28 * ease;
          canvas.drawCircle(pos + Offset(cos(a), sin(a)) * r, 2.6 * fade + 0.4, spark);
        }
      } else {
        canvas.drawCircle(
          pos,
          nodeRadius + 6 + 10 * ease,
          Paint()
            ..color = AppColors.error.withValues(alpha: 0.55 * fade)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4 * fade + 0.5,
        );
        canvas.drawCircle(
          pos,
          nodeRadius + 2,
          Paint()..color = AppColors.error.withValues(alpha: 0.35 * fade),
        );
      }
    }
  }

  // ─── Düğümler ───────────────────────────────────────────────

  void _paintNodes(Canvas canvas, List<Offset> px) {
    final visited = visitedNodes.toSet();
    final finished = completedAt != null;

    for (int i = 0; i < nodes.length; i++) {
      final pos = px[i];
      // Açılışta sırayla "pop" ederek belirme
      final appear = ((introProgress * 1.5) - 0.5 * i / max(1, nodes.length)).clamp(0.0, 1.0);
      if (appear <= 0) continue;
      final scale = Curves.elasticOut.transform(appear);
      final isActive = i == activeNode;
      final isVisited = visited.contains(i);
      final r = nodeRadius * scale;

      // Başlangıç düğümü kılavuz halkası
      if (visitedNodes.isEmpty && startNodes.contains(i)) {
        canvas.drawCircle(
          pos,
          r + 4 + pulseValue * 10,
          Paint()
            ..color = AppColors.accent.withValues(alpha: 0.55 * (1 - pulseValue))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }

      // Aktif düğüm halesi
      if (isActive && !finished) {
        canvas.drawCircle(
          pos,
          r + 8 + pulseValue * 8,
          Paint()..color = pathStartColor.withValues(alpha: 0.12 + pulseValue * 0.12),
        );
      }

      final fill = finished
          ? Color.lerp(pathEndColor, Colors.white, 0.15 * pulseValue)!
          : isActive
              ? pathStartColor
              : isVisited
                  ? pathEndColor
                  : (isDark ? const Color(0xFF4A4763) : const Color(0xFFC9C6DA));

      // Gölge / ışıma
      if (isVisited || isActive) {
        canvas.drawCircle(
          pos,
          r + 2,
          Paint()
            ..color = fill.withValues(alpha: 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      final outer = isActive ? r * 1.2 : r;
      canvas.drawCircle(pos, outer, Paint()..color = fill);
      canvas.drawCircle(
        pos,
        outer * 0.48,
        Paint()
          ..color = isVisited || isActive
              ? Colors.white
              : (isDark ? const Color(0xFF1E1B2E) : Colors.white),
      );
    }
  }

  static int _key(int a, int b) => a < b ? a * 1000 + b : b * 1000 + a;

  @override
  bool shouldRepaint(GamePainter old) => true;
}
