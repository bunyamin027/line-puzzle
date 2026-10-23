import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/settings_provider.dart';
import 'core/services/game_provider.dart';
import 'core/services/achievement_provider.dart';
import 'core/services/ad_service.dart';
import 'core/services/iap_service.dart';
import 'core/utils/app_router.dart';
import 'core/constants/app_constants.dart';

/// Çizgi Bulmaca — Ana Giriş Noktası
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dikey yönlendirmeyi zorunlu kıl (bulmaca oyunu için ideal)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar stilini ayarla
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // AdMob SDK'yı başlat
  await AdService.instance.initialize();

  runApp(const CizgiBulmacaApp());
}

class CizgiBulmacaApp extends StatelessWidget {
  const CizgiBulmacaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        // AchievementProvider GameProvider'a bağımlı
        // lazy: false — kayıtlı başarımlar açılışta yüklensin; aksi halde ilk
        // seviye bitişinde yükleme bitmeden kontrol yapılıp eski başarımlar
        // yeniden bildiriliyordu.
        ChangeNotifierProxyProvider<GameProvider, AchievementProvider>(
          lazy: false,
          create: (ctx) => AchievementProvider(ctx.read<GameProvider>()),
          update: (ctx, gameProvider, previous) =>
              previous ?? AchievementProvider(gameProvider),
        ),
        // IapService SettingsProvider'a bağımlı
        ChangeNotifierProxyProvider<SettingsProvider, IapService>(
          create: (ctx) => IapService(ctx.read<SettingsProvider>()),
          update: (ctx, settingsProvider, previous) =>
              previous ?? IapService(settingsProvider),
        ),
      ],
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settingsProvider, child) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            locale: Locale(settingsProvider.locale),

            // Tema
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,

            // Router
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
