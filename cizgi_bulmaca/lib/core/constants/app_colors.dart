import 'package:flutter/material.dart';

/// Çizgi Bulmaca — Marka Renk Paleti
/// Tüm renkler merkezi olarak burada tanımlanır.
class AppColors {
  AppColors._();

  // ─── Ana Marka Renkleri ─────────────────────────────────
  static const Color primary = Color(0xFF6C4CF5);       // Elektrik Mor
  static const Color secondary = Color(0xFF3ADEB0);     // Mint Yeşil (başarı/tamamlama)
  static const Color accent = Color(0xFFFFC93C);        // Sıcak Sarı (yıldız/ödül)
  static const Color error = Color(0xFFFF5C5C);         // Mercan Kırmızı

  // ─── Arkaplan Renkleri ──────────────────────────────────
  static const Color backgroundLight = Color(0xFFF7F6FB);  // Kırık Beyaz
  static const Color backgroundDark = Color(0xFF12101C);   // Gece Lacivert

  // ─── Yüzey Renkleri ────────────────────────────────────
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1B2E);

  // ─── Kart/Container Renkleri ────────────────────────────
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF252238);

  // ─── Metin Renkleri ─────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B6B8D);
  static const Color textPrimaryDark = Color(0xFFF0F0F5);
  static const Color textSecondaryDark = Color(0xFF9B9BB0);

  // ─── Zorluk Renk Kodlaması ──────────────────────────────
  static const Color difficultyEasy = Color(0xFF3ADEB0);    // Mint Yeşil
  static const Color difficultyMedium = Color(0xFFFFAA33);  // Sarı/Turuncu
  static const Color difficultyHard = Color(0xFFE040FB);    // Mor/Pembe
  static const Color difficultyExpert = Color(0xFF3D5AFE);  // Kozmik Mavi

  // ─── Gradient Setleri ───────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C4CF5), Color(0xFF3ADEB0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF12101C), Color(0xFF1E1B3A), Color(0xFF2A1F5E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient easyGradient = LinearGradient(
    colors: [Color(0xFF3ADEB0), Color(0xFF2BC4A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mediumGradient = LinearGradient(
    colors: [Color(0xFFFFAA33), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient hardGradient = LinearGradient(
    colors: [Color(0xFFE040FB), Color(0xFFFF5C5C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expertGradient = LinearGradient(
    colors: [Color(0xFF3D5AFE), Color(0xFF00C6FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Kutlama / Efekt Renkleri ───────────────────────────
  static const List<Color> confetti = [
    Color(0xFF6C4CF5),
    Color(0xFF3ADEB0),
    Color(0xFFFFC93C),
    Color(0xFFFF5C5C),
    Color(0xFFE040FB),
    Color(0xFF00C6FF),
  ];

  // ─── Kullanıcı Tema Preset Renkleri ─────────────────────
  static const List<Color> themePresets = [
    Color(0xFF6C4CF5), // Mor (varsayılan)
    Color(0xFF2196F3), // Mavi
    Color(0xFFFF6B35), // Turuncu
    Color(0xFFE91E8C), // Pembe
    Color(0xFF4CAF50), // Yeşil
    Color(0xFFE53935), // Kırmızı
    Color(0xFF00BCD4), // Teal
    Color(0xFFFF9800), // Amber
  ];

  // ─── Çizgi Renkleri (Oyun İçi) ──────────────────────────
  static const Color lineDefault = Color(0xFF6C4CF5);
  static const Color lineCompleted = Color(0xFF3ADEB0);
  static const Color lineError = Color(0xFFFF5C5C);
  static const Color nodeDefault = Color(0xFF9B9BB0);
  static const Color nodeActive = Color(0xFF6C4CF5);
  static const Color nodeCompleted = Color(0xFF3ADEB0);

  // ─── Overlay & Misc ─────────────────────────────────────
  static const Color overlay = Color(0x80000000);
  static const Color shimmer = Color(0x1AFFFFFF);
  static const Color dividerLight = Color(0xFFE8E7F0);
  static const Color dividerDark = Color(0xFF2F2C42);
}
