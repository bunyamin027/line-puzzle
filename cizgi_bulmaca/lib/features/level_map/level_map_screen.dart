import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/game_provider.dart';
import '../../core/services/level_repository.dart';
import '../../core/services/settings_provider.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/staggered_entrance.dart';
import '../../models/difficulty.dart';

/// Çizgi Bulmaca — Level Haritası Ekranı
/// Seçilen moda ait seviyeler grid şeklinde dizili.
/// Aktif seviye vurgulanır ve otomatik scroll yapılır.
/// Altta hızlı "Devam Et" çubuğu yer alır.
class LevelMapScreen extends StatefulWidget {
  final int difficulty; // 0=kolay, 1=orta, 2=zor, 3=uzman

  const LevelMapScreen({super.key, required this.difficulty});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  final ScrollController _scrollController = ScrollController();

  Difficulty get _difficulty => Difficulty.fromIndex(widget.difficulty);

  LinearGradient get _gradient => _difficulty.gradient;

  Color get _color => _difficulty.color;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveLevel();
    });
  }

  void _scrollToActiveLevel() {
    if (!mounted) return;
    final gameProvider = context.read<GameProvider>();
    final activeLevel = gameProvider.lastUnlockedLevel(widget.difficulty);
    // Her satırda 4 kart var, her satır yaklaşık 110px yüksekliğinde
    final rowIndex = (activeLevel - 1) ~/ 4;
    final targetOffset = (rowIndex * 110.0) - 100.0;
    if (_scrollController.hasClients && targetOffset > 0) {
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final l10n = context.l10n;
    final completedCount = gameProvider.completedLevelsCount(widget.difficulty);
    final totalLevels = gameProvider.totalLevelsForDifficulty(widget.difficulty);
    final activeLevel = gameProvider.lastUnlockedLevel(widget.difficulty);
    final activeLevelModel = LevelRepository.getLevel(widget.difficulty, activeLevel);
    final locale = context.watch<SettingsProvider>().locale;

    return Scaffold(
      appBar: AppBar(
        title: Text(_difficulty.localized(context)),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
        actions: [
          // İlerleme bilgisi
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 16, color: _color),
                    const SizedBox(width: 5),
                    Text(
                      '$completedCount / $totalLevels',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: _color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Grid Seviye Listesi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(
                top: AppConstants.paddingM,
                bottom: 100, // Alt devam çubuğu için boşluk
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: totalLevels,
              itemBuilder: (context, index) {
                final levelNumber = index + 1;
                final isUnlocked = gameProvider.isLevelUnlocked(widget.difficulty, levelNumber);
                final stars = gameProvider.getStars(widget.difficulty, levelNumber);
                final isCompleted = gameProvider.getLevelProgress(widget.difficulty, levelNumber)?.isCompleted ?? false;
                final isActive = levelNumber == activeLevel;

                final tile = PressableScale(
                  onTap: isUnlocked
                      ? () => context.push('/game/$levelNumber?d=${widget.difficulty}')
                      : null,
                  child: AnimatedContainer(
                    duration: AppConstants.shortAnimation,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? null
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.05),
                      gradient: isUnlocked
                          ? (isCompleted
                              ? _gradient
                              : LinearGradient(
                                  colors: [
                                    _color.withValues(alpha: 0.85),
                                    _color.withValues(alpha: 0.65),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ))
                          : null,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      border: isActive
                          ? Border.all(
                              color: AppColors.accent,
                              width: 3.0,
                            )
                          : null,
                      boxShadow: isUnlocked
                          ? [
                              BoxShadow(
                                color: isActive
                                    ? AppColors.accent.withValues(alpha: 0.5)
                                    : _color.withValues(alpha: isCompleted ? 0.3 : 0.15),
                                blurRadius: isActive ? 12 : 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isUnlocked)
                          Icon(
                            Icons.lock_rounded,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.25),
                            size: 22,
                          )
                        else ...[
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.active,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.black87,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          Text(
                            '$levelNumber',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (isCompleted) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (i) {
                                return Icon(
                                  i < stars
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 13,
                                  color: i < stars
                                      ? AppColors.accent
                                      : Colors.white.withValues(alpha: 0.5),
                                );
                              }),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                );

                // Satır satır dalga halinde belirme
                return StaggeredEntrance(
                  key: ValueKey(levelNumber),
                  delay: Duration(milliseconds: 30 * (index % 4) + 12 * min(index ~/ 4, 8)),
                  duration: const Duration(milliseconds: 380),
                  beginOffset: const Offset(0, 0.25),
                  beginScale: 0.85,
                  child: isActive ? _PulsingGlow(color: AppColors.accent, child: tile) : tile,
                );
              },
            ),
          ),

          // Alt Sabit Çubuk: "Kaldığın Yerden Devam Et"
          Positioned(
            left: AppConstants.paddingM,
            right: AppConstants.paddingM,
            bottom: AppConstants.paddingM,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                border: Border.all(
                  color: _color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.currentLevel,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          '${l10n.level} $activeLevel • ${activeLevelModel.localizedName(locale)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    onPressed: () => context.push('/game/$activeLevel?d=${widget.difficulty}'),
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: Text(
                      l10n.play,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aktif seviye kutucuğunun etrafında nabız gibi atan ışıma
class _PulsingGlow extends StatefulWidget {
  final Widget child;
  final Color color;

  const _PulsingGlow({required this.child, required this.color});

  @override
  State<_PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<_PulsingGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.25 + 0.35 * _controller.value),
              blurRadius: 8 + 10 * _controller.value,
              spreadRadius: 1 + 2 * _controller.value,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}
