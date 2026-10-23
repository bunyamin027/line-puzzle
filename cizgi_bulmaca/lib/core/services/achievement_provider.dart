import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_provider.dart';
import 'settings_provider.dart';

/// Çizgi Bulmaca — Başarım Tanımı
class AchievementDef {
  final String id;
  final String titleTr;
  final String titleEn;
  final String subtitleTr;
  final String subtitleEn;
  final IconData icon;
  final Color color;

  const AchievementDef({
    required this.id,
    required this.titleTr,
    required this.titleEn,
    required this.subtitleTr,
    required this.subtitleEn,
    required this.icon,
    required this.color,
  });

  // Geriye dönük uyumluluk getter'ları
  String get title => titleTr;
  String get subtitle => subtitleTr;

  String localizedTitle(BuildContext context) {
    final locale = context.watch<SettingsProvider>().locale;
    return locale == 'en' ? titleEn : titleTr;
  }

  String localizedSubtitle(BuildContext context) {
    final locale = context.watch<SettingsProvider>().locale;
    return locale == 'en' ? subtitleEn : subtitleTr;
  }

  String localizedTitleFor(String locale) => locale == 'en' ? titleEn : titleTr;
  String localizedSubtitleFor(String locale) => locale == 'en' ? subtitleEn : subtitleTr;
}

/// Çizgi Bulmaca — Başarımlar Provider
/// Başarım koşullarını kontrol eder ve açılan başarımları kalıcı olarak saklar.
class AchievementProvider extends ChangeNotifier {
  final GameProvider _gameProvider;

  // Açılmış başarım ID'leri
  final Set<String> _unlockedIds = {};

  // Yeni açılan başarımlar (bildirim göstermek için)
  final List<String> _pendingNotifications = [];

  AchievementProvider(this._gameProvider) {
    _loadUnlocked();
    _gameProvider.addListener(_checkAchievements);
  }

  @override
  void dispose() {
    _gameProvider.removeListener(_checkAchievements);
    super.dispose();
  }

  // ─── Başarım Listesi ──────────────────────────────────────

  static const List<AchievementDef> definitions = [
    AchievementDef(
      id: 'first_step',
      titleTr: 'İlk Adım',
      titleEn: 'First Step',
      subtitleTr: 'İlk level\'ı tamamla',
      subtitleEn: 'Complete your first level',
      icon: Icons.play_arrow_rounded,
      color: Color(0xFF3ADEB0),
    ),
    AchievementDef(
      id: 'star_hunter_10',
      titleTr: 'Yıldız Toplayıcı',
      titleEn: 'Star Collector',
      subtitleTr: '10 yıldız topla',
      subtitleEn: 'Collect 10 stars',
      icon: Icons.star_rounded,
      color: Color(0xFFFFC93C),
    ),
    AchievementDef(
      id: 'star_hunter_50',
      titleTr: 'Yıldız Avcısı',
      titleEn: 'Star Hunter',
      subtitleTr: '50 yıldız topla',
      subtitleEn: 'Collect 50 stars',
      icon: Icons.star_rounded,
      color: Color(0xFFFFC93C),
    ),
    AchievementDef(
      id: 'star_hunter_100',
      titleTr: 'Yıldız Ustası',
      titleEn: 'Star Master',
      subtitleTr: '100 yıldız topla',
      subtitleEn: 'Collect 100 stars',
      icon: Icons.stars_rounded,
      color: Color(0xFFFFC93C),
    ),
    AchievementDef(
      id: 'star_hunter_500',
      titleTr: 'Yıldız Efsanesi',
      titleEn: 'Star Legend',
      subtitleTr: '500 yıldız topla',
      subtitleEn: 'Collect 500 stars',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFFFC93C),
    ),
    AchievementDef(
      id: 'speed_demon',
      titleTr: 'Hız Şeytanı',
      titleEn: 'Speed Demon',
      subtitleTr: 'Bir level\'ı 5 saniyede tamamla',
      subtitleEn: 'Complete a level in 5 seconds',
      icon: Icons.speed_rounded,
      color: Color(0xFFFF6B35),
    ),
    AchievementDef(
      id: 'easy_master_10',
      titleTr: 'Kolay Usta',
      titleEn: 'Easy Master',
      subtitleTr: 'Kolay modda 10 level tamamla',
      subtitleEn: 'Complete 10 levels in Easy mode',
      icon: Icons.sentiment_satisfied_rounded,
      color: Color(0xFF3ADEB0),
    ),
    AchievementDef(
      id: 'easy_master_50',
      titleTr: 'Kolay Uzman',
      titleEn: 'Easy Expert',
      subtitleTr: 'Kolay modda 50 level tamamla',
      subtitleEn: 'Complete 50 levels in Easy mode',
      icon: Icons.sentiment_satisfied_rounded,
      color: Color(0xFF3ADEB0),
    ),
    AchievementDef(
      id: 'medium_master_10',
      titleTr: 'Orta Usta',
      titleEn: 'Medium Master',
      subtitleTr: 'Orta modda 10 level tamamla',
      subtitleEn: 'Complete 10 levels in Medium mode',
      icon: Icons.psychology_rounded,
      color: Color(0xFFFFAA33),
    ),
    AchievementDef(
      id: 'medium_master_50',
      titleTr: 'Orta Uzman',
      titleEn: 'Medium Expert',
      subtitleTr: 'Orta modda 50 level tamamla',
      subtitleEn: 'Complete 50 levels in Medium mode',
      icon: Icons.psychology_rounded,
      color: Color(0xFFFFAA33),
    ),
    AchievementDef(
      id: 'hard_master_10',
      titleTr: 'Zor Usta',
      titleEn: 'Hard Master',
      subtitleTr: 'Zor modda 10 level tamamla',
      subtitleEn: 'Complete 10 levels in Hard mode',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFE040FB),
    ),
    AchievementDef(
      id: 'hard_master_50',
      titleTr: 'Usta Çözücü',
      titleEn: 'Master Solver',
      subtitleTr: 'Zor modda 50 level tamamla',
      subtitleEn: 'Complete 50 levels in Hard mode',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFE040FB),
    ),
    AchievementDef(
      id: 'expert_master_10',
      titleTr: 'Uzman Çırak',
      titleEn: 'Expert Apprentice',
      subtitleTr: 'Uzman modda 10 level tamamla',
      subtitleEn: 'Complete 10 levels in Expert mode',
      icon: Icons.diamond_rounded,
      color: Color(0xFF3D5AFE),
    ),
    AchievementDef(
      id: 'expert_master_50',
      titleTr: 'Çizgi Efsanesi',
      titleEn: 'Line Legend',
      subtitleTr: 'Uzman modda 50 level tamamla',
      subtitleEn: 'Complete 50 levels in Expert mode',
      icon: Icons.diamond_rounded,
      color: Color(0xFF3D5AFE),
    ),
    AchievementDef(
      id: 'marathon_25',
      titleTr: 'Maraton Koşucusu',
      titleEn: 'Marathon Runner',
      subtitleTr: 'Toplam 25 level tamamla',
      subtitleEn: 'Complete 25 levels in total',
      icon: Icons.directions_run_rounded,
      color: Color(0xFF2196F3),
    ),
    AchievementDef(
      id: 'marathon_100',
      titleTr: 'Maraton Şampiyonu',
      titleEn: 'Marathon Champion',
      subtitleTr: 'Toplam 100 level tamamla',
      subtitleEn: 'Complete 100 levels in total',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFF2196F3),
    ),
    AchievementDef(
      id: 'marathon_500',
      titleTr: 'Durdurulamaz',
      titleEn: 'Unstoppable',
      subtitleTr: 'Toplam 500 level tamamla',
      subtitleEn: 'Complete 500 levels in total',
      icon: Icons.military_tech_rounded,
      color: Color(0xFF2196F3),
    ),
    AchievementDef(
      id: 'star_hunter_1000',
      titleTr: 'Galaksi Sahibi',
      titleEn: 'Galaxy Owner',
      subtitleTr: '1000 yıldız topla',
      subtitleEn: 'Collect 1000 stars',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFFFC93C),
    ),
    AchievementDef(
      id: 'hint_user',
      titleTr: 'Akıllı Hamle',
      titleEn: 'Smart Move',
      subtitleTr: 'İlk ipucunu kullan',
      subtitleEn: 'Use your first hint',
      icon: Icons.lightbulb_rounded,
      color: Color(0xFF6C4CF5),
    ),
    AchievementDef(
      id: 'perfect_3',
      titleTr: 'Mükemmeliyetçi',
      titleEn: 'Perfectionist',
      subtitleTr: 'Arka arkaya 3 level\'da 3 yıldız al',
      subtitleEn: 'Get 3 stars on 3 consecutive levels',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFFE91E8C),
    ),
  ];

  // ─── Getters ──────────────────────────────────────────────

  Set<String> get unlockedIds => Set.unmodifiable(_unlockedIds);
  int get unlockedCount => _unlockedIds.length;
  int get totalCount => definitions.length;

  bool isUnlocked(String id) => _unlockedIds.contains(id);

  /// Bildirim gösterilmeyi bekleyen başarımları tüketir
  List<AchievementDef> consumePendingNotifications() {
    final pending = _pendingNotifications
        .map((id) => definitions.firstWhere((d) => d.id == id))
        .toList();
    _pendingNotifications.clear();
    return pending;
  }

  bool get hasPendingNotifications => _pendingNotifications.isNotEmpty;

  // ─── Başarım Kontrolü ─────────────────────────────────────

  void _checkAchievements() {
    final gp = _gameProvider;
    final totalCompleted = gp.totalCompletedLevels;

    // İlk Adım
    if (totalCompleted >= 1) _unlock('first_step');

    // Yıldız Toplayıcı
    if (gp.totalStars >= 10) _unlock('star_hunter_10');
    if (gp.totalStars >= 50) _unlock('star_hunter_50');
    if (gp.totalStars >= 100) _unlock('star_hunter_100');
    if (gp.totalStars >= 500) _unlock('star_hunter_500');
    if (gp.totalStars >= 1000) _unlock('star_hunter_1000');

    // Kolay Usta
    if (gp.completedLevelsCount(0) >= 10) _unlock('easy_master_10');
    if (gp.completedLevelsCount(0) >= 50) _unlock('easy_master_50');

    // Orta Usta
    if (gp.completedLevelsCount(1) >= 10) _unlock('medium_master_10');
    if (gp.completedLevelsCount(1) >= 50) _unlock('medium_master_50');

    // Zor Usta
    if (gp.completedLevelsCount(2) >= 10) _unlock('hard_master_10');
    if (gp.completedLevelsCount(2) >= 50) _unlock('hard_master_50');

    // Uzman
    if (gp.completedLevelsCount(3) >= 10) _unlock('expert_master_10');
    if (gp.completedLevelsCount(3) >= 50) _unlock('expert_master_50');

    // Maraton
    if (totalCompleted >= 25) _unlock('marathon_25');
    if (totalCompleted >= 100) _unlock('marathon_100');
    if (totalCompleted >= 500) _unlock('marathon_500');
  }

  /// Hız Şeytanı — 5 saniye altında tamamlama (game_screen'den çağrılacak)
  void checkSpeedDemon(int timeMs) {
    if (timeMs > 0 && timeMs <= 5000) {
      _unlock('speed_demon');
    }
  }

  /// İpucu kullanımı (game_screen'den çağrılacak)
  void checkHintUsed() {
    _unlock('hint_user');
  }

  /// Arka arkaya 3 mükemmel skor (game_screen'den çağrılacak)
  void checkPerfectStreak(int consecutivePerfects) {
    if (consecutivePerfects >= 3) {
      _unlock('perfect_3');
    }
  }

  // ─── Internal ─────────────────────────────────────────────

  void _unlock(String id) {
    if (_unlockedIds.contains(id)) return;
    _unlockedIds.add(id);
    _pendingNotifications.add(id);
    notifyListeners();
    _saveUnlocked();
  }

  Future<void> _saveUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('achievements_unlocked', _unlockedIds.toList());
  }

  Future<void> _loadUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('achievements_unlocked');
    if (list != null) {
      _unlockedIds.addAll(list);
      notifyListeners();
    }
  }
}
