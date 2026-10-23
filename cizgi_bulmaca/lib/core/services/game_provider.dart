import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../models/level_progress.dart';

/// Çizgi Bulmaca — Oyun İlerleme Provider
/// Level tamamlama, yıldız, puan verilerini SharedPreferences'a kaydeder.
class GameProvider extends ChangeNotifier {
  // Her zorluk için ilerleme haritası: levelId -> LevelProgress
  final Map<int, Map<int, LevelProgress>> _progressByDifficulty = {
    0: {}, // Kolay
    1: {}, // Orta
    2: {}, // Zor
    3: {}, // Uzman
  };

  int _totalStars = 0;
  int _totalScore = 0;
  int _lastPlayedDifficulty = 0;
  int _lastPlayedLevel = 1;
  int _hintCount = AppConstants.defaultHintCount;
  Future<void>? _loadFuture;

  GameProvider() {
    _loadFuture = _loadProgress();
  }

  /// Verilerin SharedPreferences'tan tamamen yüklendiğini garanti eder
  Future<void> get isReady => _loadFuture ?? Future.value();

  // ─── Getters ─────────────────────────────────────────────

  int get totalStars => _totalStars;
  int get totalScore => _totalScore;
  int get lastPlayedDifficulty => _lastPlayedDifficulty;
  int get lastPlayedLevel => _lastPlayedLevel;
  int get hintCount => _hintCount;

  /// Belirli bir zorluktaki tamamlanan level sayısı
  int completedLevelsCount(int difficulty) {
    final map = _progressByDifficulty[difficulty] ?? {};
    return map.values.where((p) => p.isCompleted).length;
  }

  /// Belirli bir zorluktaki toplam level sayısı
  int totalLevelsForDifficulty(int difficulty) =>
      AppConstants.levelCountFor(difficulty);

  /// Tüm zorluklarda tamamlanan toplam level sayısı
  int get totalCompletedLevels {
    var total = 0;
    for (int d = 0; d < AppConstants.difficultyCount; d++) {
      total += completedLevelsCount(d);
    }
    return total;
  }

  /// Bu zorlukta [levelId]'den sonra oynanacak level var mı?
  bool hasNextLevel(int difficulty, int levelId) =>
      levelId < totalLevelsForDifficulty(difficulty);

  /// Belirli bir zorluktaki ilerleme yüzdesi (0.0 - 1.0)
  double progressForDifficulty(int difficulty) {
    final completed = completedLevelsCount(difficulty);
    final total = totalLevelsForDifficulty(difficulty);
    return total > 0 ? completed / total : 0.0;
  }

  /// Belirli bir level'ın ilerleme bilgisi
  LevelProgress? getLevelProgress(int difficulty, int levelId) {
    return _progressByDifficulty[difficulty]?[levelId];
  }

  /// Level açık mı? (İlk level her zaman açık, sonrakiler bir önceki tamamlanınca açılır)
  bool isLevelUnlocked(int difficulty, int levelId) {
    if (levelId == 1) return true; // İlk level her zaman açık
    // Bir önceki level tamamlanmışsa bu level açık
    final prevProgress = _progressByDifficulty[difficulty]?[levelId - 1];
    return prevProgress?.isCompleted ?? false;
  }

  /// En son açılan level numarası
  int lastUnlockedLevel(int difficulty) {
    final map = _progressByDifficulty[difficulty] ?? {};
    int maxCompleted = 0;
    for (final entry in map.entries) {
      if (entry.value.isCompleted && entry.key > maxCompleted) {
        maxCompleted = entry.key;
      }
    }
    // Bir sonraki level açık (son level'ı aşmasın)
    final total = totalLevelsForDifficulty(difficulty);
    return (maxCompleted + 1).clamp(1, total > 0 ? total : 1);
  }

  /// Belirli bir level'ın yıldız sayısı
  int getStars(int difficulty, int levelId) {
    return _progressByDifficulty[difficulty]?[levelId]?.stars ?? 0;
  }

  /// Son oynanan seviyeyi güncelle
  Future<void> setLastPlayed(int difficulty, int levelId) async {
    await isReady;
    _lastPlayedDifficulty = difficulty;
    _lastPlayedLevel = levelId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyLastDifficulty, _lastPlayedDifficulty);
    await prefs.setInt(AppConstants.keyLastLevel, _lastPlayedLevel);
  }

  /// İpucu kullan (varsa sayıyı azaltır ve true döner)
  Future<bool> useHint() async {
    await isReady;
    if (_hintCount > 0) {
      _hintCount--;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppConstants.keyHintCount, _hintCount);
      return true;
    }
    return false;
  }

  /// Yeni ipuçları ekle (ödüllü reklam, satın alma vb.)
  Future<void> addHints(int count) async {
    await isReady;
    _hintCount += count;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyHintCount, _hintCount);
  }

  // ─── Level Tamamlama ────────────────────────────────────

  /// Level tamamlandığında çağrılır
  Future<void> completeLevel({
    required int difficulty,
    required int levelId,
    required int stars,
    required int moves,
    required int timeMs,
  }) async {
    await isReady;
    final existingProgress = _progressByDifficulty[difficulty]?[levelId];

    // Daha iyi sonuç mu kontrol et
    final newStars = (existingProgress != null && existingProgress.stars > stars)
        ? existingProgress.stars
        : stars;
    final newBestMoves = (existingProgress != null &&
            existingProgress.bestMoves > 0 &&
            existingProgress.bestMoves < moves)
        ? existingProgress.bestMoves
        : moves;
    final newBestTime = (existingProgress != null &&
            existingProgress.bestTimeMs > 0 &&
            existingProgress.bestTimeMs < timeMs)
        ? existingProgress.bestTimeMs
        : timeMs;
    final newAttempts = (existingProgress?.attempts ?? 0) + 1;

    final progress = LevelProgress(
      levelId: levelId,
      isCompleted: true,
      stars: newStars,
      bestMoves: newBestMoves,
      bestTimeMs: newBestTime,
      attempts: newAttempts,
    );

    _progressByDifficulty[difficulty] ??= {};
    _progressByDifficulty[difficulty]![levelId] = progress;

    // Bir sonraki seviyeyi son oynanan olarak ayarla
    _lastPlayedDifficulty = difficulty;
    _lastPlayedLevel = hasNextLevel(difficulty, levelId) ? levelId + 1 : levelId;

    // Toplam yıldız ve puanı yeniden hesapla
    _recalculateTotals();

    notifyListeners();
    await _saveProgress();
  }

  // ─── Hesaplama ──────────────────────────────────────────

  void _recalculateTotals() {
    int stars = 0;
    int score = 0;
    for (final diffMap in _progressByDifficulty.values) {
      for (final progress in diffMap.values) {
        stars += progress.stars;
        // Her yıldız 100 puan
        score += progress.stars * 100;
      }
    }
    _totalStars = stars;
    _totalScore = score;
  }

  // ─── Kaydetme / Yükleme ─────────────────────────────────

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();

    for (final entry in _progressByDifficulty.entries) {
      final key = 'progress_difficulty_${entry.key}';
      final jsonMap = <String, dynamic>{};
      for (final levelEntry in entry.value.entries) {
        jsonMap[levelEntry.key.toString()] = levelEntry.value.toJson();
      }
      await prefs.setString(key, jsonEncode(jsonMap));
    }

    await prefs.setInt(AppConstants.keyTotalStars, _totalStars);
    await prefs.setInt(AppConstants.keyTotalScore, _totalScore);
    await prefs.setInt(AppConstants.keyLastDifficulty, _lastPlayedDifficulty);
    await prefs.setInt(AppConstants.keyLastLevel, _lastPlayedLevel);
    await prefs.setInt(AppConstants.keyHintCount, _hintCount);
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    for (int diff = 0; diff < AppConstants.difficultyCount; diff++) {
      final key = 'progress_difficulty_$diff';
      final jsonStr = prefs.getString(key);
      if (jsonStr != null) {
        try {
          final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
          for (final entry in jsonMap.entries) {
            final levelId = int.parse(entry.key);
            final progress =
                LevelProgress.fromJson(entry.value as Map<String, dynamic>);
            _progressByDifficulty[diff] ??= {};
            _progressByDifficulty[diff]![levelId] = progress;
          }
        } catch (_) {
          // JSON parse hatası — sessizce geç
        }
      }
    }

    _totalStars = prefs.getInt(AppConstants.keyTotalStars) ?? 0;
    _totalScore = prefs.getInt(AppConstants.keyTotalScore) ?? 0;
    _lastPlayedDifficulty = (prefs.getInt(AppConstants.keyLastDifficulty) ?? 0)
        .clamp(0, AppConstants.difficultyCount - 1);
    _lastPlayedLevel = prefs.getInt(AppConstants.keyLastLevel) ?? lastUnlockedLevel(_lastPlayedDifficulty);
    _hintCount = prefs.getInt(AppConstants.keyHintCount) ?? AppConstants.defaultHintCount;

    // Totalleri doğrula
    _recalculateTotals();
    notifyListeners();
  }
}
