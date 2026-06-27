import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'core/router.dart';
import 'providers/app_settings_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/workspace_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;

TextStyle _appFont({
  Paint? background,
  Color? backgroundColor,
  Color? color,
  TextDecoration? decoration,
  Color? decorationColor,
  TextDecorationStyle? decorationStyle,
  double? decorationThickness,
  List<ui.FontFeature>? fontFeatures,
  double? fontSize,
  FontStyle? fontStyle,
  FontWeight? fontWeight,
  Paint? foreground,
  double? height,
  double? letterSpacing,
  Locale? locale,
  List<ui.Shadow>? shadows,
  TextBaseline? textBaseline,
  TextStyle? textStyle,
  double? wordSpacing,
}) {
  return TextStyle(
    fontFamily: 'Pliant',
    background: background,
    backgroundColor: backgroundColor,
    color: color,
    decoration: decoration,
    decorationColor: decorationColor,
    decorationStyle: decorationStyle,
    decorationThickness: decorationThickness,
    fontFeatures: fontFeatures,
    fontSize: fontSize,
    fontStyle: fontStyle,
    fontWeight: fontWeight,
    foreground: foreground,
    height: height,
    letterSpacing: letterSpacing,
    locale: locale,
    shadows: shadows,
    textBaseline: textBaseline,
    wordSpacing: wordSpacing,
  ).merge(textStyle);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
            textTheme: ShadTextTheme.fromGoogleFont(_appFont), // Can still use fromGoogleFont because our _appFont matches the signature
            radius: BorderRadius.circular(12),
            primaryToastTheme: const ShadToastTheme(alignment: Alignment.topCenter),
            destructiveToastTheme: const ShadToastTheme(alignment: Alignment.topCenter),
          ),
          darkTheme: ShadThemeData(
            brightness: Brightness.dark,
            colorScheme: _getColorScheme(settings.themeColorName, true),
            textTheme: ShadTextTheme.fromGoogleFont(_appFont),
            radius: BorderRadius.circular(12),
            primaryToastTheme: const ShadToastTheme(alignment: Alignment.topCenter),
            destructiveToastTheme: const ShadToastTheme(alignment: Alignment.topCenter),
          ),
          routerConfig: router,
          builder: (context, child) {
            return GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: child,
            );
          },
        );
      },
    );
  }
}
