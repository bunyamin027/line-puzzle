import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/level_map/level_map_screen.dart';
import '../../features/game/game_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/store/store_screen.dart';
import '../../features/profile/profile_screen.dart';

/// Çizgi Bulmaca — GoRouter Yapılandırması
class AppRouter {
  AppRouter._();

  /// Solarak ve hafifçe yukarı kayarak açılan sayfa geçişi.
  /// Yalnızca `go` ile açılan kök ekranlarda kullanılır; push edilen ekranlar
  /// iOS'ta kenardan kaydırarak geri dönebilmek için varsayılan sayfayı korur.
  static CustomTransitionPage<void> _page(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
            child: ScaleTransition(
              scale: Tween(begin: 0.985, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Splash
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => _page(state, const OnboardingScreen()),
      ),

      // Ana Sayfa (Mod Seçimi)
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => _page(state, const HomeScreen()),
      ),

      // Level Haritası
      GoRoute(
        path: '/levels/:difficulty',
        name: 'levels',
        builder: (context, state) {
          final difficulty = int.tryParse(
                state.pathParameters['difficulty'] ?? '0',
              ) ?? 0;
          return LevelMapScreen(difficulty: difficulty);
        },
      ),

      // Oynanış Ekranı
      GoRoute(
        path: '/game/:levelId',
        name: 'game',
        builder: (context, state) {
          final levelId = int.tryParse(
                state.pathParameters['levelId'] ?? '1',
              ) ?? 1;
          final difficulty = int.tryParse(
                state.uri.queryParameters['d'] ?? '0',
              ) ?? 0;
          return GameScreen(levelId: levelId, difficulty: difficulty);
        },
      ),

      // Ayarlar
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Mağaza (Reklamları Kaldır)
      GoRoute(
        path: '/store',
        name: 'store',
        builder: (context, state) => const StoreScreen(),
      ),

      // Profil & Başarımlar
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
