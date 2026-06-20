import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'core/router.dart';
import 'providers/app_settings_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/workspace_provider.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => WorkspaceProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

Color? _parseColor(String colorStr) {
  if (colorStr.startsWith('#')) {
    String hex = colorStr.replaceAll('#', '').toUpperCase();
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
  }
  return null;
}

ShadColorScheme _getColorScheme(String colorString, bool isDarkMode) {
  switch (colorString) {
    case 'blue':
      return isDarkMode ? const ShadBlueColorScheme.dark() : const ShadBlueColorScheme.light();
    case 'rose':
      return isDarkMode ? const ShadRoseColorScheme.dark() : const ShadRoseColorScheme.light();
    case 'violet':
      return isDarkMode ? const ShadVioletColorScheme.dark() : const ShadVioletColorScheme.light();
    case 'zinc':
      return isDarkMode ? const ShadZincColorScheme.dark() : const ShadZincColorScheme.light();
    default:
      final customPrimary = _parseColor(colorString);
      var base = isDarkMode ? const ShadZincColorScheme.dark() : const ShadZincColorScheme.light();
      if (customPrimary != null) {
        return base.copyWith(primary: customPrimary);
      }
      return base;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettingsProvider, ThemeProvider>(
      builder: (context, settings, themeProvider, child) {
        return ShadApp.router(
          title: settings.appName,
          themeMode: themeProvider.themeMode,
          theme: ShadThemeData(
            brightness: Brightness.light,
            colorScheme: _getColorScheme(settings.themeColorName, false),
            textTheme: ShadTextTheme.fromGoogleFont(GoogleFonts.plusJakartaSans),
            radius: BorderRadius.circular(12),
            primaryToastTheme: const ShadToastTheme(alignment: Alignment.topCenter),
            destructiveToastTheme: const ShadToastTheme(alignment: Alignment.topCenter),
          ),
          darkTheme: ShadThemeData(
            brightness: Brightness.dark,
            colorScheme: _getColorScheme(settings.themeColorName, true),
            textTheme: ShadTextTheme.fromGoogleFont(GoogleFonts.plusJakartaSans),
            radius: BorderRadius.circular(12),
            primaryToastTheme: const ShadToastTheme(alignment: Alignment.topCenter),
            destructiveToastTheme: const ShadToastTheme(alignment: Alignment.topCenter),
          ),
          routerConfig: router,
        );
      },
    );
  }
}
