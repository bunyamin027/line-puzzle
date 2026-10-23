import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../../core/widgets/confetti_overlay.dart';
import '../../core/widgets/pressable_scale.dart';

/// Çizgi Bulmaca — Seviye Tamamlandı Ekranı
/// Konfeti + sırayla patlayan yıldızlar + istatistikler.
class LevelCompleteDialog {
  LevelCompleteDialog._();

  static Future<void> show(
    BuildContext context, {
    required int stars,
    required String levelLabel,
    required int moves,
    required String timeText,
    required int hintsUsed,
    required LinearGradient gradient,
    required bool hasNextLevel,
    required VoidCallback onMenu,
    required VoidCallback onReplay,
    required VoidCallback onNext,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'level_complete',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (ctx, _, _) => Stack(
        children: [
          const Positioned.fill(child: ConfettiOverlay()),
          Center(
            child: _LevelCompleteCard(
              stars: stars,
              levelLabel: levelLabel,
              moves: moves,
              timeText: timeText,
              hintsUsed: hintsUsed,
              gradient: gradient,
              hasNextLevel: hasNextLevel,
              onMenu: onMenu,
              onReplay: onReplay,
              onNext: onNext,
            ),
          ),
        ],
      ),
      transitionBuilder: (ctx, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _LevelCompleteCard extends StatefulWidget {
  final int stars;
  final String levelLabel;
  final int moves;
  final String timeText;
  final int hintsUsed;
  final LinearGradient gradient;
  final bool hasNextLevel;
  final VoidCallback onMenu;
  final VoidCallback onReplay;
  final VoidCallback onNext;

  const _LevelCompleteCard({
    required this.stars,
    required this.levelLabel,
    required this.moves,
    required this.timeText,
    required this.hintsUsed,
    required this.gradient,
    required this.hasNextLevel,
    required this.onMenu,
    required this.onReplay,
    required this.onNext,
  });

  @override
  State<_LevelCompleteCard> createState() => _LevelCompleteCardState();
}

class _LevelCompleteCardState extends State<_LevelCompleteCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  // Her yıldızın patlama anı (controller değeri olarak)
  static const List<double> _starAt = [0.22, 0.38, 0.54];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.stars; i++) {
      Future.delayed(_controller.duration! * _starAt[i], () {
        if (!mounted) return;
        SoundService.instance.playStar();
        HapticService.light();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _interval(double begin, double end, [Curve curve = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _controller, curve: Interval(begin, end, curve: curve));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = switch (widget.stars) {
      3 => l10n.resultPerfect,
      2 => l10n.resultGreat,
      _ => l10n.resultGood,
    };

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: min(MediaQuery.sizeOf(context).width - 48, 360),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: widget.gradient.colors.first.withValues(alpha: 0.35),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Üst gradient başlık + yıldızlar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
              decoration: BoxDecoration(gradient: widget.gradient),
              child: Column(
                children: [
                  FadeTransition(
                    opacity: _interval(0.0, 0.25),
                    child: ScaleTransition(
                      scale: _interval(0.0, 0.3, Curves.elasticOut),
                      child: Text(
                        title,
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FadeTransition(
                    opacity: _interval(0.1, 0.3),
                    child: Text(
                      widget.levelLabel,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(3, (i) {
                      final earned = i < widget.stars;
                      final pop = _interval(_starAt[i], _starAt[i] + 0.25, Curves.elasticOut);
                      return Padding(
                        // Ortadaki yıldız daha büyük ve yukarıda (podyum)
                        padding: EdgeInsets.only(left: 6, right: 6, bottom: i == 1 ? 12 : 0),
                        child: _StarBadge(earned: earned, pop: pop, size: i == 1 ? 62 : 50),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // İstatistikler
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
              child: FadeTransition(
                opacity: _interval(0.55, 0.8),
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.3), end: Offset.zero)
                      .animate(_interval(0.55, 0.8)),
                  child: Row(
                    children: [
                      _StatChip(
                        icon: Icons.touch_app_rounded,
                        value: '${widget.moves}',
                        label: l10n.moves,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.timer_outlined,
                        value: widget.timeText,
                        label: l10n.timeLabel,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: widget.hintsUsed == 0
                            ? Icons.verified_rounded
                            : Icons.lightbulb_rounded,
                        value: '${widget.hintsUsed}',
                        label: widget.hintsUsed == 0 ? l10n.noHintBonus : l10n.hintsUsedLabel,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (widget.stars < 3)
              FadeTransition(
                opacity: _interval(0.7, 0.9),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    l10n.starRule,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),

            // Butonlar
            FadeTransition(
              opacity: _interval(0.7, 1.0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: Row(
                  children: [
                    _RoundIconButton(
                      icon: Icons.home_rounded,
                      tooltip: l10n.mainMenu,
                      onTap: widget.onMenu,
                    ),
                    const SizedBox(width: 10),
                    _RoundIconButton(
                      icon: Icons.replay_rounded,
                      tooltip: l10n.replay,
                      onTap: widget.onReplay,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PressableScale(
                        onTap: widget.onNext,
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: widget.gradient,
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                            boxShadow: [
                              BoxShadow(
                                color: widget.gradient.colors.first.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.hasNextLevel ? l10n.nextLevel : l10n.mainMenu,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                widget.hasNextLevel
                                    ? Icons.arrow_forward_rounded
                                    : Icons.emoji_events_rounded,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarBadge extends StatelessWidget {
  final bool earned;
  final Animation<double> pop;
  final double size;

  const _StarBadge({required this.earned, required this.pop, required this.size});

  @override
  Widget build(BuildContext context) {
    final empty = Icon(
      Icons.star_rounded,
      size: size,
      color: Colors.white.withValues(alpha: 0.25),
    );
    if (!earned) return empty;

    return Stack(
      alignment: Alignment.center,
      children: [
        empty,
        AnimatedBuilder(
          animation: pop,
          builder: (context, child) => Transform.rotate(
            angle: (1 - pop.value) * -0.6,
            child: Transform.scale(scale: pop.value, child: child),
          ),
          child: Icon(
            Icons.star_rounded,
            size: size,
            color: AppColors.accent,
            shadows: [
              Shadow(color: AppColors.accent.withValues(alpha: 0.8), blurRadius: 18),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                value,
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: PressableScale(
        onTap: onTap,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          child: Icon(icon, color: primary),
        ),
      ),
    );
  }
}
