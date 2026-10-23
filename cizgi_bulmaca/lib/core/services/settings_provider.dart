import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'ad_service.dart';

/// Çizgi Bulmaca — Uygulama Ayarları Provider
/// Ses, haptic, dil, onboarding durumu gibi genel ayarları yönetir.
class SettingsProvider extends ChangeNotifier {
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  String _locale = _deviceLocale();
  bool _onboardingCompleted = false;
  bool _adsRemoved = false;

  SettingsProvider() {
    _loadPreferences();
  }

  /// İlk açılışta cihaz dili Türkçe ise 'tr', aksi halde 'en'
  static String _deviceLocale() {
    final code = PlatformDispatcher.instance.locale.languageCode;
    return code == 'tr' ? 'tr' : 'en';
  }

  // ─── Getters ─────────────────────────────────────────────
  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;
  String get locale => _locale;
  bool get onboardingCompleted => _onboardingCompleted;
  bool get adsRemoved => _adsRemoved;

  // ─── Setters ─────────────────────────────────────────────
  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keySoundEnabled, value);
  }

  Future<void> setHapticEnabled(bool value) async {
    _hapticEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyHapticEnabled, value);
  }

  Future<void> setLocale(String locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLocale, locale);
  }

  Future<void> setOnboardingCompleted(bool value) async {
    _onboardingCompleted = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingCompleted, value);
  }

  Future<void> setAdsRemoved(bool value) async {
    _adsRemoved = value;
    AdService.instance.setAdsRemoved(value);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyAdsRemoved, value);
  }

  // ─── Load Preferences ───────────────────────────────────
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    _soundEnabled = prefs.getBool(AppConstants.keySoundEnabled) ?? true;
    _hapticEnabled = prefs.getBool(AppConstants.keyHapticEnabled) ?? true;
    _locale = prefs.getString(AppConstants.keyLocale) ?? _deviceLocale();
    _onboardingCompleted = prefs.getBool(AppConstants.keyOnboardingCompleted) ?? false;
    _adsRemoved = prefs.getBool(AppConstants.keyAdsRemoved) ?? false;

    if (_adsRemoved) {
      AdService.instance.setAdsRemoved(true);
    }

    notifyListeners();
  }
}
