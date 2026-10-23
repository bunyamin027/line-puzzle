import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/settings_provider.dart';
import '../../core/widgets/constellation_background.dart';

/// Çizgi Bulmaca — Splash Ekranı
/// Logo animasyonu ile açılış ekranı (tek çizgi çizilerek belirir).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _lineAnimation;
  late Animation<double> _logoAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.splashDuration,
    );

    _lineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _logoAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.8, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      _navigateNext();
    });
  }

  void _navigateNext() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final settings = context.read<SettingsProvider>();
      if (settings.onboardingCompleted) {
        context.go('/home');
      } else {
        context.go('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: Stack(
          children: [
            const Positioned.fill(
              child: ConstellationBackground(color: Colors.white, opacity: 0.7),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo — tek çizgiyle kendini çizen yıldızın içinden belirir
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _OneStrokeStarPainter(_lineAnimation),
                          ),
                        ),
                        ScaleTransition(
                          scale: _logoAnimation,
                          child: Container(
                            width: 124,
                            height: 124,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 36,
                                  spreadRadius: 4,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                width: 124,
                                height: 124,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Uygulama Adı
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      context.l10n.appName,
                      style: AppTextStyles.displayMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      context.l10n.slogan,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Beş köşeli yıldızı tek kalem darbesiyle (pentagram) çizer — oyunun özü.
/// Çizginin ucunda parlayan bir "kalem ucu" ilerler.
class _OneStrokeStarPainter extends CustomPainter {
  final Animation<double> progress;

  _OneStrokeStarPainter(this.progress) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0) return;

    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 8;
    final points = [
      for (int i = 0; i < 5; i++)
        center +
            Offset(
                  cos(-pi / 2 + i * 2 * pi / 5),
                  sin(-pi / 2 + i * 2 * pi / 5),
                ) *
                r,
    ];
    // 0 → 2 → 4 → 1 → 3 → 0: her kenardan bir kez geçen Euler devresi
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (final i in [2, 4, 1, 3, 0]) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final metric = path.computeMetrics().first;
    final partial = metric.extractPath(0, metric.length * t);
    final shader = const LinearGradient(
      colors: [AppColors.primary, AppColors.secondary],
    ).createShader(Rect.fromCircle(center: center, radius: r));

    canvas.drawPath(
      partial,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(
      partial,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dot = Paint()..color = Colors.white;
    for (final p in points) {
      canvas.drawCircle(p, 5, dot..color = Colors.white.withValues(alpha: 0.9));
    }

    if (t < 1) {
      final tip = metric.getTangentForOffset(metric.length * t)!.position;
      canvas.drawCircle(
        tip,
        12,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(tip, 5, Paint()..color = AppColors.accent);
    }
  }

  @override
  bool shouldRepaint(_OneStrokeStarPainter old) => false;
}
