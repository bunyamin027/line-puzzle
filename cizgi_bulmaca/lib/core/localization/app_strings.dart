import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_provider.dart';

/// Çizgi Bulmaca — Yerelleştirme / Strings Sistemi
/// Ayarlar'dan dil değiştiğinde context.l10n reaktif olarak anında güncellenir.
abstract class AppStrings {
  // ─── Genel / Ortak ──────────────────────────────────────
  String get appName;
  String get slogan;
  String get cancel;
  String get continueText;
  String get ok;
  String get close;
  String get level;
  String get moves;
  String linesCount(int count);
  String drawnLinesProgress(int drawn, int total);

  // ─── Zorluk Seviyeleri ──────────────────────────────────
  String get difficultyEasy;
  String get difficultyMedium;
  String get difficultyHard;
  String get difficultyExpert;
  String get difficultyModes;
  String get totalLevelsCount;

  // ─── Onboarding ─────────────────────────────────────────
  String get skip;
  String get next;
  String get start;
  String get onboarding1Title;
  String get onboarding1Subtitle;
  String get onboarding2Title;
  String get onboarding2Subtitle;
  String get onboarding3Title;
  String get onboarding3Subtitle;

  // ─── Ana Sayfa ──────────────────────────────────────────
  String get continuePlaying;
  String levelAndName(int level, String name);
  String levelProgress(int unlocked, int total, int completed);
  String get map;
  String get storeTooltip;
  String get profileTooltip;
  String get settingsTooltip;
  String get devModeActive;
  String get devModeInactive;

  // ─── Seviye Haritası ────────────────────────────────────
  String get active;
  String get currentLevel;
  String get play;

  // ─── Oyun Ekranı ────────────────────────────────────────
  String get undo;
  String get reset;
  String get hint;
  String get outOfHintsTitle;
  String get outOfHintsDesc;
  String get watchAdReward;
  String get hintsAdded;
  String get noHintFound;
  String get smartHintTitle;
  String smartHintDrawnInfo(int drawn, int total);
  String get deadEndDesc;
  String get wrongStartDesc;
  String get previewSolution;
  String get previewActiveSnackBar;
  String switchToRoute(int steps);
  String switchedToRouteSnackBar(int steps);
  String get cancelHint;
  String get congratulations;
  String get mainMenu;
  String formatTime(int minutes, int seconds);
  String get hintStartMsg;
  String get hintNextMsg;
  String hintRollbackMsg(int count);
  String get hintWrongStartMsg;
  String get guideFullSolution;
  String get guideNextSteps;
  String get resultPerfect;
  String get resultGreat;
  String get resultGood;
  String get replay;
  String get nextLevel;
  String get difficultyCompleted;
  String get hintsUsedLabel;
  String get noHintBonus;
  String get timeLabel;
  String get starRule;

  // ─── Ayarlar ────────────────────────────────────────────
  String get settings;
  String get appearance;
  String get darkMode;
  String get themeColor;
  String get general;
  String get soundEffects;
  String get haptic;
  String get language;
  String get selectLanguage;
  String get turkish;
  String get english;
  String get purchases;
  String get removeAds;
  String get restorePurchases;
  String get checkingPurchases;
  String get about;
  String get privacyPolicy;
  String get termsOfUse;
  String get supportAndFeedback;
  String get version;

  // ─── Mağaza ─────────────────────────────────────────────
  String get store;
  String get premiumActive;
  String get premiumActiveDesc;
  String get removeAdsDesc;
  String get allAdsRemoved;
  String get lifetimeAccess;
  String get allDevices;
  String buyPrice(String price);
  String get adsRemovedChecked;
  String get lifetimeAccessChecked;

  // ─── Profil & Başarımlar ─────────────────────────────────
  String get profile;
  String get player;
  String achievementsProgress(int unlocked, int total);
  String get totalStars;
  String get totalScore;
  String get solved;
  String get difficultyProgress;
  String get achievements;

  // ─── Factory & Provider Bağlantısı ──────────────────────
  static AppStrings of(BuildContext context) {
    final locale = context.watch<SettingsProvider>().locale;
    return get(locale);
  }

  static AppStrings get(String locale) {
    if (locale == 'en') {
      return const AppStringsEn();
    }
    return const AppStringsTr();
  }
}

/// Türkçe Çeviriler
class AppStringsTr implements AppStrings {
  const AppStringsTr();

  @override
  String get appName => 'Çizgi Bulmaca';
  @override
  String get slogan => 'Çiz. Çöz. Kazan.';
  @override
  String get cancel => 'Vazgeç';
  @override
  String get continueText => 'Devam Et';
  @override
  String get ok => 'Tamam';
  @override
  String get close => 'Kapat';
  @override
  String get level => 'Seviye';
  @override
  String get moves => 'hamle';
  @override
  String linesCount(int count) => '$count çizgi';
  @override
  String drawnLinesProgress(int drawn, int total) => '$drawn / $total çizgi';

  @override
  String get difficultyEasy => 'Kolay';
  @override
  String get difficultyMedium => 'Orta';
  @override
  String get difficultyHard => 'Zor';
  @override
  String get difficultyExpert => 'Uzman';
  @override
  String get difficultyModes => 'Zorluk Modları';
  @override
  String get totalLevelsCount => '1200 Seviye';

  @override
  String get skip => 'Geç';
  @override
  String get next => 'İleri';
  @override
  String get start => 'Başla';
  @override
  String get onboarding1Title => 'Parmağını Kaldırmadan';
  @override
  String get onboarding1Subtitle => 'Şekli tek çizgiyle tamamla.\nHer kenardan sadece bir kez geç.';
  @override
  String get onboarding2Title => 'Sana Uygun Zorluk';
  @override
  String get onboarding2Subtitle => 'Kolay, Orta, Zor ve Uzman —\n1200 seviyede kendi hızında ilerle.';
  @override
  String get onboarding3Title => 'Yıldız Kazan, Rekor Kır';
  @override
  String get onboarding3Subtitle => 'Her seviyede 3 yıldız hedefle.\nİpuçları topla, başarımlar aç.';

  @override
  String get continuePlaying => 'KALDIĞIN YERDEN DEVAM ET';
  @override
  String levelAndName(int level, String name) => 'Seviye $level • $name';
  @override
  String levelProgress(int unlocked, int total, int completed) =>
      '$completed / $total tamamlandı';
  @override
  String get map => 'Harita';
  @override
  String get storeTooltip => 'Mağaza';
  @override
  String get profileTooltip => 'Profil';
  @override
  String get settingsTooltip => 'Ayarlar';
  @override
  String get devModeActive => '👑 Geliştirici Modu: Premium Aktif Edildi!';
  @override
  String get devModeInactive => 'ℹ️ Geliştirici Modu: Premium Kapatıldı (Test Modu)';

  @override
  String get active => 'AKTİF';
  @override
  String get currentLevel => 'Kaldığın Seviye';
  @override
  String get play => 'Oyna';

  @override
  String get undo => 'Geri Al';
  @override
  String get reset => 'Sıfırla';
  @override
  String get hint => 'İpucu';
  @override
  String get outOfHintsTitle => 'İpucun Bitti';
  @override
  String get outOfHintsDesc =>
      'Daha fazla ipucu almak ister misin? Kısa bir reklam izleyerek 3 ipucu kazanabilirsin.';
  @override
  String get watchAdReward => 'Reklam İzle → +3 İpucu';
  @override
  String get hintsAdded => '+3 İpucu hesabına eklendi! 🎉';
  @override
  String get noHintFound => 'Bu seviye için şu an ipucu bulunamadı!';
  @override
  String get smartHintTitle => 'Akıllı İpucu Rehberi';
  @override
  String smartHintDrawnInfo(int drawn, int total) => '$drawn / $total çizgi çizildi';
  @override
  String get deadEndDesc =>
      'Çizdiğiniz yol önceki bir ayrımda çıkmaza girdi. Tüm çizgileri tamamlamak için rotanın düzeltilmesi gerekiyor.';
  @override
  String get wrongStartDesc =>
      'Bu bulmaca matematiksel olarak yalnızca sarı halkalı başlangıç düğümlerinden başlanarak tek seferde bitirilebilir. Mevcut başlangıç noktanızla tüm çizgileri tamamlamak mümkün değil.';
  @override
  String get previewSolution => 'Çözüm Yolunu Önizle (Çizimini Korur)';
  @override
  String get previewActiveSnackBar =>
      'Tam çözüm yolu 10 sn boyunca numaralı adımlarla gösteriliyor!';
  @override
  String switchToRoute(int steps) => 'Doğru Rotaya Geç (İlk $steps Çizgiyi Tamamla)';
  @override
  String switchedToRouteSnackBar(int steps) =>
      'Doğru rotaya geçildi ve ilk $steps adım çizildi! 🚀';
  @override
  String get cancelHint => 'Vazgeç (İpucu Harcama)';
  @override
  String get congratulations => 'Tebrikler! 🎉';
  @override
  String get mainMenu => 'Ana Menü';
  @override
  String formatTime(int minutes, int seconds) =>
      '${minutes > 0 ? '$minutes dk ' : ''}$seconds sn';
  @override
  String get hintStartMsg => 'Başlangıç noktası ve ilk yön belirlendi! 💡';
  @override
  String get hintNextMsg => 'Doğru sonraki adım bağlandı! 💡';
  @override
  String hintRollbackMsg(int count) =>
      '$count hatalı hamle geri alındı, doğru yön bağlandı! 💡';
  @override
  String get hintWrongStartMsg =>
      'Bu bulmaca yalnızca işaretli başlangıç noktasından çözülebilir! 💡';
  @override
  String get guideFullSolution => 'Çözüm Kılavuzu: Numaraları sırayla takip et';
  @override
  String get guideNextSteps => 'İpucu: Sonraki adımlar parlıyor';
  @override
  String get resultPerfect => 'Mükemmel!';
  @override
  String get resultGreat => 'Harika!';
  @override
  String get resultGood => 'Tamamlandı!';
  @override
  String get replay => 'Tekrar';
  @override
  String get nextLevel => 'Sonraki Seviye';
  @override
  String get difficultyCompleted => 'Bu modun tüm seviyelerini bitirdin! 🏆';
  @override
  String get hintsUsedLabel => 'ipucu';
  @override
  String get noHintBonus => 'İpucusuz';
  @override
  String get timeLabel => 'süre';
  @override
  String get starRule => 'İpucu kullanmadan ve az geri alarak 3 yıldız kazan';

  @override
  String get settings => 'Ayarlar';
  @override
  String get appearance => 'Görünüm';
  @override
  String get darkMode => 'Koyu Mod';
  @override
  String get themeColor => 'Tema Rengi';
  @override
  String get general => 'Genel';
  @override
  String get soundEffects => 'Ses Efektleri';
  @override
  String get haptic => 'Titreşim';
  @override
  String get language => 'Dil';
  @override
  String get selectLanguage => 'Dil Seçin';
  @override
  String get turkish => 'Türkçe';
  @override
  String get english => 'English';
  @override
  String get purchases => 'Satın Alma';
  @override
  String get removeAds => 'Reklamları Kaldır';
  @override
  String get restorePurchases => 'Satın Alımları Geri Yükle';
  @override
  String get checkingPurchases => 'Satın alımlar kontrol ediliyor...';
  @override
  String get about => 'Hakkında';
  @override
  String get privacyPolicy => 'Gizlilik Politikası';
  @override
  String get termsOfUse => 'Kullanım Koşulları (EULA)';
  @override
  String get supportAndFeedback => 'Destek ve Geri Bildirim';
  @override
  String get version => 'Versiyon';

  @override
  String get store => 'Mağaza';
  @override
  String get premiumActive => 'Premium Aktif!';
  @override
  String get premiumActiveDesc => 'Reklamsız deneyimin aktif. Keyifle oyna!';
  @override
  String get removeAdsDesc =>
      'Reklamlar olmadan kesintisiz oyna.\nTek seferlik ödeme, süresiz erişim.';
  @override
  String get allAdsRemoved => 'Tüm reklamlar kaldırılır';
  @override
  String get lifetimeAccess => 'Süresiz erişim';
  @override
  String get allDevices => 'Tüm cihazlarınızda geçerli';
  @override
  String buyPrice(String price) => 'Satın Al — $price';
  @override
  String get adsRemovedChecked => 'Reklamlar kaldırıldı ✓';
  @override
  String get lifetimeAccessChecked => 'Süresiz erişim aktif ✓';

  @override
  String get profile => 'Profil';
  @override
  String get player => 'Oyuncu';
  @override
  String achievementsProgress(int unlocked, int total) => '$unlocked / $total başarım';
  @override
  String get totalStars => 'Toplam Yıldız';
  @override
  String get totalScore => 'Toplam Puan';
  @override
  String get solved => 'Çözülen';
  @override
  String get difficultyProgress => 'Zorluk İlerlemesi';
  @override
  String get achievements => 'Başarımlar';
}

/// İngilizce Çeviriler
class AppStringsEn implements AppStrings {
  const AppStringsEn();

  @override
  String get appName => 'Line Puzzle';
  @override
  String get slogan => 'Draw. Solve. Win.';
  @override
  String get cancel => 'Cancel';
  @override
  String get continueText => 'Continue';
  @override
  String get ok => 'OK';
  @override
  String get close => 'Close';
  @override
  String get level => 'Level';
  @override
  String get moves => 'moves';
  @override
  String linesCount(int count) => '$count lines';
  @override
  String drawnLinesProgress(int drawn, int total) => '$drawn / $total lines';

  @override
  String get difficultyEasy => 'Easy';
  @override
  String get difficultyMedium => 'Medium';
  @override
  String get difficultyHard => 'Hard';
  @override
  String get difficultyExpert => 'Expert';
  @override
  String get difficultyModes => 'Difficulty Modes';
  @override
  String get totalLevelsCount => '1200 Levels';

  @override
  String get skip => 'Skip';
  @override
  String get next => 'Next';
  @override
  String get start => 'Start';
  @override
  String get onboarding1Title => 'Without Lifting Your Finger';
  @override
  String get onboarding1Subtitle =>
      'Complete the shape in a single stroke.\nPass through each edge only once.';
  @override
  String get onboarding2Title => 'Difficulty For You';
  @override
  String get onboarding2Subtitle =>
      'Easy, Medium, Hard and Expert —\n1200 levels at your own pace.';
  @override
  String get onboarding3Title => 'Earn Stars, Break Records';
  @override
  String get onboarding3Subtitle =>
      'Aim for 3 stars on every level.\nCollect hints, unlock achievements.';

  @override
  String get continuePlaying => 'CONTINUE PLAYING';
  @override
  String levelAndName(int level, String name) => 'Level $level • $name';
  @override
  String levelProgress(int unlocked, int total, int completed) =>
      '$completed / $total completed';
  @override
  String get map => 'Map';
  @override
  String get storeTooltip => 'Store';
  @override
  String get profileTooltip => 'Profile';
  @override
  String get settingsTooltip => 'Settings';
  @override
  String get devModeActive => '👑 Developer Mode: Premium Activated!';
  @override
  String get devModeInactive => 'ℹ️ Developer Mode: Premium Deactivated (Test Mode)';

  @override
  String get active => 'ACTIVE';
  @override
  String get currentLevel => 'Current Level';
  @override
  String get play => 'Play';

  @override
  String get undo => 'Undo';
  @override
  String get reset => 'Reset';
  @override
  String get hint => 'Hint';
  @override
  String get outOfHintsTitle => 'Out of Hints';
  @override
  String get outOfHintsDesc =>
      'Would you like more hints? Watch a short ad to earn 3 hints.';
  @override
  String get watchAdReward => 'Watch Ad → +3 Hints';
  @override
  String get hintsAdded => '+3 Hints added to your account! 🎉';
  @override
  String get noHintFound => 'No hint found for this level right now!';
  @override
  String get smartHintTitle => 'Smart Hint Guide';
  @override
  String smartHintDrawnInfo(int drawn, int total) => '$drawn / $total lines drawn';
  @override
  String get deadEndDesc =>
      'Your path reached a dead end. The route needs to be adjusted to complete all lines.';
  @override
  String get wrongStartDesc =>
      'Mathematically, this puzzle can only be completed starting from yellow-ringed nodes. It is not possible to finish all lines from your current start point.';
  @override
  String get previewSolution => 'Preview Solution (Keeps Drawing)';
  @override
  String get previewActiveSnackBar =>
      'Full solution path is shown with numbered steps for 10s!';
  @override
  String switchToRoute(int steps) => 'Switch to Route (Draw First $steps Lines)';
  @override
  String switchedToRouteSnackBar(int steps) =>
      'Switched to correct route and drew first $steps steps! 🚀';
  @override
  String get cancelHint => 'Cancel (Keep Hint)';
  @override
  String get congratulations => 'Congratulations! 🎉';
  @override
  String get mainMenu => 'Main Menu';
  @override
  String formatTime(int minutes, int seconds) =>
      '${minutes > 0 ? '$minutes m ' : ''}$seconds s';
  @override
  String get hintStartMsg => 'Start point and first direction revealed! 💡';
  @override
  String get hintNextMsg => 'Correct next step connected! 💡';
  @override
  String hintRollbackMsg(int count) =>
      'Undid $count wrong moves and connected the right way! 💡';
  @override
  String get hintWrongStartMsg =>
      'This puzzle can only be solved from the marked start point! 💡';
  @override
  String get guideFullSolution => 'Solution Guide: Follow the numbers in order';
  @override
  String get guideNextSteps => 'Hint: Next steps are glowing';
  @override
  String get resultPerfect => 'Perfect!';
  @override
  String get resultGreat => 'Great!';
  @override
  String get resultGood => 'Completed!';
  @override
  String get replay => 'Replay';
  @override
  String get nextLevel => 'Next Level';
  @override
  String get difficultyCompleted => 'You finished every level in this mode! 🏆';
  @override
  String get hintsUsedLabel => 'hints';
  @override
  String get noHintBonus => 'No hints';
  @override
  String get timeLabel => 'time';
  @override
  String get starRule => 'Earn 3 stars with no hints and few undos';

  @override
  String get settings => 'Settings';
  @override
  String get appearance => 'Appearance';
  @override
  String get darkMode => 'Dark Mode';
  @override
  String get themeColor => 'Theme Color';
  @override
  String get general => 'General';
  @override
  String get soundEffects => 'Sound Effects';
  @override
  String get haptic => 'Haptic Feedback';
  @override
  String get language => 'Language';
  @override
  String get selectLanguage => 'Select Language';
  @override
  String get turkish => 'Türkçe';
  @override
  String get english => 'English';
  @override
  String get purchases => 'Purchases';
  @override
  String get removeAds => 'Remove Ads';
  @override
  String get restorePurchases => 'Restore Purchases';
  @override
  String get checkingPurchases => 'Checking purchases...';
  @override
  String get about => 'About';
  @override
  String get privacyPolicy => 'Privacy Policy';
  @override
  String get termsOfUse => 'Terms of Use (EULA)';
  @override
  String get supportAndFeedback => 'Support & Feedback';
  @override
  String get version => 'Version';

  @override
  String get store => 'Store';
  @override
  String get premiumActive => 'Premium Active!';
  @override
  String get premiumActiveDesc => 'Your ad-free experience is active. Enjoy playing!';
  @override
  String get removeAdsDesc =>
      'Play uninterrupted without ads.\nOne-time purchase, lifetime access.';
  @override
  String get allAdsRemoved => 'All ads removed';
  @override
  String get lifetimeAccess => 'Lifetime access';
  @override
  String get allDevices => 'Valid across all your devices';
  @override
  String buyPrice(String price) => 'Buy — $price';
  @override
  String get adsRemovedChecked => 'Ads removed ✓';
  @override
  String get lifetimeAccessChecked => 'Lifetime access active ✓';

  @override
  String get profile => 'Profile';
  @override
  String get player => 'Player';
  @override
  String achievementsProgress(int unlocked, int total) => '$unlocked / $total achievements';
  @override
  String get totalStars => 'Total Stars';
  @override
  String get totalScore => 'Total Score';
  @override
  String get solved => 'Solved';
  @override
  String get difficultyProgress => 'Difficulty Progress';
  @override
  String get achievements => 'Achievements';
}

/// BuildContext için kolay erişim extension'ı
extension AppStringsX on BuildContext {
  /// build() içinde: dil değişince widget'ı yeniden çizer
  AppStrings get l10n => AppStrings.of(this);

  /// Olay işleyicileri ve callback'ler için (dinlemez; build dışında watch yasak)
  AppStrings get l10nRead => AppStrings.get(read<SettingsProvider>().locale);
}
