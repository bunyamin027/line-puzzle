import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/game_provider.dart';
import '../../core/services/level_repository.dart';
import '../../core/services/settings_provider.dart';
import '../../core/widgets/constellation_background.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/staggered_entrance.dart';
import '../../models/difficulty.dart';

/// Çizgi Bulmaca — Ana Sayfa / Mod Seçim Ekranı
/// Kaldığın Yerden Devam Et hero kartı + Kolay, Orta, Zor, Uzman mod kartları.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _titleTapCount = 0;
  DateTime? _lastTitleTapTime;

  /// Geliştirici test kısayolu — yalnızca debug build'lerde çalışır.
  /// Release'te gizli bir IAP bypass'ı olması App Review reddine yol açar.
  void _onTitleTapped() {
    if (!kDebugMode) return;
    final now = DateTime.now();
    if (_lastTitleTapTime == null ||
        now.difference(_lastTitleTapTime!) > const Duration(seconds: 2)) {
      _titleTapCount = 1;
    } else {
      _titleTapCount++;
    }
    _lastTitleTapTime = now;

    if (_titleTapCount >= 8) {
      _titleTapCount = 0;
      HapticFeedback.heavyImpact();
      final settingsProvider = context.read<SettingsProvider>();
      final isCurrentlyActive = settingsProvider.adsRemoved;
      final newStatus = !isCurrentlyActive;
      settingsProvider.setAdsRemoved(newStatus);
      final l10n = AppStrings.get(settingsProvider.locale);

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                newStatus ? Icons.workspace_premium_rounded : Icons.info_outline_rounded,
                color: newStatus ? AppColors.accent : Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  newStatus ? l10n.devModeActive : l10n.devModeInactive,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: newStatus ? const Color(0xFF221F38) : Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final l10n = context.l10n;
    final continueDiff = gameProvider.lastPlayedDifficulty;
    final continueLevel = gameProvider.lastPlayedLevel > 0
        ? gameProvider.lastPlayedLevel
        : gameProvider.lastUnlockedLevel(continueDiff);
    final continueLevelModel = LevelRepository.getLevel(continueDiff, continueLevel);
    final continueDifficultyModel = Difficulty.fromIndex(continueDiff);
    final locale = context.watch<SettingsProvider>().locale;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ConstellationBackground(
              color: Theme.of(context).colorScheme.primary,
              opacity: Theme.of(context).brightness == Brightness.dark ? 1.0 : 0.6,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingL,
                vertical: AppConstants.paddingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Yıldız sayacı
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.accent,
                              size: 24,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${gameProvider.totalStars}',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Başlık (debug'da 8 kere tıklanınca Premium açar).
                      // Dar ekranlarda (ör. 6.1") taşmak yerine küçülür.
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _onTitleTapped,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                l10n.appName,
                                maxLines: 1,
                                style: AppTextStyles.headlineSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Menü butonları
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.push('/store'),
                            icon: const Icon(Icons.store_rounded),
                            tooltip: l10n.storeTooltip,
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            onPressed: () => context.push('/profile'),
                            icon: const Icon(Icons.person_rounded),
                            tooltip: l10n.profileTooltip,
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            onPressed: () => context.push('/settings'),
                            icon: const Icon(Icons.settings_rounded),
                            tooltip: l10n.settingsTooltip,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ─── Hero: Kaldığın Yerden Devam Et ───
                  StaggeredEntrance(
                    beginScale: 0.94,
                    child: _ContinueHeroCard(
                      difficulty: continueDifficultyModel,
                      levelNumber: continueLevel,
                      levelName: continueLevelModel.localizedName(locale),
                      onPlay: () => context.push('/game/$continueLevel?d=$continueDiff'),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Mod Seçim Başlığı
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          l10n.difficultyModes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headlineSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.totalLevelsCount,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mod Kartları
                  for (final difficulty in Difficulty.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: StaggeredEntrance(
                        delay: Duration(milliseconds: 120 + 80 * difficulty.index),
                        child: _DifficultyCard(
                          difficulty: difficulty,
                          levelCount: gameProvider.totalLevelsForDifficulty(difficulty.index),
                          unlockedLevel: gameProvider.lastUnlockedLevel(difficulty.index),
                          completedCount: gameProvider.completedLevelsCount(difficulty.index),
                          progress: gameProvider.progressForDifficulty(difficulty.index),
                          onTap: () => context.push('/levels/${difficulty.index}'),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kaldığın Yerden Devam Et Hero Kartı
class _ContinueHeroCard extends StatelessWidget {
  final Difficulty difficulty;
  final int levelNumber;
  final String levelName;
  final VoidCallback onPlay;

  const _ContinueHeroCard({
    required this.difficulty,
    required this.levelNumber,
    required this.levelName,
    required this.onPlay,
  });

  LinearGradient get _gradient => difficulty.gradient;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PressableScale(
      onTap: onPlay,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        decoration: BoxDecoration(
          gradient: _gradient,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: _gradient.colors.first.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Küçük etiket
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          l10n.continuePlaying,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Seviye ve Başlık
                  Text(
                    '${l10n.level} $levelNumber',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${difficulty.localized(context)} • $levelName',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Oyna Butonu (nefes alan halka ile dikkat çeker)
            _BreathingPlayButton(color: _gradient.colors.first),
          ],
        ),
      ),
    );
  }
}

/// Zorluk modu kartı widget'ı
class _DifficultyCard extends StatelessWidget {
  final Difficulty difficulty;
  final int levelCount;
  final int unlockedLevel;
  final int completedCount;
  final double progress; // 0.0 - 1.0
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.difficulty,
    required this.levelCount,
    required this.unlockedLevel,
    required this.completedCount,
    required this.progress,
    required this.onTap,
  });

  LinearGradient get gradient => difficulty.gradient;
  IconData get icon => difficulty.icon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 112,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingM,
          ),
          child: Row(
            children: [
              // İkon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 16),

              // Bilgiler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      difficulty.localized(context),
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.levelProgress(unlockedLevel, levelCount, completedCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 7),
                    // Mod ilerleme çubuğu (açılışta dolarak gelir)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Container(height: 5, color: Colors.white.withValues(alpha: 0.25)),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) => FractionallySizedBox(
                              widthFactor: value.clamp(0.0, 1.0),
                              child: Container(height: 5, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Oyna / Harita Butonu
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.map,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Hafifçe büyüyüp küçülen ve dışa halka yayan oynat butonu
class _BreathingPlayButton extends StatefulWidget {
  final Color color;

  const _BreathingPlayButton({required this.color});

  @override
  State<_BreathingPlayButton> createState() => _BreathingPlayButtonState();
}

class _BreathingPlayButtonState extends State<_BreathingPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final breath = 1 + 0.06 * sin(t * 2 * pi);
          return Stack(
            alignment: Alignment.center,
            children: [
              // Yayılan halka
              Container(
                width: 58 + 18 * t,
                height: 58 + 18 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6 * (1 - t)),
                    width: 2,
                  ),
                ),
              ),
              Transform.scale(scale: breath, child: child),
            ],
          );
        },
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.play_arrow_rounded, size: 38, color: widget.color),
        ),
      ),
    );
  }
}
