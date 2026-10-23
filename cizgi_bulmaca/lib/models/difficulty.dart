import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/services/settings_provider.dart';

/// Çizgi Bulmaca — Zorluk Modu Enum
/// Sıra (index) kalıcı ilerleme anahtarı olarak kullanılır; yeni mod en sona eklenmeli.
enum Difficulty {
  easy('Kolay', 'Easy', AppColors.difficultyEasy, AppColors.easyGradient,
      Icons.sentiment_satisfied_rounded),
  medium('Orta', 'Medium', AppColors.difficultyMedium, AppColors.mediumGradient,
      Icons.psychology_rounded),
  hard('Zor', 'Hard', AppColors.difficultyHard, AppColors.hardGradient,
      Icons.local_fire_department_rounded),
  expert('Uzman', 'Expert', AppColors.difficultyExpert, AppColors.expertGradient,
      Icons.diamond_rounded);

  const Difficulty(this.labelTr, this.labelEn, this.color, this.gradient, this.icon);
  final String labelTr;
  final String labelEn;
  final Color color;
  final LinearGradient gradient;
  final IconData icon;

  /// Rota parametresinden güvenli dönüşüm
  static Difficulty fromIndex(int index) =>
      Difficulty.values[index.clamp(0, Difficulty.values.length - 1)];

  /// Aktif BuildContext ve SettingsProvider'a göre reaktif isim döndürür
  String localized(BuildContext context) {
    final locale = context.watch<SettingsProvider>().locale;
    return locale == 'en' ? labelEn : labelTr;
  }

  /// Belirli bir locale koduna göre isim döndürür
  String localizedFor(String locale) {
    return locale == 'en' ? labelEn : labelTr;
  }
}
