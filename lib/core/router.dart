import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../features/splash/splash_screen.dart';

import '../features/auth/login_screen.dart';
import '../features/main/main_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    if (settings.isLoading && state.uri.path != '/') {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainScreen(),
    ),
  ],
);
